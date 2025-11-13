import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Data class representing complete payment card information
class PaymentCardData {
  /// Creates a [PaymentCardData].
  const PaymentCardData({
    required this.cardNumber,
    required this.expiryMonth,
    required this.expiryYear,
    required this.cvc,
    this.postalCode,
    this.cardBrand,
  });

  /// Card number without spaces
  final String cardNumber;

  /// Expiry month (1-12)
  final int expiryMonth;

  /// Expiry year (e.g., 2025)
  final int expiryYear;

  /// Card verification code
  final String cvc;

  /// Postal/ZIP code
  final String? postalCode;

  /// Detected card brand
  final CardBrand? cardBrand;

  /// Whether all required fields are valid
  bool get isComplete {
    return cardNumber.isNotEmpty &&
        expiryMonth > 0 &&
        expiryYear > 0 &&
        cvc.isNotEmpty;
  }
}

/// Supported card brands
enum CardBrand {
  /// Visa card
  visa,

  /// Mastercard
  mastercard,

  /// American Express
  amex,

  /// Discover card
  discover,

  /// Diners Club
  dinersClub,

  /// JCB card
  jcb,

  /// UnionPay card
  unionPay,

  /// Unknown or unsupported brand
  unknown,
}

/// Extension to get card brand display properties
extension CardBrandExtension on CardBrand {
  /// Get the display name for the card brand
  String get displayName {
    switch (this) {
      case CardBrand.visa:
        return 'Visa';
      case CardBrand.mastercard:
        return 'Mastercard';
      case CardBrand.amex:
        return 'American Express';
      case CardBrand.discover:
        return 'Discover';
      case CardBrand.dinersClub:
        return 'Diners Club';
      case CardBrand.jcb:
        return 'JCB';
      case CardBrand.unionPay:
        return 'UnionPay';
      case CardBrand.unknown:
        return 'Card';
    }
  }

  /// Get the icon for the card brand
  IconData get icon {
    // Using material icons as placeholders
    // In production, you'd use actual card brand icons/images
    switch (this) {
      case CardBrand.visa:
      case CardBrand.mastercard:
      case CardBrand.amex:
      case CardBrand.discover:
      case CardBrand.dinersClub:
      case CardBrand.jcb:
      case CardBrand.unionPay:
        return Icons.credit_card;
      case CardBrand.unknown:
        return Icons.credit_card_outlined;
    }
  }

  /// Get expected CVC length for the card brand
  int get cvcLength {
    return this == CardBrand.amex ? 4 : 3;
  }

  /// Get expected card number length for the card brand
  int get cardNumberLength {
    switch (this) {
      case CardBrand.amex:
        return 15;
      case CardBrand.dinersClub:
        return 14;
      default:
        return 16;
    }
  }
}

/// A comprehensive credit card input widget with validation and formatting
class PaymentCardInput extends StatefulWidget {
  /// Creates a [PaymentCardInput].
  const PaymentCardInput({
    super.key,
    this.onCardComplete,
    this.onCardNumberChanged,
    this.onExpiryChanged,
    this.onCvcChanged,
    this.onPostalCodeChanged,
    this.cardNumberDecoration,
    this.expiryDecoration,
    this.cvcDecoration,
    this.postalCodeDecoration,
    this.textStyle,
    this.errorStyle,
    this.labelStyle,
    this.autofocus = false,
    this.enabled = true,
    this.requirePostalCode = false,
    this.showCardBrandIcon = true,
    this.cardNumberLabel = 'Card Number',
    this.expiryLabel = 'MM/YY',
    this.cvcLabel = 'CVC',
    this.postalCodeLabel = 'Postal Code',
    this.spacing = 16.0,
    this.useCupertinoStyle = false,
  });

  /// Callback when all card fields are complete and valid
  final void Function(PaymentCardData)? onCardComplete;

  /// Callback when card number changes
  final void Function(String?)? onCardNumberChanged;

  /// Callback when expiry date changes
  final void Function(int? month, int? year)? onExpiryChanged;

  /// Callback when CVC changes
  final void Function(String?)? onCvcChanged;

  /// Callback when postal code changes
  final void Function(String?)? onPostalCodeChanged;

  /// Custom decoration for card number field
  final InputDecoration? cardNumberDecoration;

