import 'package:save_points_pdf_templates/pdf/models/base/pdf_base_invoice_model.dart';
import 'package:save_points_pdf_templates/pdf/models/base/pdf_party_model.dart';
import 'package:save_points_pdf_templates/pdf/models/pdf_invoice_types.dart';

export 'package:save_points_pdf_templates/pdf/models/base/pdf_party_model.dart';

/// One movement on a statement: an invoice raised, or a payment received.
class PdfStatementEntry {
  const PdfStatementEntry({
    required this.description,
    this.date,
    this.reference,
    this.debit = 0.0,
    this.credit = 0.0,
  });

  /// What the movement was — `Invoice INV-2026-0042`, `Payment received`.
  final String description;

  final DateTime? date;

  /// The document behind it, if any.
  final String? reference;

  /// What the customer was charged. Increases what they owe.
  final double debit;

  /// What the customer paid. Decreases what they owe.
  final double credit;

  /// The effect on the balance: positive when the customer owes more.
  double get movement => debit - credit;
}

/// A statement of account (كشف حساب): what a customer owed at the start of a
/// period, everything that moved during it, and what they owe now.
///
/// The running balance is computed here rather than asked of the caller —
/// working it out per row is the whole reason this document is tedious to
/// produce by hand, and a statement whose balance column does not reconcile
/// is worse than no statement.
class PdfStatementModel extends PdfBaseInvoiceModel {
  const PdfStatementModel({
    required super.id,
    required this.entries,
    this.customer = PdfPartyModel.empty,
    this.openingBalance = 0.0,
    this.periodStart,
    this.periodEnd,
    this.currencyNote,
    super.date,
    super.notes,
    super.title,
    super.reference,
    super.type = PdfInvoiceType.statementOfAccount,
  });

  /// Who the statement is for.
  final PdfPartyModel customer;

  /// What was owed before the first entry. Negative when the customer was in
  /// credit.
  final double openingBalance;

  final List<PdfStatementEntry> entries;

  /// The period covered, printed in the masthead.
  final DateTime? periodStart;
  final DateTime? periodEnd;

  /// An optional line such as `All amounts in SAR`.
  final String? currencyNote;

  /// Everything charged during the period.
  double get totalDebit => entries.fold(0.0, (sum, entry) => sum + entry.debit);

  /// Everything paid during the period.
  double get totalCredit =>
      entries.fold(0.0, (sum, entry) => sum + entry.credit);

  /// What is owed at the end: the opening balance plus every movement.
  double get closingBalance => openingBalance + totalDebit - totalCredit;

  /// The balance after each entry, in the same order as [entries].
  ///
  /// This is the column a reader checks the statement by, so it is derived
  /// from the entries rather than supplied alongside them: the two cannot
  /// then disagree.
  List<double> get runningBalances {
    var balance = openingBalance;
    return [for (final entry in entries) balance += entry.movement];
  }

  /// True when the customer is in credit rather than in debt.
  bool get isInCredit => closingBalance < 0;
}
