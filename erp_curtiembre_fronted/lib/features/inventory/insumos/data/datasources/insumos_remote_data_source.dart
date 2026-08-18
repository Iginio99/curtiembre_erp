import 'package:dio/dio.dart';
import 'package:erp_curtiembre_fronted/core/logging/app_talker.dart';
import 'package:erp_curtiembre_fronted/core/network/api_exception.dart';
import 'package:erp_curtiembre_fronted/features/inventory/insumos/data/models/insumo_record_model.dart';
import 'package:erp_curtiembre_fronted/features/inventory/insumos/data/models/unidad_medida_option_model.dart';
import 'package:talker_flutter/talker_flutter.dart';

class InsumosRemoteDataSource {
  InsumosRemoteDataSource(this._dio, this._talker);

  final Dio _dio;
  final Talker _talker;

  Future<List<InsumoRecordModel>> listInsumos({
    String? texto,
    String? tipoBien,
    int? unidadMedidaId,
    bool? activo,
    bool? stockBajo,
  }) async {
    const path = '/api/inventario/insumos';

    try {
      final queryParameters = <String, Object>{};
      if (texto != null && texto.trim().isNotEmpty) {
        queryParameters['texto'] = texto.trim();
      }
      if (tipoBien != null && tipoBien.trim().isNotEmpty) {
        queryParameters['tipoBien'] = tipoBien;
      }
      if (unidadMedidaId != null) {
        queryParameters['unidadMedidaId'] = unidadMedidaId;
      }
      if (activo != null) {
        queryParameters['activo'] = activo;
      }
      if (stockBajo != null) {
        queryParameters['stockBajo'] = stockBajo;
      }

      _talker.dataSource(
        'GET $path con filtros texto=${_describeText(texto)}, tipoBien=${_describeType(tipoBien)}, unidadMedidaId=$unidadMedidaId, activo=${_describeBool(activo)}, stockBajo=${_describeBool(stockBajo)}',
      );
      final response = await _dio.get<List<dynamic>>(
        path,
        queryParameters: queryParameters,
      );
      final items = response.data ?? const [];
      _talker.dataSource('GET $path completado con ${items.length} insumos.');

      return items
          .map(
            (item) => InsumoRecordModel.fromJson(item as Map<String, dynamic>),
          )
          .toList(growable: false);
    } on DioException catch (exception) {
      throw _mapAndLogDioException(exception, operation: 'GET $path');
    }
  }

  Future<InsumoRecordModel> getInsumo(int id) async {
    final path = '/api/inventario/insumos/$id';

    try {
      _talker.dataSource('GET $path');
      final response = await _dio.get<Map<String, dynamic>>(path);
      _talker.dataSource('GET $path completado.');
      return InsumoRecordModel.fromJson(response.data!);
    } on DioException catch (exception) {
      throw _mapAndLogDioException(exception, operation: 'GET $path');
    }
  }

  Future<InsumoRecordModel> createInsumo({
    required String codigo,
    required String nombre,
    required String tipoBien,
    String? presentacion,
    required int unidadMedidaId,
    required double stockMinimo,
    required bool requiereLote,
  }) async {
    const path = '/api/inventario/insumos';

    try {
      _talker.dataSource(
        'POST $path para codigo=${_describeText(codigo)}, nombre=${_describeText(nombre)}, tipoBien=$tipoBien, unidadMedidaId=$unidadMedidaId, stockMinimo=$stockMinimo, requiereLote=$requiereLote',
      );
      final response = await _dio.post<Map<String, dynamic>>(
        path,
        data: {
          'codigo': codigo,
          'nombre': nombre,
          'tipoBien': tipoBien,
          'presentacion': presentacion,
          'unidadMedidaId': unidadMedidaId,
          'stockMinimo': stockMinimo,
          'requiereLote': requiereLote,
        },
      );

      _talker.dataSource('POST $path completado.');
      return InsumoRecordModel.fromJson(response.data!);
    } on DioException catch (exception) {
      throw _mapAndLogDioException(exception, operation: 'POST $path');
    }
  }

  Future<InsumoRecordModel> updateInsumo({
    required int id,
    required String codigo,
    required String nombre,
    required String tipoBien,
    String? presentacion,
    required int unidadMedidaId,
    required double stockMinimo,
    required bool requiereLote,
  }) async {
    final path = '/api/inventario/insumos/$id';

    try {
      _talker.dataSource(
        'PUT $path para codigo=${_describeText(codigo)}, nombre=${_describeText(nombre)}, tipoBien=$tipoBien, unidadMedidaId=$unidadMedidaId, stockMinimo=$stockMinimo, requiereLote=$requiereLote',
      );
      final response = await _dio.put<Map<String, dynamic>>(
        path,
        data: {
          'codigo': codigo,
          'nombre': nombre,
          'tipoBien': tipoBien,
          'presentacion': presentacion,
          'unidadMedidaId': unidadMedidaId,
          'stockMinimo': stockMinimo,
          'requiereLote': requiereLote,
        },
      );

      _talker.dataSource('PUT $path completado.');
      return InsumoRecordModel.fromJson(response.data!);
    } on DioException catch (exception) {
      throw _mapAndLogDioException(exception, operation: 'PUT $path');
    }
  }

  Future<InsumoRecordModel> setInsumoActive({
    required int id,
    required bool active,
  }) async {
    final path = active
        ? '/api/inventario/insumos/$id/activar'
        : '/api/inventario/insumos/$id/inactivar';

    try {
      _talker.dataSource('POST $path');
      final response = await _dio.post<Map<String, dynamic>>(path);
      _talker.dataSource('POST $path completado.');
      return InsumoRecordModel.fromJson(response.data!);
    } on DioException catch (exception) {
      throw _mapAndLogDioException(exception, operation: 'POST $path');
    }
  }

  Future<List<UnidadMedidaOptionModel>> listActiveUnits() async {
    const path = '/api/configuracion/catalogos/unidades-medida/activas';

    try {
      _talker.dataSource('GET $path');
      final response = await _dio.get<List<dynamic>>(path);
      final items = response.data ?? const [];
      _talker.dataSource(
        'GET $path completado con ${items.length} unidades de medida activas.',
      );

      return items
          .map(
            (item) =>
                UnidadMedidaOptionModel.fromJson(item as Map<String, dynamic>),
          )
          .toList(growable: false);
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
