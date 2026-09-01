import 'package:save_points_pdf_templates/pdf/models/pdf_sale_invoice_model.dart';
import 'package:save_points_pdf_templates/pdf/templates/itemized_invoice_template.dart';

/// A sales invoice billed to a customer.
///
/// ```dart
/// final template = SaleInvoiceTemplate(
///   data: invoice,
///   pdfConfig: config,
///   qrCode: zatcaPayload,
/// );
/// final bytes = await PdfGenerator.generate(template: template);
/// ```
class SaleInvoiceTemplate extends ItemizedInvoiceTemplate<PdfSaleInvoiceModel> {
  SaleInvoiceTemplate({
    required super.data,
    required super.pdfConfig,
    super.headers,
    super.title,
    super.qrCode,
    super.qrCodeSize,
    super.theme,
    super.pageFormat,
    super.showRowNumbers,
    super.showSignatures,
    super.signatureLabels,
  });
}
