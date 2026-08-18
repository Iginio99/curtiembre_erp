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
