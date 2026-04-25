import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Wrapper koji prikazuje label, hint i error ispod bilo kojeg input widgeta
class FormFieldWrapper extends StatelessWidget {
  final String label;
  final String? hint;
  final String? error;
  final Widget child;

  const FormFieldWrapper({
    super.key,
    required this.label,
    required this.child,
    this.hint,
    this.error,
  });

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.kTextMid)),
          if (hint != null) ...[
            const SizedBox(height: 2),
            Text(hint!,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.kTextLight)),
          ],
          const SizedBox(height: 6),
          child,
          if (error != null) ...[
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.error_outline,
                  size: 12, color: AppColors.kError),
              const SizedBox(width: 4),
              Expanded(
                  child: Text(error!,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.kError))),
            ]),
          ],
        ],
      );
}