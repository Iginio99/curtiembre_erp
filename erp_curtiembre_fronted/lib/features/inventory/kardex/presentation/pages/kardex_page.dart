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
                    _KardexSummary(items: state.items),
                    const Gap(AppSpacing.lg),
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

class _KardexSummary extends StatelessWidget {
  const _KardexSummary({required this.items});

  final List<KardexRecord> items;

  @override
  Widget build(BuildContext context) {
    final entries = items.fold<double>(0, (sum, item) => sum + item.entrada);
    final exits = items.fold<double>(0, (sum, item) => sum + item.salida);
    final value = items.fold<double>(0, (sum, item) => sum + item.costoTotal);
    final products = items.map((item) => item.insumoId).toSet().length;
    final metrics = [
      ('Movimientos', '${items.length}', Icons.swap_vert_rounded),
      ('Insumos', '$products', Icons.inventory_2_outlined),
      ('Entradas', _formatQuantity(entries), Icons.south_west_rounded),
      ('Salidas', _formatQuantity(exits), Icons.north_east_rounded),
      ('Valor movido', _formatMoney(value), Icons.payments_outlined),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth >= 1000
            ? (constraints.maxWidth - AppSpacing.md * 4) / 5
            : 210.0;
        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: metrics
              .map(
                (metric) => SizedBox(
                  width: width,
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(metric.$3, color: Theme.of(context).colorScheme.primary),
                        ),
                        const Gap(AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(metric.$1, style: Theme.of(context).textTheme.labelMedium),
                              Text(metric.$2, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
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
                ),
              ),
              SizedBox(
                width: 220,
                child: DropdownButtonFormField<String?>(
                  isExpanded: true,
                  initialValue: state.tipoMovimientoFilter,
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
                  isExpanded: true,
                  initialValue: state.documentoTipoFilter,
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
    final selected = state.items.where((item) => item.id == selectedId).firstOrNull;

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
                            onSelected: (item) => setState(() => selectedId = item.id),
                          );
                          if (!wide) return table;
                          return Row(
                            children: [
                              Expanded(flex: 7, child: table),
                              const VerticalDivider(width: 1),
                              SizedBox(
                                width: 350,
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

class _KardexMovementsTable extends StatelessWidget {
  const _KardexMovementsTable({required this.items, required this.selectedId, required this.onSelected});

  final List<KardexRecord> items;
  final int? selectedId;
  final ValueChanged<KardexRecord> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Table(
          columnWidths: const {
            0: FlexColumnWidth(2.6),
            1: FlexColumnWidth(1.25),
            2: FlexColumnWidth(1.25),
            3: FlexColumnWidth(1.05),
            4: FlexColumnWidth(1.05),
            5: FlexColumnWidth(1.05),
            6: FlexColumnWidth(1.25),
          },
          children: [
            const TableRow(
              decoration: BoxDecoration(color: Color(0xFF343437)),
              children: [
                _KardexHeaderCell('INSUMO'),
                _KardexHeaderCell('FECHA'),
                _KardexHeaderCell('MOVIMIENTO'),
                _KardexHeaderCell('ENTRADA', end: true),
                _KardexHeaderCell('SALIDA', end: true),
                _KardexHeaderCell('STOCK', end: true),
                _KardexHeaderCell('COSTO TOTAL', end: true),
              ],
            ),
            ...items.map(
              (item) => TableRow(
                decoration: BoxDecoration(
                  color: item.id == selectedId
                      ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: .55)
                      : Theme.of(context).colorScheme.surface,
                ),
                children: [
                  _KardexDataCell(
                    onTap: () => onSelected(item),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.insumoCodigo, style: const TextStyle(fontWeight: FontWeight.w800)),
                        Text(item.insumoNombre, maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  _KardexDataCell(onTap: () => onSelected(item), child: Text(DateFormat('dd/MM/yyyy').format(item.fechaMovimiento.toLocal()))),
                  _KardexDataCell(onTap: () => onSelected(item), child: _MovementBadge(item: item)),
                  _KardexDataCell(onTap: () => onSelected(item), end: true, child: Text(_formatQuantity(item.entrada))),
                  _KardexDataCell(onTap: () => onSelected(item), end: true, child: Text(_formatQuantity(item.salida))),
                  _KardexDataCell(onTap: () => onSelected(item), end: true, child: Text(_formatQuantity(item.stockActual), style: const TextStyle(fontWeight: FontWeight.w800))),
                  _KardexDataCell(onTap: () => onSelected(item), end: true, child: Text(_formatMoney(item.costoTotal), style: const TextStyle(fontWeight: FontWeight.w700))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KardexHeaderCell extends StatelessWidget {
  const _KardexHeaderCell(this.text, {this.end = false});
  final String text;
  final bool end;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
    child: Text(text, textAlign: end ? TextAlign.right : TextAlign.left, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
  );
}

class _KardexDataCell extends StatelessWidget {
  const _KardexDataCell({required this.child, required this.onTap, this.end = false});
  final Widget child;
  final VoidCallback onTap;
  final bool end;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Container(
      alignment: end ? Alignment.centerRight : Alignment.centerLeft,
      constraints: const BoxConstraints(minHeight: 58),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Theme.of(context).colorScheme.outlineVariant))),
      child: child,
    ),
  );
}

class _MovementBadge extends StatelessWidget {
  const _MovementBadge({required this.item});

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
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(item.tipoMovimiento, style: theme.textTheme.labelSmall?.copyWith(color: badgeForeground, fontWeight: FontWeight.w800)),
    );
  }
}

class _KardexDetailPanel extends StatelessWidget {
  const _KardexDetailPanel({required this.item});
  final KardexRecord? item;

  @override
  Widget build(BuildContext context) {
    if (item == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.touch_app_outlined, size: 36),
              Gap(AppSpacing.md),
              Text('Selecciona un movimiento', style: TextStyle(fontWeight: FontWeight.w800)),
              Gap(AppSpacing.xs),
              Text('Haz clic en una fila para ampliar su trazabilidad.', textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }
    final record = item!;
    final fields = [
      ('Documento', record.documentoTipo ?? 'Sin documento'),
      ('Documento ID', record.documentoId?.toString() ?? '-'),
      ('Fecha y hora', DateFormat('dd/MM/yyyy hh:mm a').format(record.fechaMovimiento.toLocal())),
      ('Entrada', _formatQuantity(record.entrada)),
      ('Salida', _formatQuantity(record.salida)),
      ('Stock resultante', _formatQuantity(record.stockActual)),
      ('Costo unitario', _formatMoney(record.costoUnitario)),
      ('Costo total', _formatMoney(record.costoTotal)),
      ('Responsable', record.usuarioResponsable ?? 'Sin responsable'),
      ('Observacion', record.observacion ?? 'Sin observacion'),
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Expanded(child: Text(record.insumoCodigo, style: Theme.of(context).textTheme.headlineSmall)), _MovementBadge(item: record)]),
          const Gap(AppSpacing.xs),
          Text(record.insumoNombre, style: Theme.of(context).textTheme.titleMedium),
          const Gap(AppSpacing.lg),
          ...fields.map((field) => Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Theme.of(context).colorScheme.outlineVariant))),
            child: Row(children: [Expanded(child: Text(field.$1, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant))), const Gap(AppSpacing.md), Flexible(child: Text(field.$2, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w700)))]),
          )),
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

String _formatQuantity(double value) =>
    NumberFormat('#,##0.##', 'es_PE').format(value);

String _formatMoney(double value) =>
    NumberFormat.currency(locale: 'es_PE', symbol: 'S/ ').format(value);
