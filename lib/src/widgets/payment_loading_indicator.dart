import 'dart:async';
import 'package:flutter/material.dart';

/// A loading indicator widget specifically designed for payment processing
class PaymentLoadingIndicator extends StatefulWidget {
  /// Creates a [PaymentLoadingIndicator].
  const PaymentLoadingIndicator({
    super.key,
    this.message = 'Processing payment...',
    this.showCancelButton = false,
    this.onCancel,
    this.timeout,
    this.onTimeout,
    this.backgroundColor,
    this.indicatorColor,
    this.textStyle,
    this.padding,
    this.borderRadius = 16.0,
    this.showProgressMessages = true,
    this.progressMessages = const [
      'Verifying payment details...',
      'Processing payment...',
      'Confirming transaction...',
    ],
    this.messageInterval = const Duration(seconds: 3),
  });

  /// Message to display
  final String message;

  /// Whether to show cancel button
  final bool showCancelButton;

  /// Callback when cancel is tapped
  final VoidCallback? onCancel;

  /// Optional timeout duration
  final Duration? timeout;

  /// Callback when timeout occurs
  final VoidCallback? onTimeout;

  /// Background color
  final Color? backgroundColor;

  /// Progress indicator color
  final Color? indicatorColor;

  /// Text style for the message
  final TextStyle? textStyle;

  /// Padding
  final EdgeInsetsGeometry? padding;

  /// Border radius
  final double borderRadius;

  /// Whether to show rotating progress messages
  final bool showProgressMessages;

  /// List of progress messages to rotate through
  final List<String> progressMessages;

  /// Interval between message changes
  final Duration messageInterval;

  @override
  State<PaymentLoadingIndicator> createState() =>
      _PaymentLoadingIndicatorState();
}

class _PaymentLoadingIndicatorState extends State<PaymentLoadingIndicator> {
  Timer? _timeoutTimer;
  Timer? _messageTimer;
  int _currentMessageIndex = 0;
  String _currentMessage = '';

  @override
  void initState() {
    super.initState();
    _currentMessage = widget.showProgressMessages && widget.progressMessages.isNotEmpty
        ? widget.progressMessages[0]
        : widget.message;

    if (widget.timeout != null) {
      _timeoutTimer = Timer(widget.timeout!, _handleTimeout);
    }

    if (widget.showProgressMessages && widget.progressMessages.isNotEmpty) {
      _messageTimer = Timer.periodic(widget.messageInterval, _rotateMessage);
    }
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    _messageTimer?.cancel();
    super.dispose();
  }

  void _handleTimeout() {
    widget.onTimeout?.call();
  }