  /// Custom decoration for expiry field
  final InputDecoration? expiryDecoration;

  /// Custom decoration for CVC field
  final InputDecoration? cvcDecoration;

  /// Custom decoration for postal code field
  final InputDecoration? postalCodeDecoration;

  /// Text style for input fields
  final TextStyle? textStyle;

  /// Text style for error messages
  final TextStyle? errorStyle;

  /// Text style for labels
  final TextStyle? labelStyle;

  /// Whether to autofocus the card number field
  final bool autofocus;

  /// Whether the input fields are enabled
  final bool enabled;

  /// Whether postal code is required
  final bool requirePostalCode;

  /// Whether to show card brand icon
  final bool showCardBrandIcon;

  /// Label for card number field
  final String cardNumberLabel;

  /// Label for expiry field
  final String expiryLabel;

  /// Label for CVC field
  final String cvcLabel;

  /// Label for postal code field
  final String postalCodeLabel;

  /// Spacing between form fields
  final double spacing;

  /// Use Cupertino-style inputs instead of Material
  final bool useCupertinoStyle;

  @override
  State<PaymentCardInput> createState() => _PaymentCardInputState();
}

class _PaymentCardInputState extends State<PaymentCardInput> {
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvcController = TextEditingController();
  final _postalCodeController = TextEditingController();

  final _cardNumberFocus = FocusNode();
  final _expiryFocus = FocusNode();
  final _cvcFocus = FocusNode();
  final _postalCodeFocus = FocusNode();

  CardBrand _detectedBrand = CardBrand.unknown;
  String? _cardNumberError;
  String? _expiryError;
  String? _cvcError;
  String? _postalCodeError;

  @override
  void initState() {
    super.initState();
    _cardNumberController.addListener(_onCardNumberChanged);
    _expiryController.addListener(_onExpiryChanged);
    _cvcController.addListener(_onCvcChanged);
    _postalCodeController.addListener(_onPostalCodeChanged);
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvcController.dispose();
    _postalCodeController.dispose();
    _cardNumberFocus.dispose();
    _expiryFocus.dispose();
    _cvcFocus.dispose();
    _postalCodeFocus.dispose();
    super.dispose();
  }

  void _onCardNumberChanged() {
    final text = _cardNumberController.text.replaceAll(' ', '');
    final brand = _detectCardBrand(text);

    setState(() {
      _detectedBrand = brand;
      _cardNumberError = _validateCardNumber(text, brand);
    });

    widget.onCardNumberChanged?.call(text.isEmpty ? null : text);
    _checkCompletion();
  }

  void _onExpiryChanged() {
    final text = _expiryController.text;
    setState(() {
      _expiryError = _validateExpiry(text);
    });

    final parts = text.split('/');
    if (parts.length == 2) {
      final month = int.tryParse(parts[0]);
      final year = int.tryParse(parts[1]);
      widget.onExpiryChanged?.call(month, year);
    } else {
      widget.onExpiryChanged?.call(null, null);
    }

    _checkCompletion();
  }

  void _onCvcChanged() {
    final text = _cvcController.text;
    setState(() {
      _cvcError = _validateCvc(text, _detectedBrand);
    });

    widget.onCvcChanged?.call(text.isEmpty ? null : text);
    _checkCompletion();
  }

  void _onPostalCodeChanged() {
    final text = _postalCodeController.text;
    setState(() {
      _postalCodeError = _validatePostalCode(text);
    });

    widget.onPostalCodeChanged?.call(text.isEmpty ? null : text);
    _checkCompletion();
  }

  void _checkCompletion() {
    final cardNumber = _cardNumberController.text.replaceAll(' ', '');
    final expiry = _expiryController.text;
    final cvc = _cvcController.text;
    final postalCode = _postalCodeController.text;

    if (_cardNumberError == null &&
        _expiryError == null &&
        _cvcError == null &&
        (_postalCodeError == null || !widget.requirePostalCode) &&
        cardNumber.isNotEmpty &&
        expiry.isNotEmpty &&
        cvc.isNotEmpty &&
        (!widget.requirePostalCode || postalCode.isNotEmpty)) {
      final parts = expiry.split('/');
      if (parts.length == 2) {
        final month = int.tryParse(parts[0]);
        final year = int.tryParse(parts[1]);
        if (month != null && year != null) {
          widget.onCardComplete?.call(
            PaymentCardData(
              cardNumber: cardNumber,
              expiryMonth: month,
              expiryYear: 2000 + year,
              cvc: cvc,
              postalCode: postalCode.isEmpty ? null : postalCode,
              cardBrand: _detectedBrand,
            ),
          );
        }
      }
    }
  }

