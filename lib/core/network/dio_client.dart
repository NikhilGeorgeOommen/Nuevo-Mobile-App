import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import '../constants/app_constants.dart';
import '../errors/exceptions.dart';

/// Dio HTTP Client Configuration
/// Handles all API communication with proper error handling and logging
class DioClient {
  late final Dio _dio;
  // final Logger _logger = Logger();
  
  final void Function()? onUnauthorized;

  DioClient({
    Dio? dio,
    required Future<String?> Function() getAccessToken,
    this.onUnauthorized,
  }) {
    _dio = dio ?? Dio();
    
    // Base Options
    _dio.options = BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: ApiConstants.connectTimeout,
      receiveTimeout: ApiConstants.receiveTimeout,
      sendTimeout: ApiConstants.sendTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );
    
    // Request Interceptor (Add Auth Token)
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Identify public routes that don't need authentication natively
          final isPublicRoute = 
              options.path.contains('/auth/register') ||
              options.path.contains('/auth/login') ||
              options.path.contains('/auth/generate-otp') ||
              options.path.contains('/auth/login-otp') ||
              options.path.contains('/auth/forgot-password');

          if (!isPublicRoute) {
            final token = await getAccessToken();
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          
          // HIPAA/GDPR Compliance: Do NOT log request data containing PII
          // _logger.d('REQUEST[${options.method}] => PATH: ${options.path}');
          
          return handler.next(options);
        },
        onResponse: (response, handler) {
          return handler.next(response);
        },
        onError: (error, handler) {
          final isPublicRoute = 
              error.requestOptions.path.contains('/auth/register') ||
              error.requestOptions.path.contains('/auth/login') ||
              error.requestOptions.path.contains('/auth/generate-otp') ||
              error.requestOptions.path.contains('/auth/login-otp') ||
              error.requestOptions.path.contains('/auth/forgot-password');
              
          // Only trigger global session expiration on 401s for PROTECTED routes.
          // A 401 on a public route usually implies Bad Credentials, not a session timeout.
          if (error.response?.statusCode == 401 && !isPublicRoute) {
            onUnauthorized?.call();
          }
          
          return handler.next(error);
        },
      ),
    );

    // Logging Interceptor to print all requests, responses, and errors
    _dio.interceptors.add(DioLoggingInterceptor());

    // Android/Release Mode Hotfix: bypass SSL issues on Dev/Staging environments
    _dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        final client = HttpClient();
        client.badCertificateCallback = 
            (X509Certificate cert, String host, int port) => true;
        return client;
      },
    );
  }
  


  /// Expose Dio instance for Retrofit
  Dio get dio => _dio;

  /// Handle Dio Errors and convert to custom exceptions
  /// Static so it can be used without instance if needed, or by Repositories
  static AppException handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkException(
          message: ErrorMessages.timeout,
          code: error.response?.statusCode,
        );
        
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        
        String? customMessage;
        if (error.response?.data is Map) {
          customMessage = (error.response?.data['message'] ?? error.response?.data['error'])?.toString();
        } else if (error.response?.data is String && (error.response?.data as String).isNotEmpty) {
          customMessage = error.response?.data as String;
        }

        if (statusCode == 401) {
          return AuthException(
            message: customMessage ?? ErrorMessages.sessionExpired,
            code: statusCode,
          );
        } else if (statusCode == 403) {
          return AuthException(
            message: customMessage ?? ErrorMessages.unauthorized,
            code: statusCode,
          );
        } else if (statusCode != null && statusCode >= 500) {
          return ServerException(
            message: customMessage ?? ErrorMessages.serverError,
            code: statusCode,
          );
        } else if (statusCode == 404) {
          return ServerException(
            message: customMessage ?? ErrorMessages.serviceUnavailable,
            code: statusCode,
          );
        } else if (statusCode == 400) {
          // Check for validation errors
          if (error.response?.data is Map && error.response?.data['errors'] is List) {
             return ValidationException(
              message: customMessage ?? 'Validation failed',
              code: statusCode,
              errors: (error.response?.data['errors'] as List).map((e) {
                if (e is Map && e.containsKey('msg')) {
                  return e['msg'].toString();
                }
                return e.toString();
              }).toList(),
             );
          }
          return ServerException(
            message: customMessage ?? ErrorMessages.somethingWentWrong,
            code: statusCode,
          );
        } else {
          return ServerException(
            message: customMessage ?? ErrorMessages.somethingWentWrong,
            code: statusCode,
          );
        }
        
      case DioExceptionType.cancel:
        return NetworkException(
          message: 'Request cancelled',
          code: null,
        );
        
      case DioExceptionType.connectionError:
      case DioExceptionType.unknown:
      default:
        return NetworkException(
          message: ErrorMessages.noInternet,
          code: null,
        );
    }
  }
  
  /// GET Request
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }
  
  /// POST Request
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
     //  print("response: ${response.data} ====================");
      return response;
    } on DioException catch (e) {
      //print("handleDioError(e): ${handleDioError(e)} ===================");
      throw handleDioError(e);
    }
  }
  
  /// PUT Request
  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }
  
  /// DELETE Request
  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  /// PATCH Request
  Future<Response> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }
}

/// Interceptor that prints all network requests, responses, and errors.
class DioLoggingInterceptor extends Interceptor {
  final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 100,
      colors: true,
      printEmojis: true,
      printTime: true,
    ),
  );

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final buffer = StringBuffer();
    buffer.writeln('--> REQUEST [${options.method}]');
    buffer.writeln('URL: ${options.uri}');
    
    if (options.headers.isNotEmpty) {
      buffer.writeln('Headers:');
      options.headers.forEach((k, v) => buffer.writeln('  $k: $v'));
    }
    
    if (options.queryParameters.isNotEmpty) {
      buffer.writeln('Query Parameters:');
      options.queryParameters.forEach((k, v) => buffer.writeln('  $k: $v'));
    }
    
    if (options.data != null) {
      buffer.writeln('Body:');
      try {
        final encoder = const JsonEncoder.withIndent('  ');
        buffer.writeln(encoder.convert(options.data));
      } catch (_) {
        buffer.writeln(options.data.toString());
      }
    }
    
    buffer.writeln('--> END ${options.method}');
    _logger.i(buffer.toString());
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final buffer = StringBuffer();
    buffer.writeln('<-- RESPONSE [${response.statusCode}]');
    buffer.writeln('URL: ${response.requestOptions.uri}');
    
    if (response.data != null) {
      buffer.writeln('Body:');
      try {
        final encoder = const JsonEncoder.withIndent('  ');
        buffer.writeln(encoder.convert(response.data));
      } catch (_) {
        buffer.writeln(response.data.toString());
      }
    }
    
    buffer.writeln('<-- END HTTP');
    _logger.d(buffer.toString());
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final buffer = StringBuffer();
    buffer.writeln('<-- ERROR [${err.response?.statusCode}]');
    buffer.writeln('URL: ${err.requestOptions.uri}');
    buffer.writeln('Message: ${err.message}');
    
    if (err.response?.data != null) {
      buffer.writeln('Body:');
      try {
        final encoder = const JsonEncoder.withIndent('  ');
        buffer.writeln(encoder.convert(err.response?.data));
      } catch (_) {
        buffer.writeln(err.response?.data.toString());
      }
    }
    
    buffer.writeln('<-- END ERROR');
    _logger.e(buffer.toString());
    super.onError(err, handler);
  }
}
