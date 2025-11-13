import 'package:flutter/material.dart';
import 'package:flutter_universal_payments/flutter_universal_payments.dart';

import '../config/config.dart';

/// Pricing screen displaying subscription plans using the PricingTable widget
class PricingScreen extends StatefulWidget {
  const PricingScreen({super.key});

  @override
  State<PricingScreen> createState() => _PricingScreenState();
}

class _PricingScreenState extends State<PricingScreen> {
  String? _selectedPlanId;
  bool _showComparison = false;
  PricingTableLayout _layout = PricingTableLayout.list;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Your Plan'),
        actions: [
          // Toggle comparison view
          IconButton(
            icon: Icon(
              _showComparison ? Icons.view_list : Icons.table_chart,
            ),
            onPressed: () {
              setState(() {
                _showComparison = !_showComparison;
              });
            },
            tooltip: _showComparison ? 'List View' : 'Comparison View',
          ),
          // Layout selector
          if (!_showComparison)
            PopupMenuButton<PricingTableLayout>(
              icon: const Icon(Icons.view_module),
              onSelected: (layout) {
                setState(() {
                  _layout = layout;
                });
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: PricingTableLayout.list,
                  child: Text('List Layout'),
                ),
                const PopupMenuItem(
                  value: PricingTableLayout.grid,
                  child: Text('Grid Layout'),
                ),
                const PopupMenuItem(
                  value: PricingTableLayout.row,
                  child: Text('Row Layout'),
                ),
              ],
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Pricing table with all plans
            PricingTable(
              plans: AppConfig.allPlans,
              selectedPlanId: _selectedPlanId,
              recommendedPlanId: AppConfig.proMonthlyPlan.id,
              onPlanSelected: _onPlanSelected,
              layout: _layout,
              showComparisonView: _showComparison,
              headerTitle: 'Choose the Perfect Plan',
              headerSubtitle:
                  'All plans include a free trial. Cancel anytime.',
              showHeader: true,
              ctaText: 'Get Started',
              selectedText: 'Current Plan',
            ),

            const SizedBox(height: 24),

            // Additional information
            _buildAdditionalInfo(),

            const SizedBox(height: 24),

            // FAQ section
            _buildFaqSection(),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _onPlanSelected(SubscriptionPlanData plan) {
    setState(() {
      _selectedPlanId = plan.id;
    });

    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Subscribe to ${plan.name}?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You\'re about to subscribe to the ${plan.name} plan for \$${plan.formattedPrice} ${plan.intervalText}.',
            ),
            if (plan.trialDays != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.card_giftcard,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Includes ${plan.trialDays}-day free trial',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            const Text(
              'You\'ll be redirected to add a payment method.',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedPlanId = null;
              });
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Navigate to payment screen with the selected plan
              Navigator.pushNamed(
                context,
                '/payment',
                arguments: {'plan': plan},
              );
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'What\'s Included',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildInfoItem(
                icon: Icons.shield_outlined,
                title: 'Secure Payments',
                description: 'Your payment information is encrypted and secure',
              ),
              _buildInfoItem(
                icon: Icons.access_time,
                title: 'Cancel Anytime',
                description: 'No long-term commitment, cancel whenever you want',
              ),
              _buildInfoItem(
                icon: Icons.support_agent,
                title: 'Premium Support',
                description: 'Get help from our dedicated support team',
              ),
              _buildInfoItem(
                icon: Icons.update,
                title: 'Regular Updates',
                description: 'New features and improvements every month',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 24,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Frequently Asked Questions',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          _buildFaqItem(
            question: 'Can I change my plan later?',
            answer:
                'Yes! You can upgrade or downgrade your plan at any time. Changes will be prorated based on your billing cycle.',
          ),
          _buildFaqItem(
            question: 'What payment methods do you accept?',
            answer:
                'We accept all major credit cards (Visa, Mastercard, American Express) and debit cards.',
          ),
          _buildFaqItem(
            question: 'Is there a setup fee?',
            answer:
                'No, there are no setup fees or hidden charges. You only pay the subscription price.',
          ),
          _buildFaqItem(
            question: 'What happens after the trial ends?',
            answer:
                'After your free trial, your selected payment method will be charged automatically. You\'ll receive a notification before this happens.',
          ),
        ],
      ),
    );
  }

  Widget _buildFaqItem({
    required String question,
    required String answer,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              answer,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
