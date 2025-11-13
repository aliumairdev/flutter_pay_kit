import 'package:flutter/material.dart';
import 'subscription_card.dart';

/// Layout mode for the pricing table
enum PricingTableLayout {
  /// Display plans in a vertical list
  list,

  /// Display plans in a grid
  grid,

  /// Display plans in a horizontal scrollable row
  row,
}

/// A widget for displaying multiple subscription pricing options
class PricingTable extends StatelessWidget {
  /// Creates a [PricingTable].
  const PricingTable({
    super.key,
    required this.plans,
    this.selectedPlanId,
    this.onPlanSelected,
    this.layout = PricingTableLayout.list,
    this.showComparisonView = false,
    this.recommendedPlanId,
    this.gridColumns = 2,
    this.spacing = 16.0,
    this.padding,
    this.headerTitle,
    this.headerSubtitle,
    this.showHeader = true,
    this.ctaText = 'Select Plan',
    this.selectedText = 'Current Plan',
    this.emptyStateWidget,
    this.loadingWidget,
    this.isLoading = false,
  });

  /// List of subscription plans to display
  final List<SubscriptionPlanData> plans;

  /// ID of currently selected plan
  final String? selectedPlanId;

  /// Callback when a plan is selected
  final void Function(SubscriptionPlanData)? onPlanSelected;

  /// Layout mode for the pricing table
  final PricingTableLayout layout;

  /// Whether to show comparison view with features
  final bool showComparisonView;

  /// ID of recommended plan (will be highlighted)
  final String? recommendedPlanId;

  /// Number of columns for grid layout
  final int gridColumns;

  /// Spacing between plan cards
  final double spacing;

  /// Padding around the pricing table
  final EdgeInsetsGeometry? padding;

  /// Title for the header
  final String? headerTitle;

  /// Subtitle for the header
  final String? headerSubtitle;

  /// Whether to show header
  final bool showHeader;

  /// Text for call-to-action button
  final String ctaText;

  /// Text to show when plan is selected
  final String selectedText;

  /// Widget to show when there are no plans
  final Widget? emptyStateWidget;

  /// Widget to show when loading
  final Widget? loadingWidget;

  /// Whether the pricing table is in loading state
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return loadingWidget ??
          const Center(
            child: CircularProgressIndicator(),
          );
    }

    if (plans.isEmpty) {
      return emptyStateWidget ??
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inbox_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(height: 16),
                Text(
                  'No plans available',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          );
    }

    return Padding(
      padding: padding ?? EdgeInsets.all(spacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          if (showHeader) ...[
            _buildHeader(context),
            SizedBox(height: spacing * 2),
          ],

          // Plans
          if (showComparisonView)
            _buildComparisonView(context)
          else
            _buildPlanLayout(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        if (headerTitle != null)
          Text(
            headerTitle!,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        if (headerSubtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            headerSubtitle!,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.textTheme.bodySmall?.color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _buildPlanLayout(BuildContext context) {
    switch (layout) {
      case PricingTableLayout.list:
        return _buildListView(context);
      case PricingTableLayout.grid:
        return _buildGridView(context);
      case PricingTableLayout.row:
        return _buildRowView(context);
    }
  }

  Widget _buildListView(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: plans.length,
      separatorBuilder: (context, index) => SizedBox(height: spacing),
      itemBuilder: (context, index) {
        final plan = plans[index];
        return _buildPlanCard(context, plan);
      },
    );
  }

  Widget _buildGridView(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: gridColumns,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
        childAspectRatio: 0.75,
      ),
      itemCount: plans.length,
      itemBuilder: (context, index) {
        final plan = plans[index];
        return _buildPlanCard(context, plan);
      },
    );
  }

  Widget _buildRowView(BuildContext context) {
    return SizedBox(
      height: 500,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: plans.length,
        separatorBuilder: (context, index) => SizedBox(width: spacing),
        itemBuilder: (context, index) {
          final plan = plans[index];
          return SizedBox(
            width: 300,
            child: _buildPlanCard(context, plan),
          );
        },
      ),
    );
  }

  Widget _buildPlanCard(BuildContext context, SubscriptionPlanData plan) {
    final isSelected = selectedPlanId == plan.id;
    final isRecommended = recommendedPlanId == plan.id;

    return SubscriptionCard(
      plan: plan.copyWith(
        isBestValue: isRecommended || plan.isBestValue,
      ),
      isSelected: isSelected,
      onSelectTap: () => onPlanSelected?.call(plan),
      ctaText: ctaText,
      selectedText: selectedText,
    );
  }

  Widget _buildComparisonView(BuildContext context) {
    final theme = Theme.of(context);
    final allFeatures = _getAllFeatures();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          const DataColumn(label: Text('Features')),
          ...plans.map((plan) {
            final isSelected = selectedPlanId == plan.id;
            final isRecommended = recommendedPlanId == plan.id;

            return DataColumn(
              label: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        plan.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isRecommended) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'BEST',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${plan.formattedPrice}',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    plan.intervalText,
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: isSelected
                        ? null
                        : () => onPlanSelected?.call(plan),
                    child: Text(isSelected ? selectedText : ctaText),
                  ),
                ],
              ),
            );
          }),
        ],
        rows: allFeatures.map((feature) {
          return DataRow(
            cells: [
              DataCell(Text(feature)),
              ...plans.map((plan) {
                final hasFeature = plan.features.contains(feature);
                return DataCell(
                  Icon(
                    hasFeature ? Icons.check_circle : Icons.cancel,
                    color: hasFeature ? Colors.green : Colors.grey,
                    size: 20,
                  ),
                );
              }),
            ],
          );
        }).toList(),
      ),
    );
  }

  List<String> _getAllFeatures() {
    final allFeatures = <String>{};
    for (final plan in plans) {
      allFeatures.addAll(plan.features);
    }
    return allFeatures.toList();
  }
}

