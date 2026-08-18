import 'package:erp_curtiembre_fronted/core/theme/app_spacing.dart';
import 'package:erp_curtiembre_fronted/features/production/clientes/domain/entities/cliente_record.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class ClienteUpsertFormData {
  const ClienteUpsertFormData({
    required this.rucDocumento,
    required this.razonSocial,
    this.direccion,
    this.celular,
    this.correo,
    this.contacto,
  });

  final String rucDocumento;
  final String razonSocial;
  final String? direccion;
  final String? celular;
  final String? correo;
  final String? contacto;
}

class ClienteUpsertDialog extends StatefulWidget {
  const ClienteUpsertDialog({
    required this.title,
    required this.submitLabel,
    required this.isSubmitting,
    this.initialCliente,
    super.key,
  });

  final String title;
  final String submitLabel;
  final bool isSubmitting;
  final ClienteRecord? initialCliente;

  @override
  State<ClienteUpsertDialog> createState() => _ClienteUpsertDialogState();
}

class _ClienteUpsertDialogState extends State<ClienteUpsertDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _rucController;
  late final TextEditingController _razonSocialController;
  late final TextEditingController _direccionController;
  late final TextEditingController _celularController;
  late final TextEditingController _correoController;
  late final TextEditingController _contactoController;

  @override
  void initState() {
    super.initState();
    final initialCliente = widget.initialCliente;
    _rucController = TextEditingController(text: initialCliente?.rucDocumento ?? '');
    _razonSocialController = TextEditingController(text: initialCliente?.razonSocial ?? '');
    _direccionController = TextEditingController(text: initialCliente?.direccion ?? '');
    _celularController = TextEditingController(text: initialCliente?.celular ?? '');
    _correoController = TextEditingController(text: initialCliente?.correo ?? '');
    _contactoController = TextEditingController(text: initialCliente?.contacto ?? '');
  }

  @override
  void dispose() {
    _rucController.dispose();
    _razonSocialController.dispose();
    _direccionController.dispose();
    _celularController.dispose();
    _correoController.dispose();
    _contactoController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.of(context).pop(
      ClienteUpsertFormData(
        rucDocumento: _rucController.text.trim(),
        razonSocial: _razonSocialController.text.trim(),
        direccion: _normalizeOptional(_direccionController.text),
        celular: _normalizeOptional(_celularController.text),
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
                    hintText: 'Ej. 20601234567',
                  ),
                  validator: (value) {
                    if ((value?.trim() ?? '').isEmpty) {
                      return 'Ingresa el documento del cliente.';
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
                    hintText: 'Ej. Exportadora San Martin SAC',
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
                    hintText: 'Ej. Ana Ruiz',
                  ),
                ),
                const Gap(AppSpacing.md),
                TextFormField(
                  controller: _celularController,
                  maxLength: 30,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Celular',
                    hintText: 'Ej. 987654321',
                  ),
                ),
                const Gap(AppSpacing.md),
                TextFormField(
                  controller: _correoController,
                  maxLength: 150,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Correo',
                    hintText: 'Ej. operaciones@cliente.com',
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
                    hintText: 'Ej. Av. Los Talleres 410',
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
