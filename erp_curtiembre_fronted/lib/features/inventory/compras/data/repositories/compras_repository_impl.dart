import 'package:erp_curtiembre_fronted/core/logging/app_talker.dart';
import 'package:erp_curtiembre_fronted/features/inventory/compras/data/datasources/compras_remote_data_source.dart';
import 'package:erp_curtiembre_fronted/features/inventory/compras/domain/entities/orden_compra_detail.dart';
import 'package:erp_curtiembre_fronted/features/inventory/compras/domain/entities/orden_compra_record.dart';
import 'package:erp_curtiembre_fronted/features/inventory/compras/domain/repositories/compras_repository.dart';
import 'package:erp_curtiembre_fronted/features/inventory/shared/domain/entities/insumo_lookup.dart';
import 'package:erp_curtiembre_fronted/features/inventory/shared/domain/entities/proveedor_lookup.dart';
import 'package:talker_flutter/talker_flutter.dart';

class ComprasRepositoryImpl implements ComprasRepository {
  ComprasRepositoryImpl(this._remoteDataSource, this._talker);

  final ComprasRemoteDataSource _remoteDataSource;
  final Talker _talker;

  @override
  Future<List<ProveedorLookup>> listActiveSuppliers() async {
    _talker.repository(
      'Consultando proveedores activos para formularios de compras.',
    );
    final items = await _remoteDataSource.listActiveSuppliers();
    _talker.repository(
      'Se obtuvieron ${items.length} proveedores activos para compras.',
    );
    return items.map((item) => item.toEntity()).toList(growable: false);
  }

  @override
  Future<List<InsumoLookup>> listActiveInsumos() async {
    _talker.repository(
      'Consultando insumos activos para formularios de compras.',
    );
    final items = await _remoteDataSource.listActiveInsumos();
    _talker.repository(
      'Se obtuvieron ${items.length} insumos activos para compras.',
    );
    return items.map((item) => item.toEntity()).toList(growable: false);
  }

  @override
  Future<List<OrdenCompraRecord>> listOrders({
    String? texto,
    int? proveedorId,
    String? estado,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
  }) async {
    _talker.repository(
      'Consultando ordenes de compra con filtros texto=${_describeText(texto)}, proveedorId=$proveedorId, estado=${_describeState(estado)}, fechaDesde=${_describeDate(fechaDesde)}, fechaHasta=${_describeDate(fechaHasta)}.',
    );
    final items = await _remoteDataSource.listOrders(
      texto: texto,
      proveedorId: proveedorId,
      estado: estado,
      fechaDesde: fechaDesde,
      fechaHasta: fechaHasta,
    );
    _talker.repository(
      'Se obtuvieron ${items.length} ordenes de compra para la bandeja.',
    );
    return items.map((item) => item.toEntity()).toList(growable: false);
  }

  @override
  Future<OrdenCompraDetail> getOrderDetail(int id) async {
    _talker.repository('Consultando detalle de la orden de compra $id.');
    final detail = await _remoteDataSource.getOrderDetail(id);
    _talker.repository(
      'Detalle de la orden de compra $id obtenido correctamente.',
    );
    return detail.toEntity();
  }

  @override
  Future<OrdenCompraDetail> createOrder({
    required int proveedorId,
    required DateTime fechaEmision,
    String? observacion,
    required List<CreateOrdenCompraDetalleInput> detalles,
  }) async {
    _talker.repository(
      'Creando orden de compra para proveedorId=$proveedorId con ${detalles.length} detalles.',
    );
    final detail = await _remoteDataSource.createOrder(
      proveedorId: proveedorId,
      fechaEmision: fechaEmision,
      observacion: observacion,
      detalles: detalles,
    );
    _talker.repository(
      'Orden de compra creada correctamente con id=${detail.id}.',
    );
    return detail.toEntity();
  }

  @override
  Future<String> approveOrder(int id) async {
    _talker.repository(
      'Aprobando la orden de compra $id.',
      logLevel: LogLevel.warning,
    );
    final message = await _remoteDataSource.approveOrder(id);
    _talker.repository(
      'Orden de compra $id aprobada correctamente.',
      logLevel: LogLevel.warning,
    );
    return message;
  }

  @override
  Future<String> rejectOrder(int id, String motivo) async {
    _talker.repository(
      'Rechazando la orden de compra $id con motivo=${_describeText(motivo)}.',
      logLevel: LogLevel.warning,
    );
    final message = await _remoteDataSource.rejectOrder(id, motivo);
    _talker.repository(
      'Orden de compra $id rechazada correctamente.',
      logLevel: LogLevel.warning,
    );
    return message;
  }

  @override
  Future<String> cancelOrder(int id, String motivo) async {
    _talker.repository(
      'Anulando la orden de compra $id con motivo=${_describeText(motivo)}.',
      logLevel: LogLevel.warning,
    );
    final message = await _remoteDataSource.cancelOrder(id, motivo);
    _talker.repository(
      'Orden de compra $id anulada correctamente.',
      logLevel: LogLevel.warning,
    );
    return message;
  }

  String _describeText(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return 'vacio';
    }

    return '${normalized.length} caracteres';
  }

  String _describeState(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return 'vacio';
    }

    return normalized;
  }

  String _describeDate(DateTime? value) {
    if (value == null) {
      return 'sin-fecha';
    }

    return value.toIso8601String();
  }
}