/// Extension to copy SubscriptionPlanData with modifications
extension SubscriptionPlanDataCopyWith on SubscriptionPlanData {
  /// Creates a copy of this plan with some fields replaced
  SubscriptionPlanData copyWith({
    String? id,
    String? name,
    int? price,
    String? currency,
    BillingInterval? interval,
    int? intervalCount,
    String? description,
    List<String>? features,
    int? trialDays,
    bool? isBestValue,
    bool? isPopular,
    Map<String, dynamic>? metadata,
  }) {
    return SubscriptionPlanData(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      interval: interval ?? this.interval,
      intervalCount: intervalCount ?? this.intervalCount,
      description: description ?? this.description,
      features: features ?? this.features,
      trialDays: trialDays ?? this.trialDays,
      isBestValue: isBestValue ?? this.isBestValue,
      isPopular: isPopular ?? this.isPopular,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// A responsive pricing table that adapts to screen size
class ResponsivePricingTable extends StatelessWidget {
  /// Creates a [ResponsivePricingTable].
  const ResponsivePricingTable({
    super.key,
    required this.plans,
    this.selectedPlanId,
    this.onPlanSelected,
    this.recommendedPlanId,
    this.showComparisonView = false,
    this.mobileBreakpoint = 600,
    this.tabletBreakpoint = 900,
    this.headerTitle,
    this.headerSubtitle,
    this.showHeader = true,
    this.ctaText = 'Select Plan',
    this.selectedText = 'Current Plan',
  });

  /// List of subscription plans to display
  final List<SubscriptionPlanData> plans;

  /// ID of currently selected plan
  final String? selectedPlanId;

  /// Callback when a plan is selected
  final void Function(SubscriptionPlanData)? onPlanSelected;

  /// ID of recommended plan
  final String? recommendedPlanId;

  /// Whether to show comparison view
  final bool showComparisonView;

  /// Mobile breakpoint in pixels
  final double mobileBreakpoint;

  /// Tablet breakpoint in pixels
  final double tabletBreakpoint;

  /// Title for the header
  final String? headerTitle;

  /// Subtitle for the header
  final String? headerSubtitle;

  /// Whether to show header
  final bool showHeader;

  /// Text for call-to-action button
  final String ctaText;

  /// Text to show when plan is selected
  final String selectedText;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        PricingTableLayout layout;
        int gridColumns = 2;

        if (width < mobileBreakpoint) {
          // Mobile: use list layout
          layout = PricingTableLayout.list;
        } else if (width < tabletBreakpoint) {
          // Tablet: use grid with 2 columns
          layout = PricingTableLayout.grid;
          gridColumns = 2;
        } else {
          // Desktop: use grid with 3 columns or row layout
          if (plans.length <= 3) {
            layout = PricingTableLayout.row;
          } else {
            layout = PricingTableLayout.grid;
            gridColumns = 3;
          }
        }

        return PricingTable(
          plans: plans,
          selectedPlanId: selectedPlanId,
          onPlanSelected: onPlanSelected,
          layout: layout,
          showComparisonView: showComparisonView,
          recommendedPlanId: recommendedPlanId,
          gridColumns: gridColumns,
          headerTitle: headerTitle,
          headerSubtitle: headerSubtitle,
          showHeader: showHeader,
          ctaText: ctaText,
          selectedText: selectedText,
        );
      },
    );
  }
}
