import 'package:erp_curtiembre_fronted/core/theme/app_breakpoints.dart';
import 'package:erp_curtiembre_fronted/core/theme/app_spacing.dart';
import 'package:erp_curtiembre_fronted/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:erp_curtiembre_fronted/features/configuration/system_parameters/domain/entities/system_parameter_record.dart';
import 'package:erp_curtiembre_fronted/features/configuration/system_parameters/presentation/cubit/system_parameters_cubit.dart';
import 'package:erp_curtiembre_fronted/features/configuration/system_parameters/presentation/cubit/system_parameters_state.dart';
import 'package:erp_curtiembre_fronted/shared/widgets/buttons/app_button.dart';
import 'package:erp_curtiembre_fronted/shared/widgets/feedback/app_message_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class SystemParametersPage extends StatefulWidget {
  const SystemParametersPage({super.key});

  @override
  State<SystemParametersPage> createState() => _SystemParametersPageState();
}

class _SystemParametersPageState extends State<SystemParametersPage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applySearch() {
    FocusScope.of(context).unfocus();
    context.read<SystemParametersCubit>().applyFilters(
          searchTerm: _searchController.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final session = context.select((AuthCubit cubit) => cubit.state.session);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Parametros del sistema'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.lg),
            child: TextButton.icon(
              onPressed: () => context.go('/home'),
              icon: const Icon(Icons.dashboard_outlined),
              label: const Text('Panel'),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1440),
                  child: BlocBuilder<SystemParametersCubit, SystemParametersState>(
                    builder: (context, state) {
                      final isWide =
                          MediaQuery.sizeOf(context).width >= AppBreakpoints.tablet;
                      final compactHeight = constraints.maxHeight < 860;

                      if (_searchController.text != state.searchTerm) {
                        _searchController.value = TextEditingValue(
                          text: state.searchTerm,
                          selection: TextSelection.collapsed(
                            offset: state.searchTerm.length,
                          ),
                        );
                      }

                      final listPanel = _SystemParametersListPanel(
                        state: state,
                        onRetry: () => context.read<SystemParametersCubit>().initialize(),
                        onSelect: (id) =>
                            context.read<SystemParametersCubit>().selectParameter(id),
                      );

                      final detailPanel = _SystemParametersDetailPanel(state: state);

                      final headerAndFilters = <Widget>[
                        _SystemParametersHeader(
                          userName: session?.userName,
                          itemCount: state.visibleItems.length,
                          editableCount:
                              state.allItems.where((item) => item.editable).length,
                        ),
                        const Gap(AppSpacing.xl),
                        _SystemParametersFiltersCard(
                          controller: _searchController,
                          state: state,
                          isLoading: state.status == SystemParametersStatus.loading,
                          onSearch: _applySearch,
                          onEditabilityChanged: (filter) =>
                              context.read<SystemParametersCubit>().applyFilters(
                                    editabilityFilter: filter,
                                  ),
                          onTypeChanged: (value) =>
                              context.read<SystemParametersCubit>().applyFilters(
                                    typeFilter: value ?? '',
                                  ),
                        ),
                        const Gap(AppSpacing.xl),
                      ];

                      if (compactHeight) {
                        if (isWide) {
                          return SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ...headerAndFilters,
                                SizedBox(
                                  height: 620,
                                  child: Row(
                                    children: [
                                      Expanded(flex: 9, child: listPanel),
                                      const Gap(AppSpacing.xl),
                                      Expanded(flex: 8, child: detailPanel),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ...headerAndFilters,
                              SizedBox(height: 520, child: listPanel),
                              const Gap(AppSpacing.xl),
                              SizedBox(height: 560, child: detailPanel),
                            ],
                          ),
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ...headerAndFilters,
                          Expanded(
                            child: isWide
                                ? Row(
                                    children: [
                                      Expanded(flex: 9, child: listPanel),
                                      const Gap(AppSpacing.xl),
                                      Expanded(flex: 8, child: detailPanel),
                                    ],
                                  )
                                : Column(
                                    children: [
                                      Expanded(child: listPanel),
                                      const Gap(AppSpacing.xl),
                                      Expanded(child: detailPanel),
                                    ],
                                  ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SystemParametersHeader extends StatelessWidget {
  const _SystemParametersHeader({
    required this.userName,
    required this.itemCount,
    required this.editableCount,
  });

  final String? userName;
  final int itemCount;
  final int editableCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Wrap(
        spacing: AppSpacing.xl,
        runSpacing: AppSpacing.lg,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 780),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Supervisa los parametros transversales que gobiernan reglas clave del ERP.',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    height: 1.12,
                  ),
                ),
                const Gap(AppSpacing.sm),
                Text(
                  'Esta vista es de solo lectura por ahora. Te permite validar claves, tipos, valores y trazabilidad antes de habilitar futuras ediciones controladas.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.88),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              _SystemParameterSummaryBadge(
                label: 'Parametros visibles',
                value: '$itemCount',
              ),
              _SystemParameterSummaryBadge(
                label: 'Editables',
                value: '$editableCount',
              ),
              if (userName != null)
                _SystemParameterSummaryBadge(
                  label: 'Sesion actual',
                  value: userName!,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SystemParametersFiltersCard extends StatelessWidget {
  const _SystemParametersFiltersCard({
    required this.controller,
    required this.state,
    required this.isLoading,
    required this.onSearch,
    required this.onEditabilityChanged,
    required this.onTypeChanged,
  });

  final TextEditingController controller;
  final SystemParametersState state;
  final bool isLoading;
  final VoidCallback onSearch;
  final ValueChanged<SystemParameterEditabilityFilter> onEditabilityChanged;
  final ValueChanged<String?> onTypeChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Busqueda y lectura operativa', style: theme.textTheme.titleLarge),
          const Gap(AppSpacing.sm),
          Text(
            'Busca por clave, valor o descripcion. Tambien puedes distinguir rapidamente entre parametros editables y de solo lectura.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const Gap(AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.lg,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 420,
                child: TextField(
                  controller: controller,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => onSearch(),
                  decoration: const InputDecoration(
                    labelText: 'Buscar parametro',
                    hintText: 'Ej. INTENTOS_LOGIN_MAX o IGV',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
              ),
              AppButton.primary(
                label: 'Aplicar busqueda',
                icon: Icons.search_rounded,
                isLoading: isLoading,
                onPressed: onSearch,
                expand: false,
              ),
              Container(
                width: 240,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                decoration: BoxDecoration(
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: state.typeFilter.isEmpty ? null : state.typeFilter,
                    hint: const Text('Todos los tipos'),
                    items: [
                      const DropdownMenuItem<String>(
                        value: '',
                        child: Text('Todos los tipos'),
                      ),
                      ...state.availableTypes.map(
                        (item) => DropdownMenuItem<String>(
                          value: item,
                          child: Text(item),
                        ),
                      ),
                    ],
                    onChanged: onTypeChanged,
                  ),
                ),
              ),
            ],
          ),
          const Gap(AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.md,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SegmentedButton<SystemParameterEditabilityFilter>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment<SystemParameterEditabilityFilter>(
                    value: SystemParameterEditabilityFilter.all,
                    label: Text('Todos'),
                    icon: Icon(Icons.tune_outlined),
                  ),
                  ButtonSegment<SystemParameterEditabilityFilter>(
                    value: SystemParameterEditabilityFilter.editable,
                    label: Text('Editables'),
                    icon: Icon(Icons.edit_note_outlined),
                  ),
                  ButtonSegment<SystemParameterEditabilityFilter>(
                    value: SystemParameterEditabilityFilter.readOnly,
                    label: Text('Solo lectura'),
                    icon: Icon(Icons.lock_outline),
                  ),
                ],
                selected: {state.editabilityFilter},
                onSelectionChanged: (selection) {
                  final filter = selection.firstOrNull;
                  if (filter != null) {
                    onEditabilityChanged(filter);
                  }
                },
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                child: Text(
                  'Sin escritura habilitada desde UI',
                  style: theme.textTheme.labelLarge,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SystemParametersListPanel extends StatelessWidget {
  const _SystemParametersListPanel({
    required this.state,
    required this.onRetry,
    required this.onSelect,
  });

  final SystemParametersState state;
  final VoidCallback onRetry;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Listado de parametros', style: theme.textTheme.titleLarge),
            const Gap(AppSpacing.xs),
            Text(
              '${state.visibleItems.length} resultado(s) en la vista actual.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const Gap(AppSpacing.lg),
            Expanded(
              child: switch (state.status) {
                SystemParametersStatus.loading =>
                  const Center(child: CircularProgressIndicator()),
                SystemParametersStatus.error => _SystemParametersCenteredMessage(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppMessageCard.error(
                          title: 'No pudimos cargar los parametros',
                          message: state.errorMessage ??
                              'Intenta nuevamente para consultar la configuracion.',
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
                SystemParametersStatus.success => state.visibleItems.isEmpty
                    ? const _SystemParametersCenteredMessage(
                        child: AppMessageCard.info(
                          title: 'Sin resultados',
                          message:
                              'No encontramos parametros con los filtros actuales.',
                        ),
                      )
                    : ListView.separated(
                        itemCount: state.visibleItems.length,
                        separatorBuilder: (_, _) => const Gap(AppSpacing.md),
                        itemBuilder: (context, index) {
                          final item = state.visibleItems[index];
                          return _SystemParameterListTileCard(
                            item: item,
                            isSelected: item.id == state.selectedParameterId,
                            onTap: () => onSelect(item.id),
                          );
                        },
                      ),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SystemParametersDetailPanel extends StatelessWidget {
  const _SystemParametersDetailPanel({required this.state});

  final SystemParametersState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final parameter = state.selectedParameter;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Detalle del parametro', style: theme.textTheme.titleLarge),
            const Gap(AppSpacing.xs),
            Text(
              'Valida su finalidad, tipo, estado de edicion y el ultimo momento de actualizacion.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const Gap(AppSpacing.lg),
            Expanded(
              child: Builder(
                builder: (context) {
                  if (state.status == SystemParametersStatus.loading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (parameter == null) {
                    return const _SystemParametersCenteredMessage(
                      child: AppMessageCard.info(
                        title: 'Selecciona un parametro',
                        message:
                            'Escoge un registro del listado para revisar su informacion.',
                      ),
                    );
                  }

                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: AppSpacing.md,
                          runSpacing: AppSpacing.md,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              parameter.clave,
                              style: theme.textTheme.headlineSmall,
                            ),
                            _SystemParameterStatusBadge(
                              label: parameter.editable ? 'Editable' : 'Solo lectura',
                              icon: parameter.editable
                                  ? Icons.edit_note_outlined
                                  : Icons.lock_outline,
                              background: parameter.editable
                                  ? theme.colorScheme.primaryContainer
                                  : theme.colorScheme.surfaceContainerHighest,
                              foreground: parameter.editable
                                  ? theme.colorScheme.onPrimaryContainer
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ],
                        ),
                        const Gap(AppSpacing.sm),
                        _ReadOnlyValueCard(value: parameter.valor),
                        const Gap(AppSpacing.xl),
                        Wrap(
                          spacing: AppSpacing.lg,
                          runSpacing: AppSpacing.lg,
                          children: [
                            _SystemParameterDetailCard(
                              title: 'Identidad',
                              lines: [
                                'ID: ${parameter.id}',
                                'Clave: ${parameter.clave}',
                                'Tipo de dato: ${parameter.tipoDato}',
                              ],
                            ),
                            _SystemParameterDetailCard(
                              title: 'Descripcion',
                              lines: [
                                parameter.descripcion?.isNotEmpty == true
                                    ? parameter.descripcion!
                                    : 'Sin descripcion registrada.',
                              ],
                            ),
                            _SystemParameterDetailCard(
                              title: 'Trazabilidad',
                              lines: [
                                'Edicion desde UI: ${parameter.editable ? 'Permitida' : 'No permitida'}',
                                'Ultima actualizacion: ${_formatOptionalDate(parameter.actualizadoEn)}',
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SystemParameterListTileCard extends StatelessWidget {
  const _SystemParameterListTileCard({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final SystemParameterRecord item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primaryContainer.withValues(alpha: 0.68)
                : theme.colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary.withValues(alpha: 0.42)
                  : theme.colorScheme.outlineVariant,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.sm,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(item.clave, style: theme.textTheme.titleMedium),
                  _SystemParameterMiniPill(
                    label: item.editable ? 'Editable' : 'Solo lectura',
                    background: item.editable
                        ? theme.colorScheme.primaryContainer
                        : theme.colorScheme.surfaceContainerHighest,
                    foreground: item.editable
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  _SystemParameterMiniPill(
                    label: item.tipoDato,
                    background: theme.colorScheme.secondaryContainer,
                    foreground: theme.colorScheme.onSecondaryContainer,
                  ),
                ],
              ),
              const Gap(AppSpacing.sm),
              Text(
                item.valor,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.primary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const Gap(AppSpacing.md),
              Text(
                item.descripcion?.isNotEmpty == true
                    ? item.descripcion!
                    : 'Sin descripcion registrada.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReadOnlyValueCard extends StatelessWidget {
  const _ReadOnlyValueCard({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
          Text('Valor actual', style: theme.textTheme.labelLarge),
          const Gap(AppSpacing.sm),
          SelectableText(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SystemParameterDetailCard extends StatelessWidget {
  const _SystemParameterDetailCard({
    required this.title,
    required this.lines,
  });

  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 260,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleMedium),
          const Gap(AppSpacing.md),
          for (final line in lines) ...[
            Text(line, style: theme.textTheme.bodyMedium),
            const Gap(AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _SystemParameterStatusBadge extends StatelessWidget {
  const _SystemParameterStatusBadge({
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
  });

  final String label;
  final IconData icon;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: foreground),
          const Gap(AppSpacing.sm),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: foreground,
                ),
          ),
        ],
      ),
    );
  }
}

class _SystemParameterMiniPill extends StatelessWidget {
  const _SystemParameterMiniPill({
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
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: foreground,
            ),
      ),
    );
  }
}

class _SystemParameterSummaryBadge extends StatelessWidget {
  const _SystemParameterSummaryBadge({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.82),
            ),
          ),
          const Gap(AppSpacing.xs),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _SystemParametersCenteredMessage extends StatelessWidget {
  const _SystemParametersCenteredMessage({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: child,
      ),
    );
  }
}

String _formatOptionalDate(DateTime? value) {
  if (value == null) {
    return 'Sin registro';
  }

  return DateFormat('dd/MM/yyyy hh:mm a').format(value.toLocal());
}
