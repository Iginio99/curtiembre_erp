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
      'Se selecciono ${isStart ? 'fecha desde' : 'fecha hasta'} '
      'en kardex: ${DateFormat('dd/MM/yyyy').format(selected)}.',
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
      'Se aplico el filtro de responsable en kardex '
      'con valor=${parsed ?? 'vacio'}.',
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
        /*
        Antes xl.
        Más compacto para aprovechar pantalla.
        */
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1440),
            child: BlocBuilder<KardexCubit, KardexState>(
              builder: (context, state) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /*
                    ═══════════════════════════
                    KPIs
                    ═══════════════════════════
                    */
                    _KardexSummary(items: state.items),

                    const Gap(AppSpacing.md),

                    /*
                    ═══════════════════════════
                    FILTROS
                    ═══════════════════════════
                    */
                    _KardexFiltersCard(
                      state: state,
                      usuarioResponsableController:
                          _usuarioResponsableController,

                      onInsumoChanged: (value) {
                        _talker.ui(
                          'Se cambio el filtro de insumo '
                          'en kardex a ${value ?? 'todos'}.',
                          logLevel: LogLevel.debug,
                        );

                        context.read<KardexCubit>().load(
                          selectedInsumoId: value,
                        );
                      },

                      onTipoMovimientoChanged: (value) {
                        _talker.ui(
                          'Se cambio el filtro de tipo '
                          'de movimiento en kardex a '
                          '${_describeState(value)}.',
                          logLevel: LogLevel.debug,
                        );

                        context.read<KardexCubit>().load(
                          tipoMovimientoFilter: value,
                        );
                      },

                      onDocumentoTipoChanged: (value) {
                        _talker.ui(
                          'Se cambio el filtro de documento '
                          'en kardex a ${_describeState(value)}.',
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
                          'Se limpiaron los filtros '
                          'de fechas en kardex.',
                          logLevel: LogLevel.debug,
                        );

                        context.read<KardexCubit>().load(
                          fechaDesde: null,
                          fechaHasta: null,
                        );
                      },
                    ),

                    const Gap(AppSpacing.md),

                    /*
                    ═══════════════════════════
                    MOVIMIENTOS + DETALLE
                    ═══════════════════════════
                    */
                    Expanded(
                      child: _KardexListPanel(
                        state: state,
                        onRetry: () {
                          _talker.ui(
                            'Se solicito reintentar '
                            'la carga del kardex.',
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

/*
══════════════════════════════════════════════════
KPIs
══════════════════════════════════════════════════
*/

class _KardexSummary extends StatelessWidget {
  const _KardexSummary({required this.items});

  final List<KardexRecord> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final entries = items.fold<double>(0, (sum, item) => sum + item.entrada);

    final exits = items.fold<double>(0, (sum, item) => sum + item.salida);

    final value = items.fold<double>(0, (sum, item) => sum + item.costoTotal);

    /*
    Quitamos "Insumos".
    Kardex debe enfocarse en movimientos.
    */

    final metrics = [
      ('Movimientos', '${items.length}', Icons.swap_vert_rounded),
      ('Entradas', _formatQuantity(entries), Icons.south_west_rounded),
      ('Salidas', _formatQuantity(exits), Icons.north_east_rounded),
      ('Valor movido', _formatMoney(value), Icons.payments_outlined),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth >= 900
            ? (constraints.maxWidth - AppSpacing.md * 3) / 4
            : 220.0;

        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: metrics
              .map(
                (metric) => SizedBox(
                  width: width,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            metric.$3,
                            size: 21,
                            color: theme.colorScheme.primary,
                          ),
                        ),

                        const Gap(AppSpacing.md),

                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                metric.$1,
                                style: theme.textTheme.labelMedium,
                              ),

                              const Gap(2),

                              Text(
                                metric.$2,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

/*
══════════════════════════════════════════════════
FILTROS
══════════════════════════════════════════════════
*/

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

    if (usuarioResponsableController.text !=
        (state.usuarioResponsableIdFilter?.toString() ?? '')) {
      final value = state.usuarioResponsableIdFilter?.toString() ?? '';

      usuarioResponsableController.value = TextEditingValue(
        text: value,
        selection: TextSelection.collapsed(offset: value.length),
      );
    }

    return AppSurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.md),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.filter_alt_outlined,
                size: 18,
                color: theme.colorScheme.primary,
              ),

              const Gap(AppSpacing.sm),

              Text(
                'Filtros de trazabilidad',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),

          const Gap(AppSpacing.md),

          /*
          Todos los filtros juntos
          en desktop.
          */
          LayoutBuilder(
            builder: (context, constraints) {
              final insumo = DropdownButtonFormField<int?>(
                isExpanded: true,

                initialValue: state.selectedInsumoId,

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
              );

              final movement = DropdownButtonFormField<String?>(
                isExpanded: true,

                initialValue: state.tipoMovimientoFilter,

                decoration: const InputDecoration(
                  labelText: 'Tipo de movimiento',
                ),

                items: const [
                  DropdownMenuItem<String?>(value: null, child: Text('Todos')),
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
              );

              final document = DropdownButtonFormField<String?>(
                isExpanded: true,

                initialValue: state.documentoTipoFilter,

                decoration: const InputDecoration(labelText: 'Documento'),

                items: const [
                  DropdownMenuItem<String?>(value: null, child: Text('Todos')),
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
                    child: Text('Inventario físico'),
                  ),
                ],

                onChanged: onDocumentoTipoChanged,
              );

              final responsable = TextField(
                controller: usuarioResponsableController,

                keyboardType: TextInputType.number,

                decoration: const InputDecoration(
                  labelText: 'Responsable',
                  hintText: 'Usuario ID',
                ),

                onSubmitted: (_) => onApplyResponsibleFilter(),
              );

              final startDate = _DateFilterButton(
                label: 'Fecha desde',
                value: state.fechaDesde == null
                    ? null
                    : DateFormat('dd/MM/yyyy').format(state.fechaDesde!),
                onPressed: onPickStartDate,
              );

              final endDate = _DateFilterButton(
                label: 'Fecha hasta',
                value: state.fechaHasta == null
                    ? null
                    : DateFormat('dd/MM/yyyy').format(state.fechaHasta!),
                onPressed: onPickEndDate,
              );

              /*
              DESKTOP
              */

              if (constraints.maxWidth >= 1100) {
                return Row(
                  children: [
                    Expanded(flex: 5, child: insumo),

                    const Gap(AppSpacing.sm),

                    Expanded(flex: 4, child: movement),

                    const Gap(AppSpacing.sm),

                    Expanded(flex: 4, child: document),

                    const Gap(AppSpacing.sm),

                    Expanded(flex: 4, child: responsable),

                    const Gap(AppSpacing.sm),

                    SizedBox(width: 145, child: startDate),

                    const Gap(AppSpacing.sm),

                    SizedBox(width: 145, child: endDate),

                    const Gap(AppSpacing.sm),

                    FilledButton.icon(
                      onPressed: onApplyResponsibleFilter,
                      icon: const Icon(Icons.filter_alt_outlined, size: 17),
                      label: const Text('Aplicar'),
                    ),

                    const Gap(AppSpacing.sm),

                    OutlinedButton.icon(
                      onPressed: onClearDates,
                      icon: const Icon(Icons.close, size: 17),
                      label: const Text('Limpiar'),
                    ),
                  ],
                );
              }

              /*
              TABLET / PEQUEÑO
              */

              return Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  SizedBox(width: 230, child: insumo),

                  SizedBox(width: 210, child: movement),

                  SizedBox(width: 210, child: document),

                  SizedBox(width: 180, child: responsable),

                  SizedBox(width: 150, child: startDate),

                  SizedBox(width: 150, child: endDate),

                  AppButton.primary(
                    label: 'Aplicar',
                    icon: Icons.filter_alt_outlined,
                    onPressed: onApplyResponsibleFilter,
                  ),

                  AppButton.secondary(
                    label: 'Limpiar',
                    icon: Icons.close,
                    onPressed: onClearDates,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/*
══════════════════════════════════════════════════
BOTÓN DE FECHA
══════════════════════════════════════════════════
*/

class _DateFilterButton extends StatelessWidget {
  const _DateFilterButton({
    required this.label,
    required this.value,
    required this.onPressed,
  });

  final String label;
  final String? value;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,

      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      ),

      child: Row(
        children: [
          const Icon(Icons.calendar_today_outlined, size: 16),

          const Gap(7),

          Expanded(
            child: Text(
              value ?? label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/*
══════════════════════════════════════════════════
PANEL PRINCIPAL
══════════════════════════════════════════════════
*/

class _KardexListPanel extends StatefulWidget {
  const _KardexListPanel({required this.state, required this.onRetry});

  final KardexState state;
  final VoidCallback onRetry;

  @override
  State<_KardexListPanel> createState() => _KardexListPanelState();
}

class _KardexListPanelState extends State<_KardexListPanel> {
  int? selectedId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final state = widget.state;

    KardexRecord? selected;

    for (final item in state.items) {
      if (item.id == selectedId) {
        selected = item;
        break;
      }
    }

    return AppSurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /*
          CABECERA
          */
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.format_list_bulleted_rounded,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),

                const Gap(AppSpacing.sm),

                Text(
                  'Movimientos',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const Spacer(),

                Text(
                  '${state.items.length} registros',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: theme.colorScheme.outlineVariant),

          /*
          CONTENIDO
          */
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

                      const Gap(AppSpacing.md),

                      AppButton.secondary(
                        label: 'Reintentar',
                        icon: Icons.refresh_rounded,
                        onPressed: widget.onRetry,
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
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final wide = constraints.maxWidth >= 980;

                          final table = _KardexMovementsTable(
                            items: state.items,
                            selectedId: selectedId,
                            onSelected: (item) {
                              setState(() {
                                selectedId = item.id;
                              });
                            },
                          );

                          if (!wide) {
                            return table;
                          }

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              /*
                              Tabla más ancha.
                              */
                              Expanded(flex: 72, child: table),

                              VerticalDivider(
                                width: 1,
                                color: theme.colorScheme.outlineVariant,
                              ),

                              /*
                              Detalle 28%.
                              */
                              Expanded(
                                flex: 28,
                                child: _KardexDetailPanel(item: selected),
                              ),
                            ],
                          );
                        },
                      ),
            },
          ),
        ],
      ),
    );
  }
}

/*
══════════════════════════════════════════════════
TABLA
══════════════════════════════════════════════════
*/

class _KardexMovementsTable extends StatelessWidget {
  const _KardexMovementsTable({
    required this.items,
    required this.selectedId,
    required this.onSelected,
  });

  final List<KardexRecord> items;

  final int? selectedId;

  final ValueChanged<KardexRecord> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.sm),

      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),

        child: Table(
          columnWidths: const {
            0: FlexColumnWidth(2.4),
            1: FlexColumnWidth(1.30),
            2: FlexColumnWidth(1.40),
            3: FlexColumnWidth(1.75),
            4: FlexColumnWidth(1.00),
            5: FlexColumnWidth(1.00),
            6: FlexColumnWidth(1.00),
            7: FlexColumnWidth(1.30),
          },

          children: [
            /*
            HEADER
            */
            TableRow(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
              ),

              children: const [
                _KardexHeaderCell('INSUMO'),
                _KardexHeaderCell('FECHA'),
                _KardexHeaderCell('MOVIMIENTO'),
                _KardexHeaderCell('DOCUMENTO'),
                _KardexHeaderCell('ENTRADA', end: true),
                _KardexHeaderCell('SALIDA', end: true),
                _KardexHeaderCell('STOCK', end: true),
                _KardexHeaderCell('COSTO', end: true),
              ],
            ),

            /*
            FILAS
            */
            ...items.map((item) {
              final selected = item.id == selectedId;

              return TableRow(
                decoration: BoxDecoration(
                  color: selected
                      ? theme.colorScheme.primaryContainer.withValues(
                          alpha: .40,
                        )
                      : theme.colorScheme.surface,
                ),

                children: [
                  _KardexDataCell(
                    onTap: () => onSelected(item),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.insumoCodigo,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),

                        Text(
                          item.insumoNombre,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),

                  _KardexDataCell(
                    onTap: () => onSelected(item),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat(
                            'dd/MM/yyyy',
                          ).format(item.fechaMovimiento.toLocal()),
                        ),

                        Text(
                          DateFormat(
                            'HH:mm',
                          ).format(item.fechaMovimiento.toLocal()),
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),

                  _KardexDataCell(
                    onTap: () => onSelected(item),
                    child: _MovementBadge(item: item),
                  ),

                  _KardexDataCell(
                    onTap: () => onSelected(item),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.documentoTipo ?? '-',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall,
                        ),

                        if (item.documentoId != null)
                          Text(
                            item.documentoId.toString(),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),

                  _KardexDataCell(
                    onTap: () => onSelected(item),
                    end: true,
                    child: Text(_formatQuantity(item.entrada)),
                  ),

                  _KardexDataCell(
                    onTap: () => onSelected(item),
                    end: true,
                    child: Text(_formatQuantity(item.salida)),
                  ),

                  _KardexDataCell(
                    onTap: () => onSelected(item),
                    end: true,
                    child: Text(
                      _formatQuantity(item.stockActual),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),

                  _KardexDataCell(
                    onTap: () => onSelected(item),
                    end: true,
                    child: Text(
                      _formatMoney(item.costoTotal),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}

/*
══════════════════════════════════════════════════
HEADER TABLA
══════════════════════════════════════════════════
*/

class _KardexHeaderCell extends StatelessWidget {
  const _KardexHeaderCell(this.text, {this.end = false});

  final String text;
  final bool end;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      child: Text(
        text,
        textAlign: end ? TextAlign.right : TextAlign.left,
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/*
══════════════════════════════════════════════════
CELDA TABLA
══════════════════════════════════════════════════
*/

class _KardexDataCell extends StatelessWidget {
  const _KardexDataCell({
    required this.child,
    required this.onTap,
    this.end = false,
  });

  final Widget child;

  final VoidCallback onTap;

  final bool end;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,

      child: Container(
        alignment: end ? Alignment.centerRight : Alignment.centerLeft,

        constraints: const BoxConstraints(minHeight: 52),

        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),

        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
        ),

        child: child,
      ),
    );
  }
}

/*
══════════════════════════════════════════════════
BADGE MOVIMIENTO
══════════════════════════════════════════════════
*/

class _MovementBadge extends StatelessWidget {
  const _MovementBadge({required this.item});

  final KardexRecord item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final type = item.tipoMovimiento.toUpperCase();

    final isInitial = type.contains('STOCK_INICIAL');

    final badgeColor = isInitial
        ? const Color(0xFFE7EDF3)
        : item.isEntrada
        ? const Color(0xFFE2F6E8)
        : const Color(0xFFFFE3DF);

    final foreground = isInitial
        ? const Color(0xFF54616E)
        : item.isEntrada
        ? const Color(0xFF20633A)
        : const Color(0xFFB93825);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),

      decoration: BoxDecoration(
        color: badgeColor,

        borderRadius: BorderRadius.circular(999),
      ),

      child: Text(
        item.tipoMovimiento,

        maxLines: 1,

        overflow: TextOverflow.ellipsis,

        style: theme.textTheme.labelSmall?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/*
══════════════════════════════════════════════════
PANEL DERECHO
══════════════════════════════════════════════════
*/

class _KardexDetailPanel extends StatelessWidget {
  const _KardexDetailPanel({required this.item});

  final KardexRecord? item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (item == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 70,
                height: 70,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.description_outlined,
                  size: 34,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),

              const Gap(AppSpacing.md),

              const Text(
                'Selecciona un movimiento',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),

              const Gap(AppSpacing.xs),

              Text(
                'Haz clic en una fila para revisar su trazabilidad.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final record = item!;

    /*
    Stock anterior derivado:
    anterior + entrada - salida = actual

    Por lo tanto:
    anterior = actual - entrada + salida
    */

    final previousStock = record.stockActual - record.entrada + record.salida;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /*
          CABECERA
          */
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.inventory_2_outlined,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
              ),

              const Gap(AppSpacing.md),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.insumoCodigo,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    Text(
                      record.insumoNombre,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              _MovementBadge(item: record),
            ],
          ),

          const Gap(AppSpacing.lg),

          Divider(height: 1, color: theme.colorScheme.outlineVariant),

          const Gap(AppSpacing.sm),

          /*
          DOCUMENTO
          */
          _DetailRow(
            label: 'Documento',
            value: record.documentoTipo ?? 'Sin documento',
          ),

          _DetailRow(
            label: 'Documento ID',
            value: record.documentoId?.toString() ?? '-',
          ),

          _DetailRow(
            label: 'Fecha y hora',
            value: DateFormat(
              'dd/MM/yyyy HH:mm',
            ).format(record.fechaMovimiento.toLocal()),
          ),

          const Gap(AppSpacing.sm),

          Divider(height: 1, color: theme.colorScheme.outlineVariant),

          const Gap(AppSpacing.sm),

          /*
          MOVIMIENTO
          */
          _DetailRow(
            label: 'Entrada',
            value: '${_formatQuantity(record.entrada)} KG',
          ),

          _DetailRow(
            label: 'Salida',
            value: '${_formatQuantity(record.salida)} KG',
          ),

          _DetailRow(
            label: 'Stock anterior',
            value: '${_formatQuantity(previousStock)} KG',
          ),

          _DetailRow(
            label: 'Stock resultante',
            value: '${_formatQuantity(record.stockActual)} KG',
            strong: true,
          ),

          const Gap(AppSpacing.sm),

          Divider(height: 1, color: theme.colorScheme.outlineVariant),

          const Gap(AppSpacing.sm),

          /*
          COSTOS
          */
          _DetailRow(
            label: 'Costo unitario',
            value: _formatMoney(record.costoUnitario),
          ),

          _DetailRow(
            label: 'Costo total',
            value: _formatMoney(record.costoTotal),
            strong: true,
          ),

          const Gap(AppSpacing.sm),

          Divider(height: 1, color: theme.colorScheme.outlineVariant),

          const Gap(AppSpacing.sm),

          _DetailRow(
            label: 'Responsable',
            value: record.usuarioResponsable ?? 'Sin responsable',
          ),

          _DetailRow(
            label: 'Observación',
            value: record.observacion ?? 'Sin observación',
          ),
        ],
      ),
    );
  }
}

/*
══════════════════════════════════════════════════
FILA DEL DETALLE
══════════════════════════════════════════════════
*/

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.strong = false,
  });

  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),

          const Gap(AppSpacing.sm),

          Expanded(
            flex: 5,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: strong ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/*
══════════════════════════════════════════════════
FORMATOS
══════════════════════════════════════════════════
*/

/*
IMPORTANTE:

ANTES:
1000 -> 1.000

AHORA:
1000 -> 1000
15.695 -> 15.70 si realmente es decimal.

No usamos separador de miles en cantidades.
*/
String _formatQuantity(double value) {
  if (value == value.roundToDouble()) {
    return value.toStringAsFixed(0);
  }

  /*
  Hasta 2 decimales,
  eliminando ceros finales.
  */

  var result = value.toStringAsFixed(2);

  result = result.replaceFirst(RegExp(r'\.?0+$'), '');

  return result;
}

/*
Dinero:
3500 -> S/ 3,500.00
1360 -> S/ 1,360.00
3.5  -> S/ 3.50
*/
String _formatMoney(double value) {
  return NumberFormat.currency(
    locale: 'en_US',
    symbol: 'S/ ',
    decimalDigits: 2,
  ).format(value);
}
