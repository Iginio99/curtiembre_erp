import 'package:dio/dio.dart';
import 'package:erp_curtiembre_fronted/core/logging/app_talker.dart';
import 'package:erp_curtiembre_fronted/core/network/api_exception.dart';
import 'package:erp_curtiembre_fronted/features/production/clientes/data/models/cliente_option_model.dart';
import 'package:erp_curtiembre_fronted/features/production/clientes/data/models/cliente_record_model.dart';
import 'package:talker_flutter/talker_flutter.dart';

class ClientesRemoteDataSource {
  ClientesRemoteDataSource(this._dio, this._talker);

  final Dio _dio;
  final Talker _talker;

  Future<List<ClienteRecordModel>> listClientes({
    String? texto,
    bool? activo,
  }) async {
    const path = '/api/produccion/clientes';

    try {
      final queryParameters = <String, dynamic>{};
      if (texto != null && texto.trim().isNotEmpty) {
        queryParameters['texto'] = texto.trim();
      }
      if (activo != null) {
        queryParameters['activo'] = activo;
      }

      _talker.dataSource(
        'GET $path con filtros texto=${_describeText(texto)}, activo=$activo',
      );
      final response = await _dio.get<List<dynamic>>(
        path,
        queryParameters: queryParameters,
      );
      final items = response.data ?? const [];
      _talker.dataSource('GET $path completado con ${items.length} clientes.');

      return items
          .map(
            (item) => ClienteRecordModel.fromJson(item as Map<String, dynamic>),
          )
          .toList(growable: false);
    } on DioException catch (exception) {
      throw _mapAndLogDioException(exception, operation: 'GET $path');
    }
  }

  Future<ClienteRecordModel> getCliente(int id) async {
    final path = '/api/produccion/clientes/$id';

    try {
      _talker.dataSource('GET $path');
      final response = await _dio.get<Map<String, dynamic>>(path);
      _talker.dataSource('GET $path completado.');
      return ClienteRecordModel.fromJson(response.data!);
    } on DioException catch (exception) {
      throw _mapAndLogDioException(exception, operation: 'GET $path');
    }
  }

  Future<List<ClienteOptionModel>> listActiveClientes() async {
    const path = '/api/produccion/catalogos/clientes/activos';

    try {
      _talker.dataSource('GET $path');
      final response = await _dio.get<List<dynamic>>(path);
      final items = response.data ?? const [];
      _talker.dataSource(
        'GET $path completado con ${items.length} clientes activos.',
      );
      return items
          .map(
            (item) => ClienteOptionModel.fromJson(item as Map<String, dynamic>),
          )
          .toList(growable: false);
    } on DioException catch (exception) {
      throw _mapAndLogDioException(exception, operation: 'GET $path');
    }
  }

  Future<ClienteRecordModel> createCliente({
    required String rucDocumento,
    required String razonSocial,
    String? direccion,
    String? celular,
    String? correo,
    String? contacto,
  }) async {
    const path = '/api/produccion/clientes';

    try {
      _talker.dataSource(
        'POST $path para razonSocial=$razonSocial, rucDocumento=${_describeIdentifier(rucDocumento)}',
      );
      final response = await _dio.post<Map<String, dynamic>>(
        path,
        data: {
          'rucDocumento': rucDocumento,
          'razonSocial': razonSocial,
          'direccion': direccion,
          'celular': celular,
          'correo': correo,
          'contacto': contacto,
        },
      );
      _talker.dataSource(
        'POST $path completado para razonSocial=$razonSocial.',
      );
      return ClienteRecordModel.fromJson(response.data!);
    } on DioException catch (exception) {
      throw _mapAndLogDioException(exception, operation: 'POST $path');
    }
  }

  Future<ClienteRecordModel> updateCliente({
    required int id,
    required String rucDocumento,
    required String razonSocial,
    String? direccion,
    String? celular,
    String? correo,
    String? contacto,
  }) async {
    final path = '/api/produccion/clientes/$id';

    try {
      _talker.dataSource(
        'PUT $path para razonSocial=$razonSocial, rucDocumento=${_describeIdentifier(rucDocumento)}',
      );
      final response = await _dio.put<Map<String, dynamic>>(
        path,
        data: {
          'rucDocumento': rucDocumento,
          'razonSocial': razonSocial,
          'direccion': direccion,
          'celular': celular,
          'correo': correo,
          'contacto': contacto,
        },
      );
      _talker.dataSource('PUT $path completado.');
      return ClienteRecordModel.fromJson(response.data!);
    } on DioException catch (exception) {
      throw _mapAndLogDioException(exception, operation: 'PUT $path');
    }
  }

  Future<ClienteRecordModel> setClienteActive({
    required int id,
    required bool active,
  }) async {
    final path = active
        ? '/api/produccion/clientes/$id/activar'
        : '/api/produccion/clientes/$id/inactivar';

    try {
      _talker.dataSource('POST $path');
      final response = await _dio.post<Map<String, dynamic>>(path);
      _talker.dataSource('POST $path completado.');
      return ClienteRecordModel.fromJson(response.data!);
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

  String _describeText(String? texto) {
    final normalized = texto?.trim();
    if (normalized == null || normalized.isEmpty) {
      return 'vacio';
    }

    return '${normalized.length} caracteres';
  }

  String _describeIdentifier(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      return 'vacio';
    }

    return '${normalized.length} caracteres';
  }
}
