import 'package:save_points_pdf_templates/pdf/models/base/pdf_base_invoice_model.dart';
import 'package:save_points_pdf_templates/pdf/models/pdf_invoice_types.dart';

export 'package:save_points_pdf_templates/pdf/models/base/pdf_invoice_item_model.dart';
export 'package:save_points_pdf_templates/pdf/models/base/pdf_party_model.dart';

/// What a credit and a debit note share: an adjustment to an invoice that has
/// already been issued.
///
/// Neither stands on its own. A note that does not name the invoice it
/// corrects, and say why, is not something an auditor can reconcile — so both
/// fields are required rather than optional.
abstract class PdfAdjustmentNoteModel extends PdfItemizedInvoiceModel {
  const PdfAdjustmentNoteModel({
    required super.id,
    required super.type,
    required super.date,
    required super.items,
    required this.againstInvoice,
    required this.reason,
    this.againstInvoiceDate,
    super.customer,
    super.notes,
    super.title,
    super.reference,
    super.discount,
    super.tax,
    super.taxRate,
    super.total,
  });

  /// The invoice being corrected.
  final String againstInvoice;

  /// When it was issued.
  final DateTime? againstInvoiceDate;

  /// Why the correction was made — goods returned, price adjusted, an error.
  final String reason;
}

/// A credit note (إشعار دائن): value returned to the customer, reducing what
/// they owe.
class PdfCreditNoteModel extends PdfAdjustmentNoteModel {
  const PdfCreditNoteModel({
    required super.id,
    required super.date,
    required super.items,
    required super.againstInvoice,
    required super.reason,
    super.againstInvoiceDate,
    super.customer,
    super.notes,
    super.title,
    super.reference,
    super.discount,
    super.tax,
    super.taxRate,
    super.total,
    super.type = PdfInvoiceType.creditNote,
  });
}

/// A debit note (إشعار مدين): value charged on top of an invoice, increasing
/// what the customer owes.
class PdfDebitNoteModel extends PdfAdjustmentNoteModel {
  const PdfDebitNoteModel({
    required super.id,
    required super.date,
    required super.items,
    required super.againstInvoice,
    required super.reason,
    super.againstInvoiceDate,
    super.customer,
    super.notes,
    super.title,
    super.reference,
    super.discount,
    super.tax,
    super.taxRate,
    super.total,
    super.type = PdfInvoiceType.debitNote,
  });
}
