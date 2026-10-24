import 'package:flutter/material.dart';
import 'package:sentinel/core/res/style/theme_tokens.dart';

class SentinelPrimaryButton extends StatelessWidget {
  const SentinelPrimaryButton({
    super.key,
    required this.tokens,
    required this.label,
    this.icon,
    this.onPressed,
    this.onTap,
    this.isLoading = false,
    this.isFullWidth = false,
    this.height,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    this.borderRadius = 16,
    this.accentColor,
  });

  final SentinelThemeTokens tokens;
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final VoidCallback? onTap;
  final bool isLoading;
  final bool isFullWidth;
  final double? height;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed = onPressed ?? onTap;
    final baseColor = accentColor ?? tokens.greenAccent;
    final isDark = tokens.isDark;
    // Darken surface slightly so white text achieves >= 4.8:1 WCAG AA contrast
    final gradientStart = Color.lerp(baseColor, const Color(0xFF064E3B), 0.38)!;
    final gradientEnd = Color.lerp(baseColor, const Color(0xFF064E3B), 0.52)!;

    return Semantics(
      button: true,
      enabled: !isLoading && effectiveOnPressed != null,
      label: isLoading ? '$label, loading' : label,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : effectiveOnPressed,
          borderRadius: BorderRadius.circular(borderRadius),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 150),
            opacity: isLoading ? 0.65 : 1.0,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Container(
                width: isFullWidth ? double.infinity : null,
                height: height,
                padding: height == null ? padding : null,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(borderRadius),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [gradientStart, gradientEnd],
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: isDark ? 0.22 : 0.4),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: baseColor.withValues(alpha: isDark ? 0.28 : 0.2),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (icon != null) ...[
                            Icon(icon, size: 18, color: Colors.white),
                            const SizedBox(width: 8),
                          ],
                          Flexible(
                            child: Text(
                              label,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.2,
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
