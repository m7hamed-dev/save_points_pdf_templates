import 'package:save_points_pdf_templates/pdf/models/base/pdf_base_invoice_model.dart';
import 'package:save_points_pdf_templates/pdf/models/pdf_invoice_types.dart';

export 'package:save_points_pdf_templates/pdf/models/base/pdf_invoice_item_model.dart';
export 'package:save_points_pdf_templates/pdf/models/base/pdf_party_model.dart';

/// A delivery note (إشعار تسليم): what was sent, in what quantity, to whom.
///
/// Carries no money. The goods have been priced on the invoice; a driver and
/// a storekeeper check quantities against the box, and a price column on the
/// page they sign is a leak, not a service.
class PdfDeliveryNoteModel extends PdfItemizedInvoiceModel {
  const PdfDeliveryNoteModel({
    required super.id,
    required super.date,
    required super.items,
    super.customer,
    super.notes,
    super.title,
    super.reference,
    this.deliveryAddress,
    this.carrier,
    super.type = PdfInvoiceType.deliveryNote,
  });

  /// Where the goods go, when that is not the customer's own address.
  final String? deliveryAddress;

  /// Who carried them — a courier, a plate number, a driver.
  final String? carrier;
}
