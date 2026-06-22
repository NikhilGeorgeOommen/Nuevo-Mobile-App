import 'package:json_annotation/json_annotation.dart';

part 'api_response.g.dart';

/// Generic API Response Wrapper
@JsonSerializable(genericArgumentFactories: true)
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final List<ApiError>? errors;
  
  const ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.errors,
  });
  
  factory ApiResponse.fromJson(
    dynamic json,
    T Function(Object? json) fromJsonT,
  ) {
    try {
      if (json is Map<String, dynamic>) {
        final success = json['success'] == true;
        final message = json['message']?.toString();
        
        List<ApiError>? errors;
        if (json['errors'] is List) {
          errors = [];
          for (final e in json['errors'] as List) {
            if (e is Map<String, dynamic>) {
              errors.add(ApiError.fromJson(e));
            }
          }
        }
        
        T? data;
        if (json['data'] != null) {
          try {
            data = fromJsonT(json['data']);
          } catch (_) {
            // Prevent data model schema mismatch crashes
          }
        }
        
        return ApiResponse<T>(
          success: success,
          data: data,
          message: message,
          errors: errors,
        );
      }
    } catch (_) {}
    
    return ApiResponse<T>(
      success: false,
      message: json is Map ? json['message']?.toString() : (json?.toString() ?? 'Invalid server response'),
    );
  }
      
  Map<String, dynamic> toJson(Object? Function(T value) toJsonT) =>
      _$ApiResponseToJson(this, toJsonT);
}

@JsonSerializable()
class ApiError {
  final String? type;
  final String? value;
  final String? msg;
  final String? path;
  final String? location;

  const ApiError({
    this.type,
    this.value,
    this.msg,
    this.path,
    this.location,
  });

  factory ApiError.fromJson(Map<String, dynamic> json) => _$ApiErrorFromJson(json);
  Map<String, dynamic> toJson() => _$ApiErrorToJson(this);
}
