import 'package:dio/dio.dart';
import 'package:erp_curtiembre_fronted/core/network/api_exception.dart';
import 'package:erp_curtiembre_fronted/features/configuration/units/data/models/unit_record_model.dart';

class UnitsRemoteDataSource {
  UnitsRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<UnitRecordModel>> listUnits({
    String? texto,
    bool? activo,
    bool? permiteDecimales,
  }) async {
    try {
      final queryParameters = <String, dynamic>{};
      if (texto != null && texto.trim().isNotEmpty) {
        queryParameters['texto'] = texto.trim();
      }
      if (activo != null) {
        queryParameters['activo'] = activo;
      }
      if (permiteDecimales != null) {
        queryParameters['permiteDecimales'] = permiteDecimales;
      }

      final response = await _dio.get<List<dynamic>>(
        '/api/configuracion/unidades-medida',
        queryParameters: queryParameters,
      );
      final items = response.data ?? const [];

      return items
          .map((item) => UnitRecordModel.fromJson(item as Map<String, dynamic>))
          .toList(growable: false);
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }

  Future<UnitRecordModel> getUnit(int id) async {
    try {
      final response =
          await _dio.get<Map<String, dynamic>>('/api/configuracion/unidades-medida/$id');
      return UnitRecordModel.fromJson(response.data!);
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }

  Future<UnitRecordModel> createUnit({
    required String codigo,
    required String nombre,
    required bool permiteDecimales,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/configuracion/unidades-medida',
        data: {
          'codigo': codigo,
          'nombre': nombre,
          'permiteDecimales': permiteDecimales,
        },
      );
      return UnitRecordModel.fromJson(response.data!);
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }

  Future<UnitRecordModel> updateUnit({
    required int id,
    required String codigo,
    required String nombre,
    required bool permiteDecimales,
  }) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '/api/configuracion/unidades-medida/$id',
        data: {
          'codigo': codigo,
          'nombre': nombre,
          'permiteDecimales': permiteDecimales,
        },
      );
      return UnitRecordModel.fromJson(response.data!);
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }

  Future<UnitRecordModel> setUnitActive({
    required int id,
    required bool active,
  }) async {
    try {
      final path = active
          ? '/api/configuracion/unidades-medida/$id/activar'
          : '/api/configuracion/unidades-medida/$id/inactivar';
      final response = await _dio.post<Map<String, dynamic>>(path);
      return UnitRecordModel.fromJson(response.data!);
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }
}
