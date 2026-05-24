class PdfInvoiceItemModel {
  const PdfInvoiceItemModel({
    required this.title,
    required this.qty,
    required this.price,
    this.discount,
    this.tax,
  });
  final String title;
  final double qty;
  final double price;
  final double? discount;
  final double? tax;

  double get total => qty * price;
}
