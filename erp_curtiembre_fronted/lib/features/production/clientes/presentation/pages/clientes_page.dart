import 'package:erp_curtiembre_fronted/core/di/service_locator.dart';
import 'package:erp_curtiembre_fronted/core/logging/app_talker.dart';
import 'package:erp_curtiembre_fronted/core/theme/app_breakpoints.dart';
import 'package:erp_curtiembre_fronted/core/theme/app_spacing.dart';
import 'package:erp_curtiembre_fronted/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:erp_curtiembre_fronted/features/production/clientes/domain/entities/cliente_record.dart';
import 'package:erp_curtiembre_fronted/features/production/clientes/presentation/cubit/clientes_cubit.dart';
import 'package:erp_curtiembre_fronted/features/production/clientes/presentation/cubit/clientes_state.dart';
import 'package:erp_curtiembre_fronted/features/production/clientes/presentation/widgets/cliente_upsert_dialog.dart';
import 'package:erp_curtiembre_fronted/shared/widgets/buttons/app_button.dart';
import 'package:erp_curtiembre_fronted/shared/widgets/feedback/app_message_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:talker_flutter/talker_flutter.dart';

class ClientesPage extends StatefulWidget {
  const ClientesPage({super.key});

  @override
  State<ClientesPage> createState() => _ClientesPageState();
}

class _ClientesPageState extends State<ClientesPage> {
  final _searchController = TextEditingController();
  final Talker _talker = getIt<Talker>();

  @override
  void initState() {
    super.initState();
    _talker.ui('Se abrio la pantalla de clientes de produccion.');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applySearch() {
    FocusScope.of(context).unfocus();
    _talker.ui(
      'Se aplico una busqueda en clientes con texto=${_describeSearchTerm(_searchController.text)}.',
    );
    context.read<ClientesCubit>().load(
      searchTerm: _searchController.text.trim(),
    );
  }

  Future<void> _openCreateDialog(ClientesState state) async {
    _talker.ui('Se abrio el dialogo para crear cliente.');
    final payload = await showDialog<ClienteUpsertFormData>(
      context: context,
      builder: (_) => ClienteUpsertDialog(
        title: 'Nuevo cliente',
        submitLabel: 'Crear cliente',
        isSubmitting: state.isSubmittingAction,
      ),
    );

    if (payload == null || !mounted) {
      _talker.ui(
        'Se cerro el dialogo de creacion de cliente sin confirmar.',
        logLevel: LogLevel.debug,
      );
      return;
    }
    _talker.ui('Se confirmo la creacion del cliente ${payload.razonSocial}.');

    final result = await context.read<ClientesCubit>().createCliente(
      rucDocumento: payload.rucDocumento,
      razonSocial: payload.razonSocial,
      direccion: payload.direccion,
      celular: payload.celular,
      correo: payload.correo,
      contacto: payload.contacto,
    );

    if (!mounted) {
      return;
    }

    _showActionResult(result);
  }

  Future<void> _openEditDialog(
    ClientesState state,
    ClienteRecord cliente,
  ) async {
    _talker.ui('Se abrio el dialogo para editar el cliente ${cliente.id}.');
    final payload = await showDialog<ClienteUpsertFormData>(
      context: context,
      builder: (_) => ClienteUpsertDialog(
        title: 'Editar cliente',
        submitLabel: 'Guardar cambios',
        isSubmitting: state.isSubmittingAction,
        initialCliente: cliente,
      ),
    );

    if (payload == null || !mounted) {
      _talker.ui(
        'Se cerro la edicion del cliente ${cliente.id} sin confirmar.',
        logLevel: LogLevel.debug,
      );
      return;
    }
    _talker.ui(
      'Se confirmo la edicion del cliente ${cliente.id} con razonSocial=${payload.razonSocial}.',
    );

    final result = await context.read<ClientesCubit>().updateSelectedCliente(
      rucDocumento: payload.rucDocumento,
      razonSocial: payload.razonSocial,
      direccion: payload.direccion,
      celular: payload.celular,
      correo: payload.correo,
      contacto: payload.contacto,
    );

    if (!mounted) {
      return;
    }

    _showActionResult(result);
  }

  Future<void> _toggleState(ClienteRecord cliente) async {
    _talker.ui(
      cliente.activo
          ? 'Se solicito inactivar el cliente ${cliente.id}.'
          : 'Se solicito activar el cliente ${cliente.id}.',
      logLevel: LogLevel.warning,
    );
    final result = await context.read<ClientesCubit>().setSelectedClienteActive(
      !cliente.activo,
    );

    if (!mounted) {
      return;
    }

    _showActionResult(result);
  }

  void _showActionResult(ClientesActionResult result) {
    _talker.ui(
      result.success
          ? 'Accion en clientes completada correctamente.'
          : 'La accion en clientes fallo: ${result.message}',
      logLevel: result.success ? LogLevel.debug : LogLevel.error,
    );
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(result.message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: result.success ? null : const Color(0xFF8A2F22),
      ),
    );
  }

