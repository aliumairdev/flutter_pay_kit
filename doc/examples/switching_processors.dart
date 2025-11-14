/// Example of switching payment processors at runtime
///
/// This demonstrates one of the most powerful features of Flutter Universal Payments:
/// the ability to switch payment processors without changing your application code.
library;

import 'package:flutter/material.dart';
import 'package:flutter_universal_payments/flutter_universal_payments.dart';

class ProcessorSwitchingExample extends StatefulWidget {
  const ProcessorSwitchingExample({super.key});

  @override
  State<ProcessorSwitchingExample> createState() =>
      _ProcessorSwitchingExampleState();
}

class _ProcessorSwitchingExampleState extends State<ProcessorSwitchingExample> {
  ProcessorType _currentProcessor = ProcessorType.fake;
  bool _isLoading = false;
  String? _message;

  Future<void> _switchProcessor(ProcessorType processor) async {
    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      final config = _createConfig(processor);

      // Reinitialize with new processor
      await FlutterUniversalPayments.reinitialize(
        config: config,
        storage: storage, // Use the same storage
      );

      setState(() {
        _currentProcessor = processor;
        _message = 'Switched to ${processor.name}';
      });
    } catch (e) {
      setState(() {
        _message = 'Failed to switch processor: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  PaymentConfiguration _createConfig(ProcessorType processor) {
    final builder = PaymentConfigurationBuilder();

    switch (processor) {
      case ProcessorType.stripe:
        return builder
            .useStripe(
              publishableKey: 'pk_test_...',
              secretKey: 'sk_test_...',
            )
            .enableLogging()
            .build();

      case ProcessorType.paddle:
        return builder
            .usePaddle(
              vendorId: '12345',
              authCode: 'auth_code',
              publicKey: 'public_key',
              environment: PaddleEnvironment.sandbox,
            )
            .enableLogging()
            .build();

      case ProcessorType.braintree:
        return builder
            .useBraintree(
              merchantId: 'merchant_id',
              publicKey: 'public_key',
              privateKey: 'private_key',
              environment: BraintreeEnvironment.sandbox,
            )
            .enableLogging()
            .build();

      case ProcessorType.lemonSqueezy:
        return builder
            .useLemonSqueezy(
              apiKey: 'lemon_api_key',
              storeId: 'store_id',
            )
            .enableLogging()
            .build();

      case ProcessorType.totalpayGlobal:
        return builder
            .useTotalpay(
              merchantId: 'merchant_id',
              apiKey: 'api_key',
              secretKey: 'secret_key',
              environment: TotalpayEnvironment.sandbox,
            )
            .enableLogging()
            .build();

      case ProcessorType.fake:
        return builder
            .useFake(
              simulateDelays: true,
              delayDuration: const Duration(seconds: 1),
              failureRate: 0.0,
            )
            .enableLogging()
            .build();
    }
  }

  Future<void> _testCurrentProcessor() async {
    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      final service = FlutterUniversalPayments.instance;

      // Initialize customer
      await service.initialize(
        email: 'test@example.com',
        name: 'Test User',
      );

      // Try to create a subscription
      final subscription = await service.subscribe(
        priceId: 'test_price_id',
        trialDays: 14,
      );

      setState(() {
        _message = 'Success with ${_currentProcessor.name}!\n'
            'Subscription ID: ${subscription.id}';
      });
    } catch (e) {
      setState(() {
        _message = 'Error with ${_currentProcessor.name}: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Processor Switching'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Current processor
            Card(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'Current Processor',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _currentProcessor.name,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Processor selection
            const Text(
              'Switch to:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            ...ProcessorType.values.map((processor) {
              final isActive = processor == _currentProcessor;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  tileColor: isActive ? Colors.green.withOpacity(0.1) : null,
                  leading: Icon(
                    isActive ? Icons.check_circle : Icons.circle_outlined,
                    color: isActive ? Colors.green : Colors.grey,
                  ),
                  title: Text(
                    processor.name,
                    style: TextStyle(
                      fontWeight:
                          isActive ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(_getProcessorDescription(processor)),
                  trailing: isActive
                      ? null
                      : const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: isActive || _isLoading
                      ? null
                      : () => _switchProcessor(processor),
                ),
              );
            }).toList(),

            const SizedBox(height: 24),

            // Test button
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _testCurrentProcessor,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.play_arrow),
              label: Text(
                _isLoading ? 'Testing...' : 'Test Current Processor',
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),

            if (_message != null) ...[
              const SizedBox(height: 24),
              Card(
                color: _message!.startsWith('Success')
                    ? Colors.green.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _message!,
                    style: TextStyle(
                      color: _message!.startsWith('Success')
                          ? Colors.green[900]
                          : Colors.red[900],
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Info card
            Card(
              color: Colors.blue.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        const Text(
                          'How it works',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Flutter Universal Payments allows you to switch between '
                      'payment processors at runtime without changing your '
                      'application code. Your app continues to use the same '
                      'PaymentService API regardless of which processor is active.',
                      style: TextStyle(fontSize: 14),
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

  String _getProcessorDescription(ProcessorType processor) {
    switch (processor) {
      case ProcessorType.stripe:
        return 'Industry-leading payment processing';
      case ProcessorType.paddle:
        return 'SaaS billing and payments';
      case ProcessorType.braintree:
        return 'PayPal-owned payment gateway';
      case ProcessorType.lemonSqueezy:
        return 'Merchant of record for digital products';
      case ProcessorType.totalpayGlobal:
        return 'International payment processing';
      case ProcessorType.fake:
        return 'Testing processor (no real charges)';
    }
  }
}

/// Real-world use case: Multi-region payment processing
///
/// You might start with Stripe in the US, then expand to Europe with Paddle
/// for better tax handling, or use different processors for different product
/// lines - all without changing your core application logic.
class MultiRegionPaymentExample {
  final Storage storage;

  MultiRegionPaymentExample(this.storage);

  Future<void> setupForRegion(String countryCode) async {
    PaymentConfiguration config;

    if (countryCode == 'US') {
      // Use Stripe for US customers
      config = PaymentConfigurationBuilder()
          .useStripe(
            publishableKey: 'pk_us_...',
            secretKey: 'sk_us_...',
          )
          .build();
    } else if (['GB', 'DE', 'FR', 'ES', 'IT'].contains(countryCode)) {
      // Use Paddle for EU customers (handles VAT automatically)
      config = PaymentConfigurationBuilder()
          .usePaddle(
            vendorId: 'vendor_eu',
            authCode: 'auth_eu',
            publicKey: 'key_eu',
            environment: PaddleEnvironment.production,
          )
          .build();
    } else {
      // Use Totalpay for other regions
      config = PaymentConfigurationBuilder()
          .useTotalpay(
            merchantId: 'merchant_global',
            apiKey: 'api_key',
            secretKey: 'secret_key',
            environment: TotalpayEnvironment.production,
          )
          .build();
    }

    await FlutterUniversalPayments.reinitialize(
      config: config,
      storage: storage,
    );
  }
}
