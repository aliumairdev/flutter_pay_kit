import 'package:flutter/material.dart';
import 'package:flutter_universal_payments/flutter_universal_payments.dart';

import '../config/config.dart';
import '../main.dart';

/// Settings screen for configuring the app and payment processor
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  ProcessorType _selectedProcessor = ProcessorType.fake;
  bool _isLoggingEnabled = true;
  bool _isSwitching = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }

  void _loadCurrentSettings() {
    final config = FlutterUniversalPayments.configuration;
    setState(() {
      _selectedProcessor = config.processor;
      _isLoggingEnabled = config.enableLogging;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // Payment Processor Section
          _buildSection(
            title: 'Payment Processor',
            icon: Icons.payment,
            children: [
              ListTile(
                title: const Text('Current Processor'),
                subtitle: Text(_selectedProcessor.name.toUpperCase()),
                trailing: const Icon(Icons.chevron_right),
                onTap: _showProcessorSelector,
              ),
              if (_isSwitching)
                const LinearProgressIndicator()
              else
                const Divider(height: 1),
            ],
          ),

          // Configuration Section
          _buildSection(
            title: 'Configuration',
            icon: Icons.settings,
            children: [
              SwitchListTile(
                title: const Text('Enable Logging'),
                subtitle: const Text('Show payment logs in console'),
                value: _isLoggingEnabled,
                onChanged: (value) {
                  setState(() => _isLoggingEnabled = value);
                  // Note: In a real app, you'd reinitialize with new config
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Logging setting saved (restart to apply)'),
                    ),
                  );
                },
              ),
              const Divider(height: 1),
              ListTile(
                title: const Text('Request Timeout'),
                subtitle: Text('${AppConfig.requestTimeout.inSeconds} seconds'),
                trailing: const Icon(Icons.timer),
              ),
            ],
          ),

          // Test Scenarios Section
          _buildSection(
            title: 'Test Scenarios',
            icon: Icons.science,
            children: [
              ListTile(
                leading: const Icon(Icons.credit_card),
                title: const Text('Test Card Numbers'),
                subtitle: const Text('View available test cards'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _showTestCards,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.bug_report),
                title: const Text('Simulate Payment Failure'),
                subtitle: const Text('Test error handling'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _simulateFailure,
              ),
            ],
          ),

          // Data Management Section
          _buildSection(
            title: 'Data Management',
            icon: Icons.storage,
            children: [
              ListTile(
                leading: const Icon(Icons.delete_sweep),
                title: const Text('Clear Cache'),
                subtitle: const Text('Remove all cached payment data'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _clearCache,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.restore),
                title: const Text('Reset Demo Data'),
                subtitle: const Text('Reset to initial state'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _resetDemoData,
              ),
            ],
          ),

          // About Section
          _buildSection(
            title: 'About',
            icon: Icons.info,
            children: [
              ListTile(
                title: const Text('Package Version'),
                subtitle: const Text('1.0.0'),
              ),
              const Divider(height: 1),
              ListTile(
                title: const Text('Current Processor'),
                subtitle: Text(
                  FlutterUniversalPayments.configuration.processor.name.toUpperCase(),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                title: const Text('Initialized'),
                subtitle: Text(
                  FlutterUniversalPayments.isInitialized ? 'Yes' : 'No',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(children: children),
        ),
      ],
    );
  }

  void _showProcessorSelector() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Select Payment Processor',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            const Divider(height: 1),
            ...ProcessorType.values.map((processor) {
              return ListTile(
                leading: Radio<ProcessorType>(
                  value: processor,
                  groupValue: _selectedProcessor,
                  onChanged: (value) {
                    if (value != null) {
                      Navigator.pop(context);
                      _switchProcessor(value);
                    }
                  },
                ),
                title: Text(processor.name.toUpperCase()),
                subtitle: Text(_getProcessorDescription(processor)),
                onTap: () {
                  Navigator.pop(context);
                  _switchProcessor(processor);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  String _getProcessorDescription(ProcessorType processor) {
    switch (processor) {
      case ProcessorType.stripe:
        return 'Popular payment platform';
      case ProcessorType.paddle:
        return 'Merchant of record solution';
      case ProcessorType.braintree:
        return 'PayPal-owned payment gateway';
      case ProcessorType.lemonSqueezy:
        return 'Modern payment platform';
      case ProcessorType.totalpay:
        return 'Global payment processor';
      case ProcessorType.fake:
        return 'Testing and development';
    }
  }

  Future<void> _switchProcessor(ProcessorType processor) async {
    if (processor == _selectedProcessor) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Switch Payment Processor?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Switch to ${processor.name.toUpperCase()}?',
            ),
            const SizedBox(height: 16),
            if (processor != ProcessorType.fake)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Note: You\'ll need valid API credentials for ${processor.name}. The demo uses the Fake processor by default.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'The Fake processor is perfect for testing without real credentials.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Switch'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSwitching = true);

    try {
      // Create new configuration with selected processor
      PaymentConfiguration config;

      switch (processor) {
        case ProcessorType.fake:
          config = PaymentConfigurationBuilder()
              .useFake(
                simulateDelays: true,
                delayDuration: const Duration(milliseconds: 500),
              )
              .enableLogging()
              .build();
          break;
        case ProcessorType.stripe:
          config = PaymentConfigurationBuilder()
              .useStripe(
                publishableKey: AppConfig.stripePublishableKey,
                secretKey: AppConfig.stripeSecretKey,
                webhookSecret: AppConfig.stripeWebhookSecret,
              )
              .enableLogging()
              .build();
          break;
        default:
          throw UnimplementedError('Processor $processor not configured in demo');
      }

      // Reinitialize the payment system
      await FlutterUniversalPayments.reinitialize(
        config,
        storage: InMemoryStorage(),
      );

      if (mounted) {
        setState(() {
          _selectedProcessor = processor;
          _isSwitching = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Switched to ${processor.name.toUpperCase()}'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSwitching = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _showTestCards() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Test Card Numbers'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Use these test cards with the Fake processor:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ...AppConfig.testCards.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.key,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        entry.value,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 12),
              const Text(
                'Use any future expiry date (e.g., 12/25) and any 3-digit CVC.',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _simulateFailure() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Simulate Payment Failure'),
        content: const Text(
          'To test error handling, use the "Declined" test card number in the payment screen:\n\n4000000000000002',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed('/payment');
            },
            child: const Text('Go to Payment'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearCache() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache?'),
        content: const Text(
          'This will clear all cached payment data. You may need to reinitialize the customer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await FlutterUniversalPayments.instance.clearCache();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cache cleared successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _resetDemoData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Demo Data?'),
        content: const Text(
          'This will reset the app to its initial state. All demo subscriptions and payment methods will be cleared.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Clear cache and reinitialize
      await FlutterUniversalPayments.instance.clearCache();
      await initializePaymentSystem();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Demo data reset successfully')),
        );

        // Navigate back to home
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}
