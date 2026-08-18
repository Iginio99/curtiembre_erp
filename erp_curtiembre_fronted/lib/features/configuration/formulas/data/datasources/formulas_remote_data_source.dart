import 'package:dio/dio.dart';
import 'package:erp_curtiembre_fronted/core/network/api_exception.dart';
import 'package:erp_curtiembre_fronted/features/configuration/formulas/data/models/formula_record_model.dart';
import 'package:erp_curtiembre_fronted/features/inventory/shared/data/models/insumo_lookup_model.dart';

class FormulasRemoteDataSource {
  FormulasRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<FormulaRecordModel>> listFormulas({
    String? texto,
    int? procesoProductivoId,
    bool? activo,
  }) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '/api/configuracion/formulas',
        queryParameters: {
          if (texto != null && texto.trim().isNotEmpty) 'texto': texto.trim(),
          ...?procesoProductivoId == null
              ? null
              : <String, dynamic>{'procesoProductivoId': procesoProductivoId},
          ...?activo == null ? null : <String, dynamic>{'activo': activo},
        },
      );

      final items = response.data ?? const [];
      return items
          .map((item) => FormulaRecordModel.fromJson(item as Map<String, dynamic>))
          .toList(growable: false);
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }

  Future<FormulaRecordModel> getFormula(int id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/api/configuracion/formulas/$id');
      return FormulaRecordModel.fromJson(response.data!);
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }

  Future<FormulaRecordModel> createFormula({
    required String codigo,
    required String nombre,
    required int procesoProductivoId,
    String? descripcion,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/configuracion/formulas',
        data: {
          'codigo': codigo,
          'nombre': nombre,
          'procesoProductivoId': procesoProductivoId,
          'descripcion': descripcion,
        },
      );
      return FormulaRecordModel.fromJson(response.data!);
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }

  Future<FormulaRecordModel> updateFormula({
    required int id,
    required String codigo,
    required String nombre,
    required int procesoProductivoId,
    String? descripcion,
  }) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '/api/configuracion/formulas/$id',
        data: {
          'codigo': codigo,
          'nombre': nombre,
          'procesoProductivoId': procesoProductivoId,
          'descripcion': descripcion,
        },
      );
      return FormulaRecordModel.fromJson(response.data!);
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }

  Future<FormulaRecordModel> setFormulaActive({
    required int id,
    required bool active,
  }) async {
    try {
      final path = active
          ? '/api/configuracion/formulas/$id/activar'
          : '/api/configuracion/formulas/$id/inactivar';
      final response = await _dio.post<Map<String, dynamic>>(path);
      return FormulaRecordModel.fromJson(response.data!);
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }

  Future<List<FormulaVersionRecordModel>> listVersions(int formulaId) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '/api/configuracion/formulas/$formulaId/versiones',
      );
      final items = response.data ?? const [];
      return items
          .map((item) => FormulaVersionRecordModel.fromJson(item as Map<String, dynamic>))
          .toList(growable: false);
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }

  Future<FormulaVersionRecordModel> getVersion(int id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/configuracion/formula-versiones/$id',
      );
      return FormulaVersionRecordModel.fromJson(response.data!);
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }

  Future<FormulaVersionRecordModel> createVersion({
    required int formulaId,
    required int numeroVersion,
    required DateTime fechaInicioVigencia,
    DateTime? fechaFinVigencia,
    String? observacion,
    int? clonarDesdeVersionId,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/configuracion/formulas/$formulaId/versiones',
        data: {
          'numeroVersion': numeroVersion,
          'fechaInicioVigencia': fechaInicioVigencia.toIso8601String(),
          'fechaFinVigencia': fechaFinVigencia?.toIso8601String(),
          'observacion': observacion,
          'clonarDesdeVersionId': clonarDesdeVersionId,
        },
      );
      return FormulaVersionRecordModel.fromJson(response.data!);
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }

  Future<FormulaVersionRecordModel> updateVersion({
    required int id,
    required DateTime fechaInicioVigencia,
    DateTime? fechaFinVigencia,
    String? observacion,
  }) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '/api/configuracion/formula-versiones/$id',
        data: {
          'fechaInicioVigencia': fechaInicioVigencia.toIso8601String(),
          'fechaFinVigencia': fechaFinVigencia?.toIso8601String(),
          'observacion': observacion,
        },
      );
      return FormulaVersionRecordModel.fromJson(response.data!);
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }

  Future<FormulaVersionRecordModel> activateVersion(int id) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/configuracion/formula-versiones/$id/activar-vigencia',
      );
      return FormulaVersionRecordModel.fromJson(response.data!);
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }

  Future<FormulaDetailRecordModel> createDetail({
    required int versionId,
    required int insumoId,
    required double porcentaje,
    String? observacion,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/configuracion/formula-versiones/$versionId/detalles',
        data: {
          'insumoId': insumoId,
          'porcentaje': porcentaje,
          'observacion': observacion,
        },
      );
      return FormulaDetailRecordModel.fromJson(response.data!);
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }

  Future<FormulaDetailRecordModel> updateDetail({
    required int id,
    required int insumoId,
    required double porcentaje,
    String? observacion,
    required bool activo,
  }) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '/api/configuracion/formula-detalles/$id',
        data: {
          'insumoId': insumoId,
          'porcentaje': porcentaje,
          'observacion': observacion,
          'activo': activo,
        },
      );
      return FormulaDetailRecordModel.fromJson(response.data!);
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }

  Future<FormulaDetailRecordModel> deleteDetail(int id) async {
    try {
      final response = await _dio.delete<Map<String, dynamic>>(
        '/api/configuracion/formula-detalles/$id',
      );
      return FormulaDetailRecordModel.fromJson(response.data!);
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }

  Future<List<ProcesoProductivoOptionModel>> listActiveProcesses() async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '/api/configuracion/catalogos/procesos-productivos/activos-ordenados',
      );
      final items = response.data ?? const [];
      return items
          .map((item) => ProcesoProductivoOptionModel.fromJson(item as Map<String, dynamic>))
          .toList(growable: false);
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }

  Future<List<InsumoLookupModel>> listActiveInsumos() async {
    try {
      final response = await _dio.get<List<dynamic>>('/api/inventario/catalogos/insumos/activos');
      final items = response.data ?? const [];
      return items
          .map((item) => InsumoLookupModel.fromJson(item as Map<String, dynamic>))
          .toList(growable: false);
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }
}
