# API Specification

This folder contains the authoritative API definitions for the Flutter app.

- Source of truth: Postman collection
- File: postman_collection.json
- Used for:
  - Data layer implementation
  - DTO generation
  - Repository contracts
  - Mocking and unit tests

All API-related code must strictly follow this collection.

Base URL: "https://nuevo-medical-be.simelabs.in/api/v1"
https://nuevo-medical-be.simelabs.in/api/v1

## Implementation Details

### Manual ApiClient
We use a **manual Dio client implementation** instead of code generation (Retrofit) to avoid build conflicts and ensure greater control over the network layer.

- **Client**: `lib/data/datasources/remote/api_client.dart`
- **Core Dio Wrapper**: `lib/core/network/dio_client.dart`
- **Response Wrapper**: `ApiResponse<T>` generic class for standardized parsing.

All new endpoints should be added to `ApiClient` manually following the existing pattern:
```dart
Future<ApiResponse<MyData>> getData() async {
  final response = await _dioClient.get(ApiConstants.endpoint);
  return ApiResponse.fromJson(response.data, (json) => MyData.fromJson(json));
}
```
