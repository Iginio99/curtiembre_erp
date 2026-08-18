import 'package:erp_curtiembre_fronted/core/di/service_locator.dart';
import 'package:erp_curtiembre_fronted/core/theme/app_spacing.dart';
import 'package:erp_curtiembre_fronted/features/alerts/domain/entities/alert_record.dart';
import 'package:erp_curtiembre_fronted/features/alerts/presentation/cubit/alerts_cubit.dart';
import 'package:erp_curtiembre_fronted/features/alerts/presentation/cubit/alerts_state.dart';
import 'package:erp_curtiembre_fronted/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:erp_curtiembre_fronted/features/auth/presentation/cubit/auth_state.dart';
import 'package:erp_curtiembre_fronted/shared/widgets/feedback/app_message_card.dart';
import 'package:erp_curtiembre_fronted/shared/widgets/feedback/app_status_badge.dart';
import 'package:erp_curtiembre_fronted/shared/widgets/layout/app_page_header.dart';
import 'package:erp_curtiembre_fronted/shared/widgets/layout/app_shell.dart';
import 'package:erp_curtiembre_fronted/shared/widgets/layout/app_surface_card.dart';
import 'package:erp_curtiembre_fronted/shared/widgets/metrics/app_metric_card.dart';
import 'package:erp_curtiembre_fronted/shared/navigation/app_access_routes.dart';
import 'package:erp_curtiembre_fronted/features/security/presentation/cubit/security_access_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final session = authState.session;

    if (session == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return BlocProvider<AlertsCubit>(
      create: (_) => getIt<AlertsCubit>()..loadHomeSummary(),
      child: _DashboardView(
        isSigningOut: authState.status == AuthStatus.signingOut,
      ),
    );
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView({required this.isSigningOut});

  final bool isSigningOut;

  @override
  Widget build(BuildContext context) {
    final session = context.select((AuthCubit cubit) => cubit.state.session);
    final permissionCodes = context.select(
      (SecurityAccessCubit cubit) =>
          cubit.state.snapshot?.userPermissionCodes.toSet() ?? const <String>{},
    );
    if (session == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Stack(
      children: [
        BlocBuilder<AlertsCubit, AlertsState>(
          builder: (context, alertsState) {
            final summary = alertsState.summary;
            return AppShell(
              title: 'Visión General',
              currentPath: '/home',
              breadcrumbs: const ['Inicio', 'Panel inicial'],
              userName: session.nombreCompleto,
              roleName: session.rolNombre,
              alertCount: summary?.totalPendientes,
              accessibleRoutes: AppAccessRoutes.forPermissions(permissionCodes),
              onSignOut: isSigningOut
                  ? () {}
                  : () => context.read<AuthCubit>().signOut(),
              child: _DashboardContent(
                sessionName: session.nombreCompleto,
                roleName: session.rolNombre,
                alertsState: alertsState,
              ),
            );
          },
        ),
        if (isSigningOut) const _SigningOutOverlay(),
      ],
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({
    required this.sessionName,
    required this.roleName,
    required this.alertsState,
  });

  final String sessionName;
  final String roleName;
  final AlertsState alertsState;

  @override
  Widget build(BuildContext context) {
    final summary = alertsState.summary;
    final alerts = summary?.recientes ?? const <AlertRecord>[];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1360),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppPageHeader(
                title: 'Visión General',
                subtitle: 'Resumen operativo para $roleName.',
                breadcrumbs: const ['Inicio', 'Panel inicial'],
              ),
              const Gap(AppSpacing.xl),
              _MetricsGrid(summary: summary),
              const Gap(AppSpacing.xl),
              LayoutBuilder(
                builder: (context, constraints) {
                  final showSideActions = constraints.maxWidth >= 860;
                  return Column(
                    children: [
                      if (showSideActions)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _AlertsPanel(
                                state: alertsState,
                                alerts: alerts,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.lg),
                            SizedBox(
                              width: 270,
                              child: _QuickActions(roleName: roleName),
                            ),
                          ],
                        )
                      else ...[
                        _AlertsPanel(state: alertsState, alerts: alerts),
                        const Gap(AppSpacing.lg),
                        _QuickActions(roleName: roleName),
                      ],
                    ],
                  );
                },
              ),
              const Gap(AppSpacing.xl),
              Text(
                'Sesión activa: $sessionName',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({required this.summary});

  final AlertsSummary? summary;

  @override
  Widget build(BuildContext context) {
    final metrics = [
      const _MetricData(
        'Stock bajo',
        '—',
        Icons.inventory_2_outlined,
        'No disponible',
      ),
      const _MetricData(
        'Órdenes activas',
        '—',
        Icons.factory_outlined,
        'No disponible',
      ),
      const _MetricData(
        'Compras pendientes',
        '—',
        Icons.shopping_cart_outlined,
        'No disponible',
      ),
      const _MetricData(
        'Órdenes retrasadas',
        '—',
        Icons.schedule_outlined,
        'No disponible',
        AppMetricTone.error,
      ),
      const _MetricData(
        'Costo por orden',
        '—',
        Icons.payments_outlined,
        'No disponible',
      ),
      _MetricData(
        'Alertas activas',
        '${summary?.totalPendientes ?? 0}',
        Icons.notifications_active_outlined,
        summary == null
            ? 'Cargando resumen'
            : '${summary!.totalAlta} altas · ${summary!.totalMedia} medias',
        AppMetricTone.error,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final count = constraints.maxWidth >= 1080
            ? 3
            : constraints.maxWidth >= 650
            ? 2
            : 2;
        final width =
            (constraints.maxWidth - AppSpacing.lg * (count - 1)) / count;
        return Wrap(
          spacing: AppSpacing.lg,
          runSpacing: AppSpacing.lg,
          children: [
            for (final metric in metrics)
              SizedBox(
                width: width,
                child: AppMetricCard(
                  label: metric.label,
                  value: metric.value,
                  icon: metric.icon,
                  detail: metric.detail,
                  tone: metric.tone,
                  onTap: metric.label == 'Alertas activas'
                      ? () => context.go('/alertas')
                      : null,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _AlertsPanel extends StatelessWidget {
  const _AlertsPanel({required this.state, required this.alerts});

  final AlertsState state;
  final List<AlertRecord> alerts;

  @override
  Widget build(BuildContext context) {
    if (state.status == AlertsStatus.loading) {
      return const _LoadingAlertsPanel();
    }
    if (state.status == AlertsStatus.error) {
      return AppSurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppMessageCard.error(
              title: 'No pudimos cargar las alertas',
              message: state.errorMessage ?? 'Intenta nuevamente.',
            ),
            const Gap(AppSpacing.lg),
            OutlinedButton.icon(
              onPressed: () => context.read<AlertsCubit>().loadHomeSummary(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    return AppSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Alertas operativas prioritarias',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              TextButton(
                onPressed: () => context.go('/alertas'),
                child: const Text('Ver todas'),
              ),
            ],
          ),
          const Gap(AppSpacing.sm),
          if (alerts.isEmpty)
            const AppMessageCard.info(
              title: 'Sin alertas pendientes',
              message:
                  'No hay alertas operativas para revisar en este momento.',
            )
          else
            ...alerts
                .take(3)
                .map(
                  (alert) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _AlertRow(alert: alert),
                  ),
                ),
        ],
      ),
    );
  }
}

class _AlertRow extends StatelessWidget {
  const _AlertRow({required this.alert});

  final AlertRecord alert;

  @override
  Widget build(BuildContext context) {
    final tone = _toneForSeverity(alert.severidad);
    final icon = _iconForAlert(alert.tipoAlerta);
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => context.go('/alertas'),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: _colorForTone(context, tone)),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alert.titulo,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    alert.mensaje,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            AppStatusBadge(label: alert.estado, tone: tone),
          ],
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.roleName});

  final String roleName;

  @override
  Widget build(BuildContext context) {
    final actions = _actionsForRole(roleName);
    if (actions.isEmpty) return const SizedBox.shrink();

    return AppSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Accesos rápidos',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const Gap(AppSpacing.md),
          for (final action in actions) ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => context.go(action.route),
                icon: Icon(action.icon),
                label: Text(action.label),
              ),
            ),
            if (action != actions.last) const Gap(AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _LoadingAlertsPanel extends StatelessWidget {
  const _LoadingAlertsPanel();

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Alertas operativas prioritarias',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const Gap(AppSpacing.lg),
          const LinearProgressIndicator(),
          const Gap(AppSpacing.md),
          Text(
            'Cargando alertas...',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _SigningOutOverlay extends StatelessWidget {
  const _SigningOutOverlay();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.76),
        child: const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _MetricData {
  const _MetricData(
    this.label,
    this.value,
    this.icon,
    this.detail, [
    this.tone = AppMetricTone.neutral,
  ]);

  final String label;
  final String value;
  final IconData icon;
  final String detail;
  final AppMetricTone tone;
}

class _QuickAction {
  const _QuickAction(this.label, this.icon, this.route);

  final String label;
  final IconData icon;
  final String route;
}

List<_QuickAction> _actionsForRole(String roleName) {
  final role = roleName.toUpperCase();
  if (role.contains('ADMIN')) {
    return const [
      _QuickAction(
        'Ver órdenes de producción',
        Icons.factory_outlined,
        '/produccion/ordenes',
      ),
      _QuickAction(
        'Gestionar compras',
        Icons.shopping_cart_outlined,
        '/inventario/compras',
      ),
    ];
  }
  if (role.contains('LOG')) {
    return const [
      _QuickAction(
        'Ver inventario',
        Icons.inventory_2_outlined,
        '/inventario/stock',
      ),
    ];
  }
  if (role.contains('PRODU')) {
    return const [
      _QuickAction(
        'Ver órdenes de producción',
        Icons.factory_outlined,
        '/produccion/ordenes',
      ),
    ];
  }
  if (role.contains('FINAN')) {
    return const [
      _QuickAction(
        'Ver finanzas',
        Icons.payments_outlined,
        '/finanzas/periodos',
      ),
    ];
  }
  return const [];
}

AppStatusTone _toneForSeverity(String severity) {
  return switch (severity.toUpperCase()) {
    'ALTA' => AppStatusTone.error,
    'MEDIA' => AppStatusTone.warning,
    'BAJA' => AppStatusTone.info,
    _ => AppStatusTone.neutral,
  };
}

IconData _iconForAlert(String type) {
  final normalized = type.toUpperCase();
  if (normalized.contains('STOCK')) return Icons.inventory_2_outlined;
  if (normalized.contains('ORDEN')) return Icons.schedule_outlined;
  if (normalized.contains('COMPRA')) return Icons.shopping_cart_outlined;
  return Icons.notifications_none_rounded;
}

Color _colorForTone(BuildContext context, AppStatusTone tone) {
  final colors = Theme.of(context).colorScheme;
  return switch (tone) {
    AppStatusTone.error => colors.error,
    AppStatusTone.warning => colors.tertiary,
    AppStatusTone.info || AppStatusTone.success => colors.primary,
    AppStatusTone.neutral => colors.onSurfaceVariant,
  };
}
