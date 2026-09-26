import 'package:dio/dio.dart';
import 'package:erp_curtiembre_fronted/core/di/service_locator.dart';
import 'package:erp_curtiembre_fronted/core/theme/app_spacing.dart';
import 'package:erp_curtiembre_fronted/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:erp_curtiembre_fronted/features/auth/presentation/cubit/auth_state.dart';
import 'package:erp_curtiembre_fronted/features/security/presentation/cubit/security_access_cubit.dart';
import 'package:erp_curtiembre_fronted/shared/navigation/app_access_routes.dart';
import 'package:erp_curtiembre_fronted/features/production/ordenes/domain/entities/personal_empresa_option.dart';
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
  List<PersonalEmpresaOption> _items = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final response = await _dio.get<List<dynamic>>('/api/produccion/personal');
    if (!mounted) return;
    setState(() {
      _items = (response.data ?? const [])
          .map((e) => PersonalEmpresaOption.fromJson(e as Map<String, dynamic>))
          .toList();
      _loading = false;
    });
  }

  Future<void> _create() async {
    final nombre = TextEditingController();
    final cargo = TextEditingController();
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Registrar personal'),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nombre,
                decoration: const InputDecoration(labelText: 'Nombre completo'),
              ),
              const Gap(AppSpacing.md),
              TextField(
                controller: cargo,
                decoration: const InputDecoration(labelText: 'Cargo'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Registrar'),
          ),
        ],
      ),
    );
    if (accepted != true ||
        nombre.text.trim().isEmpty ||
        cargo.text.trim().isEmpty)
      return;
    await _dio.post(
      '/api/produccion/personal',
      data: {'nombre': nombre.text.trim(), 'cargo': cargo.text.trim()},
    );
    await _load();
  }

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
    if (session == null)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Registra al personal operativo que puede ser responsable de órdenes y procesos.',
                  ),
                ),
                FilledButton.icon(
                  onPressed: _create,
                  icon: const Icon(Icons.add),
                  label: const Text('Nuevo personal'),
                ),
              ],
            ),
            const Gap(AppSpacing.lg),
            Expanded(
              child: Card(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _items.isEmpty
                    ? const Center(
                        child: Text('Todavía no hay personal registrado.'),
                      )
                    : ListView.separated(
                        itemCount: _items.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (_, index) {
                          final item = _items[index];
                          return ListTile(
                            leading: const CircleAvatar(
                              child: Icon(Icons.badge_outlined),
                            ),
                            title: Text(item.nombre),
                            subtitle: Text(item.cargo),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
