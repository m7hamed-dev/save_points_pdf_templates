import 'package:save_points_pdf_templates/pdf/models/base/pdf_base_invoice_model.dart';
import 'package:save_points_pdf_templates/pdf/models/base/pdf_invoice_item_model.dart';
import 'package:save_points_pdf_templates/pdf/models/base/pdf_party_model.dart';
import 'package:save_points_pdf_templates/pdf/models/pdf_invoice_types.dart';

export 'package:save_points_pdf_templates/pdf/models/base/pdf_invoice_item_model.dart';

///
export 'package:save_points_pdf_templates/pdf/models/base/pdf_party_model.dart';

/// ===============
/// Sales Invoice
/// ===============

class PdfSaleInvoiceModel extends PdfBaseInvoiceModel {
  const PdfSaleInvoiceModel({
    /// super properties
    required super.id,
    required super.date,
    super.notes,

    required this.customer,
    required this.items,
    required this.discount,
    required this.tax,
    required this.total,
    required this.paymentMethod,
  }) : super(type: InvoiceType.salesInvoice);

  /// properties
  final PdfPartyModel customer;
  final List<PdfInvoiceItemModel> items;

  final double discount;
  final double tax;
  final double total;

  final String paymentMethod;
}
