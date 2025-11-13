import 'package:flutter/material.dart';
import 'package:flutter_universal_payments/flutter_universal_payments.dart';

import '../config/config.dart';

/// Payment screen for adding and managing payment methods
class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  PaymentCardData? _cardData;
  bool _isProcessing = false;
  bool _setAsDefault = true;
  String? _errorMessage;
  bool _showSuccess = false;
  SubscriptionPlanData? _planToSubscribe;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Get plan data if passed from pricing screen
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    if (args != null && args.containsKey('plan')) {
      _planToSubscribe = args['plan'] as SubscriptionPlanData;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _planToSubscribe != null
              ? 'Add Payment Method'
              : 'Manage Payment Methods',
        ),
      ),
      body: _showSuccess ? _buildSuccessState() : _buildPaymentForm(),
    );
  }

  Widget _buildPaymentForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Plan info if subscribing
          if (_planToSubscribe != null) ...[
            _buildPlanInfo(),
            const SizedBox(height: 24),
          ],

          // Payment card input widget
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Card Information',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),

                  // Use the PaymentCardInput widget from the package
                  PaymentCardInput(
                    onCardComplete: (cardData) {
                      setState(() {
                        _cardData = cardData;
                        _errorMessage = null;
                      });
                      print('Card data complete: ${cardData.cardNumber}');
                    },
                    autofocus: true,
                    requirePostalCode: true,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Set as default option
          Card(
            child: CheckboxListTile(
              title: const Text('Set as default payment method'),
              subtitle: const Text('Use this card for future payments'),
              value: _setAsDefault,
              onChanged: (value) {
                setState(() {
                  _setAsDefault = value ?? true;
                });
              },
            ),
          ),

          const SizedBox(height: 16),

          // Test cards info
          _buildTestCardsInfo(),

          const SizedBox(height: 24),

          // Error message
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Submit button
          FilledButton(
            onPressed: _isProcessing || _cardData == null
                ? null
                : _handlePaymentSubmit,
            child: _isProcessing
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    _planToSubscribe != null
                        ? 'Subscribe Now'
                        : 'Add Payment Method',
                  ),
          ),

          const SizedBox(height: 16),

          // Saved payment methods
          _buildSavedPaymentMethods(),
        ],
      ),
    );
  }

  Widget _buildPlanInfo() {
    final plan = _planToSubscribe!;

    return Card(
      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Subscribing to',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    plan.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                Text(
                  '\$${plan.formattedPrice}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
              ],
            ),
            Text(
              plan.intervalText,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (plan.trialDays != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.card_giftcard,
                      color: Theme.of(context).colorScheme.secondary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${plan.trialDays}-day free trial included',
                        style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onSecondaryContainer,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTestCardsInfo() {
    return Card(
      color: Theme.of(context).colorScheme.surfaceVariant,
      child: ExpansionTile(
        leading: const Icon(Icons.info_outline),
        title: const Text('Test Card Numbers'),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Use these test cards for demo:',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                ...AppConfig.testCards.entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            entry.key,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            entry.value,
                            style: const TextStyle(fontFamily: 'monospace'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Use any future expiry date and any CVC.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedPaymentMethods() {
    return FutureBuilder<List<PaymentMethod>>(
      future: FlutterUniversalPayments.instance.getPaymentMethods(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final methods = snapshot.data!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Text(
              'Saved Payment Methods',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            ...methods.map((method) {
              return Card(
                child: PaymentMethodTile(
                  paymentMethod: method,
                  onTap: () {
                    // Could implement editing/selecting here
                  },
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _removePaymentMethod(method),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildSuccessState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 64,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _planToSubscribe != null
                  ? 'Subscription Successful!'
                  : 'Payment Method Added!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              _planToSubscribe != null
                  ? 'You\'re now subscribed to ${_planToSubscribe!.name}.'
                  : 'Your payment method has been saved successfully.',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: const Text('Go to Home'),
            ),
            const SizedBox(height: 12),
            if (_planToSubscribe != null)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pushReplacementNamed('/subscription');
                },
                child: const Text('View Subscription'),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _handlePaymentSubmit() async {
    if (_cardData == null) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final service = FlutterUniversalPayments.instance;

      // For demo purposes with Fake processor, we'll use the card number as a token
      // In production with real processors, you'd tokenize the card first
      final cardToken = 'tok_${_cardData!.cardNumber}';

      if (_planToSubscribe != null) {
        // Subscribe to the plan
        await service.subscribe(
          priceId: _planToSubscribe!.id,
          paymentMethodToken: cardToken,
          trialDays: _planToSubscribe!.trialDays,
        );
      } else {
        // Just add the payment method
        await service.setDefaultPaymentMethod(cardToken);
      }

      // Show success state
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _showSuccess = true;
        });
      }
    } catch (e) {
      print('Payment error: $e');
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _errorMessage = _getErrorMessage(e);
        });
      }
    }
  }

  Future<void> _removePaymentMethod(PaymentMethod method) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Payment Method'),
        content: Text(
          'Are you sure you want to remove ${method.brand} ending in ${method.last4}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await FlutterUniversalPayments.instance.removePaymentMethod(method.id);
      if (mounted) {
        setState(() {}); // Refresh the list
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment method removed')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${_getErrorMessage(e)}')),
        );
      }
    }
  }

  String _getErrorMessage(dynamic error) {
    if (error is PaymentException) {
      return error.message;
    } else if (error is ValidationException) {
      return error.message;
    } else if (error is NetworkException) {
      return 'Network error. Please check your connection and try again.';
    } else {
      return 'An unexpected error occurred. Please try again.';
    }
  }
}
