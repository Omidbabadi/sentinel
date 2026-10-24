import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sentinel/core/res/style/theme_tokens.dart';

class SentinelGlassField extends StatelessWidget {
  const SentinelGlassField({
    super.key,
    required this.controller,
    required this.tokens,
    required this.label,
    required this.hint,
    this.isDark = false,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.isMonospace = false,
    this.maxLines = 1,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.validator,
  });

  final TextEditingController controller;
  final SentinelThemeTokens tokens;
  final bool isDark;
  final String label;
  final String hint;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final bool isMonospace;
  final int maxLines;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    final effectiveIsDark = tokens.isDark || isDark;
    final fillColor = effectiveIsDark
        ? Colors.white.withValues(alpha: 0.045)
        : Colors.black.withValues(alpha: 0.035);
    final borderColor = effectiveIsDark
        ? Colors.white.withValues(alpha: 0.11)
        : Colors.black.withValues(alpha: 0.09);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExcludeSemantics(
          child: Text(
            label,
            style: TextStyle(
              color: tokens.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Semantics(
          label: label,
          textField: true,
          child: TextFormField(
            controller: controller,
            obscureText: obscureText,
            maxLines: obscureText ? 1 : maxLines,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            inputFormatters: inputFormatters,
            validator: validator,
            style: TextStyle(
              color: tokens.textPrimary,
              fontSize: 13,
              fontFamily: isMonospace ? 'monospace' : null,
              fontWeight: FontWeight.w500,
            ),
            cursorColor: tokens.greenAccent,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: tokens.textSecondary.withValues(alpha: 0.78),
                fontSize: 12.5,
                fontFamily: isMonospace ? 'monospace' : null,
                fontWeight: FontWeight.w400,
              ),
              filled: true,
              fillColor: fillColor,
              isDense: true,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 14,
                vertical: maxLines > 1 ? 12 : 13,
              ),
              prefixIcon: prefixIcon != null
                  ? Icon(prefixIcon, size: 17, color: tokens.textSecondary)
                  : null,
              prefixIconConstraints: const BoxConstraints(
                minWidth: 38,
                minHeight: 38,
              ),
              suffixIcon: suffixIcon,
              suffixIconConstraints: const BoxConstraints(
                minWidth: 44,
                minHeight: 44,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: borderColor, width: 1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: borderColor, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: tokens.greenAccent.withValues(alpha: 0.75),
                  width: 1.3,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: tokens.redTextAccent.withValues(alpha: 0.8),
                  width: 1,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: tokens.redTextAccent, width: 1.3),
              ),
              errorStyle: TextStyle(
                color: tokens.redTextAccent,
                fontSize: 11.5,
                height: 1.15,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
