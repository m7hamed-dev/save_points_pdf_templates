import 'package:save_points_pdf_templates/pdf/models/pdf_purchase_order_model.dart';
import 'package:save_points_pdf_templates/pdf/templates/itemized_invoice_template.dart';

/// A purchase order (أمر شراء): priced lines addressed to a supplier.
///
/// Prices, because the supplier is being told what you expect to pay; no paid
/// figure and no balance, because nothing is owed until they invoice you.
class PurchaseOrderTemplate
    extends ItemizedInvoiceTemplate<PdfPurchaseOrderModel> {
  PurchaseOrderTemplate({
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
  String get partyLabel => labels.supplier;

  @override
  Map<String, String> get metaFields => {
    ...super.metaFields,
    if (data.expectedDate != null)
      labels.expectedDelivery: format.longDate(data.expectedDate),
    if (data.deliveryAddress?.isNotEmpty ?? false)
      labels.deliverTo: data.deliveryAddress!,
  };

  @override
  List<String> get signatureLabels =>
      super.signatureLabels ?? [labels.orderedBy, labels.approvedBy];
}
