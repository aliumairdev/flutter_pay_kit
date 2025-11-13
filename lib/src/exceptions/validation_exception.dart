import 'payment_exception.dart';

/// Exception thrown when input validation fails.
///
/// This exception is used for validation errors such as invalid email formats,
/// missing required fields, invalid amounts, out-of-range values, or any
/// other input validation failures before making API calls.
class ValidationException extends PaymentException {
  /// The field name that failed validation.
  final String? fieldName;

  /// The invalid value that was provided, if safe to include.
  final dynamic invalidValue;

  /// Creates a new [ValidationException] with the given [message].
  ///
  /// Optionally includes:
  /// - [code]: Error code for the validation failure
  /// - [fieldName]: The name of the field that failed validation
  /// - [invalidValue]: The invalid value (avoid including sensitive data)
  /// - [originalError]: The original error object, if any
  /// - [stackTrace]: Stack trace for debugging
  ValidationException(
    super.message, {
    super.code,
    this.fieldName,
    this.invalidValue,
    super.originalError,
    super.stackTrace,
  });

  @override
  String toString() {
    final fieldStr = fieldName != null ? ' (field: $fieldName)' : '';
    final valueStr = invalidValue != null ? ' (value: $invalidValue)' : '';
    final codeStr = code != null ? ' (code: $code)' : '';
    return 'ValidationException: $message$fieldStr$valueStr$codeStr';
  }
}
