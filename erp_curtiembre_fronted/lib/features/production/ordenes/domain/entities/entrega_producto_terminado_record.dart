class EntregaProductoTerminadoRecord {
  const EntregaProductoTerminadoRecord({
    required this.id,
    required this.codigo,
    required this.fecha,
    required this.clienteNombre,
    required this.productoTerminadoId,
    required this.producto,
    required this.cantidadLados,
    required this.estado,
    this.responsable,
    this.recibidoPor,
    this.observacion,
  });

  final int id;
  final String codigo;
  final DateTime fecha;
  final String clienteNombre;
  final int productoTerminadoId;
  final String producto;
  final double cantidadLados;
  final String estado;
  final String? responsable;
  final String? recibidoPor;
  final String? observacion;

  factory EntregaProductoTerminadoRecord.fromJson(Map<String, dynamic> json) =>
      EntregaProductoTerminadoRecord(
        id: (json['id'] as num).toInt(),
        codigo: json['codigo'] as String? ?? '',
        fecha: DateTime.parse(json['fecha'] as String),
        clienteNombre: json['clienteNombre'] as String? ?? '',
        productoTerminadoId: (json['productoTerminadoId'] as num).toInt(),
        producto: json['producto'] as String? ?? '',
        cantidadLados: (json['cantidadLados'] as num).toDouble(),
        estado: json['estado'] as String? ?? 'CONFIRMADA',
        responsable: json['responsable'] as String?,
        recibidoPor: json['recibidoPor'] as String?,
        observacion: json['observacion'] as String?,
      );
}
