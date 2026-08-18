import 'package:dio/dio.dart';
import 'package:erp_curtiembre_fronted/core/network/api_exception.dart';
import 'package:erp_curtiembre_fronted/features/configuration/skin_types/data/models/skin_type_record_model.dart';

class SkinTypesRemoteDataSource {
  SkinTypesRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<SkinTypeRecordModel>> listSkinTypes({
    String? texto,
    bool? activo,
  }) async {
    try {
      final queryParameters = <String, dynamic>{};
      if (texto != null && texto.trim().isNotEmpty) {
        queryParameters['texto'] = texto.trim();
      }
      if (activo != null) {
        queryParameters['activo'] = activo;
      }

      final response = await _dio.get<List<dynamic>>(
        '/api/configuracion/tipos-piel',
        queryParameters: queryParameters,
      );
      final items = response.data ?? const [];

      return items
          .map((item) => SkinTypeRecordModel.fromJson(item as Map<String, dynamic>))
          .toList(growable: false);
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }

  Future<SkinTypeRecordModel> getSkinType(int id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/api/configuracion/tipos-piel/$id');
      return SkinTypeRecordModel.fromJson(response.data!);
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }

  Future<SkinTypeRecordModel> createSkinType({
    required String codigo,
    required String nombre,
    String? descripcion,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/configuracion/tipos-piel',
        data: {
          'codigo': codigo,
          'nombre': nombre,
          'descripcion': descripcion,
        },
      );
      return SkinTypeRecordModel.fromJson(response.data!);
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }

  Future<SkinTypeRecordModel> updateSkinType({
    required int id,
    required String codigo,
    required String nombre,
    String? descripcion,
  }) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '/api/configuracion/tipos-piel/$id',
        data: {
          'codigo': codigo,
          'nombre': nombre,
          'descripcion': descripcion,
        },
      );
      return SkinTypeRecordModel.fromJson(response.data!);
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }

  Future<SkinTypeRecordModel> setSkinTypeActive({
    required int id,
    required bool active,
  }) async {
    try {
      final path = active
          ? '/api/configuracion/tipos-piel/$id/activar'
          : '/api/configuracion/tipos-piel/$id/inactivar';
      final response = await _dio.post<Map<String, dynamic>>(path);
      return SkinTypeRecordModel.fromJson(response.data!);
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }
}
