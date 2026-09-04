import 'package:save_points_pdf_templates/pdf/models/base/pdf_base_invoice_model.dart';
import 'package:save_points_pdf_templates/pdf/models/base/pdf_party_model.dart';
import 'package:save_points_pdf_templates/pdf/models/pdf_invoice_types.dart';

export 'package:save_points_pdf_templates/pdf/models/base/pdf_invoice_item_model.dart';
export 'package:save_points_pdf_templates/pdf/models/base/pdf_party_model.dart';

/// A purchase order (أمر شراء): what you are asking a supplier to send, at
/// what price, and where it goes.
///
/// The other party is the supplier rather than a customer, and the goods do
/// not necessarily go to the address you are billed at — a purchase order is
/// the one document where those two are routinely different.
class PdfPurchaseOrderModel extends PdfItemizedInvoiceModel {
  const PdfPurchaseOrderModel({
    required super.id,
    required super.date,
    required super.items,
    PdfPartyModel supplier = PdfPartyModel.empty,
    super.notes,
    super.title,
    super.reference,
    super.discount,
    super.tax,
    super.taxRate,
    super.paymentMethod,
    super.total,
    this.deliveryAddress,
    this.expectedDate,
    super.type = PdfInvoiceType.purchaseOrder,
  }) : super(customer: supplier);

  /// Who is being asked to supply.
  PdfPartyModel get supplier => customer;

  /// Where the goods are to be delivered, when that is not your own address.
  final String? deliveryAddress;

  /// When they are expected.
  final DateTime? expectedDate;
}
