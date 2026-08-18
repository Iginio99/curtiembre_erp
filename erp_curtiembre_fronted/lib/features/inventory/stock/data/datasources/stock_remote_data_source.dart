import 'package:dio/dio.dart';
import 'package:erp_curtiembre_fronted/core/logging/app_talker.dart';
import 'package:erp_curtiembre_fronted/core/network/api_exception.dart';
import 'package:erp_curtiembre_fronted/features/inventory/stock/data/models/stock_record_model.dart';
import 'package:talker_flutter/talker_flutter.dart';

class StockRemoteDataSource {
  StockRemoteDataSource(this._dio, this._talker);

  final Dio _dio;
  final Talker _talker;

  Future<List<StockRecordModel>> listStock({
    String? texto,
    String? tipoBien,
    bool? stockBajo,
    bool? activo,
  }) async {
    const path = '/api/inventario/stock';

    try {
      final queryParameters = <String, Object>{};
      if (texto != null && texto.trim().isNotEmpty) {
        queryParameters['texto'] = texto.trim();
      }
      if (tipoBien != null && tipoBien.trim().isNotEmpty) {
        queryParameters['tipoBien'] = tipoBien;
      }
      if (stockBajo != null) {
        queryParameters['stockBajo'] = stockBajo;
      }
      if (activo != null) {
        queryParameters['activo'] = activo;
      }

      _talker.dataSource(
        'GET $path con filtros texto=${_describeText(texto)}, tipoBien=${_describeType(tipoBien)}, stockBajo=${_describeBool(stockBajo)}, activo=${_describeBool(activo)}',
      );
      final response = await _dio.get<List<dynamic>>(
        path,
        queryParameters: queryParameters,
      );
      final items = response.data ?? const [];
      _talker.dataSource('GET $path completado con ${items.length} registros.');
      return items
          .map(
            (item) => StockRecordModel.fromJson(item as Map<String, dynamic>),
          )
          .toList(growable: false);
    } on DioException catch (exception) {
      throw _mapAndLogDioException(exception, operation: 'GET $path');
    }
  }

  Future<List<StockRecordModel>> listLowStock({
    String? texto,
    String? tipoBien,
    bool? activo,
  }) async {
    const path = '/api/inventario/stock/bajo';

    try {
      final queryParameters = <String, Object>{};
      if (texto != null && texto.trim().isNotEmpty) {
        queryParameters['texto'] = texto.trim();
      }
      if (tipoBien != null && tipoBien.trim().isNotEmpty) {
        queryParameters['tipoBien'] = tipoBien;
      }
      if (activo != null) {
        queryParameters['activo'] = activo;
      }

      _talker.dataSource(
        'GET $path con filtros texto=${_describeText(texto)}, tipoBien=${_describeType(tipoBien)}, activo=${_describeBool(activo)}',
      );
      final response = await _dio.get<List<dynamic>>(
        path,
        queryParameters: queryParameters,
      );
      final items = response.data ?? const [];
      _talker.dataSource(
        'GET $path completado con ${items.length} registros de stock bajo.',
      );
      return items
          .map(
            (item) => StockRecordModel.fromJson(item as Map<String, dynamic>),
          )
          .toList(growable: false);
    } on DioException catch (exception) {
      throw _mapAndLogDioException(exception, operation: 'GET $path');
    }
  }

  Future<StockRecordModel> getStockByInsumoId(int insumoId) async {
    final path = '/api/inventario/stock/$insumoId';

    try {
      _talker.dataSource('GET $path');
      final response = await _dio.get<Map<String, dynamic>>(path);
      _talker.dataSource('GET $path completado.');
      return StockRecordModel.fromJson(response.data!);
    } on DioException catch (exception) {
      throw _mapAndLogDioException(exception, operation: 'GET $path');
    }
  }

  ApiException _mapAndLogDioException(
    DioException exception, {
    required String operation,
  }) {
    final apiException = ApiException.fromDioException(exception);
    _talker.dataSource(
      '$operation fallo con status=${apiException.statusCode ?? 'sin-status'} y mensaje="${apiException.message}"',
      logLevel: LogLevel.error,
      exception: apiException,
      stackTrace: exception.stackTrace,
    );
    return apiException;
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
