import 'package:pdf/widgets.dart' as pw;
import 'package:save_points_pdf_templates/pdf/models/pdf_receipt_voucher_model.dart';
import 'package:save_points_pdf_templates/pdf/templates/base_template.dart';

/// A receipt voucher (سند قبض): the amount received, from whom, for what.
///
/// Laid out the way a paper voucher is — a prominent amount block, dotted
/// fill-in lines and two signature slots — rather than as a table.
class ReceiptVoucherTemplate extends BaseTemplate<ReceiptVoucherModel> {
  ReceiptVoucherTemplate({
    required super.data,
    required super.pdfConfig,
    super.title,
    super.qrCode,
    super.qrCodeSize,
    super.theme,
    super.pageFormat,
    this.signatureLabels,
  });

  /// Overrides the default `Received by` / `Payer` labels.
  final List<String>? signatureLabels;

  @override
  pw.Widget? header(pw.Context context) => sections.documentHeader(
    titleEn: title.isNotEmpty ? title : data.type.english,
    titleAr: arabicTitle(data.type.arabic),
    company: company,
    logo: logo,
    logoSize: pdfConfig.logoSize,
    documentNumber: data.id,
    documentNumberLabel: tr('No.', 'رقم'),
  );

  @override
  List<pw.Widget> body(pw.Context context) => [
    ui.gap(2),
    _amountBlock(),
    ui.gap(2),
    ui.card(
      child: pw.Column(
        crossAxisAlignment: ui.crossStart,
        children: [
          ui.dottedField(
            tr('Received from', 'استلمنا من السيد / السيدة'),
            data.payerName,
          ),
          ui.dottedField(tr('Amount', 'مبلغ وقدره'), format.money(data.amount)),
          if (data.amountInWords?.isNotEmpty ?? false)
            ui.dottedField(tr('In words', 'فقط وقدره'), data.amountInWords!),
          ui.dottedField(
            tr('Payment method', 'وذلك عن طريق'),
            data.paymentMethod,
          ),
          ui.dottedField(tr('For', 'وذلك عن'), data.statement),
          ui.dottedField(tr('Date', 'بتاريخ'), format.longDate(data.date)),
          if (data.reference?.isNotEmpty ?? false)
            ui.dottedField(tr('Reference', 'المرجع'), data.reference!),
        ],
      ),
    ),
    if (data.notes?.isNotEmpty ?? false) ...[
      ui.gap(1.5),
      sections.notes(data.notes!, label: tr('NOTES', 'ملاحظات')),
    ],
    ui.gap(3),
    sections.signatures(
      signatureLabels ??
          [
            '${tr('Received by', 'المستلم')}: ${data.receiverName}',
            '${tr('Payer', 'المسلّم')}: ${data.payerName}',
          ],
    ),
  ];

  /// The figure, set large in an accent panel — the one thing a reader of a
  /// voucher looks for first.
  pw.Widget _amountBlock() {
    return pw.Row(
      children: [
        pw.Expanded(
          child: ui.card(
            padding: theme.spacing * 1.5,
            background: theme.accent,
            borderColor: theme.accent,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                ui.text(
                  tr('AMOUNT RECEIVED', 'المبلغ المستلم'),
                  color: theme.onAccent,
                  bold: true,
                  size: theme.headingSize,
                ),
                ui.gapX(),
                ui.text(
                  format.money(data.amount),
                  color: theme.onAccent,
                  bold: true,
                  size: theme.titleSize,
                ),
              ],
            ),
          ),
        ),
        if (qrCode.isNotEmpty) ...[
          ui.gapX(),
          ui.card(
            padding: theme.spacing * 0.6,
            child: ui.qr(qrCode, size: qrCodeSize),
          ),
        ],
      ],
    );
  }
}
