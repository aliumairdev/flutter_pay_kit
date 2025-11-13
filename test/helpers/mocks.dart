/// Mock classes for testing using mocktail
library;

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_universal_payments/src/processors/base_processor.dart';
import 'package:flutter_universal_payments/src/services/storage.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Mock Dio client for HTTP requests
class MockDio extends Mock implements Dio {}

/// Mock HTTP client
class MockHttpClient extends Mock implements http.Client {}

/// Mock Response
class MockResponse extends Mock implements Response<dynamic> {}

/// Mock RequestOptions
class MockRequestOptions extends Mock implements RequestOptions {}

/// Mock SharedPreferences
class MockSharedPreferences extends Mock implements SharedPreferences {}

/// Mock FlutterSecureStorage
class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

/// Mock BaseProcessor
class MockBaseProcessor extends Mock implements BaseProcessor {}

/// Mock Storage
class MockStorage extends Mock implements Storage {}

/// Mock DioException
class MockDioException extends Mock implements DioException {}

/// Sets up fallback values for mocktail
void setupMockFallbacks() {
  registerFallbackValue(Uri());
  registerFallbackValue(RequestOptions(path: ''));
  registerFallbackValue(
    DioException(
      requestOptions: RequestOptions(path: ''),
    ),
  );
}
