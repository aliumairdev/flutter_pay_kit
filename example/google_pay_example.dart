// ignore_for_file: avoid_print

/// Example demonstrating Google Pay integration with flutter_universal_payments.
///
/// This example shows how to:
/// - Configure Google Pay
/// - Check Google Pay availability
/// - Request payments
/// - Handle payment tokens
library google_pay_example;

import 'package:flutter/material.dart';
import 'package:flutter_universal_payments/flutter_universal_payments.dart';

/// Main entry point for the Google Pay example.
void main() {
  runApp(const GooglePayExampleApp());
}

/// Example app demonstrating Google Pay integration.
class GooglePayExampleApp extends StatelessWidget {
  const GooglePayExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Google Pay Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const GooglePayExampleScreen(),
    );
  }
}

/// Main screen showing Google Pay integration.
class GooglePayExampleScreen extends StatefulWidget {
  const GooglePayExampleScreen({super.key});

  @override
  State<GooglePayExampleScreen> createState() => _GooglePayExampleScreenState();
}

class _GooglePayExampleScreenState extends State<GooglePayExampleScreen> {
  // Google Pay configuration
  late final GooglePayConfig _googlePayConfig;

  // State
  bool _isAvailable = false;
  bool _isLoading = true;
  String? _paymentToken;
  String? _error;

  @override
  void initState() {
    super.initState();

    // Initialize Google Pay configuration
    _googlePayConfig = GooglePayConfig(
      merchantId: 'BCR2DN4T2I4VJ4M7', // Example merchant ID for testing
      merchantName: 'Example Merchant',
      environment: GooglePayEnvironment.test, // Use TEST for development
      countryCode: 'US',
      currencyCode: 'USD',
      allowedCardNetworks: [
        CardNetwork.visa,
        CardNetwork.mastercard,
        CardNetwork.amex,
        CardNetwork.discover,
      ],
    );

    _checkGooglePayAvailability();
  }

  /// Check if Google Pay is available on this device.
  Future<void> _checkGooglePayAvailability() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final isAvailable = await _googlePayConfig.isAvailable();

      setState(() {
        _isAvailable = isAvailable;
        _isLoading = false;
      });

      if (!isAvailable) {
        print('Google Pay is not available on this device');
      } else {
        print('Google Pay is available and ready to use');
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to check Google Pay availability: $e';
        _isLoading = false;
      });
      print('Error checking Google Pay availability: $e');
    }
  }

  /// Request a payment using Google Pay.
  Future<void> _requestPayment({required int amountInCents}) async {
    setState(() {
      _isLoading = true;
      _error = null;
      _paymentToken = null;
    });

    try {
      // Request payment
      final token = await _googlePayConfig.requestPayment(
        amount: amountInCents,
      );

      if (token != null) {
        setState(() {
          _paymentToken = token;
          _isLoading = false;
        });

        print('Payment successful! Token: $token');

        // In a real app, you would send this token to your server
        // to complete the payment with your payment processor
        // Example:
        // await yourPaymentService.processGooglePayToken(token);

        _showSuccessDialog();
      } else {
        // User cancelled
        setState(() {
          _isLoading = false;
        });
        print('Payment cancelled by user');
      }
    } on PaymentException catch (e) {
      setState(() {
        _error = 'Payment failed: ${e.message}';
        _isLoading = false;
      });
      print('Payment error: ${e.message}');
      _showErrorDialog(e.message);
    } catch (e) {
      setState(() {
        _error = 'Unexpected error: $e';
        _isLoading = false;
      });
      print('Unexpected error: $e');
      _showErrorDialog(e.toString());
    }
  }

  /// Show success dialog after payment.
  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Payment Successful'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your payment was processed successfully!'),
            const SizedBox(height: 16),
            const Text('Payment Token:'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(4),
              ),
              child: SelectableText(
                _paymentToken ?? '',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Show error dialog.
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Payment Failed'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Google Pay Example'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Configuration Info Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Configuration',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            'Merchant ID',
                            _googlePayConfig.merchantId,
                          ),
                          _buildInfoRow(
                            'Merchant Name',
                            _googlePayConfig.merchantName,
                          ),
                          _buildInfoRow(
                            'Environment',
                            _googlePayConfig.environment.value,
                          ),
                          _buildInfoRow(
                            'Country',
                            _googlePayConfig.countryCode,
                          ),
                          _buildInfoRow(
                            'Currency',
                            _googlePayConfig.currencyCode,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Availability Status Card
                  Card(
                    color: _isAvailable ? Colors.green[50] : Colors.red[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _isAvailable ? Icons.check_circle : Icons.error,
                                color: _isAvailable ? Colors.green : Colors.red,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _isAvailable
                                    ? 'Google Pay Available'
                                    : 'Google Pay Not Available',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          if (!_isAvailable) ...[
                            const SizedBox(height: 8),
                            const Text(
                              'Google Pay is not available on this device. '
                              'Make sure you have Google Play Services installed '
                              'and a payment method configured.',
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Payment Buttons
                  const Text(
                    'Example Payments',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  _buildPaymentButton(
                    amount: 999,
                    label: 'Pay \$9.99',
                    enabled: _isAvailable,
                  ),
                  const SizedBox(height: 12),

                  _buildPaymentButton(
                    amount: 2499,
                    label: 'Pay \$24.99',
                    enabled: _isAvailable,
                  ),
                  const SizedBox(height: 12),

                  _buildPaymentButton(
                    amount: 4999,
                    label: 'Pay \$49.99',
                    enabled: _isAvailable,
                  ),

                  // Error Display
                  if (_error != null) ...[
                    const SizedBox(height: 24),
                    Card(
                      color: Colors.red[50],
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.error, color: Colors.red),
                                SizedBox(width: 8),
                                Text(
                                  'Error',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(_error!),
                          ],
                        ),
                      ),
                    ),
                  ],

                  // Instructions
                  const SizedBox(height: 24),
                  Card(
                    color: Colors.blue[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.info, color: Colors.blue),
                              SizedBox(width: 8),
                              Text(
                                'Important Notes',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildBulletPoint(
                            'This example uses TEST environment - no real charges',
                          ),
                          _buildBulletPoint(
                            'For production, use GooglePayEnvironment.production',
                          ),
                          _buildBulletPoint(
                            'Always validate payment tokens on your server',
                          ),
                          _buildBulletPoint(
                            'Test on real devices for best results',
                          ),
                          _buildBulletPoint(
                            'Make sure Google Play Services is up to date',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentButton({
    required int amount,
    required String label,
    required bool enabled,
  }) {
    return ElevatedButton(
      onPressed: enabled ? () => _requestPayment(amountInCents: amount) : null,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.all(16),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        disabledBackgroundColor: Colors.grey[300],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Google Pay logo colors
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'G Pay',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• '),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
