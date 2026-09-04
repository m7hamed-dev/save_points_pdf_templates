import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:save_points_pdf_templates/pdf/models/base/pdf_base_invoice_model.dart';
import 'package:save_points_pdf_templates/pdf/pdf_config/pdf_theme.dart';
import 'package:save_points_pdf_templates/pdf/templates/base_template.dart';

/// A till receipt for an 80mm or 57mm roll.
///
/// Not a narrower invoice. There is one column and no table: at 80mm a grid of
/// five columns leaves nothing for the item name, so each line prints its name
/// on one row and its quantity, price and amount on the next. The masthead is
/// centred, the totals sit under a rule, and nothing is boxed — a thermal head
/// prints a filled rectangle as a solid black band.
///
/// ```dart
/// ThermalReceiptTemplate(
///   pdfConfig: config,
///   data: invoice,
///   qrCode: zatcaPayload,
/// );
/// ```
class ThermalReceiptTemplate<T extends PdfItemizedInvoiceModel>
    extends BaseTemplate<T> {
  ThermalReceiptTemplate({
    required super.data,
    required super.pdfConfig,
    super.title,
    super.qrCode,
    super.qrCodeSize = 90,
    PdfTheme? theme,
    PdfPageFormat? pageFormat,
    this.footerNote,
  }) : super(
         theme: theme ?? const PdfTheme.thermal(),
         pageFormat: pageFormat ?? PdfPageFormat.roll80,
       );

  /// A closing line — `Thank you`, an exchange policy, opening hours.
  final String? footerNote;

  /// The roll has no room for a running header; everything is in the body so
  /// it prints once and the paper is not wasted repeating it.
  @override
  pw.Widget? header(pw.Context context) => null;

  @override
  pw.Widget? footer(pw.Context context) => null;

  @override
  List<pw.Widget> body(pw.Context context) => [
    _centred(buildMasthead()),
    ui.gap(),
    ui.rule(),
    ui.gap(0.5),
    ...buildLines(),
    ui.gap(0.5),
    ui.rule(),
    ui.gap(0.5),
    buildTotals(),
    if (qrCode.isNotEmpty) ...[
      ui.gap(1.5),
      _centred(ui.qr(qrCode, size: qrCodeSize)),
    ],
    if (footerNote?.isNotEmpty ?? false) ...[
      ui.gap(1.5),
      _centred(ui.caption(footerNote!, align: pw.TextAlign.center)),
    ],
    ui.gap(2),
  ];

  pw.Widget _centred(pw.Widget child) => pw.Align(child: child);

  /// Issuer, document type and number, centred the way a till prints them.
  pw.Widget buildMasthead() => pw.Column(
    children: [
      if (company?.name.isNotEmpty ?? false)
        ui.text(
          company!.name,
          bold: true,
          size: theme.titleSize,
          align: pw.TextAlign.center,
        ),
      if (company?.address?.isNotEmpty ?? false)
        ui.caption(company!.address!, align: pw.TextAlign.center),
      if (company?.phone.isNotEmpty ?? false)
        ui.caption(company!.phone, align: pw.TextAlign.center),
      if (company?.taxNumber?.isNotEmpty ?? false)
        ui.caption(
          '${labels.vat} ${company!.taxNumber}',
          align: pw.TextAlign.center,
        ),
      ui.gap(0.6),
      ui.text(
        title.isNotEmpty ? title : labels.documentType(data.type),
        bold: true,
        size: theme.headingSize,
        align: pw.TextAlign.center,
      ),
      ui.caption(
        '${labels.documentNumber} ${data.id}',
        align: pw.TextAlign.center,
      ),
      ui.caption(format.dateTime(data.date), align: pw.TextAlign.center),
    ],
  );

  /// Each line over two rows: the name, then the arithmetic.
  List<pw.Widget> buildLines() => [
    for (final item in data.chargedItems) ...[
      ui.bidiText(item.title),
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          // Through `bidiText`, because an Arabic unit beside Latin digits is
          // a mixed run: as one string the `×` ends up welded to the unit.
          ui.bidiText(
            '${format.quantity(item.qty)}'
            '${item.unit == null ? '' : ' ${item.unit}'}'
            ' × ${format.number(item.price)}',
            size: theme.captionSize,
            color: theme.mutedText,
          ),
          ui.text(format.number(item.total), bold: true),
        ],
      ),
      ui.gap(0.4),
    ],
  ];

  pw.Widget buildTotals() => pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
    children: [
      _line(labels.subtotal, data.subtotal),
      if (data.totalDiscount > 0) _line(labels.discount, -data.totalDiscount),
      if (data.totalTax > 0) _line(labels.tax, data.totalTax),
      ui.gap(0.4),
      ui.rule(color: theme.accent, thickness: 0.8),
      ui.gap(0.4),
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          ui.text(labels.total, bold: true, size: theme.headingSize),
          ui.money(data.total, bold: true, size: theme.displaySize),
        ],
      ),
      if (!data.isFullyPaid) ...[
        ui.gap(0.4),
        _line(labels.paid, data.paid),
        _line(labels.balanceDue, data.due),
      ],
    ],
  );

  pw.Widget _line(String label, double value) => pw.Padding(
    padding: pw.EdgeInsets.only(bottom: theme.spacing * 0.2),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [ui.caption(label), ui.money(value, size: theme.bodySize)],
    ),
  );
}
