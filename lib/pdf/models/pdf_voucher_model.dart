import 'package:save_points_pdf_templates/pdf/models/base/pdf_base_invoice_model.dart';
import 'package:save_points_pdf_templates/pdf/models/pdf_invoice_types.dart';

/// What every cash voucher records: a sum, the other party, whoever handled it
/// for the company, and what it was for.
///
/// A receipt voucher and a payment voucher are the same document read from
/// opposite sides — money in versus money out — so they share this and differ
/// only in what the two parties are called.
abstract class PdfVoucherModel extends PdfBaseInvoiceModel {
  const PdfVoucherModel({
    required super.id,
    required super.type,
    required this.amount,
    required this.counterparty,
    required this.officer,
    required this.paymentMethod,
    required this.statement,
    super.date,
    super.notes,
    super.title,
    super.reference,
    this.amountInWords,
  });

  /// The other side of the transaction: who the money came from on a receipt,
  /// who it went to on a payment.
  final String counterparty;

  /// Whoever handled the money for the company — took it in, or paid it out.
  final String officer;

  final double amount;

  /// `Cash`, `Bank transfer`, `Cheque #1234`.
  final String paymentMethod;

  /// What the money was for.
  final String statement;

  /// Optional written-out amount, printed under the figure. Vouchers are
  /// commonly required to carry it, and spelling rules are locale specific,
  /// so the caller supplies the string.
  final String? amountInWords;
}

/// A receipt voucher (سند قبض): money received from a payer.
class ReceiptVoucherModel extends PdfVoucherModel {
  const ReceiptVoucherModel({
    required super.id,
    required super.date,
    required String payerName,
    required super.amount,
    required super.paymentMethod,
    required super.statement,
    required String receiverName,
    super.notes,
    super.title,
    super.reference,
    super.amountInWords,
    super.type = PdfInvoiceType.receiptVoucher,
  }) : super(counterparty: payerName, officer: receiverName);

  /// Who the money came from.
  String get payerName => counterparty;

  /// Who received it on behalf of the company.
  String get receiverName => officer;
}

/// A payment voucher (سند صرف): money paid out to a beneficiary.
class PaymentVoucherModel extends PdfVoucherModel {
  const PaymentVoucherModel({
    required super.id,
    required super.date,
    required String payeeName,
    required super.amount,
    required super.paymentMethod,
    required super.statement,
    required String disburserName,
    super.notes,
    super.title,
    super.reference,
    super.amountInWords,
    super.type = PdfInvoiceType.paymentVoucher,
  }) : super(counterparty: payeeName, officer: disburserName);

  /// Who the money was paid to.
  String get payeeName => counterparty;

  /// Who paid it out on behalf of the company.
  String get disburserName => officer;
}
