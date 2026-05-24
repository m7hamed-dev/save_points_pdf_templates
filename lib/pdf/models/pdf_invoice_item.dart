class PdfInvoiceItem {
  const PdfInvoiceItem({
    required this.title,
    required this.qty,
    required this.price,
  });
  final String title;
  final double qty;
  final double price;

  double get total => qty * price;
}
