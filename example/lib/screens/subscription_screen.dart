import 'package:flutter/material.dart';
import 'package:flutter_universal_payments/flutter_universal_payments.dart';
import 'package:intl/intl.dart';

import '../config/config.dart';

/// Subscription management screen
class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Subscription'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: FutureBuilder<Subscription?>(
          future: FlutterUniversalPayments.instance.getActiveSubscription(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final subscription = snapshot.data;

            if (subscription == null) {
              return _buildNoSubscriptionState();
            }

            return _buildSubscriptionDetails(subscription);
          },
        ),
      ),
    );
  }

  Widget _buildNoSubscriptionState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 24),
            Text(
              'No Active Subscription',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'Subscribe to unlock premium features and get the most out of the app.',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/pricing'),
              icon: const Icon(Icons.stars),
              label: const Text('View Plans'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionDetails(Subscription subscription) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Subscription status widget
          FutureBuilder<PaymentMethod?>(
            future: FlutterUniversalPayments.instance.getDefaultPaymentMethod(),
            builder: (context, paymentSnapshot) {
              return SubscriptionStatusWidget(
                subscription: subscription,
                planName: _getPlanName(subscription),
                paymentMethod: paymentSnapshot.data,
                onCancel: () => _cancelSubscription(subscription),
                onChangePlan: () => Navigator.pushNamed(context, '/pricing'),
                onUpdatePayment: () => Navigator.pushNamed(context, '/payment'),
                onViewBillingHistory: () => _showBillingHistory(),
                onResume: () => _resumeSubscription(subscription),
              );
            },
          ),

          const SizedBox(height: 24),

          // Subscription details card
          _buildDetailsCard(subscription),

          const SizedBox(height: 16),

          // Billing history preview
          _buildBillingHistoryPreview(),
        ],
      ),
    );
  }

  Widget _buildDetailsCard(Subscription subscription) {
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Subscription Details',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
              icon: Icons.badge,
              label: 'Subscription ID',
              value: subscription.id,
            ),
            _buildDetailRow(
              icon: Icons.calendar_today,
              label: 'Started',
              value: dateFormat.format(subscription.currentPeriodStart),
            ),
            _buildDetailRow(
              icon: Icons.event,
              label: subscription.cancelAtPeriodEnd
                  ? 'Ends On'
                  : 'Renews On',
              value: dateFormat.format(subscription.currentPeriodEnd),
            ),
            if (subscription.isOnTrial) ...[
              _buildDetailRow(
                icon: Icons.card_giftcard,
                label: 'Trial Ends',
                value: subscription.trialEnd != null
                    ? dateFormat.format(subscription.trialEnd!)
                    : 'N/A',
              ),
            ],
            _buildDetailRow(
              icon: Icons.verified,
              label: 'Status',
              value: subscription.status.name.toUpperCase(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillingHistoryPreview() {
    return FutureBuilder<List<Charge>>(
      future: FlutterUniversalPayments.instance.getPaymentHistory(limit: 5),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final charges = snapshot.data!;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Recent Payments',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    TextButton(
                      onPressed: _showBillingHistory,
                      child: const Text('View All'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...charges.map((charge) => _buildChargeItem(charge)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildChargeItem(Charge charge) {
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: charge.status == ChargeStatus.succeeded
                  ? Colors.green.withOpacity(0.1)
                  : Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              charge.status == ChargeStatus.succeeded
                  ? Icons.check_circle
                  : Icons.error,
              color: charge.status == ChargeStatus.succeeded
                  ? Colors.green
                  : Colors.red,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  charge.description ?? 'Payment',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  dateFormat.format(charge.created),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Text(
            '\$${(charge.amount / 100).toStringAsFixed(2)}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    try {
      await FlutterUniversalPayments.instance.refreshSubscriptions();
      await FlutterUniversalPayments.instance.refreshCustomer();
      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error refreshing: $e')),
        );
      }
    }
  }

  Future<void> _cancelSubscription(Subscription subscription) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Subscription?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Are you sure you want to cancel your subscription?',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Your subscription will remain active until ${DateFormat('MMM dd, yyyy').format(subscription.currentPeriodEnd)}.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep Subscription'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Cancel Subscription'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await FlutterUniversalPayments.instance.cancelSubscription(
        subscription.id,
        immediate: false,
      );

      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Subscription will be canceled at period end'),
          ),
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

  Future<void> _resumeSubscription(Subscription subscription) async {
    try {
      await FlutterUniversalPayments.instance.resumeSubscription(
        subscription.id,
      );

      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Subscription resumed successfully')),
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

  void _showBillingHistory() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return FutureBuilder<List<Charge>>(
            future:
                FlutterUniversalPayments.instance.getPaymentHistory(limit: 50),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final charges = snapshot.data ?? [];

              return Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      border: Border(
                        bottom: BorderSide(
                          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Billing History',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: charges.isEmpty
                        ? const Center(child: Text('No payment history'))
                        : ListView.separated(
                            controller: scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: charges.length,
                            separatorBuilder: (context, index) =>
                                const Divider(),
                            itemBuilder: (context, index) {
                              final charge = charges[index];
                              return _buildChargeItem(charge);
                            },
                          ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  String _getPlanName(Subscription subscription) {
    // Try to match with configured plans
    final plan = AppConfig.allPlans.where((p) => p.id == subscription.productId).firstOrNull;
    return plan?.name ?? 'Subscription';
  }
}
