import 'package:erp_curtiembre_fronted/core/theme/app_radius.dart';
import 'package:erp_curtiembre_fronted/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';

enum AppMetricTone { neutral, primary, warning, error }

class AppMetricCard extends StatelessWidget {
  const AppMetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.detail,
    this.tone = AppMetricTone.neutral,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final String? detail;
  final AppMetricTone tone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accent = switch (tone) {
      AppMetricTone.primary => colors.primary,
      AppMetricTone.warning => colors.tertiary,
      AppMetricTone.error => colors.error,
      AppMetricTone.neutral => colors.onSurfaceVariant,
    };

    final card = Container(
      constraints: const BoxConstraints(minHeight: 122),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    letterSpacing: 0.55,
                    fontWeight: FontWeight.w800,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
              Icon(icon, size: 19, color: accent),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(value, style: Theme.of(context).textTheme.headlineSmall),
          if (detail != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              detail!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: accent),
            ),
          ],
        ],
      ),
    );

    if (onTap == null) {
      return card;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: onTap,
        child: card,
      ),
    );
  }
}
