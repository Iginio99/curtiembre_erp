import 'package:erp_curtiembre_fronted/core/theme/app_radius.dart';
import 'package:erp_curtiembre_fronted/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';

enum AppStatusTone { neutral, info, success, warning, error }

class AppStatusBadge extends StatelessWidget {
  const AppStatusBadge({
    super.key,
    required this.label,
    this.tone = AppStatusTone.neutral,
    this.icon,
  });

  final String label;
  final AppStatusTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final palette = switch (tone) {
      AppStatusTone.info => (
        colors.primaryContainer,
        colors.onPrimaryContainer,
      ),
      AppStatusTone.success => (
        colors.primaryContainer.withValues(alpha: 0.52),
        colors.primary,
      ),
      AppStatusTone.warning => (
        colors.tertiaryContainer,
        colors.onTertiaryContainer,
      ),
      AppStatusTone.error => (colors.errorContainer, colors.onErrorContainer),
      AppStatusTone.neutral => (
        colors.surfaceContainerHighest,
        colors.onSurfaceVariant,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: palette.$1,
        borderRadius: BorderRadius.circular(AppRadius.badge),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 15, color: palette.$2),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: palette.$2,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
