import 'package:save_points_pdf_templates/pdf/models/base/pdf_base_invoice_model.dart';
import 'package:save_points_pdf_templates/pdf/models/base/pdf_party_model.dart';
import 'package:save_points_pdf_templates/pdf/models/pdf_invoice_types.dart';

export 'package:save_points_pdf_templates/pdf/models/base/pdf_invoice_item_model.dart';

///
export 'package:save_points_pdf_templates/pdf/models/base/pdf_party_model.dart';

/// ===============
/// Sales Invoice
/// ===============

class PdfListStringsModel extends PdfBaseInvoiceModel {
  const PdfListStringsModel({
    /// super properties
    super.id = '0000',
    super.date,
    super.notes,
    super.title,
    super.headers,

    ///
    this.customer = PdfPartyModel.empty,
    required this.items,
    this.discount = 0.0,
    this.tax = 0.0,
    this.total = 0.0,
    this.paymentMethod = 'Unknown',
  }) : super(type: InvoiceType.salesInvoice);

  /// customer
  final PdfPartyModel customer;

  final List<List<String>> items;

  /// total
  final double discount;
  final double tax;
  final double total;
  final String paymentMethod;

  /// empty
  static const empty = PdfListStringsModel(items: []);
}
