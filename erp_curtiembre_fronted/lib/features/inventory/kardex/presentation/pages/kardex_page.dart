import 'package:erp_curtiembre_fronted/core/di/service_locator.dart';
import 'package:erp_curtiembre_fronted/core/logging/app_talker.dart';
import 'package:erp_curtiembre_fronted/core/theme/app_spacing.dart';
import 'package:erp_curtiembre_fronted/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:erp_curtiembre_fronted/features/auth/presentation/cubit/auth_state.dart';
import 'package:erp_curtiembre_fronted/features/inventory/kardex/domain/entities/kardex_record.dart';
import 'package:erp_curtiembre_fronted/features/inventory/kardex/presentation/cubit/kardex_cubit.dart';
import 'package:erp_curtiembre_fronted/features/inventory/kardex/presentation/cubit/kardex_state.dart';
import 'package:erp_curtiembre_fronted/features/security/presentation/cubit/security_access_cubit.dart';
import 'package:erp_curtiembre_fronted/shared/navigation/app_access_routes.dart';
import 'package:erp_curtiembre_fronted/shared/widgets/buttons/app_button.dart';
import 'package:erp_curtiembre_fronted/shared/widgets/feedback/app_message_card.dart';
import 'package:erp_curtiembre_fronted/shared/widgets/layout/app_shell.dart';
import 'package:erp_curtiembre_fronted/shared/widgets/layout/app_surface_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:talker_flutter/talker_flutter.dart';

class KardexPage extends StatefulWidget {
  const KardexPage({super.key});

  @override
  State<KardexPage> createState() => _KardexPageState();
}

class _KardexPageState extends State<KardexPage> {
  final _usuarioResponsableController = TextEditingController();
  final Talker _talker = getIt<Talker>();

  @override
  void initState() {
    super.initState();
    _talker.ui('Se abrio la pantalla de kardex.');
  }

  @override
  void dispose() {
    _usuarioResponsableController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({
    required bool isStart,
    required KardexState state,
  }) async {
    final initial = isStart
        ? (state.fechaDesde ?? DateTime.now())
        : (state.fechaHasta ?? DateTime.now());
    final selected = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
    );
    if (selected == null || !mounted) {
      _talker.ui(
        'Se cerro el selector de fecha de kardex sin confirmar.',
        logLevel: LogLevel.debug,
      );
      return;
    }
    _talker.ui(
      'Se selecciono ${isStart ? 'fecha desde' : 'fecha hasta'} en kardex: ${DateFormat('dd/MM/yyyy').format(selected)}.',
      logLevel: LogLevel.debug,
    );
    await context.read<KardexCubit>().load(
      fechaDesde: isStart ? selected : state.fechaDesde,
      fechaHasta: isStart ? state.fechaHasta : selected,
    );
  }

  void _applyResponsibleFilter() {
    final raw = _usuarioResponsableController.text.trim();
    final parsed = raw.isEmpty ? null : int.tryParse(raw);
    _talker.ui(
      'Se aplico el filtro de responsable en kardex con valor=${parsed ?? 'vacio'}.',
    );
    context.read<KardexCubit>().load(usuarioResponsableIdFilter: parsed);
  }

