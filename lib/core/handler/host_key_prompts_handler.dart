import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sentinel/core/common/entities/host.dart';
import 'package:sentinel/core/enums/os_names.dart';
import 'package:sentinel/core/extensions/context_extension.dart';
import 'package:sentinel/core/res/style/theme_tokens.dart';
import 'package:sentinel/core/services/router.dart';
import 'package:sentinel/core/utils/core_utils.dart';
import 'package:sentinel/core/widgets/distro_avatar.dart';
import 'package:sentinel/core/widgets/glass_card.dart';
import 'package:sentinel/core/widgets/sentinel_botton.dart';
import 'package:sentinel/core/widgets/sentinel_primary_button.dart';
import 'package:sentinel/core/widgets/sentinel_status_pill.dart';
import 'package:sentinel/core/widgets/sentinel_toast.dart';

abstract class PromptHandler {
  const PromptHandler();
  Future<bool> verifyHostKeyPromptsHandler({
    required Host host,
    required String keyType,
    required Uint8List fingerprint,
    required bool isFirstConnection,
    required String presentedFingerprint,
  });

  Future<bool> confirmDeletion({required Host host});
}

class PromptsHandlerImpl implements PromptHandler {
  const PromptsHandlerImpl();

  static String formatFingerprintHex(Uint8List bytes, String fallback) {
    if (bytes.isEmpty) return fallback;
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(':');
  }

