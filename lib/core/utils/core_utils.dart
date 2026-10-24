import 'package:sentinel/core/extensions/context_extension.dart';
import 'package:sentinel/core/services/router.dart';
import 'package:sentinel/core/widgets/sentinel_toast.dart';

abstract class CoreUtils {
  const CoreUtils();

  static void showSnackBar(
    String message, {
    bool isError = false,
    String? title,
    SentinelToastType? type,
  }) {
    showToast(
      message,
      title: title,
      type: type ??
          (isError ? SentinelToastType.error : SentinelToastType.success),
    );
  }

  static void showToast(
    String message, {
    String? title,
    SentinelToastType type = SentinelToastType.success,
    Duration duration = const Duration(milliseconds: 3200),
  }) {
    final navigatorState = rootNavigatorKey.currentState;
    final context = rootNavigatorKey.currentContext;
    final overlay = navigatorState?.overlay;

    if (context == null || !context.mounted || overlay == null) return;

    SentinelToastController.show(
      overlay: overlay,
      message: message,
      title: title,
      type: type,
      duration: duration,
      isDark: context.isDarkMode,
    );
  }

  static String? nullIfEmpty(String text) {
    final trimmed = text.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
