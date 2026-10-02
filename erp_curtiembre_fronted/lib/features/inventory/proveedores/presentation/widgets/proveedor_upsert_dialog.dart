import 'package:erp_curtiembre_fronted/features/inventory/proveedores/domain/entities/proveedor_record.dart';

import 'package:flutter/material.dart';

// ============================================================
// COLORES
// ============================================================

const Color _accent = Color(0xFFE8590C);
const Color _accentSoft = Color(0xFFFFE9DC);

// ============================================================
// DATOS DEL FORMULARIO
// ============================================================

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

// ============================================================
// DIALOGO NUEVO / EDITAR PROVEEDOR
// ============================================================

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

  bool get _isEditing => widget.initialProveedor != null;

  // ==========================================================
  // INICIALIZACION
  // ==========================================================

  @override
  void initState() {
    super.initState();

    final proveedor = widget.initialProveedor;

    _rucController = TextEditingController(text: proveedor?.rucDocumento ?? '');

    _razonSocialController = TextEditingController(
      text: proveedor?.razonSocial ?? '',
    );

    _direccionController = TextEditingController(
      text: proveedor?.direccion ?? '',
    );

    _telefonoController = TextEditingController(
      text: proveedor?.telefono ?? '',
    );

    _correoController = TextEditingController(text: proveedor?.correo ?? '');

    _contactoController = TextEditingController(
      text: proveedor?.contacto ?? '',
    );
  }

  // ==========================================================
  // LIBERAR CONTROLADORES
  // ==========================================================

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

  // ==========================================================
  // GUARDAR
  // ==========================================================

  void _submit() {
    if (widget.isSubmitting) return;

    if (!(_formKey.currentState?.validate() ?? false)) {
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

  // ==========================================================
  // VISTA PRINCIPAL
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final screen = MediaQuery.sizeOf(context);

    final compact = screen.width < 850;

    final dialogHeight = (screen.height * 0.90).clamp(320.0, 860.0).toDouble();

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 24,
        vertical: compact ? 12 : 20,
      ),
      backgroundColor: theme.colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: compact ? 600 : 900,
          maxHeight: dialogHeight,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ================================================
            // ENCABEZADO BLANCO / SIN FONDO DE CUERO
            // ================================================
            _buildHeader(context, compact),

            Divider(height: 1, color: theme.colorScheme.outlineVariant),

            // ================================================
            // CONTENIDO DESPLAZABLE
            // ================================================
            Flexible(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(compact ? 14 : 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // INFORMACION GENERAL
                      _buildGeneralSection(context, compact),

                      const SizedBox(height: 15),

                      // INFORMACION DE CONTACTO
                      _buildContactSection(context, compact),

                      const SizedBox(height: 15),

                      // DIRECCION
                      _buildAddressSection(context),
                    ],
                  ),
                ),
              ),
            ),

            // ================================================
            // BOTONES FIJOS
            // ================================================
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // ENCABEZADO
  // ==========================================================

  Widget _buildHeader(BuildContext context, bool compact) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 15 : 23,
        vertical: compact ? 16 : 20,
      ),
      child: Row(
        children: [
          Container(
            height: 49,
            width: 49,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.brightness == Brightness.dark
                  ? _accent.withValues(alpha: 0.16)
                  : _accentSoft,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              _isEditing
                  ? Icons.edit_note_rounded
                  : Icons.local_shipping_outlined,
              color: _accent,
              size: 26,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontSize: compact ? 20 : 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  _isEditing
                      ? 'Actualiza los datos del proveedor.'
                      : 'Registra un nuevo proveedor en el sistema.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 12,
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
            style: IconButton.styleFrom(
              backgroundColor: theme.colorScheme.surfaceContainerLow,
            ),
            icon: const Icon(Icons.close_rounded, size: 21),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // SECCION 1 - INFORMACION GENERAL
  // ==========================================================

  Widget _buildGeneralSection(BuildContext context, bool compact) {
    return _FormSection(
      icon: Icons.business_outlined,
      title: 'Información general',
      subtitle: 'Datos principales del proveedor.',
      child: _responsivePair(
        compact: compact,
        first: _buildRucField(),
        second: _buildRazonSocialField(),
      ),
    );
  }

  // ==========================================================
  // SECCION 2 - INFORMACION DE CONTACTO
  // ==========================================================

  Widget _buildContactSection(BuildContext context, bool compact) {
    return _FormSection(
      icon: Icons.call_outlined,
      title: 'Información de contacto',
      subtitle: 'Datos para la comunicación con el proveedor.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildContactoField(),

          const SizedBox(height: 16),

          _responsivePair(
            compact: compact,
            first: _buildTelefonoField(),
            second: _buildCorreoField(),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // SECCION 3 - DIRECCION
  // ==========================================================

  Widget _buildAddressSection(BuildContext context) {
    return _FormSection(
      icon: Icons.location_on_outlined,
      title: 'Dirección',
      subtitle: 'Ubicación del proveedor.',
      child: _buildDireccionField(),
    );
  }

  // ==========================================================
  // DISTRIBUCION RESPONSIVE
  // ==========================================================

  Widget _responsivePair({
    required bool compact,
    required Widget first,
    required Widget second,
  }) {
    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [first, const SizedBox(height: 16), second],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: first),

        const SizedBox(width: 16),

        Expanded(child: second),
      ],
    );
  }

  // ==========================================================
  // CAMPO RUC
  // ==========================================================

  Widget _buildRucField() {
    return _FieldBlock(
      label: 'RUC o documento',
      requiredField: true,
      child: TextFormField(
        controller: _rucController,
        maxLength: 20,
        textInputAction: TextInputAction.next,
        decoration: _inputDecoration(
          hint: 'Ej. 20600000001',
          icon: Icons.description_outlined,
        ).copyWith(counterText: ''),
        validator: (value) {
          final text = value?.trim() ?? '';

          if (text.isEmpty) {
            return 'Ingresa el documento del proveedor.';
          }

          return null;
        },
      ),
    );
  }

  // ==========================================================
  // CAMPO RAZON SOCIAL
  // ==========================================================

  Widget _buildRazonSocialField() {
    return _FieldBlock(
      label: 'Razón social',
      requiredField: true,
      child: TextFormField(
        controller: _razonSocialController,
        maxLength: 180,
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.next,
        decoration: _inputDecoration(
          hint: 'Nombre o razón social del proveedor',
          icon: Icons.business_rounded,
        ).copyWith(counterText: ''),
        validator: (value) {
          if ((value?.trim() ?? '').isEmpty) {
            return 'Ingresa la razón social.';
          }

          return null;
        },
      ),
    );
  }

  // ==========================================================
  // CAMPO CONTACTO
  // ==========================================================

  Widget _buildContactoField() {
    return _FieldBlock(
      label: 'Persona de contacto',
      child: TextFormField(
        controller: _contactoController,
        maxLength: 150,
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.next,
        decoration: _inputDecoration(
          hint: 'Ej. Juan Pérez',
          icon: Icons.person_outline_rounded,
        ).copyWith(counterText: ''),
      ),
    );
  }

  // ==========================================================
  // CAMPO TELEFONO
  // ==========================================================

  Widget _buildTelefonoField() {
    return _FieldBlock(
      label: 'Teléfono',
      child: TextFormField(
        controller: _telefonoController,
        maxLength: 30,
        keyboardType: TextInputType.phone,
        textInputAction: TextInputAction.next,
        decoration: _inputDecoration(
          hint: 'Ej. 949657719',
          icon: Icons.phone_outlined,
        ).copyWith(counterText: ''),
      ),
    );
  }

  // ==========================================================
  // CAMPO CORREO
  // ==========================================================

  Widget _buildCorreoField() {
    return _FieldBlock(
      label: 'Correo electrónico',
      child: TextFormField(
        controller: _correoController,
        maxLength: 150,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.next,
        decoration: _inputDecoration(
          hint: 'correo@proveedor.com',
          icon: Icons.mail_outline_rounded,
        ).copyWith(counterText: ''),
        validator: (value) {
          final text = value?.trim() ?? '';

          if (text.isEmpty) return null;

          final valid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text);

          if (!valid) {
            return 'Ingresa un correo válido.';
          }

          return null;
        },
      ),
    );
  }

  // ==========================================================
  // CAMPO DIRECCION
  // ==========================================================

  Widget _buildDireccionField() {
    return _FieldBlock(
      label: 'Dirección del proveedor',
      child: TextFormField(
        controller: _direccionController,
        maxLength: 250,
        minLines: 2,
        maxLines: 3,
        textCapitalization: TextCapitalization.sentences,
        keyboardType: TextInputType.streetAddress,
        decoration: _inputDecoration(
          hint: 'Ej. Av. Industrial 123, Trujillo',
          icon: Icons.location_on_outlined,
        ).copyWith(alignLabelWithHint: true, counterText: ''),
      ),
    );
  }

  // ==========================================================
  // DECORACION UNIFICADA DE LOS CAMPOS
  // ==========================================================

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    final colors = Theme.of(context).colorScheme;

    return InputDecoration(
      isDense: true,
      hintText: hint,
      hintStyle: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
      prefixIcon: Icon(icon, size: 19, color: colors.onSurfaceVariant),
      filled: true,
      fillColor: colors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(9)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: BorderSide(color: colors.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(color: _accent, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: BorderSide(color: colors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: BorderSide(color: colors.error, width: 1.5),
      ),
    );
  }

  // ==========================================================
  // PIE FIJO CON BOTONES
  // ==========================================================

  Widget _buildFooter(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.outlineVariant)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(
            onPressed: widget.isSubmitting
                ? null
                : () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 19, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9),
              ),
            ),
            child: const Text('Cancelar'),
          ),

          const SizedBox(width: 12),

          FilledButton.icon(
            onPressed: widget.isSubmitting ? null : _submit,
            icon: widget.isSubmitting
                ? const SizedBox(
                    width: 17,
                    height: 17,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save_outlined, size: 19),
            label: Text(widget.submitLabel),
            style: FilledButton.styleFrom(
              backgroundColor: _accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 21, vertical: 15),
              textStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// TARJETA DE SECCION
// ============================================================

class _FormSection extends StatelessWidget {
  const _FormSection({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 37,
                width: 37,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? _accent.withValues(alpha: 0.16)
                      : _accentSoft,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: _accent, size: 20),
              ),

              const SizedBox(width: 11),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 17),

          child,
        ],
      ),
    );
  }
}

// ============================================================
// ETIQUETA DE CAMPO
// ============================================================

class _FieldBlock extends StatelessWidget {
  const _FieldBlock({
    required this.label,
    required this.child,
    this.requiredField = false,
  });

  final String label;
  final Widget child;
  final bool requiredField;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

            if (requiredField) ...[
              const SizedBox(width: 4),
              const Text(
                '*',
                style: TextStyle(color: _accent, fontWeight: FontWeight.w800),
              ),
            ],
          ],
        ),

        const SizedBox(height: 7),

        child,
      ],
    );
  }
}
