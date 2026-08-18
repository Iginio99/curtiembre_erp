import 'package:dio/dio.dart';
import 'package:erp_curtiembre_fronted/core/network/api_exception.dart';
import 'package:erp_curtiembre_fronted/features/configuration/areas/data/models/area_record_model.dart';

class AreasRemoteDataSource {
  AreasRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<AreaRecordModel>> listAreas({
    String? texto,
    bool? activo,
  }) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '/api/configuracion/areas',
        queryParameters: {
          if (texto != null && texto.trim().isNotEmpty) 'texto': texto.trim(),
          'activo': activo,
        },
      );
      final items = response.data ?? const [];

      return items
          .map((item) => AreaRecordModel.fromJson(item as Map<String, dynamic>))
          .toList(growable: false);
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }

  Future<AreaRecordModel> getArea(int id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/api/configuracion/areas/$id');
      return AreaRecordModel.fromJson(response.data!);
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }

  Future<AreaRecordModel> createArea({
    required String codigo,
    required String nombre,
    String? descripcion,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/configuracion/areas',
        data: {
          'codigo': codigo,
          'nombre': nombre,
          'descripcion': descripcion,
        },
      );
      return AreaRecordModel.fromJson(response.data!);
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }

  Future<AreaRecordModel> updateArea({
    required int id,
    required String codigo,
    required String nombre,
    String? descripcion,
  }) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '/api/configuracion/areas/$id',
        data: {
          'codigo': codigo,
          'nombre': nombre,
          'descripcion': descripcion,
        },
      );
      return AreaRecordModel.fromJson(response.data!);
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }

  Future<AreaRecordModel> setAreaActive({
    required int id,
    required bool active,
  }) async {
    try {
      final path = active
          ? '/api/configuracion/areas/$id/activar'
          : '/api/configuracion/areas/$id/inactivar';
      final response = await _dio.post<Map<String, dynamic>>(path);
      return AreaRecordModel.fromJson(response.data!);
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }
}
