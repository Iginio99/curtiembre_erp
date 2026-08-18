import 'package:erp_curtiembre_fronted/core/theme/app_breakpoints.dart';
import 'package:erp_curtiembre_fronted/core/theme/app_colors.dart';
import 'package:erp_curtiembre_fronted/core/theme/app_spacing.dart';
import 'package:erp_curtiembre_fronted/core/theme/theme_mode_controller.dart';
import 'package:erp_curtiembre_fronted/core/di/service_locator.dart';
import 'package:erp_curtiembre_fronted/shared/widgets/color_token_card.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class ThemePreviewPage extends StatelessWidget {
  const ThemePreviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isMobile = MediaQuery.sizeOf(context).width < AppBreakpoints.tablet;
    final cardsPerRow = isMobile ? 1 : 2;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ERP Curtiembre'),
        actions: [
          AnimatedBuilder(
            animation: getIt<ThemeModeController>(),
            builder: (context, _) {
              final controller = getIt<ThemeModeController>();
              final isDarkMode = controller.isDarkMode;
              return TextButton.icon(
                onPressed: controller.toggleLightDark,
                icon: Icon(isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
                label: Text(isDarkMode ? 'Modo claro' : 'Modo oscuro'),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.lg),
            child: Center(
              child: Text(
                'Sistema visual base',
                style: theme.textTheme.labelLarge,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1240),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tema base', style: theme.textTheme.displaySmall),
                const Gap(AppSpacing.sm),
                Text(
                  'Paleta cuero premium, superficies suaves y jerarquia clara para web, desktop y movil.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const Gap(AppSpacing.xl),
                Wrap(
                  spacing: AppSpacing.lg,
                  runSpacing: AppSpacing.lg,
                  children: [
                    _SummaryCard(
                      title: 'Accion principal',
                      subtitle: 'Guardar, registrar, confirmar',
                      child: FilledButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Registrar lote'),
                      ),
                    ),
                    _SummaryCard(
                      title: 'Acciones secundarias',
                      subtitle: 'Cancelar, volver, filtros',
                      child: Row(
                        children: [
                          OutlinedButton(
                            onPressed: () {},
                            child: const Text('Volver'),
                          ),
                          const Gap(AppSpacing.md),
                          TextButton(
                            onPressed: () {},
                            child: const Text('Limpiar filtros'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Gap(AppSpacing.xl),
                Text('Tokens de color', style: theme.textTheme.headlineSmall),
                const Gap(AppSpacing.md),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: cardsPerRow,
                  crossAxisSpacing: AppSpacing.lg,
                  mainAxisSpacing: AppSpacing.lg,
                  childAspectRatio: isMobile ? 3.4 : 2.9,
                  children: const [
                    ColorTokenCard(
                      name: 'Primary',
                      value: AppColors.primary,
                      usage: 'Marca y accion principal',
                    ),
                    ColorTokenCard(
                      name: 'Primary Alt',
                      value: AppColors.primaryAlt,
                      usage: 'Activos, acentos, graficos',
                    ),
                    ColorTokenCard(
                      name: 'Primary Soft',
                      value: AppColors.primarySoft,
                      usage: 'Resaltados suaves',
                    ),
                    ColorTokenCard(
                      name: 'Background',
                      value: AppColors.background,
                      usage: 'Fondo general',
                    ),
                    ColorTokenCard(
                      name: 'Surface',
                      value: AppColors.surface,
                      usage: 'Cards, paneles, modales',
                    ),
                    ColorTokenCard(
                      name: 'Card',
                      value: AppColors.card,
                      usage: 'Fondos internos y headers',
                    ),
                    ColorTokenCard(
                      name: 'Success',
                      value: AppColors.success,
                      usage: 'Confirmado o correcto',
                    ),
                    ColorTokenCard(
                      name: 'Warning',
                      value: AppColors.warning,
                      usage: 'Pendiente y advertencia',
                    ),
                    ColorTokenCard(
                      name: 'Error',
                      value: AppColors.error,
                      usage: 'Accion destructiva o fallo',
                    ),
                  ],
                ),
                const Gap(AppSpacing.xl),
                Text('Estados y legibilidad', style: theme.textTheme.headlineSmall),
                const Gap(AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.md,
                  children: [
                    _StatusChip(
                      label: 'Activo',
                      background: AppColors.successSoft,
                      foreground: AppColors.success,
                    ),
                    _StatusChip(
                      label: 'Pendiente',
                      background: AppColors.warningSoft,
                      foreground: AppColors.warning,
                    ),
                    _StatusChip(
                      label: 'Observado',
                      background: AppColors.errorSoft,
                      foreground: AppColors.error,
                    ),
                    _StatusChip(
                      label: 'Inactivo',
                      background: colorScheme.surfaceContainerHighest,
                      foreground: colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
                const Gap(AppSpacing.xl),
                Text('Superficies', style: theme.textTheme.headlineSmall),
                const Gap(AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.lg,
                  runSpacing: AppSpacing.lg,
                  children: [
                    _SurfaceExample(
                      title: 'Card operativa',
                      subtitle: 'Para bloques, formularios y resumenes',
                      color: colorScheme.surface,
                      borderColor: colorScheme.outlineVariant,
                    ),
                    _SurfaceExample(
                      title: 'Panel interno',
                      subtitle: 'Para filtros, resumen lateral o headers',
                      color: colorScheme.surfaceContainerLow,
                      borderColor: colorScheme.outlineVariant,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 420,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleMedium),
          const Gap(AppSpacing.xs),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const Gap(AppSpacing.lg),
          child,
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SurfaceExample extends StatelessWidget {
  const _SurfaceExample({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.borderColor,
  });

  final String title;
  final String subtitle;
  final Color color;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 420,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleMedium),
          const Gap(AppSpacing.sm),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const Gap(AppSpacing.lg),
          Container(
            height: 12,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ],
      ),
    );
  }
}
