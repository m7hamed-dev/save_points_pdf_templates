import 'package:save_points_pdf_templates/pdf/models/base/pdf_base_invoice_model.dart';
import 'package:save_points_pdf_templates/pdf/models/base/pdf_party_model.dart';
import 'package:save_points_pdf_templates/pdf/models/pdf_invoice_types.dart';

export 'package:save_points_pdf_templates/pdf/models/base/pdf_invoice_item_model.dart';
export 'package:save_points_pdf_templates/pdf/models/base/pdf_party_model.dart';

/// The smallest useful invoice: a number, a customer name, a date and lines.
///
/// Reach for `PdfSaleInvoiceModel` when you need discounts, tax, payment
/// state or full customer details.
class PdfInvoiceModel extends PdfItemizedInvoiceModel {
  PdfInvoiceModel({
    required String invoiceNo,
    required String customerName,
    required DateTime super.date,
    required super.items,
    super.notes,
    super.title,
    super.discount,
    super.tax,
    super.paymentMethod,
    super.dueDate,
    super.total,
    super.paidAmount,
  }) : super(
         id: invoiceNo,
         type: PdfInvoiceType.salesInvoice,
         customer: PdfPartyModel(name: customerName),
       );

  /// Alias of [PdfBaseInvoiceModel.id].
  String get invoiceNo => id;

  /// Alias of `customer.name`.
  String get customerName => customer.name;
}
