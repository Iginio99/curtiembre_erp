import 'package:erp_curtiembre_fronted/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';

class AppMessageCard extends StatelessWidget {
  const AppMessageCard._({
    super.key,
    required this.title,
    required this.message,
    required this.background,
    required this.foreground,
    required this.icon,
  });

  const AppMessageCard.info({
    required String title,
    required String message,
    Key? key,
  }) : this._(
         key: key,
         title: title,
         message: message,
         background: const Color(0xFFECE4DB),
         foreground: const Color(0xFF5B4638),
         icon: Icons.info_outline,
       );

  const AppMessageCard.warning({
    required String title,
    required String message,
    Key? key,
  }) : this._(
         key: key,
         title: title,
         message: message,
         background: const Color(0xFFF9E8BF),
         foreground: const Color(0xFF7A5512),
         icon: Icons.warning_amber_rounded,
       );

  const AppMessageCard.error({
    required String title,
    required String message,
    Key? key,
  }) : this._(
         key: key,
         title: title,
         message: message,
         background: const Color(0xFFF7D8D3),
         foreground: const Color(0xFF8A2F22),
         icon: Icons.error_outline,
       );

  final String title;
  final String message;
  final Color background;
  final Color foreground;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isInfo = icon == Icons.info_outline;
    final normalizedTitle = title.trim().toLowerCase();
    final requiresAction =
        normalizedTitle.startsWith('selecciona') ||
        normalizedTitle.startsWith('elige') ||
        normalizedTitle.startsWith('busca');

    if (isInfo) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xl,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                requiresAction ? Icons.touch_app_outlined : Icons.check_rounded,
                color: theme.colorScheme.primary,
                size: 28,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: foreground),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: foreground,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: foreground,
                    height: 1.45,
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
