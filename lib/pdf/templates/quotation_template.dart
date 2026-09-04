import 'package:pdf/pdf.dart';
import 'package:save_points_pdf_templates/pdf/models/pdf_quotation_model.dart';
import 'package:save_points_pdf_templates/pdf/templates/itemized_invoice_template.dart';

/// A quotation (عرض سعر): the invoice layout with the debt taken out.
///
/// No paid figure, no balance due and no paid/unpaid stamp — none of them mean
/// anything before the customer accepts. What replaces them is the one fact a
/// quotation turns on: whether it is still valid.
class QuotationTemplate extends ItemizedInvoiceTemplate<PdfQuotationModel> {
  QuotationTemplate({
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
  bool get showSettlement => false;

  @override
  String get partyLabel => labels.quotedTo;

  @override
  String? get statusLabel {
    if (data.validUntil == null) return null;
    return data.isExpiredOn(asOf) ? labels.statusExpired : labels.statusValid;
  }

  @override
  PdfColor? get statusColor =>
      data.isExpiredOn(asOf) ? PdfColors.red700 : PdfColors.green700;

  @override
  Map<String, String> get metaFields => {
    ...super.metaFields,
    if (data.validUntil != null)
      labels.validUntil: format.longDate(data.validUntil),
  };

  @override
  String get settlementLabel => labels.terms;

  @override
  Map<String, String> get settlementLines => {
    if (data.paymentMethod.isNotEmpty) labels.payment: data.paymentMethod,
    if (data.terms?.isNotEmpty ?? false) '': data.terms!,
  };

  /// A quotation is signed to accept it, not to acknowledge receipt.
  @override
  List<String> get signatureLabels =>
      super.signatureLabels ?? [labels.quotedBy, labels.acceptedBy];
}
