import 'package:dio/dio.dart';
import 'package:erp_curtiembre_fronted/core/di/service_locator.dart';
import 'package:erp_curtiembre_fronted/core/theme/app_spacing.dart';
import 'package:erp_curtiembre_fronted/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:erp_curtiembre_fronted/features/auth/presentation/cubit/auth_state.dart';
import 'package:erp_curtiembre_fronted/features/production/ordenes/domain/entities/personal_empresa_option.dart';
import 'package:erp_curtiembre_fronted/features/security/presentation/cubit/security_access_cubit.dart';
import 'package:erp_curtiembre_fronted/shared/navigation/app_access_routes.dart';
import 'package:erp_curtiembre_fronted/shared/widgets/layout/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';

class PersonalEmpresaPage extends StatefulWidget {
  const PersonalEmpresaPage({super.key});

  @override
  State<PersonalEmpresaPage> createState() => _PersonalEmpresaPageState();
}

class _PersonalEmpresaPageState extends State<PersonalEmpresaPage> {
  final Dio _dio = getIt<Dio>();

  final TextEditingController _searchController = TextEditingController();

  List<PersonalEmpresaOption> _items = const [];

  bool _loading = true;

  // ===========================================================================
  // INIT / DISPOSE
  // ===========================================================================

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ===========================================================================
  // CARGAR PERSONAL
  // ===========================================================================

  Future<void> _load() async {
    if (mounted) {
      setState(() => _loading = true);
    }

    try {
      final response = await _dio.get<List<dynamic>>(
        '/api/produccion/personal',
      );

      if (!mounted) return;

      setState(() {
        _items = (response.data ?? const [])
            .map(
              (e) => PersonalEmpresaOption.fromJson(e as Map<String, dynamic>),
            )
            .toList();

        _loading = false;
      });
    } on DioException catch (e) {
      if (!mounted) return;

      setState(() => _loading = false);

      _showMessage(
        _extractErrorMessage(e, fallback: 'No se pudo cargar el personal.'),
        error: true,
      );
    } catch (_) {
      if (!mounted) return;

      setState(() => _loading = false);

      _showMessage('No se pudo cargar el personal.', error: true);
    }
  }

  // ===========================================================================
  // REGISTRAR PERSONAL
  // ===========================================================================

  Future<void> _create() async {
    final nombreController = TextEditingController();
    final cargoController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.62),
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        final colors = theme.colorScheme;

        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Material(
              color: colors.surface,
              borderRadius: BorderRadius.circular(22),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  // =========================================================
                  // DECORACIÓN
                  // =========================================================
                  Positioned(
                    top: -90,
                    right: -70,
                    child: IgnorePointer(
                      child: Container(
                        width: 210,
                        height: 210,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colors.primary.withValues(alpha: 0.07),
                        ),
                      ),
                    ),
                  ),