  CardBrand _detectCardBrand(String number) {
    if (number.isEmpty) return CardBrand.unknown;

    // Visa: starts with 4
    if (number.startsWith('4')) return CardBrand.visa;

    // Mastercard: 51-55, 2221-2720
    if (RegExp(r'^5[1-5]').hasMatch(number)) return CardBrand.mastercard;
    if (number.length >= 4) {
      final prefix = int.tryParse(number.substring(0, 4));
      if (prefix != null && prefix >= 2221 && prefix <= 2720) {
        return CardBrand.mastercard;
      }
    }

    // Amex: starts with 34 or 37
    if (RegExp(r'^3[47]').hasMatch(number)) return CardBrand.amex;

    // Discover: starts with 6011, 622126-622925, 644-649, 65
    if (RegExp(r'^6011|^64[4-9]|^65').hasMatch(number)) {
      return CardBrand.discover;
    }
    if (number.length >= 6) {
      final prefix = int.tryParse(number.substring(0, 6));
      if (prefix != null && prefix >= 622126 && prefix <= 622925) {
        return CardBrand.discover;
      }
    }

    // Diners Club: starts with 36, 38, 300-305
    if (RegExp(r'^3(?:0[0-5]|[68])').hasMatch(number)) {
      return CardBrand.dinersClub;
    }

    // JCB: starts with 35
    if (number.startsWith('35')) return CardBrand.jcb;

    // UnionPay: starts with 62
    if (number.startsWith('62')) return CardBrand.unionPay;

    return CardBrand.unknown;
  }

  String? _validateCardNumber(String number, CardBrand brand) {
    if (number.isEmpty) return null;

    if (number.length < 13) return 'Card number is too short';

    final expectedLength = brand.cardNumberLength;
    if (number.length != expectedLength) {
      return 'Card number should be $expectedLength digits';
    }

    // Luhn algorithm validation
    if (!_luhnCheck(number)) return 'Invalid card number';

    return null;
  }

  bool _luhnCheck(String number) {
    int sum = 0;
    bool alternate = false;

    for (int i = number.length - 1; i >= 0; i--) {
      int digit = int.parse(number[i]);

      if (alternate) {
        digit *= 2;
        if (digit > 9) digit -= 9;
      }

      sum += digit;
      alternate = !alternate;
    }

    return sum % 10 == 0;
  }

  String? _validateExpiry(String expiry) {
    if (expiry.isEmpty) return null;

    final parts = expiry.split('/');
    if (parts.length != 2) return 'Invalid format';

    final month = int.tryParse(parts[0]);
    final year = int.tryParse(parts[1]);

    if (month == null || year == null) return 'Invalid date';
    if (month < 1 || month > 12) return 'Invalid month';

    final now = DateTime.now();
    final currentYear = now.year % 100;
    final currentMonth = now.month;

    if (year < currentYear) return 'Card expired';
    if (year == currentYear && month < currentMonth) return 'Card expired';

    return null;
  }

  String? _validateCvc(String cvc, CardBrand brand) {
    if (cvc.isEmpty) return null;

    final expectedLength = brand.cvcLength;
    if (cvc.length != expectedLength) {
      return 'CVC should be $expectedLength digits';
    }

    return null;
  }