  void _rotateMessage(Timer timer) {
    if (mounted && widget.progressMessages.isNotEmpty) {
      setState(() {
        _currentMessageIndex =
            (_currentMessageIndex + 1) % widget.progressMessages.length;
        _currentMessage = widget.progressMessages[_currentMessageIndex];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Card(
        color: widget.backgroundColor ?? colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
        child: Padding(
          padding: widget.padding ?? const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Loading indicator
              SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  strokeWidth: 4,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    widget.indicatorColor ?? colorScheme.primary,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Message
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  _currentMessage,
                  key: ValueKey<String>(_currentMessage),
                  style: widget.textStyle ??
                      theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),

              // Cancel button
              if (widget.showCancelButton) ...[
                const SizedBox(height: 24),
                TextButton(
                  onPressed: widget.onCancel,
                  child: const Text('Cancel'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// An overlay loading indicator that covers the entire screen
class PaymentLoadingOverlay extends StatelessWidget {
  /// Creates a [PaymentLoadingOverlay].
  const PaymentLoadingOverlay({
    super.key,
    this.message = 'Processing payment...',
    this.showCancelButton = false,
    this.onCancel,
    this.timeout,
    this.onTimeout,
    this.barrierColor,
    this.showProgressMessages = true,
    this.progressMessages = const [
      'Verifying payment details...',
      'Processing payment...',
      'Confirming transaction...',
    ],
  });

  /// Message to display
  final String message;

  /// Whether to show cancel button
  final bool showCancelButton;

  /// Callback when cancel is tapped
  final VoidCallback? onCancel;

  /// Optional timeout duration
  final Duration? timeout;

  /// Callback when timeout occurs
  final VoidCallback? onTimeout;

  /// Color of the barrier behind the loading indicator
  final Color? barrierColor;

  /// Whether to show rotating progress messages
  final bool showProgressMessages;

  /// List of progress messages to rotate through
  final List<String> progressMessages;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: barrierColor ?? Colors.black54,
      child: PaymentLoadingIndicator(
        message: message,
        showCancelButton: showCancelButton,
        onCancel: onCancel,
        timeout: timeout,
        onTimeout: onTimeout,
        showProgressMessages: showProgressMessages,
        progressMessages: progressMessages,
      ),
    );
  }

  /// Shows the loading overlay
  static void show(
    BuildContext context, {
    String message = 'Processing payment...',
    bool showCancelButton = false,
    VoidCallback? onCancel,
    Duration? timeout,
    VoidCallback? onTimeout,
    Color? barrierColor,
    bool showProgressMessages = true,
    List<String> progressMessages = const [
      'Verifying payment details...',
      'Processing payment...',
      'Confirming transaction...',
    ],
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: barrierColor,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: PaymentLoadingOverlay(
          message: message,
          showCancelButton: showCancelButton,
          onCancel: onCancel,
          timeout: timeout,
          onTimeout: onTimeout,
          barrierColor: Colors.transparent,
          showProgressMessages: showProgressMessages,
          progressMessages: progressMessages,
        ),
      ),
    );
  }

  /// Hides the loading overlay
  static void hide(BuildContext context) {
    Navigator.of(context).pop();
  }
}

/// A compact inline loading indicator for payment processing
class CompactPaymentLoading extends StatelessWidget {
  /// Creates a [CompactPaymentLoading].
  const CompactPaymentLoading({
    super.key,
    this.message = 'Processing...',
    this.size = 20.0,
    this.color,
    this.textStyle,
  });

  /// Message to display
  final String message;

  /// Size of the loading indicator
  final double size;

  /// Color of the loading indicator
  final Color? color;

  /// Text style for the message
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              color ?? theme.colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          message,
          style: textStyle ?? theme.textTheme.bodyMedium,
        ),
      ],
    );
  }
}

/// A loading button that shows loading state during payment processing
class PaymentLoadingButton extends StatelessWidget {
  /// Creates a [PaymentLoadingButton].
  const PaymentLoadingButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.isLoading = false,
    this.loadingText,
    this.style,
    this.icon,
  });

  /// Callback when button is pressed
  final VoidCallback? onPressed;

  /// Child widget (usually Text)
  final Widget child;

  /// Whether the button is in loading state
  final bool isLoading;

  /// Text to show when loading
  final String? loadingText;

  /// Button style
  final ButtonStyle? style;

  /// Optional icon
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget buttonChild;

    if (isLoading) {
      buttonChild = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.onPrimary,
              ),
            ),
          ),
          if (loadingText != null) ...[
            const SizedBox(width: 12),
            Text(loadingText!),
          ],
        ],
      );
    } else {
      buttonChild = icon != null
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                icon!,
                const SizedBox(width: 8),
                child,
              ],
            )
          : child;
    }

    return FilledButton(
      onPressed: isLoading ? null : onPressed,
      style: style,
      child: buttonChild,
    );
  }
}

/// A shimmer loading effect for payment method placeholders
class PaymentMethodShimmer extends StatefulWidget {
  /// Creates a [PaymentMethodShimmer].
  const PaymentMethodShimmer({
    super.key,
    this.itemCount = 3,
    this.itemHeight = 80.0,
    this.spacing = 8.0,
  });

  /// Number of shimmer items to show
  final int itemCount;

  /// Height of each shimmer item
  final double itemHeight;

  /// Spacing between items
  final double spacing;

  @override
  State<PaymentMethodShimmer> createState() => _PaymentMethodShimmerState();
}

class _PaymentMethodShimmerState extends State<PaymentMethodShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: List.generate(
        widget.itemCount,
        (index) => Padding(
          padding: EdgeInsets.only(
            bottom: index < widget.itemCount - 1 ? widget.spacing : 0,
          ),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Container(
                height: widget.itemHeight,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    stops: [
                      _controller.value - 0.3,
                      _controller.value,
                      _controller.value + 0.3,
                    ].map((e) => e.clamp(0.0, 1.0)).toList(),
                    colors: isDark
                        ? [
                            Colors.grey[800]!,
                            Colors.grey[700]!,
                            Colors.grey[800]!,
                          ]
                        : [
                            Colors.grey[300]!,
                            Colors.grey[200]!,
                            Colors.grey[300]!,
                          ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
