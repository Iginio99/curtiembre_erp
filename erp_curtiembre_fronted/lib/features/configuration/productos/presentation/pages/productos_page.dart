import 'package:dio/dio.dart';
import 'package:erp_curtiembre_fronted/core/di/service_locator.dart';
import 'package:flutter/material.dart';

class ProductosPage extends StatefulWidget {
  const ProductosPage({super.key});

  @override
  State<ProductosPage> createState() => _ProductosPageState();
}

class _ProductosPageState extends State<ProductosPage> {
  final _dio = getIt<Dio>();
  List<Map<String, dynamic>> _items = const [];
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final response = await _dio.get<List<dynamic>>('/api/configuracion/productos');
      if (!mounted) return;
      setState(() {
        _items = (response.data ?? const []).map((x) => Map<String, dynamic>.from(x as Map)).toList();
        _loading = false;
      });
    } on DioException catch (_) {
      if (mounted) setState(() { _loading = false; _error = 'No pudimos cargar los productos. Verifica la migración y el backend.'; });
    }
  }

  Future<void> _edit([Map<String, dynamic>? item]) async {
    final input = await showDialog<_ProductoInput>(context: context, builder: (_) => _ProductoDialog(item: item));
    if (input == null) return;
    try {
      final id = item?['id'];
      if (id == null) await _dio.post('/api/configuracion/productos', data: input.toJson());
      else await _dio.put('/api/configuracion/productos/$id', data: input.toJson());
      await _load();
    } on DioException catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo guardar el producto.')));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Productos')),
    floatingActionButton: FloatingActionButton.extended(onPressed: _loading ? null : () => _edit(), icon: const Icon(Icons.add), label: const Text('Nuevo producto')),
    body: _loading ? const Center(child: CircularProgressIndicator()) : _error != null ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Text(_error!), OutlinedButton(onPressed: _load, child: const Text('Reintentar'))])) : _items.isEmpty ? const Center(child: Text('No hay productos registrados.')) : ListView.separated(
      itemCount: _items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, index) {
        final item = _items[index];
        return ListTile(
          title: Text('${item['codigo']} · ${item['nombre']}'),
          subtitle: Text('${item['tipo']}${item['color'] == null ? '' : ' · ${item['color']}'} · ID ${item['id']}'),
          trailing: IconButton(onPressed: () => _edit(item), icon: const Icon(Icons.edit_outlined)),
        );
      },
    ),
  );
}

class _ProductoInput {
  const _ProductoInput(this.codigo, this.tipo, this.nombre, this.color);
  final String codigo, tipo, nombre;
  final String? color;
  Map<String, dynamic> toJson() => {'codigo': codigo, 'tipo': tipo, 'nombre': nombre, 'color': color};
}

class _ProductoDialog extends StatefulWidget {
  const _ProductoDialog({this.item});
  final Map<String, dynamic>? item;
  @override
  State<_ProductoDialog> createState() => _ProductoDialogState();
}

class _ProductoDialogState extends State<_ProductoDialog> {
  final _form = GlobalKey<FormState>();
  late final _codigo = TextEditingController(text: widget.item?['codigo']?.toString() ?? '');
  late final _tipo = TextEditingController(text: widget.item?['tipo']?.toString() ?? '');
  late final _nombre = TextEditingController(text: widget.item?['nombre']?.toString() ?? '');
  late final _color = TextEditingController(text: widget.item?['color']?.toString() ?? '');
  @override
  void dispose() { _codigo.dispose(); _tipo.dispose(); _nombre.dispose(); _color.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.item == null ? 'Nuevo producto' : 'Editar producto'),
    content: SizedBox(width: 420, child: Form(key: _form, child: Column(mainAxisSize: MainAxisSize.min, children: [_field(_codigo, 'Código', true), _field(_tipo, 'Tipo', true), _field(_nombre, 'Nombre', true), _field(_color, 'Color', false)]))),
    actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')), FilledButton(onPressed: () { if (!_form.currentState!.validate()) return; Navigator.pop(context, _ProductoInput(_codigo.text.trim(), _tipo.text.trim(), _nombre.text.trim(), _color.text.trim().isEmpty ? null : _color.text.trim())); }, child: const Text('Guardar'))],
  );
  Widget _field(TextEditingController controller, String label, bool required) => Padding(padding: const EdgeInsets.only(bottom: 12), child: TextFormField(controller: controller, decoration: InputDecoration(labelText: label), validator: required ? (value) => value == null || value.trim().isEmpty ? '$label es obligatorio.' : null : null));
}
