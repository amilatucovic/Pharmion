import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';

class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final String? error;
  final bool obscureText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool readOnly;
  final int maxLines;
  final TextInputAction? textInputAction;
  final VoidCallback? onSubmitted;

  const AppTextField({
    super.key,
    required this.controller,
    required this.hint,
    this.error,
    this.obscureText = false,
    this.keyboardType,
    this.inputFormatters,
    this.onChanged,
    this.onTap,
    this.prefixIcon,
    this.suffixIcon,
    this.readOnly = false,
    this.maxLines = 1,
    this.textInputAction,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        onChanged: onChanged,
        onTap: onTap,
        readOnly: readOnly,
        maxLines: maxLines,
        textInputAction: textInputAction,
        onSubmitted: onSubmitted != null ? (_) => onSubmitted!() : null,
        style: const TextStyle(
            fontSize: 14, color: AppColors.kTextDark),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
              color: AppColors.kTextLight, fontSize: 14),
          prefixIcon: prefixIcon != null
              ? Icon(prefixIcon, color: AppColors.kTextMid, size: 20)
              : null,
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: readOnly ? AppColors.kSurface : Colors.white,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: error != null
                  ? AppColors.kError
                  : AppColors.kBorder,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: error != null
                  ? AppColors.kError
                  : AppColors.kBorder,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: error != null ? AppColors.kError : AppColors.kTeal,
              width: 2,
            ),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.kBorder),
          ),
        ),
      );
}