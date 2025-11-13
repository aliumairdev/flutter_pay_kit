import 'package:flutter_universal_payments/flutter_universal_payments.dart';

/// Example configuration and sample data for the demo app
class AppConfig {
  // ==========================================================================
  // PAYMENT PROCESSOR CONFIGURATIONS
  // ==========================================================================

  /// Example Stripe test keys
  /// Get your own test keys at: https://dashboard.stripe.com/test/apikeys
  static const String stripePublishableKey = 'pk_test_example';
  static const String stripeSecretKey = 'sk_test_example';
  static const String stripeWebhookSecret = 'whsec_example';

  /// Example Paddle configuration
  static const String paddleVendorId = '12345';
  static const String paddleAuthCode = 'example_auth_code';
  static const String paddlePublicKey = 'example_public_key';

  // ==========================================================================
  // SAMPLE SUBSCRIPTION PLANS
  // ==========================================================================

  /// Basic monthly plan
  static const basicMonthlyPlan = SubscriptionPlanData(
    id: 'plan_basic_monthly',
    name: 'Basic',
    price: 999, // $9.99
    currency: 'USD',
    interval: BillingInterval.month,
    intervalCount: 1,
    description: 'Perfect for individuals getting started',
    features: [
      'Up to 5 projects',
      '1 GB storage',
      'Email support',
      'Basic analytics',
    ],
    trialDays: 7,
  );

  /// Pro monthly plan
  static const proMonthlyPlan = SubscriptionPlanData(
    id: 'plan_pro_monthly',
    name: 'Professional',
    price: 1999, // $19.99
    currency: 'USD',
    interval: BillingInterval.month,
    intervalCount: 1,
    description: 'For professionals who need more power',
    features: [
      'Unlimited projects',
      '10 GB storage',
      'Priority email support',
      'Advanced analytics',
      'API access',
      'Custom integrations',
    ],
    trialDays: 14,
    isBestValue: true,
  );

  /// Pro yearly plan (save 20%)
  static const proYearlyPlan = SubscriptionPlanData(
    id: 'plan_pro_yearly',
    name: 'Professional Annual',
    price: 19190, // $191.90 (save 20%)
    currency: 'USD',
    interval: BillingInterval.year,
    intervalCount: 1,
    description: 'Save 20% with annual billing',
    features: [
      'Unlimited projects',
      '10 GB storage',
      'Priority email support',
      'Advanced analytics',
      'API access',
      'Custom integrations',
      'Save \$47.88/year',
    ],
    trialDays: 14,
    isPopular: true,
  );

  /// Enterprise plan
  static const enterprisePlan = SubscriptionPlanData(
    id: 'plan_enterprise',
    name: 'Enterprise',
    price: 4999, // $49.99
    currency: 'USD',
    interval: BillingInterval.month,
    intervalCount: 1,
    description: 'For teams and large organizations',
    features: [
      'Everything in Pro',
      'Unlimited storage',
      'Dedicated support',
      'SLA guarantees',
      'Custom contract',
      'Team management',
      'Advanced security',
    ],
    trialDays: 30,
  );

  /// List of all available plans
  static const List<SubscriptionPlanData> allPlans = [
    basicMonthlyPlan,
    proMonthlyPlan,
    proYearlyPlan,
    enterprisePlan,
  ];

  // ==========================================================================
  // TEST CARD NUMBERS
  // ==========================================================================

  /// Test card numbers for different scenarios
  static const Map<String, String> testCards = {
    'Success': '4242424242424242',
    'Declined': '4000000000000002',
    'Insufficient Funds': '4000000000009995',
    'Expired Card': '4000000000000069',
    'Processing Error': '4000000000000119',
    '3D Secure Required': '4000002500003155',
  };

  // ==========================================================================
  // DEMO CUSTOMER DATA
  // ==========================================================================

  static const String demoCustomerEmail = 'demo@example.com';
  static const String demoCustomerName = 'Demo User';
  static const String demoCustomerPhone = '+1234567890';

  // ==========================================================================
  // APP SETTINGS
  // ==========================================================================

  /// Default processor to use (Fake for easy testing)
  static const ProcessorType defaultProcessor = ProcessorType.fake;

  /// Whether to enable logging by default
  static const bool enableLogging = true;

  /// Request timeout duration
  static const Duration requestTimeout = Duration(seconds: 30);
}

/// In-memory storage implementation for the example app
/// In production, use SharedPreferencesStorage or another persistent storage
class InMemoryStorage implements Storage {
  final Map<String, String> _storage = {};

  @override
  Future<String?> getString(String key) async {
    return _storage[key];
  }

  @override
  Future<void> setString(String key, String value) async {
    _storage[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    _storage.remove(key);
  }

  @override
  Future<bool> containsKey(String key) async {
    return _storage.containsKey(key);
  }

  @override
  Future<void> clear() async {
    _storage.clear();
  }
}
