import 'package:save_points_pdf_templates/pdf/models/pdf_voucher_model.dart';
import 'package:save_points_pdf_templates/pdf/templates/voucher_template.dart';

/// A receipt voucher (سند قبض): the amount received, from whom, for what.
///
/// ```dart
/// ReceiptVoucherTemplate(
///   pdfConfig: config,
///   data: ReceiptVoucherModel(
///     id: 'RV-2026-0031',
///     date: DateTime.now(),
///     payerName: 'Acme Trading Co.',
///     amount: 12500,
///     paymentMethod: 'Bank transfer',
///     statement: 'Part settlement of INV-2026-0042',
///     receiverName: 'Mohamed',
///   ),
/// );
/// ```
class ReceiptVoucherTemplate extends VoucherTemplate<ReceiptVoucherModel> {
  ReceiptVoucherTemplate({
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
  String get amountLabel => labels.amountReceived;

  @override
  String get counterpartyLabel => labels.receivedFrom;

  @override
  List<String> get defaultSignatureLabels => [labels.receivedBy, labels.payer];
}
