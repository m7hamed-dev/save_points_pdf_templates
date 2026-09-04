import 'package:save_points_pdf_templates/pdf/models/base/pdf_base_invoice_model.dart';
import 'package:save_points_pdf_templates/pdf/models/base/pdf_party_model.dart';
import 'package:save_points_pdf_templates/pdf/models/pdf_invoice_types.dart';

export 'package:save_points_pdf_templates/pdf/models/base/pdf_party_model.dart';

/// One line of a payslip: a salary component or a deduction.
class PdfPayLine {
  const PdfPayLine({required this.label, required this.amount, this.note});

  /// `Basic salary`, `Housing allowance`, `GOSI`.
  final String label;

  final double amount;

  /// An optional aside — a rate, a reference, a number of days.
  final String? note;
}

/// A payslip (قسيمة راتب): what an employee earned in a period, what was
/// taken off, and what they were paid.
///
/// Net pay is computed rather than supplied. It is the only figure the
/// employee checks, and a slip whose net does not equal earnings less
/// deductions is a dispute waiting to happen.
class PdfPayslipModel extends PdfBaseInvoiceModel {
  const PdfPayslipModel({
    required super.id,
    required this.employee,
    required this.earnings,
    this.deductions = const [],
    this.employeeNumber,
    this.jobTitle,
    this.periodLabel,
    this.paymentMethod = '',
    super.date,
    super.notes,
    super.title,
    super.reference,
    super.type = PdfInvoiceType.report,
  });

  /// Who was paid.
  final PdfPartyModel employee;

  /// Their staff number.
  final String? employeeNumber;

  final String? jobTitle;

  /// The period covered, already formatted — `September 2026`, `سبتمبر 2026`.
  /// Months are named differently enough across calendars that the caller
  /// decides how to say it.
  final String? periodLabel;

  final List<PdfPayLine> earnings;
  final List<PdfPayLine> deductions;

  final String paymentMethod;

  /// Everything earned before deductions.
  double get grossPay => earnings.fold(0.0, (sum, line) => sum + line.amount);

  /// Everything taken off.
  double get totalDeductions =>
      deductions.fold(0.0, (sum, line) => sum + line.amount);

  /// What actually reached the employee.
  double get netPay => grossPay - totalDeductions;
}
