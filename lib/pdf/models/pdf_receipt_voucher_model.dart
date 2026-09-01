import 'package:save_points_pdf_templates/pdf/models/base/pdf_base_invoice_model.dart';
import 'package:save_points_pdf_templates/pdf/models/pdf_invoice_types.dart';

/// A receipt voucher (سند قبض): money received from a payer, with the
/// reason it was received and who took it in.
class ReceiptVoucherModel extends PdfBaseInvoiceModel {
  const ReceiptVoucherModel({
    required super.id,
    required super.date,
    required this.payerName,
    required this.amount,
    required this.paymentMethod,
    required this.statement,
    required this.receiverName,
    super.notes,
    super.title,
    super.reference,
    this.amountInWords,
    super.type = PdfInvoiceType.receiptVoucher,
  });

  /// Who the money came from.
  final String payerName;

  final double amount;

  /// `Cash`, `Bank transfer`, `Cheque #1234`.
  final String paymentMethod;

  /// What the payment was for.
  final String statement;

  /// Who received the money on behalf of the company.
  final String receiverName;

  /// Optional written-out amount, printed under the figure. Vouchers are
  /// commonly required to carry it, and spelling rules are locale specific,
  /// so the caller supplies the string.
  final String? amountInWords;
}