  String _describeSearchTerm(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      return 'vacio';
    }

    return '${normalized.length} caracteres';
  }

  @override
  Widget build(BuildContext context) {
    final session = context.select((AuthCubit cubit) => cubit.state.session);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clientes de produccion'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.lg),
            child: TextButton.icon(
              onPressed: () {
                _talker.ui(
                  'Se regreso desde clientes de produccion al panel principal.',
                );
                context.go('/home');
              },
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
                  child: BlocBuilder<ClientesCubit, ClientesState>(
                    builder: (context, state) {
                      final isWide =
                          MediaQuery.sizeOf(context).width >=
                          AppBreakpoints.tablet;
                      final compactHeight = constraints.maxHeight < 860;

                      if (_searchController.text != state.searchTerm) {
                        _searchController.value = TextEditingValue(
                          text: state.searchTerm,
                          selection: TextSelection.collapsed(
                            offset: state.searchTerm.length,
                          ),
                        );
                      }

                      final listPanel = _ClientesListPanel(
                        state: state,
                        onRetry: () =>
                            context.read<ClientesCubit>().initialize(),
                        onSelectCliente: (clienteId) {
                          _talker.ui(
                            'Se selecciono el cliente $clienteId desde el listado.',
                            logLevel: LogLevel.debug,
                          );
                          context.read<ClientesCubit>().selectCliente(
                            clienteId,
                          );
                        },
                      );

                      final detailPanel = _ClienteDetailPanel(
                        state: state,
                        onRetry: () =>
                            context.read<ClientesCubit>().retryDetail(),
                        onEdit: state.selectedCliente == null
                            ? null
                            : () => _openEditDialog(
                                state,
                                state.selectedCliente!,
                              ),
                        onToggleState: state.selectedCliente == null
                            ? null
                            : () => _toggleState(state.selectedCliente!),
                      );

                      final headerAndFilters = <Widget>[
                        _ClientesHeader(
                          totalItems: state.items.length,
                          sessionUserName: session?.userName,
                        ),
                        const Gap(AppSpacing.xl),
                        _ClientesFiltersCard(
                          controller: _searchController,
                          selectedFilter: state.filter,
                          isLoading: state.status == ClientesStatus.loading,
                          isSubmittingAction: state.isSubmittingAction,
                          onSearch: _applySearch,
                          onCreateCliente: () => _openCreateDialog(state),
                          onFilterChanged: (filter) {
                            _talker.ui(
                              'Se cambio el filtro de clientes a $filter.',
                              logLevel: LogLevel.debug,
                            );
                            context.read<ClientesCubit>().load(filter: filter);
                          },
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

class _ClientesHeader extends StatelessWidget {
  const _ClientesHeader({
    required this.totalItems,
    required this.sessionUserName,
  });

  final int totalItems;
  final String? sessionUserName;

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
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Administra la base comercial que alimenta lotes y ordenes de produccion.',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    height: 1.12,
                  ),
                ),
                const Gap(AppSpacing.sm),
                Text(
                  'Aqui conviene mantener limpia la identidad del cliente, su contacto y su vigencia operativa antes de asociarlo a nuevos lotes.',
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
              _SummaryBadge(label: 'Clientes visibles', value: '$totalItems'),
              if (sessionUserName != null)
                _SummaryBadge(label: 'Sesion actual', value: sessionUserName!),
            ],
          ),
        ],
      ),
    );
  }
}

