import 'package:save_points_pdf_templates/pdf/models/base/pdf_base_invoice_model.dart';
import 'package:save_points_pdf_templates/pdf/models/pdf_invoice_types.dart';

/// ===============================
/// Receipt Voucher سند قبض
/// ===============================

class ReceiptVoucherModel extends PdfBaseInvoiceModel {
  const ReceiptVoucherModel({
    required super.id,
    required super.date,
    super.notes,
    required this.payerName,
    required this.amount,
    required this.paymentMethod,
    required this.statement,
    required this.receiverName,
  }) : super(type: InvoiceType.receiptVoucher);

  final String payerName;
  final double amount;
  final String paymentMethod;
  final String statement;
  final String receiverName;
}
