import 'package:save_points_pdf_templates/pdf/models/pdf_voucher_model.dart';
import 'package:save_points_pdf_templates/pdf/templates/receipt_voucher_template.dart';
import 'package:save_points_pdf_templates/pdf/templates/voucher_template.dart';

/// A payment voucher (سند صرف): the amount paid out, to whom, for what.
///
/// The mirror of [ReceiptVoucherTemplate] — same layout, opposite direction of
/// money — so a book of receipts and a book of payments look like one set.
///
/// ```dart
/// PaymentVoucherTemplate(
///   pdfConfig: config,
///   data: PaymentVoucherModel(
///     id: 'PV-2026-0014',
///     date: DateTime.now(),
///     payeeName: 'Gulf Office Supplies',
///     amount: 3200,
///     paymentMethod: 'Cheque #4471',
///     statement: 'Office furniture',
///     disburserName: 'Mohamed',
///   ),
/// );
/// ```
class PaymentVoucherTemplate extends VoucherTemplate<PaymentVoucherModel> {
  PaymentVoucherTemplate({
    required super.data,
    required super.pdfConfig,
    super.title,
    super.qrCode,
    super.qrCodeSize,
    super.theme,
    super.pageFormat,
    super.signatureLabels,
  });

  @override
  String get amountLabel => tr('AMOUNT PAID', 'المبلغ المصروف');

  @override
  String get counterpartyLabel => tr('Paid to', 'صرفنا إلى السيد / السيدة');

  @override
  List<String> get defaultSignatureLabels => [
    tr('Paid by', 'الصارف'),
    tr('Received by', 'المستلم'),
  ];
}