  @override
  Widget build(BuildContext context) {
    final session = context.select((AuthCubit cubit) => cubit.state.session);
    final isSigningOut = context.select(
      (AuthCubit cubit) => cubit.state.status == AuthStatus.signingOut,
    );
    final permissionCodes = context.select(
      (SecurityAccessCubit cubit) =>
          cubit.state.snapshot?.userPermissionCodes.toSet() ?? const <String>{},
    );

    if (session == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return AppShell(
      title: 'Kardex',
      currentPath: '/inventario/kardex',
      breadcrumbs: const ['Inicio', 'Inventario', 'Kardex'],
      userName: session.nombreCompleto,
      roleName: session.rolNombre,
      accessibleRoutes: AppAccessRoutes.forPermissions(permissionCodes),
      onSignOut: isSigningOut
          ? () {}
          : () => context.read<AuthCubit>().signOut(),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1440),
            child: BlocBuilder<KardexCubit, KardexState>(
              builder: (context, state) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Consulta la trazabilidad de cada insumo, sus movimientos y el costo histórico asociado.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const Gap(AppSpacing.xl),
                    _KardexFiltersCard(
                      state: state,
                      usuarioResponsableController:
                          _usuarioResponsableController,
                      onInsumoChanged: (value) {
                        _talker.ui(
                          'Se cambio el filtro de insumo en kardex a ${value ?? 'todos'}.',
                          logLevel: LogLevel.debug,
                        );
                        context.read<KardexCubit>().load(
                          selectedInsumoId: value,
                        );
                      },
                      onTipoMovimientoChanged: (value) {
                        _talker.ui(
                          'Se cambio el filtro de tipo de movimiento en kardex a ${_describeState(value)}.',
                          logLevel: LogLevel.debug,
                        );
                        context.read<KardexCubit>().load(
                          tipoMovimientoFilter: value,
                        );
                      },
                      onDocumentoTipoChanged: (value) {
                        _talker.ui(
                          'Se cambio el filtro de documento en kardex a ${_describeState(value)}.',
                          logLevel: LogLevel.debug,
                        );
                        context.read<KardexCubit>().load(
                          documentoTipoFilter: value,
                        );
                      },
                      onApplyResponsibleFilter: _applyResponsibleFilter,
                      onPickStartDate: () =>
                          _pickDate(isStart: true, state: state),
                      onPickEndDate: () =>
                          _pickDate(isStart: false, state: state),
                      onClearDates: () {
                        _talker.ui(
                          'Se limpiaron los filtros de fechas en kardex.',
                          logLevel: LogLevel.debug,
                        );
                        context.read<KardexCubit>().load(
                          fechaDesde: null,
                          fechaHasta: null,
                        );
                      },
                    ),
                    const Gap(AppSpacing.xl),
                    Expanded(
                      child: _KardexListPanel(
                        state: state,
                        onRetry: () {
                          _talker.ui(
                            'Se solicito reintentar la carga del kardex.',
                          );
                          context.read<KardexCubit>().initialize();
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  String _describeState(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return 'vacio';
    }

    return normalized;
  }
}

class _KardexFiltersCard extends StatelessWidget {
  const _KardexFiltersCard({
    required this.state,
    required this.usuarioResponsableController,
    required this.onInsumoChanged,
    required this.onTipoMovimientoChanged,
    required this.onDocumentoTipoChanged,
    required this.onApplyResponsibleFilter,
    required this.onPickStartDate,
    required this.onPickEndDate,
    required this.onClearDates,
  });

  final KardexState state;
  final TextEditingController usuarioResponsableController;
  final ValueChanged<int?> onInsumoChanged;
  final ValueChanged<String?> onTipoMovimientoChanged;
  final ValueChanged<String?> onDocumentoTipoChanged;
  final VoidCallback onApplyResponsibleFilter;
  final VoidCallback onPickStartDate;
  final VoidCallback onPickEndDate;
  final VoidCallback onClearDates;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateLabel = [
      if (state.fechaDesde != null)
        'Desde ${DateFormat('dd/MM/yyyy').format(state.fechaDesde!)}',
      if (state.fechaHasta != null)
        'Hasta ${DateFormat('dd/MM/yyyy').format(state.fechaHasta!)}',
    ].join(' · ');

    if (usuarioResponsableController.text !=
        (state.usuarioResponsableIdFilter?.toString() ?? '')) {
      usuarioResponsableController.value = TextEditingValue(
        text: state.usuarioResponsableIdFilter?.toString() ?? '',
        selection: TextSelection.collapsed(
          offset: (state.usuarioResponsableIdFilter?.toString() ?? '').length,
        ),
      );
    }

    return AppSurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Filtros de trazabilidad', style: theme.textTheme.titleLarge),
          const Gap(AppSpacing.sm),
          Text(
            'Filtra por insumo, tipo de movimiento, tipo documental, responsable o rango de fechas.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const Gap(AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.lg,
            children: [
              SizedBox(
                width: 280,
                child: DropdownButtonFormField<int?>(
                  initialValue: state.selectedInsumoId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Insumo'),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Todos'),
                    ),
                    ...state.insumos.map(
                      (item) => DropdownMenuItem<int?>(
                        value: item.id,
                        child: Text(
                          item.displayName,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                  onChanged: onInsumoChanged,
                ),
              ),
              SizedBox(
                width: 220,
                child: DropdownButtonFormField<String?>(
                  initialValue: state.tipoMovimientoFilter,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de movimiento',
                  ),
                  items: const [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Todos'),
                    ),
                    DropdownMenuItem<String?>(
                      value: 'ENTRADA',
                      child: Text('Entrada'),
                    ),
                    DropdownMenuItem<String?>(
                      value: 'SALIDA',
                      child: Text('Salida'),
                    ),
                  ],
                  onChanged: onTipoMovimientoChanged,
                ),
              ),
              SizedBox(
                width: 220,
                child: DropdownButtonFormField<String?>(
                  initialValue: state.documentoTipoFilter,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Documento tipo',
                  ),
                  items: const [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Todos'),
                    ),
                    DropdownMenuItem<String?>(
                      value: 'ORDEN_COMPRA',
                      child: Text('Orden compra'),
                    ),
                    DropdownMenuItem<String?>(
                      value: 'ENTRADA_INVENTARIO',
                      child: Text('Entrada inventario'),
                    ),
                    DropdownMenuItem<String?>(
                      value: 'SALIDA_INVENTARIO',
                      child: Text('Salida inventario'),
                    ),
                    DropdownMenuItem<String?>(
                      value: 'AJUSTE_INVENTARIO',
                      child: Text('Ajuste inventario'),
                    ),
                    DropdownMenuItem<String?>(
                      value: 'INVENTARIO_FISICO',
                      child: Text('Inventario fisico'),
                    ),
                  ],
                  onChanged: onDocumentoTipoChanged,
                ),
              ),
              SizedBox(
                width: 180,
                child: TextField(
                  controller: usuarioResponsableController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Usuario ID'),
                  onSubmitted: (_) => onApplyResponsibleFilter(),
                ),
              ),
              AppButton.secondary(
                label: 'Aplicar responsable',
                icon: Icons.filter_alt_outlined,
                onPressed: onApplyResponsibleFilter,
              ),
            ],
          ),
          const Gap(AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              AppButton.secondary(
                label: 'Fecha desde',
                icon: Icons.event_outlined,
                onPressed: onPickStartDate,
              ),
              AppButton.secondary(
                label: 'Fecha hasta',
                icon: Icons.event_available_outlined,
                onPressed: onPickEndDate,
              ),
              AppButton.secondary(
                label: 'Limpiar fechas',
                icon: Icons.backspace_outlined,
                onPressed: onClearDates,
              ),
              if (dateLabel.isNotEmpty)
                Text(
                  dateLabel,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _KardexListPanel extends StatelessWidget {
  const _KardexListPanel({required this.state, required this.onRetry});

  final KardexState state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppSurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: Row(
              children: [
                Text('Movimientos', style: theme.textTheme.titleMedium),
                const Spacer(),
                Text(
                  '${state.items.length}',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: switch (state.status) {
              KardexStatus.loading => const Center(
                child: CircularProgressIndicator(),
              ),
              KardexStatus.error => Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppMessageCard.error(
                        title: 'No pudimos cargar el kardex',
                        message:
                            state.errorMessage ??
                            'Intenta nuevamente para consultar los movimientos.',
                      ),
                      const Gap(AppSpacing.lg),
                      AppButton.secondary(
                        label: 'Reintentar',
                        icon: Icons.refresh_rounded,
                        onPressed: onRetry,
                      ),
                    ],
                  ),
                ),
              ),
              KardexStatus.success =>
                state.items.isEmpty
                    ? Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 520),
                          child: const AppMessageCard.info(
                            title: 'Sin resultados',
                            message:
                                'No encontramos movimientos con los filtros actuales.',
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: state.items.length,
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          AppSpacing.xs,
                          AppSpacing.md,
                          AppSpacing.md,
                        ),
                        separatorBuilder: (_, _) => const Gap(AppSpacing.sm),
                        itemBuilder: (context, index) {
                          final item = state.items[index];
                          return _KardexTile(item: item);
                        },
                      ),
            },
          ),
        ],
      ),
    );
  }
}

