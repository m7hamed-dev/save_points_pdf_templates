import 'package:save_points_pdf_templates/pdf/models/base/pdf_base_invoice_model.dart';
import 'package:save_points_pdf_templates/pdf/models/pdf_invoice_types.dart';

export 'package:save_points_pdf_templates/pdf/models/base/pdf_invoice_item_model.dart';
export 'package:save_points_pdf_templates/pdf/models/base/pdf_party_model.dart';

/// A sales invoice: priced line items billed to a customer.
///
/// Leave `total` null to let the package compute
/// `subtotal - discount + tax`, or pass it to reproduce a figure that was
/// calculated elsewhere.
class PdfSaleInvoiceModel extends PdfItemizedInvoiceModel {
  const PdfSaleInvoiceModel({
    required super.id,
    required super.date,
    required super.items,
    super.customer,
    super.notes,
    super.title,
    super.reference,
    super.discount,
    super.tax,
    super.taxRate,
    super.paymentMethod,
    super.dueDate,
    super.total,
    super.paidAmount,
    super.type = PdfInvoiceType.salesInvoice,
  });
}
