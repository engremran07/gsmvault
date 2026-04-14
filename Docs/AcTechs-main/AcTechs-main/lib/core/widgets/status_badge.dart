import 'package:flutter/material.dart';
import 'package:ac_techs/core/theme/arctic_theme.dart';
import 'package:ac_techs/l10n/app_localizations.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status, this.fontSize = 12});

  final String status;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final (color, label) = switch (status) {
      'approved' => (ArcticTheme.arcticSuccess, l.approved),
      'rejected' => (ArcticTheme.arcticError, l.rejected),
      'pending' => (ArcticTheme.arcticPending, l.pending),
      _ => (ArcticTheme.arcticTextSecondary, status),
    };

    return Semantics(
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: color,
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
