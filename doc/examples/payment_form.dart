/// Complete payment form example
///
/// This example shows how to create a complete payment form with:
/// - Card input
/// - Validation
/// - Error handling
/// - Loading states
library;

import 'package:flutter/material.dart';
import 'package:flutter_universal_payments/flutter_universal_payments.dart';

class PaymentFormExample extends StatefulWidget {
  final String priceId;
  final int amount;
  final String currency;

  const PaymentFormExample({
    super.key,
    required this.priceId,
    required this.amount,
    required this.currency,
  });

  @override
  State<PaymentFormExample> createState() => _PaymentFormExampleState();
}

class _PaymentFormExampleState extends State<PaymentFormExample> {
  final PaymentService _service = FlutterUniversalPayments.instance;
  PaymentCardData? _cardData;
  PaymentLoadingState _loadingState = PaymentLoadingState.idle;
  final _formKey = GlobalKey<FormState>();

  bool get _canSubmit =>
      _cardData != null &&
      _cardData!.isValid &&
      _loadingState != PaymentLoadingState.loading;

  Future<void> _processPayment() async {
    if (!_canSubmit) return;

    setState(() => _loadingState = PaymentLoadingState.loading);

    try {
      // In a real app, you'd tokenize the card on your backend
      // and return a payment method token
      final token = await _tokenizeCard(_cardData!);

      // Set payment method
      await _service.setDefaultPaymentMethod(token);

      // Create subscription
      final subscription = await _service.subscribe(
        priceId: widget.priceId,
      );

      setState(() => _loadingState = PaymentLoadingState.success);

      // Wait a moment to show success state
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        Navigator.pop(context, subscription);
      }
    } on ProcessorException catch (e) {
      setState(() => _loadingState = PaymentLoadingState.failure);
      _handleProcessorError(e);
    } on NetworkException catch (e) {
      setState(() => _loadingState = PaymentLoadingState.failure);
      _showError('Network error. Please check your connection.');
    } catch (e) {
      setState(() => _loadingState = PaymentLoadingState.failure);
      _showError('An unexpected error occurred: $e');
    }
  }

  /// Tokenize card (this would typically be done on your backend)
  Future<String> _tokenizeCard(PaymentCardData cardData) async {
    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    // In production, send card data to your backend
    // which then creates a payment method token via the processor
    return 'pm_card_${DateTime.now().millisecondsSinceEpoch}';
  }

  void _handleProcessorError(ProcessorException e) {
    String message;

    switch (e.code) {
      case 'card_declined':
        message = 'Your card was declined. Please try another payment method.';
        break;
      case 'insufficient_funds':
        message = 'Insufficient funds. Please use a different card.';
        break;
      case 'expired_card':
        message = 'Your card has expired. Please update your payment method.';
        break;
      case 'incorrect_cvc':
        message = 'Invalid security code. Please check and try again.';
        break;
      case 'processing_error':
        message = 'Payment processor error. Please try again.';
        break;
      default:
        message = 'Payment failed: ${e.message}';
    }

    _showError(message);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: () {
            setState(() => _loadingState = PaymentLoadingState.idle);
          },
        ),
      ),
    );
  }

  String get _formattedAmount {
    final dollars = (widget.amount / 100).toStringAsFixed(2);
    return '\$${dollars} ${widget.currency}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
      ),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Amount summary
                  Card(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const Text(
                            'Total Amount',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _formattedAmount,
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Payment card input
                  PaymentCardInput(
                    requirePostalCode: true,
                    onCardChanged: (cardData) {
                      setState(() => _cardData = cardData);
                    },
                  ),

                  const SizedBox(height: 16),

                  // Security notice
                  Row(
                    children: [
                      Icon(
                        Icons.lock,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Your payment information is encrypted and secure',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Submit button
                  ElevatedButton(
                    onPressed: _canSubmit ? _processPayment : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      'Pay $_formattedAmount',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Cancel button
                  TextButton(
                    onPressed: _loadingState == PaymentLoadingState.loading
                        ? null
                        : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ),
          ),

          // Loading overlay
          if (_loadingState != PaymentLoadingState.idle)
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                child: Center(
                  child: PaymentLoadingIndicator(
                    state: _loadingState,
                    loadingMessage: 'Processing your payment...',
                    successMessage: 'Payment successful!',
                    failureMessage: 'Payment failed',
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Example usage:
/// ```dart
/// final result = await Navigator.push(
///   context,
///   MaterialPageRoute(
///     builder: (context) => PaymentFormExample(
///       priceId: 'price_monthly_999',
///       amount: 999,  // $9.99
///       currency: 'USD',
///     ),
///   ),
/// );
///
/// if (result != null) {
///   // Payment successful, result is a Subscription object
///   print('Subscription created: ${result.id}');
/// }
/// ```
