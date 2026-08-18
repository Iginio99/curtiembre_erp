import 'package:dio/dio.dart';

class ApiException implements Exception {
  ApiException({
    required this.message,
    this.statusCode,
    this.code,
  });

  final String message;
  final int? statusCode;
  final String? code;

  factory ApiException.fromDioException(DioException exception) {
    final responseData = exception.response?.data;
    final message = responseData is Map<String, dynamic> && responseData['message'] is String
        ? responseData['message'] as String
        : _fallbackMessage(exception);
    final code = responseData is Map<String, dynamic> ? responseData['error'] as String? : null;

    return ApiException(
      message: message,
      statusCode: exception.response?.statusCode,
      code: code,
    );
  }

  static String _fallbackMessage(DioException exception) {
    return switch (exception.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.sendTimeout =>
        'El servidor tardo demasiado en responder. Intenta nuevamente.',
      DioExceptionType.connectionError =>
        'No pudimos conectarnos con el backend. Revisa que la API este levantada.',
      _ => 'No pudimos completar la operacion. Intenta nuevamente.',
    };
  }
}
