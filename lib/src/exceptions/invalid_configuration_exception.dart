import 'payment_exception.dart';

/// Exception thrown when payment processor configuration is invalid or incomplete.
///
/// This exception is used when API keys are missing, invalid, or when
/// required configuration parameters are not properly set. It helps
/// developers identify configuration issues during initialization.
class InvalidConfigurationException extends PaymentException {
  /// The name of the configuration field that is invalid or missing.
  final String? fieldName;

  /// Creates a new [InvalidConfigurationException] with the given [message].
  ///
  /// Optionally includes:
  /// - [code]: Error code for the configuration issue
  /// - [fieldName]: The specific configuration field that is invalid or missing
  /// - [originalError]: The original error object, if any
  /// - [stackTrace]: Stack trace for debugging
  InvalidConfigurationException(
    super.message, {
    super.code,
    this.fieldName,
    super.originalError,
    super.stackTrace,
  });

  @override
  String toString() {
    final fieldStr = fieldName != null ? ' (field: $fieldName)' : '';
    final codeStr = code != null ? ' (code: $code)' : '';
    return 'InvalidConfigurationException: $message$fieldStr$codeStr';
  }
}
