import 'package:pdf/pdf.dart';
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
  pw.Widget? footer(pw.Context context) =>
      sections.pageFooter(context, note: company?.name, reference: data.id);

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
          // The figure already dominates the block above; repeating it as a
          // field would print the same amount twice.
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
    ui.gap(2.5),
    pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          flex: 3,
          child: sections.signatures(
            signatureLabels ??
                [tr('Received by', 'المستلم'), tr('Payer', 'المسلّم')],
            names: [data.receiverName, data.payerName],
          ),
        ),
        ui.gapX(2),
        pw.Expanded(
          child: pw.Padding(
            padding: pw.EdgeInsets.only(top: theme.spacing * 3.5),
            child: ui.stampArea(tr('Stamp', 'الختم')),
          ),
        ),
      ],
    ),
  ];

  /// The figure, set large in an accent panel — the one thing a reader of a
  /// voucher looks for first.
  pw.Widget _amountBlock() {
    // Both boxes share one height so their top and bottom edges line up.
    final blockHeight = qrCodeSize + theme.spacing * 2;
    return pw.Row(
      children: [
        pw.Expanded(
          child: pw.SizedBox(
            height: blockHeight,
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
                  ui.money(
                    data.amount,
                    color: theme.onAccent,
                    bold: true,
                    size: theme.titleSize,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (qrCode.isNotEmpty) ...[
          ui.gapX(),
          // Built with the same widget and the same height as the bar beside
          // it, so both boxes line up at the top and the bottom.
          pw.SizedBox(
            height: blockHeight,
            width: blockHeight,
            child: ui.card(
              padding: theme.spacing,
              background: PdfColors.white,
              alignment: pw.Alignment.center,
              child: ui.qr(qrCode, size: qrCodeSize),
            ),
          ),
        ],
      ],
    );
  }
}
