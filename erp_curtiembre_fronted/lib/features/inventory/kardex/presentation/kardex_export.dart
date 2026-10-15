import 'package:erp_curtiembre_fronted/features/inventory/kardex/domain/entities/kardex_record.dart';
import 'package:erp_curtiembre_fronted/features/inventory/shared/domain/entities/insumo_lookup.dart';
import 'package:erp_curtiembre_fronted/features/inventory/stock/domain/entities/stock_record.dart';
import 'package:erp_curtiembre_fronted/features/inventory/kardex/presentation/kardex_export_stub.dart'
    if (dart.library.html) 'kardex_export_web.dart'
    as download;
import 'package:intl/intl.dart';

void exportKardex(
  InsumoLookup insumo,
  StockRecord? stock,
  List<KardexRecord> rows,
  DateTime? from,
  DateTime? to, {
  required double opening,
  required double entries,
  required double exits,
  required double closing,
}) {
  final date = DateFormat('dd/MM/yyyy');
  final dateTime = DateFormat('dd/MM/yyyy HH:mm');
  final csvRows = <List<Object?>>[
    ['KARDEX POR INSUMO'],
    ['Código', insumo.codigo, 'Insumo', insumo.nombre],
    ['Categoría', insumo.tipoBien, 'Unidad', insumo.unidadMedidaCodigo],
    [
      'Stock actual',
      stock?.cantidadActual ?? insumo.stockActual,
      'Costo promedio',
      stock?.costoPromedioActual ?? '',
    ],
    [
      'Valor del stock',
      stock == null ? '' : stock.cantidadActual * stock.costoPromedioActual,
    ],
    [
      'Desde',
      from == null ? 'Todas' : date.format(from),
      'Hasta',
      to == null ? 'Todas' : date.format(to),
    ],
    [],
    [
      'Insumo',
      'Fecha y hora',
      'Movimiento',
      'Documento',
      'ID documento',
      'Entrada',
      'Salida',
      'Stock',
      'Costo unitario',
      'Costo total',
      'Responsable',
      'ID responsable',
      'Observación',
    ],
    ...rows.map(
      (row) => [
        '${row.insumoCodigo} - ${row.insumoNombre}',
        dateTime.format(row.fechaMovimiento),
        row.tipoMovimiento,
        row.documentoTipo ?? '',
        row.documentoId ?? '',
        row.entrada,
        row.salida,
        row.stockActual,
        row.costoUnitario,
        row.costoTotal,
        row.usuarioResponsable ?? '',
        row.usuarioResponsableId ?? '',
        row.observacion ?? '',
      ],
    ),
    [],
    ['Saldo anterior', opening, insumo.unidadMedidaCodigo],
    ['Total entradas', entries, insumo.unidadMedidaCodigo],
    ['Total salidas', exits, insumo.unidadMedidaCodigo],
    ['Saldo final', closing, insumo.unidadMedidaCodigo],
    ['Diferencia de conciliación', opening + entries - exits - closing],
  ];
  final csv =
      '\uFEFF${csvRows.map((row) => row.map(_csvCell).join(';')).join('\r\n')}';
  download.downloadKardexCsv(
    csv,
    'kardex_${insumo.codigo}_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv',
  );
}

String _csvCell(Object? value) {
  final text = value?.toString() ?? '';
  // Quoted text also prevents formulas in user-supplied observations.
  final trimmed = text.trimLeft();
  final safe =
      value is String &&
          (trimmed.startsWith('=') ||
              trimmed.startsWith('+') ||
              trimmed.startsWith('-') ||
              trimmed.startsWith('@'))
      ? "'$text"
      : text;
  return '"${safe.replaceAll('"', '""')}"';
}
