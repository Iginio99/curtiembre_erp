import 'package:flutter/material.dart';

class OrdenCompraDecisionDialogResult {
  const OrdenCompraDecisionDialogResult({required this.motivo});

  final String motivo;
}

class OrdenCompraDecisionDialog extends StatefulWidget {
  const OrdenCompraDecisionDialog({
    required this.title,
    required this.submitLabel,
    required this.helperText,
    required this.isSubmitting,
    super.key,
  });

  final String title;
  final String submitLabel;
  final String helperText;
  final bool isSubmitting;

  @override
  State<OrdenCompraDecisionDialog> createState() => _OrdenCompraDecisionDialogState();
}

class _OrdenCompraDecisionDialogState extends State<OrdenCompraDecisionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _motivoController = TextEditingController();

  @override
  void dispose() {
    _motivoController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      OrdenCompraDecisionDialogResult(
        motivo: _motivoController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.helperText),
            const SizedBox(height: 16),
            TextFormField(
              controller: _motivoController,
              maxLength: 500,
              minLines: 3,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Motivo',
              ),
              validator: (value) {
                if ((value?.trim() ?? '').isEmpty) {
                  return 'Ingresa el motivo de la decision.';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: widget.isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: widget.isSubmitting ? null : _submit,
          child: Text(widget.submitLabel),
        ),
      ],
    );
  }
}
