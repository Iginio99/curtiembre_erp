import 'package:erp_curtiembre_fronted/core/logging/app_talker.dart';
import 'package:erp_curtiembre_fronted/features/inventory/stock/data/datasources/stock_remote_data_source.dart';
import 'package:erp_curtiembre_fronted/features/inventory/stock/domain/entities/stock_record.dart';
import 'package:erp_curtiembre_fronted/features/inventory/stock/domain/repositories/stock_repository.dart';
import 'package:talker_flutter/talker_flutter.dart';

class StockRepositoryImpl implements StockRepository {
  StockRepositoryImpl(this._remoteDataSource, this._talker);

  final StockRemoteDataSource _remoteDataSource;
  final Talker _talker;

  @override
  Future<List<StockRecord>> listStock({
    String? texto,
    String? tipoBien,
    bool? stockBajo,
    bool? activo,
  }) async {
    _talker.repository(
      'Consultando stock con filtros texto=${_describeText(texto)}, tipoBien=${_describeType(tipoBien)}, stockBajo=${_describeBool(stockBajo)}, activo=${_describeBool(activo)}.',
    );
    final items = await _remoteDataSource.listStock(
      texto: texto,
      tipoBien: tipoBien,
      stockBajo: stockBajo,
      activo: activo,
    );
    _talker.repository(
      'Se obtuvieron ${items.length} registros de stock para la bandeja.',
    );
    return items.map((item) => item.toEntity()).toList(growable: false);
  }

  @override
  Future<List<StockRecord>> listLowStock({
    String? texto,
    String? tipoBien,
    bool? activo,
  }) async {
    _talker.repository(
      'Consultando stock bajo con filtros texto=${_describeText(texto)}, tipoBien=${_describeType(tipoBien)}, activo=${_describeBool(activo)}.',
    );
    final items = await _remoteDataSource.listLowStock(
      texto: texto,
      tipoBien: tipoBien,
      activo: activo,
    );
    _talker.repository(
      'Se obtuvieron ${items.length} registros de stock bajo.',
    );
    return items.map((item) => item.toEntity()).toList(growable: false);
  }

  @override
  Future<StockRecord> getStockByInsumoId(int insumoId) async {
    _talker.repository(
      'Consultando detalle de stock para el insumo $insumoId.',
    );
    final item = await _remoteDataSource.getStockByInsumoId(insumoId);
    _talker.repository(
      'Detalle de stock para el insumo $insumoId obtenido correctamente.',
    );
    return item.toEntity();
  }

  String _describeText(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return 'vacio';
    }

    return '${normalized.length} caracteres';
  }

  String _describeType(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return 'vacio';
    }

    return normalized;
  }

  String _describeBool(bool? value) {
    if (value == null) {
      return 'sin-filtro';
    }

    return value.toString();
  }
}
