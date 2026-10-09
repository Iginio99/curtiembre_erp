import 'dart:typed_data';
import 'dart:html' as html;

import 'package:erp_curtiembre_fronted/features/production/reportes/domain/entities/consumo_proceso_reporte_item.dart';
import 'package:erp_curtiembre_fronted/features/production/reportes/domain/entities/costo_orden_reporte_item.dart';
import 'package:erp_curtiembre_fronted/features/production/reportes/domain/entities/costo_proceso_reporte_item.dart';
import 'package:erp_curtiembre_fronted/features/production/reportes/domain/entities/orden_activa_reporte_item.dart';
import 'package:erp_curtiembre_fronted/features/production/reportes/domain/entities/orden_cliente_reporte_item.dart';
import 'package:erp_curtiembre_fronted/features/production/ordenes/domain/entities/orden_proceso_record.dart';
import 'package:erp_curtiembre_fronted/features/production/ordenes/domain/entities/orden_producto_record.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class ProductionReportPdfService {
  static final _date = DateFormat('dd/MM/yyyy');
  static final _money = NumberFormat.currency(locale: 'es_PE', symbol: 'S/ ');
  static const _orange = PdfColor.fromInt(0xFFE8590C);
  static const _charcoal = PdfColor.fromInt(0xFF343437);

  static Future<void> printActiveOrder(
    BuildContext context,
    OrdenActivaReporteItem order,
    List<OrdenProcesoRecord> processes,
    List<OrdenProductoRecord> products,
  ) {
    return _print(
      context,
      '${order.codigoOrden}_orden_activa.pdf',
      title: 'Ficha de orden activa',
      code: order.codigoOrden,
      summary: [
        ('Cliente', order.cliente),
        ('Lote', order.codigoLote),
        ('Estado', order.estado),
        ('Responsable', order.responsable ?? 'Sin responsable'),
        ('Inicio', _optionalDate(order.fechaInicioReal)),
        ('Fin estimado', _date.format(order.fechaFinEstimada)),
      ],
      sections: const [],
      processes: processes,
      orderProducts: products,
    );
  }

  static Future<void> printClientOrder(
    BuildContext context,
    OrdenClienteReporteItem order,
    List<OrdenProcesoRecord> processes,
    List<OrdenProductoRecord> products,
  ) {
    return _print(
      context,
      '${order.codigoOrden}_orden_cliente.pdf',
      title: 'Ficha de orden de produccion',
      code: order.codigoOrden,
      summary: [
        ('Cliente', order.cliente),
        ('Lote', order.codigoLote),
        ('Estado', order.estado),
        ('Cantidad de pieles', _number(order.cantidadPieles)),
        ('Inicio', _optionalDate(order.fechaInicioReal)),
        ('Fin estimado', _date.format(order.fechaFinEstimada)),
        ('Fin real', _optionalDate(order.fechaFinReal)),
      ],
      sections: const [],
      processes: processes,
      orderProducts: products,
    );
  }

  static Future<void> printConsumption({
    required BuildContext context,
    required String code,
    required String client,
    required List<ConsumoProcesoReporteItem> items,
  }) {
    final commonGroups = <String, List<ConsumoProcesoReporteItem>>{};
    final productItems = <int, List<ConsumoProcesoReporteItem>>{};
    for (final item in items) {
      if (item.ordenProductoId == null) {
        commonGroups.putIfAbsent(item.procesoNombre, () => []).add(item);
      } else {
        productItems.putIfAbsent(item.ordenProductoId!, () => []).add(item);
      }
    }
    final productGroups = productItems.values
        .map((productRows) {
          final first = productRows.first;
          final color = (first.productoColor ?? '').trim();
          final phases = <_PdfSection>[];
          for (final processCode in const ['RECURTIDO', 'ACABADO']) {
            final phaseRows = productRows
                .where((item) => item.procesoCodigo == processCode)
                .toList(growable: false);
            phases.add(
              _consumptionSection(
                processCode == 'RECURTIDO' ? 'Recurtido' : 'Acabado',
                phaseRows,
                emptyStatus: phaseRows.isEmpty ? 'PENDIENTE' : null,
                metrics: _stageMetrics(
                  phaseRows.isEmpty ? first : phaseRows.first,
                ),
              ),
            );
          }
          return _PdfProductGroup(
            title:
                '${first.productoNombre ?? 'Producto'}${color.isEmpty ? '' : ' · $color'}',
            total: productRows.fold<double>(
              0,
              (sum, item) => sum + item.costoTotal,
            ),
            cantidadPieles: first.productoCantidadPieles ?? 0,
            cantidadLados: first.productoCantidadLados ?? 0,
            cantidadTerminada: first.productoCantidadPielesTerminadas,
            sections: phases,
          );
        })
        .toList(growable: false);
    final total = items.fold<double>(0, (sum, item) => sum + item.costoTotal);
    return _print(
      context,
      '${code}_consumo_por_producto.pdf',
      title: 'Consumo por producto',
      code: code,
      summary: [
        ('Cliente', client),
        ('Productos', '${productGroups.length}'),
        ('Insumos registrados', '${items.length}'),
        ('Costo total', _money.format(total)),
      ],
      sections: commonGroups.entries
          .map(
            (entry) => _consumptionSection(
              entry.key,
              entry.value,
              detail:
                  '${_number(entry.value.first.ordenCantidadPieles)} pieles · ${_number(entry.value.first.ordenCantidadPieles * 2)} lados usados en la etapa general',
            ),
          )
          .toList(growable: false),
      productGroups: productGroups,
    );
  }

  static _PdfSection _consumptionSection(
    String title,
    List<ConsumoProcesoReporteItem> rows, {
    String? emptyStatus,
    String? detail,
    List<(String, String)> metrics = const [],
  }) {
    final status = rows.isEmpty
        ? 'Estado: ${emptyStatus ?? 'PENDIENTE'}'
        : rows.first.productoEstado == null
        ? null
        : 'Estado: ${rows.first.productoEstado!.replaceAll('_', ' ')}';
    return _PdfSection(
      title: title,
      subtitle: [
        if (status != null) status,
        if (detail != null) detail,
      ].join('   '),
      metrics: metrics,
      total: rows.fold<double>(0, (sum, item) => sum + item.costoTotal),
      rows: rows.isEmpty
          ? const [
              ['Sin consumos registrados', '-', 'S/ 0.00'],
            ]
          : rows
                .map(
                  (item) => [
                    '${item.insumoCodigo} - ${item.insumoNombre}',
                    _number(item.cantidadReal),
                    _money.format(item.costoTotal),
                  ],
                )
                .toList(growable: false),
    );
  }

  static List<(String, String)> _stageMetrics(ConsumoProcesoReporteItem item) =>
      [
        ('Pieles', '${_number(item.productoCantidadPieles ?? 0)} pieles'),
        ('Peso base', '${_number(item.productoPesoBaseKg ?? 0)} kg'),
        ('Inicio', _optionalDate(item.productoInicio)),
        ('Fin', _optionalDate(item.productoFin)),
      ];

  static Future<void> printRealCosts({
    required BuildContext context,
    required CostoOrdenReporteItem order,
    required List<CostoProcesoReporteItem> processes,
  }) {
    final groups = <String, List<CostoProcesoReporteItem>>{};
    for (final item in processes) {
      groups
          .putIfAbsent(
            '${item.ordenProcesoId}-${item.ordenProductoId ?? 0}',
            () => [],
          )
          .add(item);
    }
    final total = order.costoPieles + order.costoMaterialesReal;
    return _print(
      context,
      '${order.codigoOrden}_costos_reales.pdf',
      title: 'Ficha de costos reales',
      code: order.codigoOrden,
      summary: [
        ('Cliente', order.cliente),
        ('Lote', order.codigoLote),
        ('Pieles', _number(order.cantidadPieles)),
        ('Lados', _number(order.cantidadLados)),
        (
          'Costo de pieles',
          order.clienteTraeLote
              ? 'Traidas por el cliente'
              : _money.format(order.costoPieles),
        ),
        ('Costo por piel', _money.format(order.costoMaterialesPorPiel)),
        ('Costo por lado', _money.format(order.costoMaterialesPorLado)),
        ('Costo total', _money.format(total)),
      ],
      sections: groups.values
          .map((rows) {
            final first = rows.first;
            return _PdfSection(
              title:
                  '${first.procesoNombre}${first.ordenProductoId == null ? '' : ' - ${first.productoNombre ?? 'Producto'}${(first.productoColor ?? '').trim().isEmpty ? '' : ' · ${first.productoColor}'}'}',
              subtitle:
                  'Inicio ${_optionalDate(first.fechaInicio)}   Fin ${_optionalDate(first.fechaFin)}',
              headers: const ['INSUMO', 'PORCENTAJE', 'CANTIDAD', 'SOLES'],
              total: rows.fold<double>(
                0,
                (sum, item) => sum + item.costoMaterialesReal,
              ),
              rows: rows
                  .where((item) => item.insumoId != null)
                  .map(
                    (item) => [
                      '${item.insumoCodigo ?? '-'} - ${item.insumoNombre ?? 'Insumo'}',
                      item.porcentaje == null
                          ? '-'
                          : '${_number(item.porcentaje!)}%',
                      _number(item.cantidadConsumida),
                      _money.format(item.costoMaterialesReal),
                    ],
                  )
                  .toList(growable: false),
            );
          })
          .toList(growable: false),
    );
  }

  static Future<void> _print(
    BuildContext context,
    String fileName, {
    required String title,
    required String code,
    required List<(String, String)> summary,
    required List<_PdfSection> sections,
    List<OrdenProcesoRecord> processes = const [],
    List<_PdfProductGroup> productGroups = const [],
    List<OrdenProductoRecord> orderProducts = const [],
  }) async {
    final accepted = await _showPreview(
      context,
      title: title,
      code: code,
      summary: summary,
      sections: sections,
      processes: processes,
      productGroups: productGroups,
      orderProducts: orderProducts,
    );
    if (!accepted) return;

    final previewWindow = html.window.open('', '_blank');
    final bytes = await _build(
      title: title,
      code: code,
      summary: summary,
      sections: sections,
      processes: processes,
      productGroups: productGroups,
      orderProducts: orderProducts,
    );
    final blob = html.Blob([bytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    previewWindow.location.href = url;
    Future<void>.delayed(
      const Duration(minutes: 2),
    ).then((_) => html.Url.revokeObjectUrl(url));
  }

  static Future<bool> _showPreview(
    BuildContext context, {
    required String title,
    required String code,
    required List<(String, String)> summary,
    required List<_PdfSection> sections,
    required List<OrdenProcesoRecord> processes,
    required List<_PdfProductGroup> productGroups,
    required List<OrdenProductoRecord> orderProducts,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920, maxHeight: 860),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
                child: Row(
                  children: [
                    const Icon(Icons.preview_outlined),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Vista previa del documento',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Cerrar',
                      onPressed: () => Navigator.pop(dialogContext, false),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ColoredBox(
                  color: const Color(0xFFE7E7E9),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Container(
                        width: 760,
                        padding: const EdgeInsets.only(bottom: 28),
                        color: Colors.white,
                        child: _DocumentPreview(
                          title: title,
                          code: code,
                          summary: summary,
                          sections: sections,
                          processes: processes,
                          productGroups: productGroups,
                          orderProducts: orderProducts,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: () => Navigator.pop(dialogContext, true),
                      icon: const Icon(Icons.picture_as_pdf_outlined),
                      label: const Text('Abrir PDF'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return result ?? false;
  }

  static Future<Uint8List> _build({
    required String title,
    required String code,
    required List<(String, String)> summary,
    required List<_PdfSection> sections,
    required List<OrdenProcesoRecord> processes,
    required List<_PdfProductGroup> productGroups,
    required List<OrdenProductoRecord> orderProducts,
  }) async {
    final document = pw.Document(
      title: '$title - $code',
      author: 'CITEccal Trujillo ERP',
    );
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(30, 30, 30, 34),
        header: (context) => _header(title, code),
        footer: (context) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'CITEccal Trujillo ERP',
              style: const pw.TextStyle(fontSize: 8),
            ),
            pw.Text(
              'Pagina ${context.pageNumber} de ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 8),
            ),
          ],
        ),
        build: (_) => [
          pw.SizedBox(height: 16),
          _summary(summary),
          if (processes.isNotEmpty) ...[
            pw.SizedBox(height: 22),
            _processTimeline(processes),
          ],
          if (orderProducts.isNotEmpty) ...[
            pw.SizedBox(height: 14),
            ...orderProducts.map(_orderProductCard),
            _orderProductsSummary(orderProducts),
          ] else if (productGroups.isNotEmpty && sections.isNotEmpty)
            _commonSectionGroup(sections)
          else
            ...sections.map(_section),
          for (final group in productGroups) ...[
            pw.NewPage(freeSpace: _productGroupMinHeight(group)),
            _productGroup(group),
          ],
          pw.SizedBox(height: 34),
          pw.Row(
            children: ['Elaborado por', 'Jefe de planta', 'Control de calidad']
                .map(
                  (label) => pw.Expanded(
                    child: pw.Container(
                      margin: const pw.EdgeInsets.symmetric(horizontal: 10),
                      padding: const pw.EdgeInsets.only(top: 5),
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(top: pw.BorderSide(color: _charcoal)),
                      ),
                      child: pw.Text(
                        label,
                        textAlign: pw.TextAlign.center,
                        style: const pw.TextStyle(fontSize: 8),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
    return document.save();
  }

  static pw.Widget _header(String title, String code) => pw.Column(
    children: [
      pw.Container(
        color: _charcoal,
        padding: const pw.EdgeInsets.all(18),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.RichText(
                  text: pw.TextSpan(
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                    children: const [
                      pw.TextSpan(text: 'CITEccal Trujillo '),
                      pw.TextSpan(
                        text: 'ERP',
                        style: pw.TextStyle(color: _orange),
                      ),
                    ],
                  ),
                ),
                pw.Text(
                  'GESTION DE CURTIEMBRE',
                  style: const pw.TextStyle(
                    fontSize: 7,
                    color: PdfColors.grey300,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  title.toUpperCase(),
                  style: const pw.TextStyle(
                    fontSize: 8,
                    color: PdfColors.grey300,
                  ),
                ),
                pw.Text(
                  code,
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
                pw.Text(
                  _date.format(DateTime.now()),
                  style: const pw.TextStyle(
                    fontSize: 8,
                    color: PdfColors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      pw.Container(height: 5, color: _orange),
    ],
  );

  static pw.Widget _summary(List<(String, String)> values) => pw.Wrap(
    spacing: 12,
    runSpacing: 8,
    children: values
        .map(
          (item) => pw.Container(
            width: 245,
            padding: const pw.EdgeInsets.only(bottom: 4),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfColors.grey400, width: .5),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  item.$1,
                  style: const pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Flexible(
                  child: pw.Text(
                    item.$2,
                    textAlign: pw.TextAlign.right,
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        )
        .toList(),
  );

  static pw.Widget _section(_PdfSection section) => pw.Container(
    margin: const pw.EdgeInsets.only(top: 18),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  section.title,
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: _charcoal,
                  ),
                ),
                if (section.subtitle != null)
                  pw.Text(
                    section.subtitle!,
                    style: const pw.TextStyle(
                      fontSize: 8,
                      color: PdfColors.grey700,
                    ),
                  ),
              ],
            ),
            pw.Text(
              _money.format(section.total),
              style: pw.TextStyle(
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
                color: _orange,
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 6),
        pw.TableHelper.fromTextArray(
          headers: section.headers,
          data: section.rows,
          headerDecoration: const pw.BoxDecoration(color: _charcoal),
          headerStyle: pw.TextStyle(
            color: PdfColors.white,
            fontWeight: pw.FontWeight.bold,
            fontSize: 8,
          ),
          cellStyle: const pw.TextStyle(fontSize: 8),
          cellAlignments: {
            for (var index = 1; index < section.headers.length; index++)
              index: pw.Alignment.centerRight,
          },
          columnWidths: section.headers.length == 4
              ? const {
                  0: pw.FlexColumnWidth(5),
                  1: pw.FlexColumnWidth(1.7),
                  2: pw.FlexColumnWidth(1.7),
                  3: pw.FlexColumnWidth(1.8),
                }
              : const {
                  0: pw.FlexColumnWidth(6),
                  1: pw.FlexColumnWidth(2),
                  2: pw.FlexColumnWidth(2),
                },
          border: const pw.TableBorder(
            horizontalInside: pw.BorderSide(
              color: PdfColors.grey300,
              width: .5,
            ),
          ),
        ),
      ],
    ),
  );

  static pw.Widget _commonSectionGroup(List<_PdfSection> sections) =>
      pw.Container(
        margin: const pw.EdgeInsets.only(top: 18),
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: const PdfColor.fromInt(0xFFF2F3F4),
          border: pw.Border.all(color: PdfColors.grey300),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.RichText(
              text: pw.TextSpan(
                children: [
                  pw.TextSpan(
                    text: 'Procesos comunes ',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: _charcoal,
                    ),
                  ),
                  const pw.TextSpan(
                    text: '(para todos los productos)',
                    style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                  ),
                ],
              ),
            ),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                for (var index = 0; index < sections.length; index++) ...[
                  if (index > 0) pw.SizedBox(width: 10),
                  pw.Expanded(child: _section(sections[index])),
                ],
              ],
            ),
          ],
        ),
      );

  static pw.Widget _productGroup(_PdfProductGroup group) => pw.Container(
    margin: const pw.EdgeInsets.only(top: 18),
    padding: const pw.EdgeInsets.all(10),
    decoration: pw.BoxDecoration(
      color: const PdfColor.fromInt(0xFFFFF8F3),
      border: pw.Border.all(color: const PdfColor.fromInt(0xFFF5B58D)),
      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Expanded(
              child: pw.Text(
                'Producto: ${group.title}',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: _charcoal,
                ),
              ),
            ),
            pw.SizedBox(width: 12),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 9,
                vertical: 6,
              ),
              decoration: pw.BoxDecoration(
                color: _orange,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
              ),
              child: pw.Text(
                'Total del producto: ${_money.format(group.total)}',
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 3),
        pw.Text(
          '${_number(group.cantidadPieles)} pieles  ·  '
          '${_number(group.cantidadLados)} lados'
          '${group.cantidadTerminada == null ? '' : '  ·  ${_number(group.cantidadTerminada!)} terminadas'}',
          style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 8),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            for (var index = 0; index < group.sections.length; index++) ...[
              if (index > 0) pw.SizedBox(width: 10),
              pw.Expanded(child: _compactSection(group.sections[index])),
            ],
          ],
        ),
      ],
    ),
  );

  static pw.Widget _compactSection(_PdfSection section) => pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Row(
        children: [
          pw.Text(
            section.title.toUpperCase(),
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(width: 6),
          if (_statusFromSubtitle(section.subtitle) != null)
            _pdfStatusBadge(_statusFromSubtitle(section.subtitle)!),
          pw.Spacer(),
          pw.Text(
            _money.format(section.total),
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: _orange,
            ),
          ),
        ],
      ),
      if (_detailFromSubtitle(section.subtitle) != null) ...[
        pw.SizedBox(height: 3),
        pw.Text(
          _detailFromSubtitle(section.subtitle)!,
          style: const pw.TextStyle(fontSize: 6.3, color: PdfColors.grey700),
        ),
      ],
      if (section.metrics.isNotEmpty) ...[
        pw.SizedBox(height: 5),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
          decoration: const pw.BoxDecoration(
            color: PdfColor.fromInt(0xFFF2F3F4),
            borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
          ),
          child: pw.Row(
            children: section.metrics
                .map(
                  (metric) => pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          metric.$1,
                          style: const pw.TextStyle(
                            fontSize: 5.7,
                            color: PdfColors.grey700,
                          ),
                        ),
                        pw.Text(
                          metric.$2,
                          style: pw.TextStyle(
                            fontSize: 6.2,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        ),
      ],
      pw.SizedBox(height: 5),
      pw.TableHelper.fromTextArray(
        headers: section.headers,
        data: section.rows,
        headerDecoration: const pw.BoxDecoration(color: _charcoal),
        headerStyle: pw.TextStyle(
          color: PdfColors.white,
          fontWeight: pw.FontWeight.bold,
          fontSize: 5.5,
        ),
        cellStyle: const pw.TextStyle(fontSize: 6.5),
        cellAlignments: const {
          1: pw.Alignment.centerRight,
          2: pw.Alignment.centerRight,
        },
        columnWidths: const {
          0: pw.FlexColumnWidth(5.2),
          1: pw.FlexColumnWidth(2.2),
          2: pw.FlexColumnWidth(1.6),
        },
        border: const pw.TableBorder(
          horizontalInside: pw.BorderSide(color: PdfColors.grey300, width: .5),
        ),
      ),
    ],
  );

  static double _productGroupMinHeight(_PdfProductGroup group) {
    final longestTable = group.sections.fold<int>(
      0,
      (current, section) =>
          section.rows.length > current ? section.rows.length : current,
    );
    return 92 + (longestTable * 15.0);
  }

  static pw.Widget _orderProductCard(OrdenProductoRecord product) {
    final title =
        '${product.nombre}${(product.color ?? '').trim().isEmpty ? '' : ' - ${product.color}'}';
    final progress =
        (_stageProgress(product.estadoRecurtido) +
            _stageProgress(product.estadoAcabado)) /
        2;
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      padding: const pw.EdgeInsets.all(9),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      title,
                      style: pw.TextStyle(
                        fontSize: 13,
                        fontWeight: pw.FontWeight.bold,
                        color: _charcoal,
                      ),
                    ),
                    pw.Text(
                      'Pieles: ${_number(product.cantidadPieles)}',
                      style: const pw.TextStyle(
                        fontSize: 7,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('Avance general', style: pw.TextStyle(fontSize: 6.5)),
                  pw.Text(
                    '${progress.round()}%',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 4),
          _pdfProgressBar(progress, _progressColor(progress)),
          pw.SizedBox(height: 7),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: _orderStageCard(
                  title: 'CURTIDO / RECURTIDO',
                  status: product.estadoRecurtido,
                  start: product.inicioRecurtido,
                  end: product.finRecurtido,
                  responsible: product.responsableRecurtidoNombre,
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: _orderStageCard(
                  title: 'ACABADO',
                  status: product.estadoAcabado,
                  start: product.inicioAcabado,
                  end: product.finAcabado,
                  responsible: product.responsableAcabadoNombre,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _orderStageCard({
    required String title,
    required String status,
    required DateTime? start,
    required DateTime? end,
    required String? responsible,
  }) {
    final progress = _stageProgress(status);
    final color = _progressColor(progress);
    return pw.Container(
      padding: const pw.EdgeInsets.all(7),
      decoration: pw.BoxDecoration(
        color: _stageBackground(status),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Container(
                width: 16,
                height: 16,
                alignment: pw.Alignment.center,
                decoration: pw.BoxDecoration(
                  color: color,
                  shape: pw.BoxShape.circle,
                ),
                child: pw.Text(
                  status == 'FINALIZADO' ? 'OK' : '${progress.round()}',
                  style: pw.TextStyle(
                    fontSize: 5,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
              ),
              pw.SizedBox(width: 5),
              pw.Expanded(
                child: pw.Text(
                  title,
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              _pdfStatusBadge(status.replaceAll('_', ' ')),
            ],
          ),
          pw.SizedBox(height: 5),
          _stageInfoRow('Inicio', _optionalDate(start)),
          _stageInfoRow('Fin', _optionalDate(end)),
          _stageInfoRow('Responsable', responsible ?? 'Sin asignar'),
          pw.SizedBox(height: 5),
          _pdfProgressBar(progress, color),
        ],
      ),
    );
  }

  static pw.Widget _stageInfoRow(String label, String value) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 2),
    child: pw.Row(
      children: [
        pw.SizedBox(
          width: 48,
          child: pw.Text(
            label,
            style: const pw.TextStyle(fontSize: 6, color: PdfColors.grey700),
          ),
        ),
        pw.Expanded(
          child: pw.Text(
            value,
            style: pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold),
          ),
        ),
      ],
    ),
  );

  static pw.Widget _pdfProgressBar(double progress, PdfColor color) =>
      pw.Container(
        height: 6,
        decoration: const pw.BoxDecoration(
          color: PdfColor.fromInt(0xFFDDE1E5),
          borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
        ),
        child: pw.Row(
          children: [
            if (progress > 0)
              pw.Expanded(
                flex: progress.round(),
                child: pw.Container(
                  decoration: pw.BoxDecoration(
                    color: color,
                    borderRadius: const pw.BorderRadius.all(
                      pw.Radius.circular(4),
                    ),
                  ),
                ),
              ),
            if (progress < 100)
              pw.Expanded(flex: (100 - progress).round(), child: pw.SizedBox()),
          ],
        ),
      );

  static pw.Widget _orderProductsSummary(List<OrdenProductoRecord> products) {
    final completed = products
        .where((item) => item.estadoAcabado == 'FINALIZADO')
        .length;
    final active = products.length - completed;
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 2, bottom: 8),
      padding: const pw.EdgeInsets.all(9),
      decoration: const pw.BoxDecoration(
        color: PdfColor.fromInt(0xFFF0F2F4),
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Row(
        children: [
          pw.Text(
            'RESUMEN DE LA ORDEN',
            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
          ),
          pw.Spacer(),
          pw.Text(
            '$completed producto${completed == 1 ? '' : 's'} finalizado${completed == 1 ? '' : 's'}',
            style: const pw.TextStyle(fontSize: 7, color: PdfColors.green700),
          ),
          pw.SizedBox(width: 16),
          pw.Text(
            '$active producto${active == 1 ? '' : 's'} en proceso',
            style: const pw.TextStyle(fontSize: 7, color: _orange),
          ),
        ],
      ),
    );
  }

  static double _stageProgress(String status) => status == 'FINALIZADO'
      ? 100
      : status == 'EN_PROCESO'
      ? 50
      : 0;

  static PdfColor _progressColor(double progress) => progress >= 100
      ? const PdfColor.fromInt(0xFF27A844)
      : progress > 0
      ? _orange
      : PdfColors.grey500;

  static PdfColor _stageBackground(String status) => status == 'FINALIZADO'
      ? const PdfColor.fromInt(0xFFF0FAF3)
      : status == 'EN_PROCESO'
      ? const PdfColor.fromInt(0xFFFFF5ED)
      : const PdfColor.fromInt(0xFFF3F4F5);

  static pw.Widget _processTimeline(List<OrdenProcesoRecord> processes) {
    final ordered = [...processes]
      ..sort((a, b) => a.secuencia.compareTo(b.secuencia));
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'LINEA DE TIEMPO DEL PROCESO',
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
            color: _charcoal,
          ),
        ),
        pw.SizedBox(height: 14),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: ordered.map((process) {
            final completed =
                process.fechaFin != null || process.estado == 'FINALIZADO';
            final active = !completed && process.fechaInicio != null;
            final color = completed || active ? _orange : PdfColors.grey400;
            return pw.Expanded(
              child: pw.Column(
                children: [
                  pw.Container(
                    width: 22,
                    height: 22,
                    alignment: pw.Alignment.center,
                    decoration: pw.BoxDecoration(
                      color: completed ? _orange : PdfColors.white,
                      border: pw.Border.all(color: color, width: 1.5),
                      shape: pw.BoxShape.circle,
                    ),
                    child: pw.Text(
                      completed ? 'OK' : '${process.secuencia}',
                      style: pw.TextStyle(
                        fontSize: 6.5,
                        fontWeight: pw.FontWeight.bold,
                        color: completed ? PdfColors.white : color,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    process.procesoNombre,
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    _processStatus(process),
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(fontSize: 6.5, color: color),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  static String _processStatus(OrdenProcesoRecord process) {
    if (process.fechaFin != null) {
      return 'Finalizado ${_date.format(process.fechaFin!)}';
    }
    if (process.fechaInicio != null) return 'En proceso';
    return process.estado.replaceAll('_', ' ');
  }

  static String? _statusFromSubtitle(String? subtitle) {
    if (subtitle == null || !subtitle.startsWith('Estado: ')) return null;
    return subtitle.substring(8).split('   ').first;
  }

  static String? _detailFromSubtitle(String? subtitle) {
    if (subtitle == null) return null;
    final parts = subtitle.split('   ');
    final detail = parts
        .where((part) => !part.startsWith('Estado: '))
        .join(' ');
    return detail.isEmpty ? null : detail;
  }

  static pw.Widget _pdfStatusBadge(String status) {
    final normalized = status.toUpperCase();
    final color = normalized == 'FINALIZADO'
        ? const PdfColor.fromInt(0xFFD6F5E3)
        : normalized == 'EN PROCESO'
        ? const PdfColor.fromInt(0xFFD8ECFF)
        : const PdfColor.fromInt(0xFFFFE8B0);
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: pw.BoxDecoration(
        color: color,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Text(
        normalized,
        style: pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  static String _optionalDate(DateTime? value) =>
      value == null ? 'Sin registro' : _date.format(value);
  static String _number(double value) =>
      NumberFormat('#,##0.##', 'es_PE').format(value);
}

class _PdfSection {
  const _PdfSection({
    required this.title,
    required this.total,
    required this.rows,
    this.headers = const ['INSUMO', 'CANTIDAD', 'COSTO'],
    this.subtitle,
    this.metrics = const [],
  });

  final String title;
  final String? subtitle;
  final double total;
  final List<List<String>> rows;
  final List<String> headers;
  final List<(String, String)> metrics;
}

class _PdfProductGroup {
  const _PdfProductGroup({
    required this.title,
    required this.total,
    required this.cantidadPieles,
    required this.cantidadLados,
    this.cantidadTerminada,
    required this.sections,
  });

  final String title;
  final double total;
  final double cantidadPieles;
  final double cantidadLados;
  final double? cantidadTerminada;
  final List<_PdfSection> sections;
}

class _DocumentPreview extends StatelessWidget {
  const _DocumentPreview({
    required this.title,
    required this.code,
    required this.summary,
    required this.sections,
    required this.processes,
    required this.productGroups,
    required this.orderProducts,
  });

  final String title;
  final String code;
  final List<(String, String)> summary;
  final List<_PdfSection> sections;
  final List<OrdenProcesoRecord> processes;
  final List<_PdfProductGroup> productGroups;
  final List<OrdenProductoRecord> orderProducts;

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFFE8590C);
    const charcoal = Color(0xFF343437);
    return DefaultTextStyle(
      style: const TextStyle(color: Color(0xFF252527), fontSize: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            color: charcoal,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                        ),
                        children: [
                          TextSpan(text: 'CITEccal Trujillo '),
                          TextSpan(
                            text: 'ERP',
                            style: TextStyle(color: orange),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'GESTION DE CURTIEMBRE',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 9,
                        letterSpacing: 1.4,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      title.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      code,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      ProductionReportPdfService._date.format(DateTime.now()),
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(height: 6, color: orange),
          Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 5.5,
                    crossAxisSpacing: 24,
                    mainAxisSpacing: 6,
                  ),
                  itemCount: summary.length,
                  itemBuilder: (_, index) {
                    final item = summary[index];
                    return Container(
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Color(0xFFD6D6D8)),
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            item.$1,
                            style: const TextStyle(color: Colors.black54),
                          ),
                          const Spacer(),
                          Flexible(
                            child: Text(
                              item.$2,
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                if (processes.isNotEmpty) ...[
                  const SizedBox(height: 28),
                  _PreviewProcessTimeline(processes: processes),
                ],
                if (orderProducts.isNotEmpty) ...[
                  ...orderProducts.map(
                    (product) => _PreviewOrderProductCard(product: product),
                  ),
                  _PreviewOrderSummary(products: orderProducts),
                ] else if (productGroups.isNotEmpty && sections.isNotEmpty)
                  _PreviewCommonProcesses(sections: sections)
                else
                  ...sections.map(
                    (section) => Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      section.title,
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    if (section.subtitle != null)
                                      Text(
                                        section.subtitle!,
                                        style: const TextStyle(
                                          color: Colors.black54,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Text(
                                ProductionReportPdfService._money.format(
                                  section.total,
                                ),
                                style: const TextStyle(
                                  color: orange,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _PreviewTableHeader(headers: section.headers),
                          ...section.rows.map(
                            (row) => _PreviewTableRow(
                              row: row,
                              columnCount: section.headers.length,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ...productGroups.map(
                  (group) => _PreviewProductGroup(group: group),
                ),
                const SizedBox(height: 48),
                const Row(
                  children: [
                    Expanded(child: _Signature(label: 'Elaborado por')),
                    SizedBox(width: 28),
                    Expanded(child: _Signature(label: 'Jefe de planta')),
                    SizedBox(width: 28),
                    Expanded(child: _Signature(label: 'Control de calidad')),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewCommonProcesses extends StatelessWidget {
  const _PreviewCommonProcesses({required this.sections});

  final List<_PdfSection> sections;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(top: 24),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFF2F3F4),
      border: Border.all(color: const Color(0xFFD8DADD)),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'Procesos comunes ',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              TextSpan(
                text: '(para todos los productos)',
                style: TextStyle(color: Colors.black54),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: sections
              .asMap()
              .entries
              .map((entry) {
                final section = entry.value;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(left: entry.key == 0 ? 0 : 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                section.title,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            Text(
                              ProductionReportPdfService._money.format(
                                section.total,
                              ),
                              style: const TextStyle(
                                color: Color(0xFFE8590C),
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        if (section.subtitle != null) ...[
                          const SizedBox(height: 3),
                          Text(
                            section.subtitle!,
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 10,
                            ),
                          ),
                        ],
                        const SizedBox(height: 7),
                        _PreviewTableHeader(headers: section.headers),
                        ...section.rows.map(
                          (row) => _PreviewTableRow(
                            row: row,
                            columnCount: section.headers.length,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              })
              .toList(growable: false),
        ),
      ],
    ),
  );
}

class _PreviewOrderProductCard extends StatelessWidget {
  const _PreviewOrderProductCard({required this.product});

  final OrdenProductoRecord product;

  @override
  Widget build(BuildContext context) {
    final progress =
        (ProductionReportPdfService._stageProgress(product.estadoRecurtido) +
            ProductionReportPdfService._stageProgress(product.estadoAcabado)) /
        2;
    final color = progress >= 100
        ? const Color(0xFF27A844)
        : progress > 0
        ? const Color(0xFF1687D9)
        : Colors.black38;
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFD8DADD)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${product.nombre}${(product.color ?? '').trim().isEmpty ? '' : ' - ${product.color}'}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Pieles: ${ProductionReportPdfService._number(product.cantidadPieles)}',
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Avance general'),
                  Text(
                    '${progress.round()}%',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: progress / 100,
            minHeight: 7,
            borderRadius: BorderRadius.circular(99),
            color: color,
            backgroundColor: const Color(0xFFDDE1E5),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _PreviewOrderStageCard(
                  title: 'CURTIDO / RECURTIDO',
                  status: product.estadoRecurtido,
                  start: product.inicioRecurtido,
                  end: product.finRecurtido,
                  responsible: product.responsableRecurtidoNombre,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PreviewOrderStageCard(
                  title: 'ACABADO',
                  status: product.estadoAcabado,
                  start: product.inicioAcabado,
                  end: product.finAcabado,
                  responsible: product.responsableAcabadoNombre,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PreviewOrderStageCard extends StatelessWidget {
  const _PreviewOrderStageCard({
    required this.title,
    required this.status,
    required this.start,
    required this.end,
    required this.responsible,
  });

  final String title;
  final String status;
  final DateTime? start;
  final DateTime? end;
  final String? responsible;

  @override
  Widget build(BuildContext context) {
    final progress = ProductionReportPdfService._stageProgress(status);
    final completed = status == 'FINALIZADO';
    final active = status == 'EN_PROCESO';
    final color = completed
        ? const Color(0xFF27A844)
        : active
        ? const Color(0xFFFF5A0A)
        : Colors.black38;
    final background = completed
        ? const Color(0xFFF0FAF3)
        : active
        ? const Color(0xFFFFF5ED)
        : const Color(0xFFF3F4F5);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 13,
                backgroundColor: color,
                child: Icon(
                  completed
                      ? Icons.check_rounded
                      : active
                      ? Icons.sync_rounded
                      : Icons.schedule_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              _PreviewStatusBadge(status: status.replaceAll('_', ' ')),
            ],
          ),
          const SizedBox(height: 10),
          _PreviewStageInfo(
            label: 'Inicio',
            value: ProductionReportPdfService._optionalDate(start),
          ),
          _PreviewStageInfo(
            label: 'Fin',
            value: ProductionReportPdfService._optionalDate(end),
          ),
          _PreviewStageInfo(
            label: 'Responsable',
            value: responsible ?? 'Sin asignar',
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress / 100,
            minHeight: 7,
            borderRadius: BorderRadius.circular(99),
            color: color,
            backgroundColor: const Color(0xFFD5D9DD),
          ),
        ],
      ),
    );
  }
}

class _PreviewStageInfo extends StatelessWidget {
  const _PreviewStageInfo({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 3),
    child: Row(
      children: [
        SizedBox(
          width: 78,
          child: Text(label, style: const TextStyle(color: Colors.black54)),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}

class _PreviewOrderSummary extends StatelessWidget {
  const _PreviewOrderSummary({required this.products});
  final List<OrdenProductoRecord> products;

  @override
  Widget build(BuildContext context) {
    final completed = products
        .where((item) => item.estadoAcabado == 'FINALIZADO')
        .length;
    final active = products.length - completed;
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2F4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.bar_chart_rounded),
          const SizedBox(width: 8),
          const Text(
            'RESUMEN DE LA ORDEN',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const Spacer(),
          Text(
            '$completed finalizado${completed == 1 ? '' : 's'}',
            style: const TextStyle(
              color: Color(0xFF168A3F),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 20),
          Text(
            '$active en proceso',
            style: const TextStyle(
              color: Color(0xFFE8590C),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewProductGroup extends StatelessWidget {
  const _PreviewProductGroup({required this.group});

  final _PdfProductGroup group;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(top: 24),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF8F3),
      border: Border.all(color: const Color(0xFFF5B58D)),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Producto: ${group.title}',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    '${ProductionReportPdfService._number(group.cantidadPieles)} pieles · ${ProductionReportPdfService._number(group.cantidadLados)} lados${group.cantidadTerminada == null ? '' : ' · ${ProductionReportPdfService._number(group.cantidadTerminada!)} terminadas'}',
                    style: const TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFF5A0A),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(
                'Total del producto: ${ProductionReportPdfService._money.format(group.total)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: group.sections
              .asMap()
              .entries
              .map((entry) {
                final section = entry.value;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(left: entry.key == 0 ? 0 : 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                section.title.toUpperCase(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            if (ProductionReportPdfService._statusFromSubtitle(
                                  section.subtitle,
                                ) !=
                                null)
                              _PreviewStatusBadge(
                                status:
                                    ProductionReportPdfService._statusFromSubtitle(
                                      section.subtitle,
                                    )!,
                              ),
                            const SizedBox(width: 6),
                            Text(
                              ProductionReportPdfService._money.format(
                                section.total,
                              ),
                              style: const TextStyle(
                                color: Color(0xFFE8590C),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        if (ProductionReportPdfService._detailFromSubtitle(
                              section.subtitle,
                            ) !=
                            null) ...[
                          const SizedBox(height: 3),
                          Text(
                            ProductionReportPdfService._detailFromSubtitle(
                              section.subtitle,
                            )!,
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 10,
                            ),
                          ),
                        ],
                        if (section.metrics.isNotEmpty) ...[
                          const SizedBox(height: 7),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F2F3),
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: Row(
                              children: section.metrics
                                  .map(
                                    (metric) => Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            metric.$1,
                                            style: const TextStyle(
                                              color: Colors.black54,
                                              fontSize: 9,
                                            ),
                                          ),
                                          Text(
                                            metric.$2,
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                  .toList(growable: false),
                            ),
                          ),
                        ],
                        const SizedBox(height: 6),
                        _PreviewTableHeader(headers: section.headers),
                        ...section.rows.map(
                          (row) => _PreviewTableRow(
                            row: row,
                            columnCount: section.headers.length,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              })
              .toList(growable: false),
        ),
      ],
    ),
  );
}

class _PreviewStatusBadge extends StatelessWidget {
  const _PreviewStatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = status.toUpperCase();
    final background = normalized == 'FINALIZADO'
        ? const Color(0xFFD6F5E3)
        : normalized == 'EN PROCESO'
        ? const Color(0xFFD8ECFF)
        : const Color(0xFFFFE8B0);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        normalized,
        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _PreviewProcessTimeline extends StatelessWidget {
  const _PreviewProcessTimeline({required this.processes});

  final List<OrdenProcesoRecord> processes;

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFFE8590C);
    final ordered = [...processes]
      ..sort((a, b) => a.secuencia.compareTo(b.secuencia));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'LINEA DE TIEMPO DEL PROCESO',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1),
        ),
        const SizedBox(height: 18),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: ordered.map((process) {
            final completed =
                process.fechaFin != null || process.estado == 'FINALIZADO';
            final active = !completed && process.fechaInicio != null;
            final color = completed || active ? orange : Colors.black26;
            return Expanded(
              child: Column(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: completed ? orange : Colors.white,
                      border: Border.all(color: color, width: 2),
                    ),
                    child: completed
                        ? const Icon(
                            Icons.check_rounded,
                            size: 19,
                            color: Colors.white,
                          )
                        : Text(
                            '${process.secuencia}',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: color,
                            ),
                          ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    process.procesoNombre,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    ProductionReportPdfService._processStatus(process),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 10, color: color),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _PreviewTableHeader extends StatelessWidget {
  const _PreviewTableHeader({required this.headers});

  final List<String> headers;

  @override
  Widget build(BuildContext context) => Container(
    color: const Color(0xFF343437),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    child: Row(
      children: headers
          .asMap()
          .entries
          .map((entry) {
            return Expanded(
              flex: entry.key == 0 ? 6 : 2,
              child: Text(
                entry.value,
                textAlign: entry.key == 0 ? TextAlign.left : TextAlign.right,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            );
          })
          .toList(growable: false),
    ),
  );
}

class _PreviewTableRow extends StatelessWidget {
  const _PreviewTableRow({required this.row, required this.columnCount});
  final List<String> row;
  final int columnCount;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: Color(0xFFE3E3E5))),
    ),
    child: Row(
      children: row
          .asMap()
          .entries
          .map((entry) {
            return Expanded(
              flex: entry.key == 0 ? 6 : 2,
              child: Text(
                entry.value,
                textAlign: entry.key == 0 ? TextAlign.left : TextAlign.right,
                style: entry.key == columnCount - 1
                    ? const TextStyle(fontWeight: FontWeight.w700)
                    : null,
              ),
            );
          })
          .toList(growable: false),
    ),
  );
}

class _Signature extends StatelessWidget {
  const _Signature({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.only(top: 6),
    decoration: const BoxDecoration(
      border: Border(top: BorderSide(color: Colors.black54)),
    ),
    child: Text(
      label,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 10, color: Colors.black54),
    ),
  );
}
