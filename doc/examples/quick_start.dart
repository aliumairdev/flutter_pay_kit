/// Quick start example for Flutter Universal Payments
///
/// This example shows the minimal setup required to get started
/// with Flutter Universal Payments.
library;

import 'package:flutter/material.dart';
import 'package:flutter_universal_payments/flutter_universal_payments.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize payment service
  await initializePaymentService();

  runApp(const MyApp());
}

Future<void> initializePaymentService() async {
  // Create storage implementation
  final prefs = await SharedPreferences.getInstance();
  final storage = SimpleStorage(prefs);

  // Configure payment processor
  final config = PaymentConfigurationBuilder()
      .useStripe(
        publishableKey: 'pk_test_...',
        secretKey: 'sk_test_...',
      )
      .enableLogging()
      .build();

  // Initialize
  await FlutterUniversalPayments.initialize(
    config: config,
    storage: storage,
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Payment Quick Start',
      home: const QuickStartScreen(),
    );
  }
}

class QuickStartScreen extends StatefulWidget {
  const QuickStartScreen({super.key});

  @override
  State<QuickStartScreen> createState() => _QuickStartScreenState();
}

class _QuickStartScreenState extends State<QuickStartScreen> {
  bool isLoading = false;
  String? message;

  Future<void> createSubscription() async {
    setState(() {
      isLoading = true;
      message = null;
    });

    try {
      final service = FlutterUniversalPayments.instance;

      // Initialize customer
      await service.initialize(
        email: 'customer@example.com',
        name: 'John Doe',
      );

      // Create subscription
      final subscription = await service.subscribe(
        priceId: 'price_monthly_999',
        trialDays: 14,
      );

      setState(() {
        message = 'Success! Subscription ID: ${subscription.id}';
      });
    } catch (e) {
      setState(() {
        message = 'Error: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quick Start Example'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              const CircularProgressIndicator()
            else
              ElevatedButton(
                onPressed: createSubscription,
                child: const Text('Create Subscription'),
              ),
            if (message != null) ...[
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  message!,
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Simple storage implementation
class SimpleStorage implements Storage {
  final SharedPreferences prefs;

  SimpleStorage(this.prefs);

  @override
  Future<String?> getString(String key) async => prefs.getString(key);

  @override
  Future<void> setString(String key, String value) async {
    await prefs.setString(key, value);
  }

  @override
  Future<int?> getInt(String key) async => prefs.getInt(key);

  @override
  Future<void> setInt(String key, int value) async {
    await prefs.setInt(key, value);
  }

  @override
  Future<bool?> getBool(String key) async => prefs.getBool(key);

  @override
  Future<void> setBool(String key, bool value) async {
    await prefs.setBool(key, value);
  }

  @override
  Future<T?> getObject<T>(
    String key,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    final jsonString = prefs.getString(key);
    if (jsonString == null) return null;
    return fromJson(jsonDecode(jsonString));
  }

  @override
  Future<void> setObject<T>(
    String key,
    T value,
    Map<String, dynamic> Function(T) toJson,
  ) async {
    await prefs.setString(key, jsonEncode(toJson(value)));
  }

  @override
  Future<void> remove(String key) async {
    await prefs.remove(key);
  }

  @override
  Future<bool> containsKey(String key) async => prefs.containsKey(key);

  @override
  Future<void> clear() async {
    await prefs.clear();
  }
}
