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
    // An explicit title is one string in an unknown language, so it
    // stands alone rather than being captioned by the type's Arabic.
    titleAr: title.isNotEmpty ? '' : arabicTitle(data.type.arabic),
    company: company,
    logo: logo,
    logoSize: pdfConfig.logoSize,
    documentNumber: data.id,
    documentNumberLabel: tr('No.', 'رقم'),
  );

  @override
  List<pw.Widget> body(pw.Context context) => [
    ui.gap(1.5),
    _amountBlock(),
    ui.gap(1.8),
    pw.Column(
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

  /// The figure, set as the largest thing on the page — the one item a reader
  /// of a voucher looks for first.
  ///
  /// Carried by its own size and a keyline rather than a filled panel: a solid
  /// slab reads as a screen component, and it is the amount that should draw
  /// the eye, not the box around it.
  pw.Widget _amountBlock() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: ui.crossStart,
                children: [
                  ui.microLabel(
                    tr('AMOUNT RECEIVED', 'المبلغ المستلم'),
                    color: theme.mutedText,
                  ),
                  pw.SizedBox(height: theme.spacing * 0.4),
                  ui.money(
                    data.amount,
                    color: theme.accent,
                    bold: true,
                    size: theme.titleSize,
                  ),
                ],
              ),
            ),
            if (qrCode.isNotEmpty) ...[
              ui.gapX(2),
              ui.qr(qrCode, size: qrCodeSize),
            ],
          ],
        ),
        pw.SizedBox(height: theme.spacing * 0.9),
        ui.keyline(),
      ],
    );
  }
}
