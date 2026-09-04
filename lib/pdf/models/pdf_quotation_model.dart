import 'package:save_points_pdf_templates/pdf/models/base/pdf_base_invoice_model.dart';
import 'package:save_points_pdf_templates/pdf/models/pdf_invoice_types.dart';

export 'package:save_points_pdf_templates/pdf/models/base/pdf_invoice_item_model.dart';
export 'package:save_points_pdf_templates/pdf/models/base/pdf_party_model.dart';

/// A quotation (عرض سعر): priced lines offered, not owed.
///
/// Structurally an invoice, legally not one. Nothing has been paid, nothing is
/// outstanding, and the offer stops meaning anything after [validUntil].
class PdfQuotationModel extends PdfItemizedInvoiceModel {
  const PdfQuotationModel({
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
    super.total,
    this.validUntil,
    this.terms,
    super.type = PdfInvoiceType.quotation,
  });

  /// The last day the prices hold.
  final DateTime? validUntil;

  /// Delivery terms, lead time, payment terms — whatever the offer rests on.
  final String? terms;

  /// True when [validUntil] has passed.
  ///
  /// Takes the day to compare against rather than reading the clock, so the
  /// document renders the same whenever it is printed.
  bool isExpiredOn(DateTime date) {
    final until = validUntil;
    return until != null && date.isAfter(until);
  }
}