                  Positioned(
                    top: -45,
                    right: 30,
                    child: IgnorePointer(
                      child: Container(
                        width: 125,
                        height: 125,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colors.primary.withValues(alpha: 0.05),
                        ),
                      ),
                    ),
                  ),

                  // =========================================================
                  // CONTENIDO
                  // =========================================================
                  Padding(
                    padding: const EdgeInsets.fromLTRB(36, 32, 36, 28),
                    child: Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // =================================================
                          // HEADER
                          // =================================================
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: colors.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Icon(
                                  Icons.person_add_alt_1_rounded,
                                  size: 34,
                                  color: colors.primary,
                                ),
                              ),

                              const Gap(20),

                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 5),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Registrar personal',
                                        style: theme.textTheme.headlineSmall
                                            ?.copyWith(
                                              fontSize: 28,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: -0.5,
                                            ),
                                      ),

                                      const Gap(6),

                                      Text(
                                        'Agrega los datos básicos del trabajador.',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              fontSize: 15,
                                              color: colors.onSurfaceVariant,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const Gap(12),

                              Container(
                                decoration: BoxDecoration(
                                  color: colors.surfaceContainerHighest,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: colors.outlineVariant,
                                  ),
                                ),
                                child: IconButton(
                                  tooltip: 'Cerrar',
                                  onPressed: () {
                                    Navigator.pop(dialogContext);
                                  },
                                  icon: const Icon(Icons.close_rounded),
                                ),
                              ),
                            ],
                          ),

                          const Gap(30),

                          // =================================================
                          // NOMBRE
                          // =================================================
                          Row(
                            children: [
                              Text(
                                'Nombre completo',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const Gap(4),
                              Text(
                                '*',
                                style: TextStyle(
                                  color: colors.error,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),

                          const Gap(9),

                          TextFormField(
                            controller: nombreController,
                            autofocus: true,
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.next,
                            decoration: _modalInputDecoration(
                              context: dialogContext,
                              hintText: 'Ingresa el nombre completo',
                              icon: Icons.person_outline_rounded,
                            ),
                            validator: (value) {
                              final text = value?.trim() ?? '';

                              if (text.isEmpty) {
                                return 'Ingresa el nombre completo.';
                              }

                              if (text.length < 3) {
                                return 'El nombre es demasiado corto.';
                              }

                              return null;
                            },
                          ),

                          const Gap(22),

                          // =================================================
                          // CARGO
                          // =================================================
                          Row(
                            children: [
                              Text(
                                'Cargo',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const Gap(4),
                              Text(
                                '*',
                                style: TextStyle(
                                  color: colors.error,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),

                          const Gap(9),

                          TextFormField(
                            controller: cargoController,
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.done,
                            decoration: _modalInputDecoration(
                              context: dialogContext,
                              hintText: 'Ingresa el cargo',
                              icon: Icons.work_outline_rounded,
                            ),
                            validator: (value) {
                              final text = value?.trim() ?? '';

                              if (text.isEmpty) {
                                return 'Ingresa el cargo.';
                              }

                              return null;
                            },
                            onFieldSubmitted: (_) {
                              if (!(formKey.currentState?.validate() ??
                                  false)) {
                                return;
                              }

                              Navigator.pop(dialogContext, {
                                'nombre': nombreController.text.trim(),
                                'cargo': cargoController.text.trim(),
                              });
                            },
                          ),

                          const Gap(30),

                          Divider(height: 1, color: colors.outlineVariant),

                          const Gap(20),

                          // =================================================
                          // BOTONES
                          // =================================================
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(dialogContext);
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: colors.primary,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 14,
                                  ),
                                ),
                                child: const Text(
                                  'Cancelar',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                              ),

                              const Gap(12),

                              FilledButton.icon(
                                onPressed: () {
                                  if (!(formKey.currentState?.validate() ??
                                      false)) {
                                    return;
                                  }

                                  Navigator.pop(dialogContext, {
                                    'nombre': nombreController.text.trim(),
                                    'cargo': cargoController.text.trim(),
                                  });
                                },
                                icon: const Icon(Icons.add_rounded, size: 20),
                                label: const Text(
                                  'Registrar',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                                style: FilledButton.styleFrom(
                                  backgroundColor: colors.primary,
                                  foregroundColor: colors.onPrimary,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(11),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    final nombre = result?['nombre'];
    final cargo = result?['cargo'];

    if (nombre == null || cargo == null) {
      nombreController.dispose();
      cargoController.dispose();
      return;
    }

    try {
      await _dio.post(
        '/api/produccion/personal',
        data: {'nombre': nombre, 'cargo': cargo},
      );

      await _load();

      if (!mounted) return;

      _showMessage('Personal registrado correctamente.');
    } on DioException catch (e) {
      if (!mounted) return;

      _showMessage(
        _extractErrorMessage(e, fallback: 'No se pudo registrar el personal.'),
        error: true,
      );
    } catch (_) {
      if (!mounted) return;

      _showMessage('No se pudo registrar el personal.', error: true);
    } finally {
      nombreController.dispose();
      cargoController.dispose();
    }
  }

  // ===========================================================================
  // FILTRADO
  // ===========================================================================

  List<PersonalEmpresaOption> get _filteredItems {
    final search = _searchController.text.trim().toLowerCase();

    if (search.isEmpty) {
      return _items;
    }

    return _items.where((item) {
      final nombre = item.nombre.toLowerCase();
      final cargo = item.cargo.toLowerCase();

      return nombre.contains(search) || cargo.contains(search);
    }).toList();
  }

  // ===========================================================================
  // MENSAJES
  // ===========================================================================

  void _showMessage(String message, {bool error = false}) {
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);

    messenger.hideCurrentSnackBar();

    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: error ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }

  String _extractErrorMessage(
    DioException exception, {
    required String fallback,
  }) {
    final data = exception.response?.data;

    if (data is Map<String, dynamic>) {
      final message = data['message'] ?? data['mensaje'] ?? data['error'];

      if (message is String && message.trim().isNotEmpty) {
        return message;
      }
    }

    if (data is String && data.trim().isNotEmpty) {
      return data;
    }

    return fallback;
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final session = context.select((AuthCubit cubit) => cubit.state.session);

    final isSigningOut = context.select(
      (AuthCubit cubit) => cubit.state.status == AuthStatus.signingOut,
    );

    final permissions = context.select(
      (SecurityAccessCubit cubit) =>
          cubit.state.snapshot?.userPermissionCodes.toSet() ?? const <String>{},
    );

    if (session == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final filteredItems = _filteredItems;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return AppShell(
      title: 'Personal de empresa',
      currentPath: '/produccion/personal',
      userName: session.nombreCompleto,
      roleName: session.rolNombre,
      accessibleRoutes: AppAccessRoutes.forPermissions(permissions),
      onSignOut: isSigningOut
          ? () {}
          : () => context.read<AuthCubit>().signOut(),
      breadcrumbs: const ['Inicio', 'Producción', 'Personal'],
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ===============================================================
            // DESCRIPCIÓN
            // ===============================================================
            Text(
              'Registra al personal operativo que puede ser responsable de órdenes y procesos.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),

            const Gap(AppSpacing.lg),

            // ===============================================================
            // BUSCADOR Y BOTÓN
            // ===============================================================
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 720;

                final searchField = TextField(
                  controller: _searchController,
                  onChanged: (_) {
                    setState(() {});
                  },
                  decoration: InputDecoration(
                    hintText: 'Buscar por nombre o cargo...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    filled: true,
                    fillColor: colors.surfaceContainerLowest,
                  ),
                );

                final createButton = FilledButton.icon(
                  onPressed: _create,
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: const Text('Nuevo personal'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                );

                if (compact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      searchField,
                      const Gap(AppSpacing.md),
                      createButton,
                    ],
                  );
                }

                return Row(
                  children: [
                    SizedBox(width: 390, child: searchField),
                    const Spacer(),
                    createButton,
                  ],
                );
              },
            ),

            const Gap(AppSpacing.lg),

            // ===============================================================
            // LISTADO
            // ===============================================================
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: colors.outlineVariant),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    // =======================================================
                    // CABECERA
                    // =======================================================
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 18,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Listado de personal',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),

                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: colors.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '${filteredItems.length} registros',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colors.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    Divider(height: 1, color: colors.outlineVariant),

                    // =======================================================
                    // HEADER TABLA
                    // =======================================================
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      color: colors.surfaceContainerLow,
                      child: const Row(
                        children: [
                          SizedBox(
                            width: 45,
                            child: Text(
                              '#',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),

                          Expanded(
                            flex: 5,
                            child: Text(
                              'Nombre completo',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),

                          Expanded(
                            flex: 3,
                            child: Text(
                              'Cargo',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),

                          SizedBox(
                            width: 110,
                            child: Text(
                              'Acciones',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    ),

                    Divider(height: 1, color: colors.outlineVariant),

                    // =======================================================
                    // FILAS
                    // =======================================================
                    Expanded(
                      child: _loading
                          ? const Center(child: CircularProgressIndicator())
                          : filteredItems.isEmpty
                          ? _EmptyPersonalState(
                              hasSearch: _searchController.text
                                  .trim()
                                  .isNotEmpty,
                            )
                          : ListView.separated(
                              itemCount: filteredItems.length,
                              separatorBuilder: (_, _) => Divider(
                                height: 1,
                                color: colors.outlineVariant,
                              ),
                              itemBuilder: (context, index) {
                                final item = filteredItems[index];

                                return _PersonalRow(
                                  number: index + 1,
                                  item: item,
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// FILA DE PERSONAL
// =============================================================================

class _PersonalRow extends StatelessWidget {
  const _PersonalRow({required this.number, required this.item});

  final int number;
  final PersonalEmpresaOption item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final cleanName = item.nombre.trim();

    final initial = cleanName.isNotEmpty
        ? cleanName.substring(0, 1).toUpperCase()
        : '?';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
      child: Row(
        children: [
          SizedBox(
            width: 45,
            child: Text(
              '$number',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ),

          Expanded(
            flex: 5,
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    initial,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),

                const Gap(AppSpacing.md),

                Expanded(
                  child: Text(
                    item.nombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            flex: 3,
            child: Text(
              item.cargo,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ),

          SizedBox(
            width: 110,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  tooltip: 'Editar - endpoint pendiente',
                  onPressed: null,
                  icon: const Icon(Icons.edit_outlined, size: 19),
                ),

                IconButton(
                  tooltip: 'Eliminar - endpoint pendiente',
                  onPressed: null,
                  icon: const Icon(Icons.delete_outline_rounded, size: 19),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// ESTADO VACÍO
// =============================================================================

class _EmptyPersonalState extends StatelessWidget {
  const _EmptyPersonalState({required this.hasSearch});

  final bool hasSearch;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(
                hasSearch ? Icons.search_off_rounded : Icons.badge_outlined,
                color: colors.primary,
                size: 30,
              ),
            ),

            const Gap(AppSpacing.md),

            Text(
              hasSearch ? 'Sin resultados' : 'Todavía no hay personal',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),

            const Gap(AppSpacing.xs),

            Text(
              hasSearch
                  ? 'No encontramos personal que coincida con la búsqueda.'
                  : 'Registra al primer trabajador para comenzar.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// DECORACIÓN DE INPUTS DEL MODAL
// =============================================================================

InputDecoration _modalInputDecoration({
  required BuildContext context,
  required String hintText,
  required IconData icon,
}) {
  final colors = Theme.of(context).colorScheme;

  return InputDecoration(
    hintText: hintText,
    prefixIcon: Icon(icon, color: colors.onSurfaceVariant, size: 21),
    filled: true,
    fillColor: colors.surfaceContainerLowest,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: colors.outlineVariant),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: colors.outlineVariant),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: colors.primary, width: 1.6),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: colors.error),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: colors.error, width: 1.6),
    ),
  );
}
