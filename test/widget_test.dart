import 'dart:async';
import 'dart:typed_data';

import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentinel/core/common/application/cache_helper.dart';
import 'package:sentinel/core/common/application/riverpod/user_prefs.dart';
import 'package:sentinel/core/common/entities/host.dart';
import 'package:sentinel/core/common/singelton/core.dart';
import 'package:sentinel/core/common/singelton/user_prefs.dart';
import 'package:sentinel/core/enums/ssh_auth_type.dart';
import 'package:sentinel/core/res/style/theme_tokens.dart';
import 'package:sentinel/core/services/injection_container.dart';
import 'package:sentinel/core/widgets/sentinel_botton.dart';
import 'package:sentinel/core/widgets/sentinel_primary_button.dart';
import 'package:sentinel/core/widgets/sentinel_status_pill.dart';
import 'package:sentinel/src/groups/data/model/server_group_model.dart';
import 'package:sentinel/src/hosts/presention/app/adapter/hosts_adapter.dart';
import 'package:sentinel/src/sftp/domain/entities/sftp_entry.dart';
import 'package:sentinel/src/sftp/presention/adapter/sftp_editor_helper.dart';
import 'package:sentinel/src/sftp/presention/views/sentinel_sftp_view.dart';
import 'package:sentinel/src/ssh/presention/app/adapter/ssh_adapter.dart';
import 'package:sentinel/src/ssh/widget/glass_terminal_accessory_bar.dart';
import 'package:sentinel/src/ssh/widget/no_active_host.dart';
import 'package:sentinel/src/ssh/widget/terminal_modifier_controller.dart';
import 'package:sentinel/src/ssh/widget/terminal_session_body.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xterm2/core.dart';
import 'package:xterm2/ui.dart';

class _FakeSSHClient extends Fake implements SSHClient {
  _FakeSSHClient({this.installedEditorOutput = 'nano\n'});

  final String installedEditorOutput;

  @override
  Future<Uint8List> run(
    String command, {
    bool runInPty = false,
    bool stdout = true,
    bool stderr = true,
    Map<String, String>? environment,
  }) async {
    return Uint8List.fromList(installedEditorOutput.codeUnits);
  }
}

class _FakeSSHSession extends Fake implements SSHSession {}

class _FakeSshAdapter extends SshAdapter {
  @override
  Map<int, SshState> build() => const {};
}