class _KardexTile extends StatelessWidget {
  const _KardexTile({required this.item});

  final KardexRecord item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final badgeColor = item.isEntrada
        ? const Color(0xFFE2F6E8)
        : const Color(0xFFF7E0DF);
    final badgeForeground = item.isEntrada
        ? const Color(0xFF20633A)
        : const Color(0xFF8A2F22);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                '${item.insumoCodigo} · ${item.insumoNombre}',
                style: theme.textTheme.titleMedium,
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  item.tipoMovimiento,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: badgeForeground,
                  ),
                ),
              ),
            ],
          ),
          const Gap(AppSpacing.sm),
          Text(
            '${DateFormat('dd/MM/yyyy hh:mm a').format(item.fechaMovimiento.toLocal())} · Documento: ${item.documentoTipo ?? 'Sin documento'}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const Gap(AppSpacing.md),
          Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.sm,
            children: [
              _InlineInfo(
                label: 'Entrada',
                value: item.entrada.toStringAsFixed(2),
              ),
              _InlineInfo(
                label: 'Salida',
                value: item.salida.toStringAsFixed(2),
              ),
              _InlineInfo(
                label: 'Stock',
                value: item.stockActual.toStringAsFixed(2),
              ),
              _InlineInfo(
                label: 'Costo unitario',
                value: 'S/ ${item.costoUnitario.toStringAsFixed(2)}',
              ),
              _InlineInfo(
                label: 'Costo total',
                value: 'S/ ${item.costoTotal.toStringAsFixed(2)}',
              ),
            ],
          ),
          if (item.usuarioResponsable?.isNotEmpty == true ||
              item.observacion?.isNotEmpty == true) ...[
            const Gap(AppSpacing.md),
            Text(
              'Responsable: ${item.usuarioResponsable ?? 'Sin responsable'} · Observacion: ${item.observacion ?? 'Sin observacion'}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InlineInfo extends StatelessWidget {
  const _InlineInfo({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return RichText(
      text: TextSpan(
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurface,
        ),
        children: [
          TextSpan(
            text: '$label: ',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          TextSpan(text: value),
        ],
      ),
    );
  }
}
