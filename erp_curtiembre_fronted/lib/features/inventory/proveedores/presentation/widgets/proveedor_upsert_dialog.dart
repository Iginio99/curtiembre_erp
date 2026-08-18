import 'package:erp_curtiembre_fronted/core/theme/app_spacing.dart';
import 'package:erp_curtiembre_fronted/features/inventory/proveedores/domain/entities/proveedor_record.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class ProveedorUpsertFormData {
  const ProveedorUpsertFormData({
    required this.rucDocumento,
    required this.razonSocial,
    this.direccion,
    this.telefono,
    this.correo,
    this.contacto,
  });

  final String rucDocumento;
  final String razonSocial;
  final String? direccion;
  final String? telefono;
  final String? correo;
  final String? contacto;
}

class ProveedorUpsertDialog extends StatefulWidget {
  const ProveedorUpsertDialog({
    required this.title,
    required this.submitLabel,
    required this.isSubmitting,
    this.initialProveedor,
    super.key,
  });

  final String title;
  final String submitLabel;
  final bool isSubmitting;
  final ProveedorRecord? initialProveedor;

  @override
  State<ProveedorUpsertDialog> createState() => _ProveedorUpsertDialogState();
}

class _ProveedorUpsertDialogState extends State<ProveedorUpsertDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _rucController;
  late final TextEditingController _razonSocialController;
  late final TextEditingController _direccionController;
  late final TextEditingController _telefonoController;
  late final TextEditingController _correoController;
  late final TextEditingController _contactoController;

  @override
  void initState() {
    super.initState();
    final initialProveedor = widget.initialProveedor;
    _rucController = TextEditingController(text: initialProveedor?.rucDocumento ?? '');
    _razonSocialController =
        TextEditingController(text: initialProveedor?.razonSocial ?? '');
    _direccionController = TextEditingController(text: initialProveedor?.direccion ?? '');
    _telefonoController = TextEditingController(text: initialProveedor?.telefono ?? '');
    _correoController = TextEditingController(text: initialProveedor?.correo ?? '');
    _contactoController = TextEditingController(text: initialProveedor?.contacto ?? '');
  }

  @override
  void dispose() {
    _rucController.dispose();
    _razonSocialController.dispose();
    _direccionController.dispose();
    _telefonoController.dispose();
    _correoController.dispose();
    _contactoController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.of(context).pop(
      ProveedorUpsertFormData(
        rucDocumento: _rucController.text.trim(),
        razonSocial: _razonSocialController.text.trim(),
        direccion: _normalizeOptional(_direccionController.text),
        telefono: _normalizeOptional(_telefonoController.text),
        correo: _normalizeOptional(_correoController.text),
        contacto: _normalizeOptional(_contactoController.text),
      ),
    );
  }

  String? _normalizeOptional(String value) {
    final normalized = value.trim();
    return normalized.isEmpty ? null : normalized;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _rucController,
                  maxLength: 20,
                  decoration: const InputDecoration(
                    labelText: 'RUC o documento',
                    hintText: 'Ej. 20123456789',
                  ),
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.isEmpty) {
                      return 'Ingresa el documento del proveedor.';
                    }
                    return null;
                  },
                ),
                const Gap(AppSpacing.md),
                TextFormField(
                  controller: _razonSocialController,
                  maxLength: 180,
                  decoration: const InputDecoration(
                    labelText: 'Razon social',
                    hintText: 'Ej. Quimicos Andinos SAC',
                  ),
                  validator: (value) {
                    if ((value?.trim() ?? '').isEmpty) {
                      return 'Ingresa la razon social.';
                    }
                    return null;
                  },
                ),
                const Gap(AppSpacing.md),
                TextFormField(
                  controller: _contactoController,
                  maxLength: 150,
                  decoration: const InputDecoration(
                    labelText: 'Contacto',
                    hintText: 'Ej. Juan Perez',
                  ),
                ),
                const Gap(AppSpacing.md),
                TextFormField(
                  controller: _telefonoController,
                  maxLength: 30,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Telefono',
                    hintText: 'Ej. 999999999',
                  ),
                ),
                const Gap(AppSpacing.md),
                TextFormField(
                  controller: _correoController,
                  maxLength: 150,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Correo',
                    hintText: 'Ej. compras@proveedor.com',
                  ),
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.isEmpty) {
                      return null;
                    }

                    final isValid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text);
                    if (!isValid) {
                      return 'Ingresa un correo valido.';
                    }

                    return null;
                  },
                ),
                const Gap(AppSpacing.md),
                TextFormField(
                  controller: _direccionController,
                  maxLength: 250,
                  minLines: 2,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Direccion',
                    hintText: 'Ej. Av. Industrial 123',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: widget.isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: widget.isSubmitting ? null : _submit,
          icon: widget.isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_outlined),
          label: Text(widget.submitLabel),
        ),
      ],
    );
  }
}