  @override
  Future<bool> verifyHostKeyPromptsHandler({
    required Host host,
    required String keyType,
    required Uint8List fingerprint,
    required bool isFirstConnection,
    required String presentedFingerprint,
  }) async {
    final context = rootNavigatorKey.currentContext;
    if (context == null || !context.mounted) return false;

    final formattedFingerprint = formatFingerprintHex(
      fingerprint,
      presentedFingerprint,
    );

    final accepted = await _showSentinelGlassDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext, tokens, isDark) {
        final accentColor = isFirstConnection
            ? tokens.greenAccent
            : tokens.redAccent;
        final textAccentColor = isFirstConnection
            ? tokens.greenTextAccent
            : tokens.redTextAccent;

        return _SentinelDialogShell(
          tokens: tokens,
          accentColor: accentColor,
          icon: isFirstConnection
              ? Icons.fingerprint_rounded
              : Icons.gpp_maybe_rounded,
          badgeSubtitle: isFirstConnection
              ? 'NEW SSH IDENTITY'
              : 'SECURITY WARNING',
          title: isFirstConnection
              ? 'Trust SSH Host Key?'
              : 'Host Key Changed!',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _HostSummaryPill(host: host, tokens: tokens),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: tokens.innerPillSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: tokens.innerPillBorder, width: 0.9),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'ALGORITHM',
                          style: TextStyle(
                            color: tokens.textMuted,
                            fontSize: 10,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                        SentinelStatusPill(
                          tokens: tokens,
                          label: keyType,
                          color: tokens.blueAccent,
                          borderRadius: 8,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Divider(
                      height: 1,
                      thickness: 0.7,
                      color: tokens.dividerColor,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'FINGERPRINT',
                          style: TextStyle(
                            color: tokens.textMuted,
                            fontSize: 10,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                        Semantics(
                          button: true,
                          label: 'Copy fingerprint',
                          child: InkWell(
                            onTap: () {
                              Clipboard.setData(
                                ClipboardData(text: formattedFingerprint),
                              );
                              CoreUtils.showToast(
                                'SSH fingerprint copied to clipboard',
                                title: 'Copied',
                                type: SentinelToastType.info,
                              );
                            },
                            borderRadius: BorderRadius.circular(6),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.copy_rounded,
                                    size: 12,
                                    color: textAccentColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Copy',
                                    style: TextStyle(
                                      color: textAccentColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    SelectableText(
                      formattedFingerprint,
                      style: TextStyle(
                        color: tokens.textPrimary,
                        fontSize: 11.5,
                        fontFamily: 'monospace',
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.30),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      isFirstConnection
                          ? Icons.shield_outlined
                          : Icons.warning_amber_rounded,
                      size: 16,
                      color: textAccentColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isFirstConnection
                            ? 'First connection to this host. Verify the fingerprint matches your server before trusting.'
                            : 'This server presented a different key than previously trusted. This may indicate a server rebuild or a man-in-the-middle attack.',
                        style: TextStyle(
                          color: tokens.textSecondary,
                          fontSize: 11.5,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: SentinelButton(
                      tokens: tokens,
                      isDark: isDark,
                      width: null,
                      height: 46,
                      borderRadius: 14,
                      semanticLabel: 'Reject host key',
                      onTap: () => Navigator.of(dialogContext).pop(false),
                      child: Text(
                        'Reject',
                        style: TextStyle(
                          color: tokens.textPrimary,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: isFirstConnection
                        ? SentinelPrimaryButton(
                            tokens: tokens,
                            label: 'Trust & Connect',
                            icon: Icons.verified_user_outlined,
                            borderRadius: 14,
                            onPressed: () =>
                                Navigator.of(dialogContext).pop(true),
                          )
                        : _SentinelDangerButton(
                            label: 'Accept New Key',
                            icon: Icons.gpp_maybe_rounded,
                            onTap: () => Navigator.of(dialogContext).pop(true),
                          ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    return accepted ?? false;
  }

  @override
  Future<bool> confirmDeletion({required Host host}) async {
    final context = rootNavigatorKey.currentContext;
    if (context == null || !context.mounted) return false;

    final confirmed = await _showSentinelGlassDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext, tokens, isDark) {
        return _SentinelDialogShell(
          tokens: tokens,
          accentColor: tokens.redAccent,
          icon: Icons.delete_outline_rounded,
          badgeSubtitle: 'DESTRUCTIVE ACTION',
          title: 'Delete Host?',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _HostSummaryPill(host: host, tokens: tokens),
              const SizedBox(height: 12),
              Text(
                'Are you sure you want to permanently remove "${host.hostname}" and its encrypted SSH credentials from your vault? This action cannot be undone.',
                style: TextStyle(
                  color: tokens.textSecondary,
                  fontSize: 12.5,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: SentinelButton(
                      tokens: tokens,
                      isDark: isDark,
                      width: null,
                      height: 46,
                      borderRadius: 14,
                      semanticLabel: 'Cancel deletion',
                      onTap: () => Navigator.of(dialogContext).pop(false),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: tokens.textPrimary,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SentinelDangerButton(
                      label: 'Delete Host',
                      icon: Icons.delete_outline_rounded,
                      onTap: () => Navigator.of(dialogContext).pop(true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    return confirmed ?? false;
  }
}

Future<T?> _showSentinelGlassDialog<T>({
  required BuildContext context,
  required bool barrierDismissible,
  required Widget Function(
    BuildContext dialogContext,
    SentinelThemeTokens tokens,
    bool isDark,
  )
  builder,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: 'Dismiss dialog',
    barrierColor: Colors.black.withValues(alpha: 0.55),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (dialogContext, _, _) {
      final isDark = dialogContext.isDarkMode;
      final tokens = SentinelThemeTokens(isDark);
      return Center(
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            bottom: MediaQuery.viewInsetsOf(dialogContext).bottom,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 365),
            child: Material(
              color: Colors.transparent,
              child: builder(dialogContext, tokens, isDark),
            ),
          ),
        ),
      );
    },
    transitionBuilder: (context, animation, _, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeIn,
      );
      return BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 8 * animation.value,
          sigmaY: 8 * animation.value,
        ),
        child: FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1.0).animate(curved),
            child: child,
          ),
        ),
      );
    },
  );
}

class _SentinelDialogShell extends StatelessWidget {
  const _SentinelDialogShell({
    required this.tokens,
    required this.accentColor,
    required this.icon,
    required this.badgeSubtitle,
    required this.title,
    required this.child,
  });

  final SentinelThemeTokens tokens;
  final Color accentColor;
  final IconData icon;
  final String badgeSubtitle;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      tokens: tokens,
      borderRadius: 24,
      padding: const EdgeInsets.all(18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accentColor.withValues(alpha: 0.15),
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.35),
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.25),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Icon(icon, size: 20, color: accentColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      badgeSubtitle,
                      style: TextStyle(
                        color: accentColor == tokens.redAccent
                            ? tokens.redTextAccent
                            : tokens.greenTextAccent,
                        fontSize: 10,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Semantics(
                      header: true,
                      child: Text(
                        title,
                        style: TextStyle(
                          color: tokens.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _HostSummaryPill extends StatelessWidget {
  const _HostSummaryPill({required this.host, required this.tokens});

  final Host host;
  final SentinelThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: tokens.innerPillSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tokens.innerPillBorder, width: 0.9),
      ),
      child: Row(
        children: [
          DistroAvatar(
            distro: host.os?.osName ?? OsNames.unknown,
            tokens: tokens,
            size: 32,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  host.hostname,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: tokens.textPrimary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${host.username}@${host.ip}:${host.port}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: tokens.textSecondary,
                    fontSize: 11.5,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SentinelDangerButton extends StatelessWidget {
  const _SentinelDangerButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 46),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFE11D48), Color(0xFFBE123C)],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE11D48).withValues(alpha: 0.32),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 17, color: Colors.white),
                    const SizedBox(width: 7),
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
