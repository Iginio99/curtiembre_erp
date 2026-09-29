import 'package:erp_curtiembre_fronted/core/theme/app_spacing.dart';
import 'package:erp_curtiembre_fronted/features/production/clientes/domain/entities/cliente_record.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

    _rucController = TextEditingController(
      text: initialCliente?.rucDocumento ?? '',
    );

    _razonSocialController = TextEditingController(
      text: initialCliente?.razonSocial ?? '',
    );

    _direccionController = TextEditingController(
      text: initialCliente?.direccion ?? '',
    );

    _celularController = TextEditingController(
      text: initialCliente?.celular ?? '',
    );

    _correoController = TextEditingController(
      text: initialCliente?.correo ?? '',
    );

    _contactoController = TextEditingController(
      text: initialCliente?.contacto ?? '',
    );
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
    final theme = Theme.of(context);

    final isEditing = widget.initialCliente != null;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.antiAlias,

      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),

        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            /*
            ═══════════════════════════════
            HEADER
            ═══════════════════════════════
            */
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),

                        const Gap(4),

                        Text(
                          isEditing
                              ? 'Actualiza la información del cliente.'
                              : 'Registra los datos principales del cliente.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),

                  IconButton(
                    tooltip: 'Cerrar',
                    onPressed: widget.isSubmitting
                        ? null
                        : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),

            Divider(height: 1, color: theme.colorScheme.outlineVariant),

            /*
            ═══════════════════════════════
            FORMULARIO
            ═══════════════════════════════
            */
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 18),

                child: Form(
                  key: _formKey,

                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isDesktop = constraints.maxWidth >= 620;

                      final rucField = TextFormField(
                        controller: _rucController,

                        maxLength: 20,

                        keyboardType: TextInputType.number,

                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],

                        decoration: const InputDecoration(
                          labelText: 'RUC o documento *',

                          hintText: 'Ej. 20601234567',

                          prefixIcon: Icon(Icons.badge_outlined, size: 18),
                        ),

                        validator: (value) {
                          if ((value?.trim() ?? '').isEmpty) {
                            return 'Ingresa el documento.';
                          }

                          return null;
                        },
                      );

                      final razonField = TextFormField(
                        controller: _razonSocialController,

                        maxLength: 180,

                        textCapitalization: TextCapitalization.characters,

                        decoration: const InputDecoration(
                          labelText: 'Razón social *',

                          hintText: 'Ej. Exportadora San Martín S.A.C.',

                          prefixIcon: Icon(Icons.business_outlined, size: 18),
                        ),

                        validator: (value) {
                          if ((value?.trim() ?? '').isEmpty) {
                            return 'Ingresa la razón social.';
                          }

                          return null;
                        },
                      );

                      final contactoField = TextFormField(
                        controller: _contactoController,

                        maxLength: 150,

                        textCapitalization: TextCapitalization.words,

                        decoration: const InputDecoration(
                          labelText: 'Contacto',

                          hintText: 'Ej. Ana Ruiz',

                          prefixIcon: Icon(
                            Icons.person_outline_rounded,
                            size: 18,
                          ),
                        ),
                      );

                      final celularField = TextFormField(
                        controller: _celularController,

                        maxLength: 30,

                        keyboardType: TextInputType.phone,

                        decoration: const InputDecoration(
                          labelText: 'Celular',

                          hintText: 'Ej. 987654321',

                          prefixIcon: Icon(Icons.phone_outlined, size: 18),
                        ),
                      );

                      final correoField = TextFormField(
                        controller: _correoController,

                        maxLength: 150,

                        keyboardType: TextInputType.emailAddress,

                        decoration: const InputDecoration(
                          labelText: 'Correo',

                          hintText: 'Ej. operaciones@cliente.com',

                          prefixIcon: Icon(
                            Icons.mail_outline_rounded,
                            size: 18,
                          ),
                        ),

                        validator: (value) {
                          final text = value?.trim() ?? '';

                          if (text.isEmpty) {
                            return null;
                          }

                          final isValid = RegExp(
                            r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                          ).hasMatch(text);

                          if (!isValid) {
                            return 'Correo inválido.';
                          }

                          return null;
                        },
                      );

                      final direccionField = TextFormField(
                        controller: _direccionController,

                        maxLength: 250,

                        minLines: 1,
                        maxLines: 2,

                        textCapitalization: TextCapitalization.words,

                        decoration: const InputDecoration(
                          labelText: 'Dirección',

                          hintText: 'Ej. Av. Los Talleres 410',

                          prefixIcon: Icon(
                            Icons.location_on_outlined,
                            size: 18,
                          ),
                        ),
                      );

                      /*
                      ═══════════════════════
                      DESKTOP: 2 COLUMNAS
                      ═══════════════════════
                      */

                      if (isDesktop) {
                        return Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: rucField),

                                const Gap(AppSpacing.md),

                                Expanded(child: razonField),
                              ],
                            ),

                            const Gap(AppSpacing.md),

                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: contactoField),

                                const Gap(AppSpacing.md),

                                Expanded(child: celularField),
                              ],
                            ),

                            const Gap(AppSpacing.md),

                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: correoField),

                                const Gap(AppSpacing.md),

                                Expanded(child: direccionField),
                              ],
                            ),
                          ],
                        );
                      }

                      /*
                      ═══════════════════════
                      MOBILE: 1 COLUMNA
                      ═══════════════════════
                      */

                      return Column(
                        children: [
                          rucField,

                          const Gap(AppSpacing.md),

                          razonField,

                          const Gap(AppSpacing.md),

                          contactoField,

                          const Gap(AppSpacing.md),

                          celularField,

                          const Gap(AppSpacing.md),

                          correoField,

                          const Gap(AppSpacing.md),

                          direccionField,
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),

            /*
            ═══════════════════════════════
            FOOTER
            ═══════════════════════════════
            */
            Divider(height: 1, color: theme.colorScheme.outlineVariant),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),

              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: widget.isSubmitting
                        ? null
                        : () => Navigator.of(context).pop(),

                    child: const Text('Cancelar'),
                  ),

                  const Gap(AppSpacing.sm),

                  FilledButton.icon(
                    onPressed: widget.isSubmitting ? null : _submit,

                    icon: widget.isSubmitting
                        ? const SizedBox(
                            width: 15,
                            height: 15,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            isEditing
                                ? Icons.save_outlined
                                : Icons.person_add_alt_1_rounded,

                            size: 17,
                          ),

                    label: Text(widget.submitLabel),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
