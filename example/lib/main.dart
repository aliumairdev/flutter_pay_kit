import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_universal_payments/flutter_universal_payments.dart';

import 'config/config.dart';
import 'screens/home_screen.dart';
import 'screens/pricing_screen.dart';
import 'screens/payment_screen.dart';
import 'screens/subscription_screen.dart';
import 'screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the payment system with Fake processor for demo
  // This uses the Fake processor for easy testing without real payment credentials
  await initializePaymentSystem();

  runApp(
    // Wrap app with ProviderScope for Riverpod state management
    const ProviderScope(
      child: PaymentsExampleApp(),
    ),
  );
}

/// Initialize the payment system with configuration
Future<void> initializePaymentSystem() async {
  // Create payment configuration using the Fake processor
  // This allows testing all features without real payment processor credentials
  final config = PaymentConfigurationBuilder()
      .useFake(
        simulateDelays: true, // Simulate network delays for realistic testing
        delayDuration: const Duration(milliseconds: 500),
        failureRate: 0.0, // No random failures by default
      )
      .enableLogging() // Enable logging for debugging
      .setTimeout(AppConfig.requestTimeout)
      .build();

  // Create storage instance
  final storage = InMemoryStorage();

  // Initialize the Flutter Universal Payments system
  await FlutterUniversalPayments.initialize(
    config,
    storage: storage,
  );

  print('Payment system initialized with ${config.processor} processor');
}

/// Main application widget
class PaymentsExampleApp extends StatelessWidget {
  const PaymentsExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Payments Example',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 12,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 12,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      // Define named routes for navigation
      routes: {
        '/': (context) => const HomeScreen(),
        '/pricing': (context) => const PricingScreen(),
        '/payment': (context) => const PaymentScreen(),
        '/subscription': (context) => const SubscriptionScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
      initialRoute: '/',
    );
  }
}
