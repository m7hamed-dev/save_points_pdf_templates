/// A single line on an invoice, quotation or expense document.
///
/// Discount and tax can be given either way: as an absolute amount, or as a
/// rate that the line works out for itself. A rate wins when both are given.
///
/// ```dart
/// // 3 × 3,200 with 15% VAT
/// const PdfInvoiceItemModel(
///   title: 'HP ProBook 450',
///   qty: 3,
///   price: 3200,
///   taxRate: 15,
/// );
/// ```
class PdfInvoiceItemModel {
  const PdfInvoiceItemModel({
    required this.title,
    required this.qty,
    required this.price,
    double discount = 0.0,
    double tax = 0.0,
    this.discountRate,
    this.taxRate,
    this.unit,
    this.description,
    this.sku,
  }) : _discount = discount,
       _tax = tax;

  /// Item name as printed in the first column.
  final String title;

  /// Quantity. May be fractional (0.5 kg, 1.25 hours).
  final double qty;

  /// Unit price before discount and tax.
  final double price;

  final double _discount;
  final double _tax;

  /// Discount as a percentage of [subtotal] — `10` for 10%. Takes priority
  /// over the absolute amount passed as `discount`.
  final double? discountRate;

  /// Tax as a percentage of [taxableAmount] — `15` for 15% VAT. Takes
  /// priority over the absolute amount passed as `tax`.
  ///
  /// Worth using even when you could compute the amount yourself: it is what
  /// lets the document group its lines into a tax breakdown by rate, which a
  /// GCC tax invoice has to print.
  final double? taxRate;

  /// Optional unit label — `pcs`, `kg`, `hr`.
  final String? unit;

  /// Optional second line printed under [title] in a muted style.
  final String? description;

  /// Optional stock keeping unit, printed next to the title when present.
  final String? sku;

  /// `qty * price`, before discount and tax.
  double get subtotal => qty * price;

  /// Absolute discount on this line, from [discountRate] when set.
  double get discount {
    final rate = discountRate;
    return rate == null ? _discount : subtotal * rate / 100;
  }

  /// What tax is charged on: the line less its discount.
  double get taxableAmount => subtotal - discount;

  /// Absolute tax on this line, from [taxRate] when set.
  double get tax {
    final rate = taxRate;
    return rate == null ? _tax : taxableAmount * rate / 100;
  }

  /// The rate actually charged, as a percentage — the one given in [taxRate],
  /// or the one implied by an absolute amount. Zero when nothing is taxed.
  ///
  /// Rounded to two places so lines that differ only by floating-point noise
  /// still group together in a breakdown.
  double get effectiveTaxRate {
    final rate = taxRate;
    if (rate != null) return rate;
    if (taxableAmount == 0) return 0;
    return double.parse((tax / taxableAmount * 100).toStringAsFixed(2));
  }

  /// `subtotal - discount + tax` — what this line contributes to the document.
  double get total => taxableAmount + tax;

  PdfInvoiceItemModel copyWith({
    String? title,
    double? qty,
    double? price,
    double? discount,
    double? tax,
    double? discountRate,
    double? taxRate,
    String? unit,
    String? description,
    String? sku,
  }) {
    return PdfInvoiceItemModel(
      title: title ?? this.title,
      qty: qty ?? this.qty,
      price: price ?? this.price,
      discount: discount ?? _discount,
      tax: tax ?? _tax,
      discountRate: discountRate ?? this.discountRate,
      taxRate: taxRate ?? this.taxRate,
      unit: unit ?? this.unit,
      description: description ?? this.description,
      sku: sku ?? this.sku,
    );
  }
}

/// One row of a document's tax breakdown: everything charged at one rate.
///
/// A tax invoice that mixes rates — standard-rated goods beside zero-rated
/// ones — has to show what was taxed at each, not just one total.
class PdfTaxBand {
  const PdfTaxBand({
    required this.rate,
    required this.taxableAmount,
    required this.tax,
  });

  /// The rate as a percentage: `15` for 15%.
  final double rate;

  /// The amount taxed at [rate].
  final double taxableAmount;

  /// The tax charged on it.
  final double tax;
}
