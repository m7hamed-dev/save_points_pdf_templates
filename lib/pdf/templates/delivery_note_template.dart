import 'package:save_points_pdf_templates/pdf/models/pdf_delivery_note_model.dart';
import 'package:save_points_pdf_templates/pdf/templates/itemized_invoice_template.dart';

/// A delivery note (إشعار تسليم): the item table with every trace of money
/// taken out, and a receipt signature at the bottom.
///
/// ```dart
/// DeliveryNoteTemplate(
///   pdfConfig: config,
///   data: PdfDeliveryNoteModel(
///     id: 'DN-2026-0088',
///     date: DateTime.now(),
///     customer: const PdfPartyModel(name: 'Acme Trading Co.'),
///     deliveryAddress: 'Warehouse 4, Industrial City, Jeddah',
///     items: lines,
///   ),
/// );
/// ```
class DeliveryNoteTemplate
    extends ItemizedInvoiceTemplate<PdfDeliveryNoteModel> {
  DeliveryNoteTemplate({
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
  bool get showPricing => false;

  @override
  String get partyLabel => tr('DELIVER TO', 'تسليم إلى');

  @override
  Map<String, String> get metaFields => {
    ...super.metaFields,
    if (data.deliveryAddress?.isNotEmpty ?? false)
      tr('Address', 'العنوان'): data.deliveryAddress!,
    if (data.carrier?.isNotEmpty ?? false)
      tr('Carrier', 'الناقل'): data.carrier!,
  };

  /// The two people who matter on a delivery note are the one who handed the
  /// goods over and the one who took them.
  @override
  List<String> get signatureLabels =>
      super.signatureLabels ??
      [tr('Delivered by', 'المُسلِّم'), tr('Received by', 'المستلم')];
}
