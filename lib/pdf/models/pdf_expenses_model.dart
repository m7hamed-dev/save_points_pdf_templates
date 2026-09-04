import 'package:save_points_pdf_templates/pdf/models/base/pdf_base_invoice_model.dart';
import 'package:save_points_pdf_templates/pdf/models/pdf_invoice_types.dart';

export 'package:save_points_pdf_templates/pdf/models/base/pdf_invoice_item_model.dart';
export 'package:save_points_pdf_templates/pdf/models/base/pdf_party_model.dart';

/// An expense document: costs paid to a supplier or an employee.
///
/// Structurally identical to a sales invoice — the difference is the label
/// and the party, which is a payee rather than a customer.
class PdfExpensesInvoiceModel extends PdfItemizedInvoiceModel {
  const PdfExpensesInvoiceModel({
    required super.id,
    required super.date,
    required super.items,
    super.customer,
    super.notes,
    super.title,
    super.reference,
    super.discount,
    super.tax,
    super.paymentMethod,
    super.dueDate,
    super.total,
    super.paidAmount,
    this.category,
  }) : super(type: PdfInvoiceType.expensesInvoice);

  /// Optional expense category — `Rent`, `Utilities`, `Salaries`.
  final String? category;
}
