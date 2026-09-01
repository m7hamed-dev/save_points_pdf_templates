import 'package:save_points_pdf_templates/pdf/models/pdf_invoice_model.dart';
import 'package:save_points_pdf_templates/pdf/templates/itemized_invoice_template.dart';

/// The minimal invoice: number, customer name, date and lines.
///
/// Same layout as `SaleInvoiceTemplate` with signatures off, which suits a
/// receipt-style document that nobody signs.
class InvoiceTemplate extends ItemizedInvoiceTemplate<PdfInvoiceModel> {
  InvoiceTemplate({
    required super.data,
    required super.pdfConfig,
    super.headers,
    super.title,
    super.qrCode,
    super.qrCodeSize,
    super.theme,
    super.pageFormat,
    super.showRowNumbers,
    super.showSignatures = false,
    super.signatureLabels,
  });
}
