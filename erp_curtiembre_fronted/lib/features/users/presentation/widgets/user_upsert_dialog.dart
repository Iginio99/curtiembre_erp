import 'package:erp_curtiembre_fronted/core/theme/app_spacing.dart';
import 'package:erp_curtiembre_fronted/features/security/domain/entities/security_role.dart';
import 'package:erp_curtiembre_fronted/features/users/domain/entities/user_area_option.dart';
import 'package:erp_curtiembre_fronted/features/users/domain/entities/user_detail.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class UserUpsertFormData {
  const UserUpsertFormData({
    required this.dni,
    required this.nombres,
    required this.apellidos,
    required this.userName,
    required this.rolId,
    required this.areaId,
    this.passwordTemporal,
  });

  final String dni;
  final String nombres;
  final String apellidos;
  final String userName;
  final int rolId;
  final int areaId;
  final String? passwordTemporal;
}

class UserUpsertDialog extends StatefulWidget {
  const UserUpsertDialog({
    required this.title,
    required this.submitLabel,
    required this.roles,
    required this.areas,
    required this.isSubmitting,
    this.initialUser,
    super.key,
  });

  final String title;
  final String submitLabel;
  final List<SecurityRole> roles;
  final List<UserAreaOption> areas;
  final bool isSubmitting;
  final UserDetail? initialUser;

  bool get isEditMode => initialUser != null;

  @override
  State<UserUpsertDialog> createState() => _UserUpsertDialogState();
}

class _UserUpsertDialogState extends State<UserUpsertDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _dniController;
  late final TextEditingController _nombresController;
  late final TextEditingController _apellidosController;
  late final TextEditingController _userNameController;
  late final TextEditingController _passwordTemporalController;
  late int? _selectedRolId;
  late int? _selectedAreaId;

  @override
  void initState() {
    super.initState();
    final initialUser = widget.initialUser;
    _dniController = TextEditingController(text: initialUser?.dni ?? '');
    _nombresController = TextEditingController(text: initialUser?.nombres ?? '');
    _apellidosController = TextEditingController(text: initialUser?.apellidos ?? '');
    _userNameController = TextEditingController(text: initialUser?.userName ?? '');
    _passwordTemporalController = TextEditingController();
    _selectedRolId = initialUser?.rolId ?? _firstRoleId;
    _selectedAreaId = initialUser?.areaId ?? _firstAreaId;
  }

  int? get _firstRoleId => widget.roles.isEmpty ? null : widget.roles.first.id;

  int? get _firstAreaId => widget.areas.isEmpty ? null : widget.areas.first.id;

  @override
  void dispose() {
    _dniController.dispose();
    _nombresController.dispose();
    _apellidosController.dispose();
    _userNameController.dispose();
    _passwordTemporalController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final rolId = _selectedRolId;
    final areaId = _selectedAreaId;
    if (rolId == null || areaId == null) {
      return;
    }

    Navigator.of(context).pop(
      UserUpsertFormData(
        dni: _dniController.text.trim(),
        nombres: _nombresController.text.trim(),
        apellidos: _apellidosController.text.trim(),
        userName: _userNameController.text.trim(),
        rolId: rolId,
        areaId: areaId,
        passwordTemporal: widget.isEditMode
            ? null
            : _passwordTemporalController.text.trim().isEmpty
                ? null
                : _passwordTemporalController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canSubmit = !widget.isSubmitting &&
        widget.roles.isNotEmpty &&
        widget.areas.isNotEmpty;

    return Dialog(
      insetPadding: const EdgeInsets.all(AppSpacing.xl),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(widget.title, style: theme.textTheme.headlineSmall),
                  const Gap(AppSpacing.sm),
                  Text(
                    widget.isEditMode
                        ? 'Actualiza la identidad, rol y area operativa del usuario.'
                        : 'Registra un nuevo usuario y define su acceso inicial al sistema.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Gap(AppSpacing.xl),
                  TextFormField(
                    controller: _dniController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'DNI',
                      hintText: 'Ej. 87654321',
                    ),
                    validator: (value) {
                      final text = value?.trim() ?? '';
                      if (text.isEmpty) {
                        return 'Ingresa el DNI del usuario.';
                      }
                      if (text.length < 8) {
                        return 'El DNI debe tener al menos 8 caracteres.';
                      }
                      return null;
                    },
                  ),
                  const Gap(AppSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _nombresController,
                          decoration: const InputDecoration(
                            labelText: 'Nombres',
                          ),
                          validator: (value) {
                            final text = value?.trim() ?? '';
                            if (text.isEmpty) {
                              return 'Ingresa los nombres.';
                            }
                            return null;
                          },
                        ),
                      ),
                      const Gap(AppSpacing.lg),
                      Expanded(
                        child: TextFormField(
                          controller: _apellidosController,
                          decoration: const InputDecoration(
                            labelText: 'Apellidos',
                          ),
                          validator: (value) {
                            final text = value?.trim() ?? '';
                            if (text.isEmpty) {
                              return 'Ingresa los apellidos.';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const Gap(AppSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _userNameController,
                          decoration: const InputDecoration(
                            labelText: 'Usuario',
                            hintText: 'Ej. nuevo.admin',
                          ),
                          validator: (value) {
                            final text = value?.trim() ?? '';
                            if (text.isEmpty) {
                              return 'Ingresa el usuario.';
                            }
                            if (text.length < 3) {
                              return 'Ingresa un usuario valido.';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const Gap(AppSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          initialValue: _selectedRolId,
                          decoration: const InputDecoration(labelText: 'Rol'),
                          items: widget.roles
                              .where((role) => role.activo)
                              .map(
                                (role) => DropdownMenuItem<int>(
                                  value: role.id,
                                  child: Text(role.nombre),
                                ),
                              )
                              .toList(growable: false),
                          onChanged: widget.isSubmitting
                              ? null
                              : (value) => setState(() => _selectedRolId = value),
                          validator: (value) =>
                              value == null ? 'Selecciona un rol.' : null,
                        ),
                      ),
                      const Gap(AppSpacing.lg),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          initialValue: _selectedAreaId,
                          decoration: const InputDecoration(labelText: 'Area'),
                          items: widget.areas
                              .map(
                                (area) => DropdownMenuItem<int>(
                                  value: area.id,
                                  child: Text(area.nombre),
                                ),
                              )
                              .toList(growable: false),
                          onChanged: widget.isSubmitting
                              ? null
                              : (value) => setState(() => _selectedAreaId = value),
                          validator: (value) =>
                              value == null ? 'Selecciona un area.' : null,
                        ),
                      ),
                    ],
                  ),
                  if (!widget.isEditMode) ...[
                    const Gap(AppSpacing.lg),
                    TextFormField(
                      controller: _passwordTemporalController,
                      decoration: const InputDecoration(
                        labelText: 'Password temporal',
                        hintText: 'Dejalo vacio para generar una automaticamente',
                      ),
                      validator: (value) {
                        final text = value?.trim() ?? '';
                        if (text.isEmpty) {
                          return null;
                        }
                        if (text.length < 8) {
                          return 'La clave temporal debe tener al menos 8 caracteres.';
                        }
                        return null;
                      },
                    ),
                  ],
                  const Gap(AppSpacing.xl),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: widget.isSubmitting
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: const Text('Cancelar'),
                      ),
                      const Gap(AppSpacing.md),
                      FilledButton.icon(
                        onPressed: canSubmit ? _submit : null,
                        icon: widget.isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.check_circle_outline),
                        label: Text(widget.submitLabel),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