  String? _validatePostalCode(String postalCode) {
    if (!widget.requirePostalCode) return null;
    if (postalCode.isEmpty) return null;
    if (postalCode.length < 3) return 'Postal code is too short';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Card Number Field
        Semantics(
          label: 'Credit card number input',
          child: TextField(
            controller: _cardNumberController,
            focusNode: _cardNumberFocus,
            decoration: (widget.cardNumberDecoration ??
                    InputDecoration(
                      labelText: widget.cardNumberLabel,
                      hintText: '1234 5678 9012 3456',
                      errorText: _cardNumberError,
                      suffixIcon: widget.showCardBrandIcon
                          ? Icon(_detectedBrand.icon)
                          : null,
                    ))
                .copyWith(
              errorText: _cardNumberError,
              labelStyle: widget.labelStyle,
              errorStyle: widget.errorStyle,
            ),
            style: widget.textStyle,
            keyboardType: TextInputType.number,
            autofocus: widget.autofocus,
            enabled: widget.enabled,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(_detectedBrand.cardNumberLength),
              _CardNumberInputFormatter(),
            ],
            onSubmitted: (_) => _expiryFocus.requestFocus(),
            textInputAction: TextInputAction.next,
          ),
        ),

        SizedBox(height: widget.spacing),

        // Expiry and CVC Row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Expiry Field
            Expanded(
              child: Semantics(
                label: 'Card expiry date input',
                child: TextField(
                  controller: _expiryController,
                  focusNode: _expiryFocus,
                  decoration: (widget.expiryDecoration ??
                          InputDecoration(
                            labelText: widget.expiryLabel,
                            hintText: 'MM/YY',
                            errorText: _expiryError,
                          ))
                      .copyWith(
                    errorText: _expiryError,
                    labelStyle: widget.labelStyle,
                    errorStyle: widget.errorStyle,
                  ),
                  style: widget.textStyle,
                  keyboardType: TextInputType.number,
                  enabled: widget.enabled,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                    _ExpiryDateInputFormatter(),
                  ],
                  onSubmitted: (_) => _cvcFocus.requestFocus(),
                  textInputAction: TextInputAction.next,
                ),
              ),
            ),

            SizedBox(width: widget.spacing),

            // CVC Field
            Expanded(
              child: Semantics(
                label: 'Card security code input',
                child: TextField(
                  controller: _cvcController,
                  focusNode: _cvcFocus,
                  decoration: (widget.cvcDecoration ??
                          InputDecoration(
                            labelText: widget.cvcLabel,
                            hintText: _detectedBrand == CardBrand.amex
                                ? '1234'
                                : '123',
                            errorText: _cvcError,
                          ))
                      .copyWith(
                    errorText: _cvcError,
                    labelStyle: widget.labelStyle,
                    errorStyle: widget.errorStyle,
                  ),
                  style: widget.textStyle,
                  keyboardType: TextInputType.number,
                  enabled: widget.enabled,
                  obscureText: true,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(_detectedBrand.cvcLength),
                  ],
                  onSubmitted: (_) {
                    if (widget.requirePostalCode) {
                      _postalCodeFocus.requestFocus();
                    }
                  },
                  textInputAction: widget.requirePostalCode
                      ? TextInputAction.next
                      : TextInputAction.done,
                ),
              ),
            ),
          ],
        ),

        // Postal Code Field (optional)
        if (widget.requirePostalCode) ...[
          SizedBox(height: widget.spacing),
          Semantics(
            label: 'Postal code input',
            child: TextField(
              controller: _postalCodeController,
              focusNode: _postalCodeFocus,
              decoration: (widget.postalCodeDecoration ??
                      InputDecoration(
                        labelText: widget.postalCodeLabel,
                        hintText: '12345',
                        errorText: _postalCodeError,
                      ))
                  .copyWith(
                errorText: _postalCodeError,
                labelStyle: widget.labelStyle,
                errorStyle: widget.errorStyle,
              ),
              style: widget.textStyle,
              keyboardType: TextInputType.text,
              enabled: widget.enabled,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [
                LengthLimitingTextInputFormatter(10),
              ],
              textInputAction: TextInputAction.done,
            ),
          ),
        ],
      ],
    );
  }
}

/// Input formatter for card number with spacing
class _CardNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      final nonZeroIndex = i + 1;
      if (nonZeroIndex % 4 == 0 && nonZeroIndex != text.length) {
        buffer.write(' ');
      }
    }

    final string = buffer.toString();
    return newValue.copyWith(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}

/// Input formatter for expiry date (MM/YY)
class _ExpiryDateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;

    if (text.length > 2) {
      final month = text.substring(0, 2);
      final year = text.substring(2);
      return newValue.copyWith(
        text: '$month/$year',
        selection: TextSelection.collapsed(offset: '$month/$year'.length),
      );
    }

    return newValue;
  }
}
