/// Complete subscription management example
///
/// This example demonstrates:
/// - Creating subscriptions
/// - Checking subscription status
/// - Changing plans
/// - Canceling subscriptions
/// - Resuming subscriptions
library;

import 'package:flutter/material.dart';
import 'package:flutter_universal_payments/flutter_universal_payments.dart';

class SubscriptionManagementExample extends StatefulWidget {
  const SubscriptionManagementExample({super.key});

  @override
  State<SubscriptionManagementExample> createState() =>
      _SubscriptionManagementExampleState();
}

class _SubscriptionManagementExampleState
    extends State<SubscriptionManagementExample> {
  final PaymentService _service = FlutterUniversalPayments.instance;
  Subscription? currentSubscription;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSubscription();
  }

  Future<void> _loadSubscription() async {
    setState(() => isLoading = true);
    try {
      final subscription = await _service.getActiveSubscription('product_id');
      setState(() => currentSubscription = subscription);
    } catch (e) {
      _showError('Failed to load subscription: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _createSubscription(String priceId) async {
    setState(() => isLoading = true);
    try {
      final subscription = await _service.subscribe(
        priceId: priceId,
        trialDays: 14,
      );
      setState(() => currentSubscription = subscription);
      _showSuccess('Subscription created successfully!');
    } on ProcessorException catch (e) {
      _showError('Payment failed: ${e.message}');
    } catch (e) {
      _showError('Failed to create subscription: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _changePlan(String newPriceId) async {
    if (currentSubscription == null) return;

    setState(() => isLoading = true);
    try {
      await _service.changePlan(
        subscriptionId: currentSubscription!.id,
        newPriceId: newPriceId,
      );
      await _loadSubscription(); // Reload to get updated subscription
      _showSuccess('Plan changed successfully!');
    } catch (e) {
      _showError('Failed to change plan: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _cancelSubscription({required bool immediate}) async {
    if (currentSubscription == null) return;

    final confirmed = await _showConfirmDialog(
      'Cancel Subscription',
      immediate
          ? 'Your subscription will be canceled immediately.'
          : 'Your subscription will remain active until the end of the billing period.',
    );

    if (!confirmed) return;

    setState(() => isLoading = true);
    try {
      await _service.cancelSubscription(
        id: currentSubscription!.id,
        immediate: immediate,
      );
      await _loadSubscription();
      _showSuccess('Subscription canceled');
    } catch (e) {
      _showError('Failed to cancel subscription: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _resumeSubscription() async {
    if (currentSubscription == null) return;

    setState(() => isLoading = true);
    try {
      await _service.resumeSubscription(id: currentSubscription!.id);
      await _loadSubscription();
      _showSuccess('Subscription resumed!');
    } catch (e) {
      _showError('Failed to resume subscription: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<bool> _showConfirmDialog(String title, String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscription Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSubscription,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : currentSubscription == null
              ? _buildNoSubscription()
              : _buildSubscriptionDetails(),
    );
  }

  Widget _buildNoSubscription() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inbox, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'No Active Subscription',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => _createSubscription('price_monthly_999'),
            child: const Text('Subscribe Now'),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionDetails() {
    final sub = currentSubscription!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status card
          SubscriptionStatusWidget(subscription: sub),

          const SizedBox(height: 24),

          // Details card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Subscription Details',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow('Status', sub.status.name),
                  _buildDetailRow('Price ID', sub.priceId),
                  _buildDetailRow('Product ID', sub.productId),
                  if (sub.isOnTrial) ...[
                    _buildDetailRow(
                      'Trial Ends',
                      sub.trialEnd?.toString() ?? 'N/A',
                    ),
                  ],
                  _buildDetailRow(
                    'Current Period',
                    '${sub.currentPeriodStart} - ${sub.currentPeriodEnd}',
                  ),
                  if (sub.cancelAtPeriodEnd) ...[
                    _buildDetailRow(
                      'Cancels At',
                      sub.currentPeriodEnd.toString(),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Actions
          Text(
            'Actions',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),

          // Change plan
          if (!sub.cancelAtPeriodEnd) ...[
            ListTile(
              leading: const Icon(Icons.swap_horiz),
              title: const Text('Change Plan'),
              subtitle: const Text('Upgrade or downgrade your subscription'),
              onTap: () => _showPlanChangeDialog(),
            ),
            const Divider(),
          ],

          // Cancel subscription
          if (!sub.cancelAtPeriodEnd) ...[
            ListTile(
              leading: const Icon(Icons.cancel, color: Colors.orange),
              title: const Text('Cancel at Period End'),
              subtitle: const Text('Remain active until billing period ends'),
              onTap: () => _cancelSubscription(immediate: false),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.close, color: Colors.red),
              title: const Text('Cancel Immediately'),
              subtitle: const Text('Lose access right away'),
              onTap: () => _cancelSubscription(immediate: true),
            ),
          ] else ...[
            ListTile(
              leading: const Icon(Icons.play_arrow, color: Colors.green),
              title: const Text('Resume Subscription'),
              subtitle: const Text('Continue your subscription'),
              onTap: _resumeSubscription,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  void _showPlanChangeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Plan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Monthly - \$9.99'),
              onTap: () {
                Navigator.pop(context);
                _changePlan('price_monthly_999');
              },
            ),
            ListTile(
              title: const Text('Annual - \$99.99'),
              subtitle: const Text('Save 17%'),
              onTap: () {
                Navigator.pop(context);
                _changePlan('price_annual_9999');
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
