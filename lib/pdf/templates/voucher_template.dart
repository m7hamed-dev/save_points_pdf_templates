import 'package:pdf/widgets.dart' as pw;
import 'package:save_points_pdf_templates/pdf/models/pdf_voucher_model.dart';
import 'package:save_points_pdf_templates/pdf/templates/base_template.dart';

/// The shared layout behind every cash voucher: a prominent amount, dotted
/// fill-in lines, two signature slots and a space to stamp.
///
/// Laid out the way a paper voucher is rather than as a table. A receipt and a
/// payment voucher differ only in what the two parties are called, so they
/// subclass this and override the labels.
abstract class VoucherTemplate<T extends PdfVoucherModel>
    extends BaseTemplate<T> {
  VoucherTemplate({
    required super.data,
    required super.pdfConfig,
    super.title,
    super.qrCode,
    super.qrCodeSize,
    super.theme,
    super.pageFormat,
    this.signatureLabels,
  });

  /// Overrides the two default signature labels.
  final List<String>? signatureLabels;

  /// The label over the figure — `AMOUNT RECEIVED` or `AMOUNT PAID`.
  String get amountLabel;

  /// Introduces the other party: `Received from` / `Paid to`.
  String get counterpartyLabel;

  /// The two signature slots, company side first.
  List<String> get defaultSignatureLabels;

  /// The amount written out: the caller's own wording when they gave one,
  /// otherwise spelled by the config.
  String get amountInWords =>
      data.amountInWords?.isNotEmpty ?? false
          ? data.amountInWords!
          : pdfConfig.spellAmount(data.amount);

  @override
  pw.Widget? footer(pw.Context context) =>
      sections.pageFooter(context, note: company?.name, reference: data.id);

  @override
  pw.Widget? header(pw.Context context) => sections.documentHeader(
    titleEn: title.isNotEmpty ? title : labels.documentType(data.type),
    // An explicit title is one string in an unknown language, so it stands
    // alone rather than being captioned by a name in another.
    titleAr:
        title.isNotEmpty ? '' : arabicTitle(labels.documentSubtitle(data.type)),
    company: company,
    logo: logo,
    logoSize: pdfConfig.logoSize,
    documentNumber: data.id,
    documentNumberLabel: labels.documentNumber,
  );

  @override
  List<pw.Widget> body(pw.Context context) => [
    ui.gap(1.5),
    buildAmountBlock(),
    ui.gap(1.8),
    pw.Column(
      crossAxisAlignment: ui.crossStart,
      children: [
        ui.dottedField(counterpartyLabel, data.counterparty),
        // Not a repeat of the figure above: the words are what the voucher
        // is signed against, because a figure can be altered with a pen and
        // a sentence cannot. Spelled for you when the caller supplies none.
        ui.dottedField(labels.inWords, amountInWords),
        ui.dottedField(labels.voucherMethod, data.paymentMethod),
        ui.dottedField(labels.voucherFor, data.statement),
        ui.dottedField(labels.voucherDate, format.longDate(data.date)),
        if (data.reference?.isNotEmpty ?? false)
          ui.dottedField(labels.reference, data.reference!),
      ],
    ),
    if (data.notes?.isNotEmpty ?? false) ...[
      ui.gap(1.5),
      sections.notes(data.notes!, label: labels.notes),
    ],
    ui.gap(2.5),
    pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          flex: 3,
          child: sections.signatures(
            signatureLabels ?? defaultSignatureLabels,
            names: [data.officer, data.counterparty],
          ),
        ),
        ui.gapX(2),
        pw.Expanded(
          child: pw.Padding(
            padding: pw.EdgeInsets.only(top: theme.spacing * 3.5),
            child: ui.stampArea(labels.stamp),
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
  pw.Widget buildAmountBlock() {
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
                  ui.microLabel(amountLabel, color: theme.mutedText),
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