class _ClientesFiltersCard extends StatelessWidget {
  const _ClientesFiltersCard({
    required this.controller,
    required this.selectedFilter,
    required this.isLoading,
    required this.isSubmittingAction,
    required this.onSearch,
    required this.onCreateCliente,
    required this.onFilterChanged,
  });

  final TextEditingController controller;
  final ClienteActivityFilter selectedFilter;
  final bool isLoading;
  final bool isSubmittingAction;
  final VoidCallback onSearch;
  final VoidCallback onCreateCliente;
  final ValueChanged<ClienteActivityFilter> onFilterChanged;

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
          Text('Busqueda comercial', style: theme.textTheme.titleLarge),
          const Gap(AppSpacing.sm),
          Text(
            'Filtra por razon social, documento o contacto y revisa rapidamente quienes siguen disponibles para nuevos lotes.',
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
                    labelText: 'Buscar cliente',
                    hintText: 'Ej. 20601234567 o Exportadora San Martin',
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
              AppButton.secondary(
                label: 'Nuevo cliente',
                icon: Icons.add_business_outlined,
                isLoading: isSubmittingAction,
                onPressed: onCreateCliente,
              ),
            ],
          ),
          const Gap(AppSpacing.lg),
          SegmentedButton<ClienteActivityFilter>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment<ClienteActivityFilter>(
                value: ClienteActivityFilter.active,
                label: Text('Activos'),
                icon: Icon(Icons.verified_outlined),
              ),
              ButtonSegment<ClienteActivityFilter>(
                value: ClienteActivityFilter.inactive,
                label: Text('Inactivos'),
                icon: Icon(Icons.block_outlined),
              ),
              ButtonSegment<ClienteActivityFilter>(
                value: ClienteActivityFilter.all,
                label: Text('Todos'),
                icon: Icon(Icons.groups_outlined),
              ),
            ],
            selected: {selectedFilter},
            onSelectionChanged: (selection) {
              final filter = selection.firstOrNull;
              if (filter != null) {
                onFilterChanged(filter);
              }
            },
          ),
        ],
      ),
    );
  }
}

class _ClientesListPanel extends StatelessWidget {
  const _ClientesListPanel({
    required this.state,
    required this.onRetry,
    required this.onSelectCliente,
  });