class _FakeHostsAdapter extends HostsAdapter {
  @override
  HostsState build() {
    return HostsLoaded([
      Host(
        id: 1,
        hostname: 'prod-web-01',
        ip: '10.0.0.12',
        port: 22,
        username: 'ubuntu',
        authType: SshAuthType.password,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      ),
    ]);
  }
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    if (sl.isRegistered<CacheHelper>()) {
      await sl.unregister<CacheHelper>();
    }
    sl.registerLazySingleton<CacheHelper>(() => CacheHelper(prefs));
  });

  group('Theme & Preferences Defaults', () {
    test(
      'Default theme mode is ThemeMode.dark across UserPrefs and CacheHelper',
      () {
        const prefs = UserPrefs();
        expect(prefs.themeMode, equals(ThemeMode.dark));
        expect(Cache.instance.themeModeNotifier.value, equals(ThemeMode.dark));

        final cacheHelper = sl<CacheHelper>();
        expect(cacheHelper.getThemeMode(), equals(ThemeMode.dark));
        expect(cacheHelper.getUserPrefs().themeMode, equals(ThemeMode.dark));
      },
    );
  });

  group('ServerGroupModel', () {
    test('serializes and deserializes group data accurately', () {
      final model = ServerGroupModel(
        id: 7,
        name: 'Production Cluster',
        description: 'Primary AWS nodes',
        iconName: 'cloud',
        colorHex: '#4ADE80',
        createdAt: DateTime(2026, 10, 24),
        updatedAt: DateTime(2026, 10, 24),
      );

      final map = model.toMap();
      final restored = ServerGroupModel.fromMap(map);

      expect(restored, equals(model));
      expect(restored.name, equals('Production Cluster'));
      expect(restored.iconName, equals('cloud'));
      expect(restored.colorHex, equals('#4ADE80'));
    });
  });

  group('SFTP Editor & Entry Helpers', () {
    test(
      'SftpEditorHelper builds nano command and falls back when nano is absent',
      () async {
        expect(
          SftpEditorHelper.buildEditorCommand(
            editor: 'nano',
            remotePath: '/etc/nginx/sites-available/default.conf',
          ),
          equals('nano "/etc/nginx/sites-available/default.conf"'),
        );

        final nanoClient = _FakeSSHClient(installedEditorOutput: 'nano\n');
        expect(
          await SftpEditorHelper.detectInstalledEditor(nanoClient),
          equals('nano'),
        );

        final vimFallbackClient = _FakeSSHClient(
          installedEditorOutput: 'vim\n',
        );
        final fallbackEditor = await SftpEditorHelper.detectInstalledEditor(
          vimFallbackClient,
        );
        expect(fallbackEditor, equals('vim'));
        expect(
          SftpEditorHelper.buildEditorCommand(
            editor: fallbackEditor,
            remotePath: '/var/log/app log.txt',
          ),
          equals('vim "/var/log/app log.txt"'),
        );
      },
    );

    test('SftpEntry formats file sizes and directories accurately', () {
      const dirEntry = SftpEntry(
        name: 'configs',
        fullPath: '/home/ubuntu/configs',
        isDirectory: true,
        isSymbolicLink: false,
      );
      const fileEntry = SftpEntry(
        name: 'app.log',
        fullPath: '/home/ubuntu/app.log',
        isDirectory: false,
        isSymbolicLink: false,
        size: 2048,
        permissionsOctal: '644',
      );

      expect(dirEntry.formattedSize, equals('Folder'));
      expect(fileEntry.formattedSize, equals('2.0 KB'));
    });

    test(
      'TerminalModifierController transforms any key when Ctrl or Alt is active and resets',
      () {
        TerminalModifierController.reset();
        expect(TerminalModifierController.state.isActive, isFalse);

        // Arm Ctrl and send 'x' -> should emit Ctrl+X (0x18) and auto-reset
        TerminalModifierController.toggleCtrl();
        expect(TerminalModifierController.state.ctrl, isTrue);

        final ctrlX = TerminalModifierController.applyAndConsume('x');
        expect(ctrlX.codeUnitAt(0), equals(0x18));
        expect(TerminalModifierController.state.isActive, isFalse);

        // Subsequent 'x' without Ctrl armed passes through unchanged
        expect(TerminalModifierController.applyAndConsume('x'), equals('x'));

        // Arm Ctrl and send 'o' -> should emit Ctrl+O (0x0F)
        TerminalModifierController.toggleCtrl();
        final ctrlO = TerminalModifierController.applyAndConsume('o');
        expect(ctrlO.codeUnitAt(0), equals(0x0F));

        // Arm Alt and send 'f' -> should emit ESC + 'f'
        TerminalModifierController.toggleAlt();
        final altF = TerminalModifierController.applyAndConsume('f');
        expect(altF, equals('\x1bf'));
        expect(TerminalModifierController.state.isActive, isFalse);
      },
    );
  });

  group('Core Widgets & NoActiveHost Sheet', () {
    testWidgets(
      'Sentinel core widgets expose accessible semantics without overflow',
      (WidgetTester tester) async {
        final handle = tester.ensureSemantics();
        final tokens = SentinelThemeTokens(true);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  SentinelPrimaryButton(
                    tokens: tokens,
                    label: 'Connect Host',
                    icon: Icons.terminal_rounded,
                    onPressed: () {},
                  ),
                  SentinelStatusPill(
                    tokens: tokens,
                    label: '3 Active',
                    showDot: true,
                  ),
                  SentinelButton(
                    tokens: tokens,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, size: 14),
                        SizedBox(width: 6),
                        Text('New Group'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        expect(find.bySemanticsLabel('Connect Host'), findsOneWidget);
        expect(find.text('3 Active'), findsOneWidget);
        expect(find.text('New Group'), findsOneWidget);
        expect(tester.takeException(), isNull);

        handle.dispose();
      },
    );

    testWidgets(
      'NoActiveHost Select a Host button opens OpenTerminalHostSheet modal',
      (WidgetTester tester) async {
        final tokens = SentinelThemeTokens(true);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              hostsAdapterProvider.overrideWith(_FakeHostsAdapter.new),
              sshAdapterProvider.overrideWith(_FakeSshAdapter.new),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: NoActiveHost(
                  onToggleTheme: () {},
                  tokens: tokens,
                ),
              ),
            ),
          ),
        );

        expect(find.text('No Active SSH Sessions'), findsOneWidget);
        expect(find.text('Select a Host'), findsOneWidget);

        await tester.tap(find.text('Select a Host'));
        await tester.pumpAndSettle();

        expect(find.text('Open SSH Terminal'), findsOneWidget);
        expect(find.text('prod-web-01'), findsOneWidget);
      },
    );
  });

  group('TerminalSessionBody interactions', () {
    testWidgets(
      'keeps keyboard locked during pinch-to-zoom, unlocks on single tap, and shows Copy bar on selection',
      (WidgetTester tester) async {
        final tokens = SentinelThemeTokens(true);
        final terminal = Terminal(maxLines: 200);
        terminal.write('sentinel@prod-web-01:~\$ ls -la\r\n');

        final host = Host.test();
        final stdoutSub = const Stream<Uint8List>.empty().listen((_) {});
        final stderrSub = const Stream<Uint8List>.empty().listen((_) {});
        addTearDown(() async {
          await stdoutSub.cancel();
          await stderrSub.cancel();
        });

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: SizedBox(
                  width: 400,
                  height: 500,
                  child: TerminalSessionBody(
                    activeHost: host,
                    activeHostId: 1,
                    sshState: SshConnected(
                      client: _FakeSSHClient(),
                      session: _FakeSSHSession(),
                      terminal: terminal,
                      host: host,
                      stdoutSubscription: stdoutSub,
                      stderrSubscription: stderrSub,
                    ),
                    tokens: tokens,
                    isDark: true,
                    onReconnect: () {},
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        TerminalView terminalView() =>
            tester.widget<TerminalView>(find.byType(TerminalView));

        // 1. Initially readOnly is true so pinch/long-press won't pop up keyboard
        expect(terminalView().readOnly, isTrue);
        expect(terminalView().hardwareKeyboardOnly, isFalse);

        // 2. Single tap unlocks the soft keyboard (readOnly -> false)
        await tester.tap(find.byType(TerminalView));
        await tester.pump();
        expect(terminalView().readOnly, isFalse);

        // 3. Two-finger pinch-to-zoom immediately locks/closes keyboard and scales font size
        final center = tester.getCenter(find.byType(TerminalView));
        final g1 = await tester.startGesture(center - const Offset(30, 0));
        final g2 = await tester.startGesture(center + const Offset(30, 0));
        await tester.pump();

        expect(terminalView().readOnly, isTrue);

        await g1.moveTo(center - const Offset(90, 0));
        await g2.moveTo(center + const Offset(90, 0));
        await tester.pump();

        final container = ProviderScope.containerOf(
          tester.element(find.byType(TerminalSessionBody)),
        );
        expect(
          container.read(userPrefsProvider).terminalFontSize,
          greaterThan(UserPrefs.defaultFontSize),
        );

        await g1.up();
        await g2.up();
        await tester.pump();

        // 4. Selecting text shows the floating Copy / Paste / All toolbar
        final controller = terminalView().controller!;
        controller.setSelection(
          terminal.buffer.createAnchor(0, 0),
          terminal.buffer.createAnchor(8, 0),
        );
        await tester.pump();

        expect(find.text('Copy'), findsOneWidget);
        expect(find.text('Paste'), findsOneWidget);
        expect(find.text('All'), findsOneWidget);
      },
    );

    testWidgets(
      'GlassTerminalAccessoryBar renders sticky ctrl/alt and ctrl+x/ctrl+o shortcuts',
      (WidgetTester tester) async {
        TerminalModifierController.reset();
        final tokens = SentinelThemeTokens(true);
        final terminal = Terminal(maxLines: 100);
        String? lastOutput;
        terminal.onOutput = (data) {
          lastOutput = TerminalModifierController.applyAndConsume(data);
        };

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: GlassTerminalAccessoryBar(
                terminal: terminal,
                tokens: tokens,
                isDark: true,
              ),
            ),
          ),
        );

        expect(find.text('ctrl'), findsOneWidget);
        expect(find.text('alt'), findsOneWidget);
        expect(find.text('ctrl+x'), findsOneWidget);
        expect(find.text('ctrl+o'), findsOneWidget);

        // Tap sticky 'ctrl' button, then simulate typing 'w' on the terminal
        await tester.tap(find.text('ctrl'));
        await tester.pump();
        expect(find.text('ctrl •'), findsOneWidget);

        terminal.textInput('w');
        expect(lastOutput?.codeUnitAt(0), equals(0x17)); // Ctrl+W = 0x17
        await tester.pump();
        expect(find.text('ctrl'), findsOneWidget);

        // Tap direct 'ctrl+x' button
        await tester.tap(find.text('ctrl+x'));
        await tester.pump();
        expect(lastOutput?.codeUnitAt(0), equals(0x18)); // Ctrl+X = 0x18
      },
    );

    testWidgets(
      'SentinelSftpView renders full-screen SFTP view when no host is selected',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              hostsAdapterProvider.overrideWith(_FakeHostsAdapter.new),
              sshAdapterProvider.overrideWith(_FakeSshAdapter.new),
            ],
            child: const MaterialApp(
              home: Scaffold(
                body: SentinelSftpView(),
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.text('SFTP Browser'), findsOneWidget);
        expect(find.text('No Host Selected'), findsOneWidget);
        expect(find.text('Select Host'), findsOneWidget);
      },
    );
  });
}
