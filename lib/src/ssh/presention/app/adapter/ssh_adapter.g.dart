// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ssh_adapter.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SshAdapter)
final sshAdapterProvider = SshAdapterProvider._();

final class SshAdapterProvider
    extends $NotifierProvider<SshAdapter, Map<int, SshState>> {
  SshAdapterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sshAdapterProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sshAdapterHash();

  @$internal
  @override
  SshAdapter create() => SshAdapter();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<int, SshState> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<int, SshState>>(value),
    );
  }
}

String _$sshAdapterHash() => r'657ed1e2c3aeb76b5dedb9b4d81b3d09a4c7c8fa';

abstract class _$SshAdapter extends $Notifier<Map<int, SshState>> {
  Map<int, SshState> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<Map<int, SshState>, Map<int, SshState>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Map<int, SshState>, Map<int, SshState>>,
              Map<int, SshState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
