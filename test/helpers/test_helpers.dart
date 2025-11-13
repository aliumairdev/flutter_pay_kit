/// Test helper utilities
library;

import 'package:dio/dio.dart';
import 'package:mocktail/mocktail.dart';

/// Creates a successful Dio Response
Response<T> createSuccessResponse<T>(
  T data, {
  int statusCode = 200,
  String? statusMessage,
  RequestOptions? requestOptions,
}) {
  return Response<T>(
    data: data,
    statusCode: statusCode,
    statusMessage: statusMessage ?? 'OK',
    requestOptions: requestOptions ?? RequestOptions(path: '/test'),
  );
}

/// Creates a Dio error response
DioException createDioException({
  int statusCode = 400,
  String? message,
  dynamic data,
  DioExceptionType type = DioExceptionType.badResponse,
}) {
  final requestOptions = RequestOptions(path: '/test');
  return DioException(
    requestOptions: requestOptions,
    response: Response(
      statusCode: statusCode,
      statusMessage: message ?? 'Bad Request',
      data: data,
      requestOptions: requestOptions,
    ),
    type: type,
    message: message,
  );
}

/// Creates a network error
DioException createNetworkError({String? message}) {
  return DioException(
    requestOptions: RequestOptions(path: '/test'),
    type: DioExceptionType.connectionError,
    message: message ?? 'Network error',
  );
}

/// Verifies that a function was called with specific arguments
void verifyCall<T>(
  T mock,
  dynamic Function() invocation, {
  int times = 1,
}) {
  verify(invocation).called(times);
}

/// Verifies that a function was never called
void verifyNeverCalled<T>(
  T mock,
  dynamic Function() invocation,
) {
  verifyNever(invocation);
}

/// Sets up a mock to return a value
void whenCall<T>(
  dynamic Function() invocation,
  dynamic Function(Invocation) thenReturn,
) {
  when(invocation).thenAnswer(thenReturn);
}

/// Sets up a mock to throw an error
void whenThrow<T>(
  dynamic Function() invocation,
  dynamic error,
) {
  when(invocation).thenThrow(error);
}
