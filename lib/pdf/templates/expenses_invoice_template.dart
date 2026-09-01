import 'package:save_points_pdf_templates/pdf/models/pdf_expenses_model.dart';
import 'package:save_points_pdf_templates/pdf/templates/itemized_invoice_template.dart';

/// An expense document — money paid out rather than billed.
///
/// Reuses the invoice layout with a payee card instead of a customer card,
/// and surfaces [PdfExpensesInvoiceModel.category] in the meta block.
class ExpensesInvoiceTemplate
    extends ItemizedInvoiceTemplate<PdfExpensesInvoiceModel> {
  ExpensesInvoiceTemplate({
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

  @override
  String get partyLabel => tr('PAID TO', 'صرف إلى');

  @override
  Map<String, String> get metaFields => {
    if (data.category?.isNotEmpty ?? false)
      tr('Category', 'التصنيف'): data.category!,
    ...super.metaFields,
  };

  @override
  List<String> get signatureLabels =>
      super.signatureLabels ??
      [tr('Approved by', 'المعتمد'), tr('Paid by', 'الصارف')];
}
