/// A single line on an invoice, quotation or expense document.
class PdfInvoiceItemModel {
  const PdfInvoiceItemModel({
    required this.title,
    required this.qty,
    required this.price,
    this.discount = 0.0,
    this.tax = 0.0,
    this.unit,
    this.description,
    this.sku,
  });

  /// Item name as printed in the first column.
  final String title;

  /// Quantity. May be fractional (0.5 kg, 1.25 hours).
  final double qty;

  /// Unit price before discount and tax.
  final double price;

  /// Absolute discount applied to this line, not a percentage.
  final double discount;

  /// Absolute tax applied to this line, not a percentage.
  final double tax;

  /// Optional unit label — `pcs`, `kg`, `hr`.
  final String? unit;

  /// Optional second line printed under [title] in a muted style.
  final String? description;

  /// Optional stock keeping unit, printed next to the title when present.
  final String? sku;

  /// `qty * price`, before [discount] and [tax].
  double get subtotal => qty * price;

  /// `subtotal - discount + tax` — what this line contributes to the document.
  double get total => subtotal - discount + tax;

  PdfInvoiceItemModel copyWith({
    String? title,
    double? qty,
    double? price,
    double? discount,
    double? tax,
    String? unit,
    String? description,
    String? sku,
  }) {
    return PdfInvoiceItemModel(
      title: title ?? this.title,
      qty: qty ?? this.qty,
      price: price ?? this.price,
      discount: discount ?? this.discount,
      tax: tax ?? this.tax,
      unit: unit ?? this.unit,
      description: description ?? this.description,
      sku: sku ?? this.sku,
    );
  }
}
