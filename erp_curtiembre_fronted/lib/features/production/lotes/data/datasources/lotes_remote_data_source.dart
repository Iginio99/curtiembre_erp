import 'package:dio/dio.dart';
import 'package:erp_curtiembre_fronted/core/logging/app_talker.dart';
import 'package:erp_curtiembre_fronted/core/network/api_exception.dart';
import 'package:erp_curtiembre_fronted/features/production/clientes/data/models/cliente_option_model.dart';
import 'package:erp_curtiembre_fronted/features/production/lotes/data/models/lote_disponibilidad_model.dart';
import 'package:erp_curtiembre_fronted/features/production/lotes/data/models/lote_record_model.dart';
import 'package:erp_curtiembre_fronted/features/production/lotes/data/models/tipo_piel_option_model.dart';
import 'package:talker_flutter/talker_flutter.dart';

class LotesRemoteDataSource {
  LotesRemoteDataSource(this._dio, this._talker);

  final Dio _dio;
  final Talker _talker;

  Future<List<LoteRecordModel>> listLotes({
    String? texto,
    int? clienteId,
    int? tipoPielId,
    String? estado,
  }) async {
    const path = '/api/produccion/lotes';

    try {
      final queryParameters = <String, dynamic>{};
      if (texto != null && texto.trim().isNotEmpty) {
        queryParameters['texto'] = texto.trim();
      }
      if (clienteId != null) {
        queryParameters['clienteId'] = clienteId;
      }
      if (tipoPielId != null) {
        queryParameters['tipoPielId'] = tipoPielId;
      }
      if (estado != null && estado.trim().isNotEmpty) {
        queryParameters['estado'] = estado.trim();
      }

      _talker.dataSource(
        'GET $path con filtros texto=${_describeText(texto)}, clienteId=$clienteId, tipoPielId=$tipoPielId, estado=${_describeState(estado)}',
      );
      final response = await _dio.get<List<dynamic>>(
        path,
        queryParameters: queryParameters,
      );
      final items = response.data ?? const [];
      _talker.dataSource('GET $path completado con ${items.length} lotes.');
      return items
          .map((item) => LoteRecordModel.fromJson(item as Map<String, dynamic>))
          .toList(growable: false);
    } on DioException catch (exception) {
      throw _mapAndLogDioException(exception, operation: 'GET $path');
    }
  }

  Future<LoteRecordModel> getLote(int id) async {
    final path = '/api/produccion/lotes/$id';

    try {
      _talker.dataSource('GET $path');
      final response = await _dio.get<Map<String, dynamic>>(path);
      _talker.dataSource('GET $path completado.');
      return LoteRecordModel.fromJson(response.data!);
    } on DioException catch (exception) {
      throw _mapAndLogDioException(exception, operation: 'GET $path');
    }
  }

  Future<LoteDisponibilidadModel> getDisponibilidad(int id) async {
    final path = '/api/produccion/lotes/$id/disponibilidad';

    try {
      _talker.dataSource('GET $path');
      final response = await _dio.get<Map<String, dynamic>>(path);
      _talker.dataSource('GET $path completado.');
      return LoteDisponibilidadModel.fromJson(response.data!);
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

  Future<List<TipoPielOptionModel>> listActiveTiposPiel() async {
    const path = '/api/configuracion/catalogos/tipos-piel/activos';

    try {
      _talker.dataSource('GET $path');
      final response = await _dio.get<List<dynamic>>(path);
      final items = response.data ?? const [];
      _talker.dataSource(
        'GET $path completado con ${items.length} tipos de piel activos.',
      );
      return items
          .map(
            (item) =>
                TipoPielOptionModel.fromJson(item as Map<String, dynamic>),
          )
          .toList(growable: false);
    } on DioException catch (exception) {
      throw _mapAndLogDioException(exception, operation: 'GET $path');
    }
  }

  Future<LoteRecordModel> createLote({
    required int clienteId,
    required int tipoPielId,
    required DateTime fechaIngreso,
    required double cantidadPielesInicial,
    required bool clienteTraeLote,
    required double costoPielesTotal,
    String? observacion,
  }) async {
    const path = '/api/produccion/lotes';

    try {
      _talker.dataSource(
        'POST $path para clienteId=$clienteId, tipoPielId=$tipoPielId, cantidadPielesInicial=$cantidadPielesInicial, clienteTraeLote=$clienteTraeLote',
      );
      final response = await _dio.post<Map<String, dynamic>>(
        path,
        data: {
          'clienteId': clienteId,
          'tipoPielId': tipoPielId,
          'fechaIngreso': fechaIngreso.toIso8601String(),
          'cantidadPielesInicial': cantidadPielesInicial,
          'clienteTraeLote': clienteTraeLote,
          'costoPielesTotal': costoPielesTotal,
          'observacion': observacion,
        },
      );
      _talker.dataSource('POST $path completado para clienteId=$clienteId.');
      return LoteRecordModel.fromJson(response.data!);
    } on DioException catch (exception) {
      throw _mapAndLogDioException(exception, operation: 'POST $path');
    }
  }

  Future<LoteRecordModel> updateLote({
    required int id,
    required int clienteId,
    required int tipoPielId,
    required DateTime fechaIngreso,
    required double cantidadPielesInicial,
    required bool clienteTraeLote,
    required double costoPielesTotal,
    String? observacion,
  }) async {
    final path = '/api/produccion/lotes/$id';

    try {
      _talker.dataSource(
        'PUT $path para clienteId=$clienteId, tipoPielId=$tipoPielId, cantidadPielesInicial=$cantidadPielesInicial, clienteTraeLote=$clienteTraeLote',
      );
      final response = await _dio.put<Map<String, dynamic>>(
        path,
        data: {
          'clienteId': clienteId,
          'tipoPielId': tipoPielId,
          'fechaIngreso': fechaIngreso.toIso8601String(),
          'cantidadPielesInicial': cantidadPielesInicial,
          'clienteTraeLote': clienteTraeLote,
          'costoPielesTotal': costoPielesTotal,
          'observacion': observacion,
        },
      );
      _talker.dataSource('PUT $path completado.');
      return LoteRecordModel.fromJson(response.data!);
    } on DioException catch (exception) {
      throw _mapAndLogDioException(exception, operation: 'PUT $path');
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

  String _describeState(String? estado) {
    final normalized = estado?.trim();
    if (normalized == null || normalized.isEmpty) {
      return 'vacio';
    }

    return normalized;
  }
}