  final ClientesState state;
  final VoidCallback onRetry;
  final ValueChanged<int> onSelectCliente;

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
            Text('Listado de clientes', style: theme.textTheme.titleLarge),
            const Gap(AppSpacing.xs),
            Text(
              '${state.items.length} resultado(s) para la vista actual.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const Gap(AppSpacing.lg),
            Expanded(
              child: switch (state.status) {
                ClientesStatus.loading => const Center(
                  child: CircularProgressIndicator(),
                ),
                ClientesStatus.error => _CenteredMessage(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppMessageCard.error(
                        title: 'No pudimos cargar los clientes',
                        message:
                            state.errorMessage ??
                            'Intenta nuevamente para consultar la informacion comercial.',
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
                ClientesStatus.success =>
                  state.items.isEmpty
                      ? const _CenteredMessage(
                          child: AppMessageCard.info(
                            title: 'Sin resultados',
                            message:
                                'No encontramos clientes con los filtros actuales.',
                          ),
                        )
                      : ListView.separated(
                          itemCount: state.items.length,
                          separatorBuilder: (_, _) => const Gap(AppSpacing.md),
                          itemBuilder: (context, index) {
                            final item = state.items[index];
                            return _ClienteListTileCard(
                              item: item,
                              isSelected: item.id == state.selectedClienteId,
                              onTap: () => onSelectCliente(item.id),
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

class _ClienteDetailPanel extends StatelessWidget {
  const _ClienteDetailPanel({
    required this.state,
    required this.onRetry,
    required this.onEdit,
    required this.onToggleState,
  });

  final ClientesState state;
  final VoidCallback onRetry;
  final VoidCallback? onEdit;
  final VoidCallback? onToggleState;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cliente = state.selectedCliente;

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
            Text('Detalle del cliente', style: theme.textTheme.titleLarge),
            const Gap(AppSpacing.xs),
            Text(
              'Revisa identidad comercial, datos de contacto y vigencia para nuevos lotes y ordenes.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const Gap(AppSpacing.lg),
            Expanded(
              child: Builder(
                builder: (context) {
                  if (state.isDetailLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state.detailErrorMessage != null) {
                    return _CenteredMessage(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AppMessageCard.error(
                            title: 'No pudimos cargar el detalle',
                            message: state.detailErrorMessage!,
                          ),
                          const Gap(AppSpacing.lg),
                          AppButton.secondary(
                            label: 'Reintentar detalle',
                            icon: Icons.refresh_rounded,
                            onPressed: onRetry,
                          ),
                        ],
                      ),
                    );
                  }

                  if (cliente == null) {
                    return const _CenteredMessage(
                      child: AppMessageCard.info(
                        title: 'Selecciona un cliente',
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
                              cliente.razonSocial,
                              style: theme.textTheme.headlineSmall,
                            ),
                            _StatusBadge(
                              label: cliente.activo ? 'Activo' : 'Inactivo',
                              icon: cliente.activo
                                  ? Icons.verified_outlined
                                  : Icons.block_outlined,
                              background: cliente.activo
                                  ? theme.colorScheme.primaryContainer
                                  : theme.colorScheme.surfaceContainerHighest,
                              foreground: cliente.activo
                                  ? theme.colorScheme.onPrimaryContainer
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ],
                        ),
                        const Gap(AppSpacing.xs),
                        Text(
                          cliente.rucDocumento,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const Gap(AppSpacing.lg),
                        Wrap(
                          spacing: AppSpacing.md,
                          runSpacing: AppSpacing.md,
                          children: [
                            AppButton.secondary(
                              label: 'Editar cliente',
                              icon: Icons.edit_outlined,
                              isLoading: state.isSubmittingAction,
                              onPressed: onEdit,
                            ),
                            AppButton.secondary(
                              label: cliente.activo
                                  ? 'Inactivar cliente'
                                  : 'Activar cliente',
                              icon: cliente.activo
                                  ? Icons.block_outlined
                                  : Icons.check_circle_outline,
                              isLoading: state.isSubmittingAction,
                              onPressed: onToggleState,
                            ),
                          ],
                        ),
                        const Gap(AppSpacing.xl),
                        Wrap(
                          spacing: AppSpacing.lg,
                          runSpacing: AppSpacing.lg,
                          children: [
                            _DetailCard(
                              title: 'Identidad',
                              lines: [
                                'ID: ${cliente.id}',
                                'Documento: ${cliente.rucDocumento}',
                                'Razon social: ${cliente.razonSocial}',
                              ],
                            ),
                            _DetailCard(
                              title: 'Contacto',
                              lines: [
                                'Persona: ${cliente.contacto ?? 'Sin contacto'}',
                                'Celular: ${cliente.celular ?? 'Sin celular'}',
                                'Correo: ${cliente.correo ?? 'Sin correo'}',
                              ],
                            ),
                            _DetailCard(
                              title: 'Ubicacion y trazabilidad',
                              lines: [
                                'Direccion: ${cliente.direccion ?? 'Sin direccion'}',
                                'Creado: ${_formatDateTime(cliente.creadoEn)}',
                                'Actualizado: ${_formatOptionalDate(cliente.actualizadoEn)}',
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

class _ClienteListTileCard extends StatelessWidget {
  const _ClienteListTileCard({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final ClienteRecord item;
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
                  Text(item.razonSocial, style: theme.textTheme.titleMedium),
                  _MiniPill(
                    label: item.activo ? 'Activo' : 'Inactivo',
                    background: item.activo
                        ? theme.colorScheme.primaryContainer
                        : theme.colorScheme.surfaceContainerHighest,
                    foreground: item.activo
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              const Gap(AppSpacing.sm),
              Text(
                item.rucDocumento,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
              const Gap(AppSpacing.md),
              Text(
                item.contacto ??
                    item.correo ??
                    'Sin contacto principal registrado.',
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

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.title, required this.lines});

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

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
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
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: foreground),
          ),
        ],
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  const _MiniPill({
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
        style: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(color: foreground),
      ),
    );
  }
}

class _SummaryBadge extends StatelessWidget {
  const _SummaryBadge({required this.label, required this.value});

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

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({required this.child});

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

  return _formatDateTime(value);
}

String _formatDateTime(DateTime value) {
  return DateFormat('dd/MM/yyyy hh:mm a').format(value.toLocal());
}
