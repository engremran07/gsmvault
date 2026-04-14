import 'package:flutter/material.dart';
import 'package:ac_techs/core/theme/arctic_theme.dart';
import 'package:ac_techs/core/models/app_exception.dart';

class ErrorCard extends StatelessWidget {
  const ErrorCard({
    super.key,
    required this.exception,
    this.locale = 'en',
    this.onRetry,
  });

  final AppException exception;
  final String locale;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ArcticTheme.arcticError.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ArcticTheme.arcticError.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: ArcticTheme.arcticError,
            size: 40,
          ),
          const SizedBox(height: 12),
          Text(
            exception.message(locale),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: ArcticTheme.arcticTextPrimary,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(switch (locale) {
                'ur' => 'دوبارہ کوشش کریں',
                'ar' => 'إعادة المحاولة',
                _ => 'Try Again',
              }),
              style: TextButton.styleFrom(
                foregroundColor: ArcticTheme.arcticBlue,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
