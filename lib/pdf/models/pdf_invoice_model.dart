import 'package:save_points_pdf_templates/pdf/models/pdf_invoice_item.dart';

class PdfInvoiceModel {
  const PdfInvoiceModel({
    required this.invoiceNo,
    required this.customerName,
    required this.date,
    required this.items,
  });

  final String invoiceNo;
  final String customerName;
  final DateTime date;
  final List<PdfInvoiceItem> items;

  double get total => items.fold(0, (sum, item) => sum + item.total);
}
