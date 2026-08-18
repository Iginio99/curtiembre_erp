import 'package:erp_curtiembre_fronted/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class ColorTokenCard extends StatelessWidget {
  const ColorTokenCard({
    required this.name,
    required this.value,
    required this.usage,
    super.key,
  });

  final String name;
  final Color value;
  final String usage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hex = value.toARGB32().toRadixString(16).toUpperCase().substring(2);
    final foreground = ThemeData.estimateBrightnessForColor(value) == Brightness.dark
        ? Colors.white
        : const Color(0xFF2B2118);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 88,
            decoration: BoxDecoration(
              color: value,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(
              '#$hex',
              style: theme.textTheme.labelMedium?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const Gap(AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: theme.textTheme.titleMedium),
                const Gap(AppSpacing.xs),
                Text(
                  usage,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
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
