import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_universal_payments/flutter_universal_payments.dart';
import 'package:intl/intl.dart';

import '../config/config.dart';

/// Home screen showing subscription status and quick actions
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isInitialized = false;
  bool _isInitializing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeCustomer();
  }

  /// Initialize the customer for demo purposes
  Future<void> _initializeCustomer() async {
    if (_isInitializing) return;

    setState(() {
      _isInitializing = true;
      _error = null;
    });

    try {
      final service = FlutterUniversalPayments.instance;

      // Check if already initialized
      final isInitialized = await service.isInitialized();

      if (!isInitialized) {
        // Initialize with demo customer data
        await service.initialize(
          email: AppConfig.demoCustomerEmail,
          name: AppConfig.demoCustomerName,
          phone: AppConfig.demoCustomerPhone,
        );
        print('Customer initialized successfully');
      }

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _isInitializing = false;
        });
      }
    } catch (e) {
      print('Error initializing customer: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isInitializing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Payments Demo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: _isInitializing
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : _buildContent(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Initialization Error',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                setState(() => _error = null);
                _initializeCustomer();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return RefreshIndicator(
      onRefresh: () async {
        final service = FlutterUniversalPayments.instance;
        await service.refreshSubscriptions();
        await service.refreshCustomer();
        setState(() {}); // Trigger rebuild
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Welcome header
            _buildWelcomeHeader(),
            const SizedBox(height: 24),

            // Subscription status card
            _buildSubscriptionStatusCard(),
            const SizedBox(height: 16),

            // Payment method card
            _buildPaymentMethodCard(),
            const SizedBox(height: 24),

            // Quick actions
            _buildQuickActions(),
            const SizedBox(height: 24),

            // Feature overview
            _buildFeatureOverview(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    final theme = Theme.of(context);

    return FutureBuilder<Customer?>(
      future: FlutterUniversalPayments.instance.getCurrentCustomer(),
      builder: (context, snapshot) {
        final customerName = snapshot.data?.name ?? 'Guest';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back,',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
            Text(
              customerName,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSubscriptionStatusCard() {
    return FutureBuilder<Subscription?>(
      future: FlutterUniversalPayments.instance.getActiveSubscription(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final subscription = snapshot.data;

        return Card(
          child: InkWell(
            onTap: subscription != null
                ? () => Navigator.pushNamed(context, '/subscription')
                : null,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        subscription != null
                            ? Icons.check_circle
                            : Icons.info_outline,
                        color: subscription != null
                            ? Colors.green
                            : Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              subscription != null
                                  ? 'Active Subscription'
                                  : 'No Active Subscription',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            if (subscription != null)
                              Text(
                                'Renews ${DateFormat('MMM dd, yyyy').format(subscription.currentPeriodEnd)}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                          ],
                        ),
                      ),
                      if (subscription != null)
                        const Icon(Icons.chevron_right),
                    ],
                  ),
                  if (subscription == null) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Subscribe to unlock premium features and get the most out of the app.',
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => Navigator.pushNamed(context, '/pricing'),
                      icon: const Icon(Icons.stars),
                      label: const Text('View Plans'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPaymentMethodCard() {
    return FutureBuilder<PaymentMethod?>(
      future: FlutterUniversalPayments.instance.getDefaultPaymentMethod(),
      builder: (context, snapshot) {
        final paymentMethod = snapshot.data;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.credit_card,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Payment Method',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (paymentMethod != null)
                  Row(
                    children: [
                      Text(
                        '${paymentMethod.brand ?? 'Card'} •••• ${paymentMethod.last4 ?? '****'}',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => Navigator.pushNamed(context, '/payment'),
                        child: const Text('Update'),
                      ),
                    ],
                  )
                else
                  FilledButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/payment'),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Payment Method'),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _QuickActionCard(
              icon: Icons.shopping_cart,
              title: 'View Plans',
              subtitle: 'Browse subscriptions',
              onTap: () => Navigator.pushNamed(context, '/pricing'),
            ),
            _QuickActionCard(
              icon: Icons.payment,
              title: 'Payment',
              subtitle: 'Manage methods',
              onTap: () => Navigator.pushNamed(context, '/payment'),
            ),
            _QuickActionCard(
              icon: Icons.subscriptions,
              title: 'Subscription',
              subtitle: 'Manage plan',
              onTap: () => Navigator.pushNamed(context, '/subscription'),
            ),
            _QuickActionCard(
              icon: Icons.settings,
              title: 'Settings',
              subtitle: 'Configure app',
              onTap: () => Navigator.pushNamed(context, '/settings'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFeatureOverview() {
    final features = [
      'Multiple payment processors supported',
      'Secure payment handling',
      'Subscription management',
      'Billing history tracking',
      'Automatic retry logic',
      'Comprehensive error handling',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Package Features',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: features
                  .map(
                    (feature) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            color: Theme.of(context).colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(feature),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }
}

/// Quick action card widget
class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 32,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
