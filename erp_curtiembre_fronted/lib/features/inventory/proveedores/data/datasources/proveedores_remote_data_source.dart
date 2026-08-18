import 'package:dio/dio.dart';
import 'package:erp_curtiembre_fronted/core/logging/app_talker.dart';
import 'package:erp_curtiembre_fronted/core/network/api_exception.dart';
import 'package:erp_curtiembre_fronted/features/inventory/proveedores/data/models/proveedor_record_model.dart';
import 'package:talker_flutter/talker_flutter.dart';

class ProveedoresRemoteDataSource {
  ProveedoresRemoteDataSource(this._dio, this._talker);

  final Dio _dio;
  final Talker _talker;

  Future<List<ProveedorRecordModel>> listProveedores({
    String? texto,
    bool? activo,
  }) async {
    const path = '/api/inventario/proveedores';

    try {
      _talker.dataSource(
        'GET $path con filtros texto=${_describeText(texto)}, activo=${_describeBool(activo)}',
      );
      final response = await _dio.get<List<dynamic>>(
        path,
        queryParameters: {
          if (texto != null && texto.trim().isNotEmpty) 'texto': texto.trim(),
          'activo': activo,
        },
      );
      final items = response.data ?? const [];
      _talker.dataSource(
        'GET $path completado con ${items.length} proveedores.',
      );

      return items
          .map(
            (item) =>
                ProveedorRecordModel.fromJson(item as Map<String, dynamic>),
          )
          .toList(growable: false);
    } on DioException catch (exception) {
      throw _mapAndLogDioException(exception, operation: 'GET $path');
    }
  }

  Future<ProveedorRecordModel> getProveedor(int id) async {
    final path = '/api/inventario/proveedores/$id';

    try {
      _talker.dataSource('GET $path');
      final response = await _dio.get<Map<String, dynamic>>(path);
      _talker.dataSource('GET $path completado.');
      return ProveedorRecordModel.fromJson(response.data!);
    } on DioException catch (exception) {
      throw _mapAndLogDioException(exception, operation: 'GET $path');
    }
  }

  Future<ProveedorRecordModel> createProveedor({
    required String rucDocumento,
    required String razonSocial,
    String? direccion,
    String? telefono,
    String? correo,
    String? contacto,
  }) async {
    const path = '/api/inventario/proveedores';

    try {
      _talker.dataSource(
        'POST $path para ruc=${_describeText(rucDocumento)}, razonSocial=${_describeText(razonSocial)}, direccion=${_describeText(direccion)}, telefono=${_describeText(telefono)}, correo=${_describeText(correo)}, contacto=${_describeText(contacto)}',
      );
      final response = await _dio.post<Map<String, dynamic>>(
        path,
        data: {
          'rucDocumento': rucDocumento,
          'razonSocial': razonSocial,
          'direccion': direccion,
          'telefono': telefono,
          'correo': correo,
          'contacto': contacto,
        },
      );

      _talker.dataSource('POST $path completado.');
      return ProveedorRecordModel.fromJson(response.data!);
    } on DioException catch (exception) {
      throw _mapAndLogDioException(exception, operation: 'POST $path');
    }
  }

  Future<ProveedorRecordModel> updateProveedor({
    required int id,
    required String rucDocumento,
    required String razonSocial,
    String? direccion,
    String? telefono,
    String? correo,
    String? contacto,
  }) async {
    final path = '/api/inventario/proveedores/$id';

    try {
      _talker.dataSource(
        'PUT $path para ruc=${_describeText(rucDocumento)}, razonSocial=${_describeText(razonSocial)}, direccion=${_describeText(direccion)}, telefono=${_describeText(telefono)}, correo=${_describeText(correo)}, contacto=${_describeText(contacto)}',
      );
      final response = await _dio.put<Map<String, dynamic>>(
        path,
        data: {
          'rucDocumento': rucDocumento,
          'razonSocial': razonSocial,
          'direccion': direccion,
          'telefono': telefono,
          'correo': correo,
          'contacto': contacto,
        },
      );

      _talker.dataSource('PUT $path completado.');
      return ProveedorRecordModel.fromJson(response.data!);
    } on DioException catch (exception) {
      throw _mapAndLogDioException(exception, operation: 'PUT $path');
    }
  }

  Future<ProveedorRecordModel> setProveedorActive({
    required int id,
    required bool active,
  }) async {
    final path = active
        ? '/api/inventario/proveedores/$id/activar'
        : '/api/inventario/proveedores/$id/inactivar';

    try {
      _talker.dataSource('POST $path');
      final response = await _dio.post<Map<String, dynamic>>(path);
      _talker.dataSource('POST $path completado.');
      return ProveedorRecordModel.fromJson(response.data!);
    } on DioException catch (exception) {
      throw _mapAndLogDioException(exception, operation: 'POST $path');
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

  String _describeBool(bool? value) {
    if (value == null) {
      return 'sin-filtro';
    }

    return value.toString();
  }
}
