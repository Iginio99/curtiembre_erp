import 'dart:typed_data';
import 'dart:html' as html;

import 'package:erp_curtiembre_fronted/features/production/reportes/domain/entities/consumo_proceso_reporte_item.dart';
import 'package:erp_curtiembre_fronted/features/production/reportes/domain/entities/costo_orden_reporte_item.dart';
import 'package:erp_curtiembre_fronted/features/production/reportes/domain/entities/costo_proceso_reporte_item.dart';
import 'package:erp_curtiembre_fronted/features/production/reportes/domain/entities/orden_activa_reporte_item.dart';
import 'package:erp_curtiembre_fronted/features/production/reportes/domain/entities/orden_cliente_reporte_item.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class ProductionReportPdfService {
  static final _date = DateFormat('dd/MM/yyyy');
  static final _money = NumberFormat.currency(locale: 'es_PE', symbol: 'S/ ');
  static const _orange = PdfColor.fromInt(0xFFE8590C);
  static const _charcoal = PdfColor.fromInt(0xFF343437);

  static Future<void> printActiveOrder(BuildContext context, OrdenActivaReporteItem order) {
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
    );
  }

  static Future<void> printClientOrder(BuildContext context, OrdenClienteReporteItem order) {
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
    );
  }

  static Future<void> printConsumption({
    required BuildContext context,
    required String code,
    required String client,
    required List<ConsumoProcesoReporteItem> items,
  }) {
    final groups = <String, List<ConsumoProcesoReporteItem>>{};
    for (final item in items) {
      groups.putIfAbsent(item.procesoNombre, () => []).add(item);
    }
    final total = items.fold<double>(0, (sum, item) => sum + item.costoTotal);
    return _print(
      context,
      '${code}_consumo_por_proceso.pdf',
      title: 'Consumo real por proceso',
      code: code,
      summary: [
        ('Cliente', client),
        ('Procesos', '${groups.length}'),
        ('Insumos registrados', '${items.length}'),
        ('Costo total', _money.format(total)),
      ],
      sections: groups.entries
          .map(
            (entry) => _PdfSection(
              title: entry.key,
              total: entry.value.fold<double>(
                0,
                (sum, item) => sum + item.costoTotal,
              ),
              rows: entry.value
                  .map(
                    (item) => [
                      '${item.insumoCodigo} - ${item.insumoNombre}',
                      _number(item.cantidadReal),
                      _money.format(item.costoTotal),
                    ],
                  )
                  .toList(growable: false),
            ),
          )
          .toList(growable: false),
    );
  }

  static Future<void> printRealCosts({
    required BuildContext context,
    required CostoOrdenReporteItem order,
    required List<CostoProcesoReporteItem> processes,
  }) {
    final groups = <int, List<CostoProcesoReporteItem>>{};
    for (final item in processes) {
      groups.putIfAbsent(item.ordenProcesoId, () => []).add(item);
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
              title: first.procesoNombre,
              subtitle:
                  'Inicio ${_optionalDate(first.fechaInicio)}   Fin ${_optionalDate(first.fechaFin)}',
              total: rows.fold<double>(
                0,
                (sum, item) => sum + item.costoMaterialesReal,
              ),
              rows: rows
                  .where((item) => item.insumoId != null)
                  .map(
                    (item) => [
                      '${item.insumoCodigo ?? '-'} - ${item.insumoNombre ?? 'Insumo'}',
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
  }) async {
    final accepted = await _showPreview(
      context,
      title: title,
      code: code,
      summary: summary,
      sections: sections,
    );
    if (!accepted) return;

    final previewWindow = html.window.open('', '_blank');
    final bytes = await _build(
      title: title,
      code: code,
      summary: summary,
      sections: sections,
    );
    final blob = html.Blob([bytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    if (previewWindow != null) {
      previewWindow.location.href = url;
    } else {
      html.AnchorElement(href: url)
        ..target = '_blank'
        ..rel = 'noopener'
        ..click();
    }
    Future<void>.delayed(const Duration(minutes: 2)).then(
      (_) => html.Url.revokeObjectUrl(url),
    );
  }

  static Future<bool> _showPreview(
    BuildContext context, {
    required String title,
    required String code,
    required List<(String, String)> summary,
    required List<_PdfSection> sections,
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
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
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
          ...sections.map(_section),
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
          headers: const ['INSUMO', 'CANTIDAD', 'SOLES'],
          data: section.rows,
          headerDecoration: const pw.BoxDecoration(color: _charcoal),
          headerStyle: pw.TextStyle(
            color: PdfColors.white,
            fontWeight: pw.FontWeight.bold,
            fontSize: 8,
          ),
          cellStyle: const pw.TextStyle(fontSize: 8),
          cellAlignments: const {
            1: pw.Alignment.centerRight,
            2: pw.Alignment.centerRight,
          },
          columnWidths: const {
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
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final double total;
  final List<List<String>> rows;
}

class _DocumentPreview extends StatelessWidget {
  const _DocumentPreview({
    required this.title,
    required this.code,
    required this.summary,
    required this.sections,
  });

  final String title;
  final String code;
  final List<(String, String)> summary;
  final List<_PdfSection> sections;

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
                          TextSpan(text: 'ERP', style: TextStyle(color: orange)),
                        ],
                      ),
                    ),
                    Text(
                      'GESTION DE CURTIEMBRE',
                      style: TextStyle(color: Colors.white60, fontSize: 9, letterSpacing: 1.4),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(title.toUpperCase(), style: const TextStyle(color: Colors.white70, fontSize: 10)),
                    Text(code, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
                    Text(ProductionReportPdfService._date.format(DateTime.now()), style: const TextStyle(color: Colors.white70)),
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
                        border: Border(bottom: BorderSide(color: Color(0xFFD6D6D8))),
                      ),
                      child: Row(
                        children: [
                          Text(item.$1, style: const TextStyle(color: Colors.black54)),
                          const Spacer(),
                          Flexible(
                            child: Text(item.$2, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
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
                                  Text(section.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                                  if (section.subtitle != null) Text(section.subtitle!, style: const TextStyle(color: Colors.black54)),
                                ],
                              ),
                            ),
                            Text(
                              ProductionReportPdfService._money.format(section.total),
                              style: const TextStyle(color: orange, fontSize: 16, fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const _PreviewTableHeader(),
                        ...section.rows.map((row) => _PreviewTableRow(row: row)),
                      ],
                    ),
                  ),
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

class _PreviewTableHeader extends StatelessWidget {
  const _PreviewTableHeader();

  @override
  Widget build(BuildContext context) => Container(
    color: const Color(0xFF343437),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    child: const Row(
      children: [
        Expanded(flex: 6, child: Text('INSUMO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800))),
        Expanded(flex: 2, child: Text('CANTIDAD', textAlign: TextAlign.right, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800))),
        Expanded(flex: 2, child: Text('SOLES', textAlign: TextAlign.right, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800))),
      ],
    ),
  );
}

class _PreviewTableRow extends StatelessWidget {
  const _PreviewTableRow({required this.row});
  final List<String> row;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFE3E3E5)))),
    child: Row(
      children: [
        Expanded(flex: 6, child: Text(row[0])),
        Expanded(flex: 2, child: Text(row[1], textAlign: TextAlign.right)),
        Expanded(flex: 2, child: Text(row[2], textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w700))),
      ],
    ),
  );
}

class _Signature extends StatelessWidget {
  const _Signature({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.only(top: 6),
    decoration: const BoxDecoration(border: Border(top: BorderSide(color: Colors.black54))),
    child: Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: Colors.black54)),
  );
}
