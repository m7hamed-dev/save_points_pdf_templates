import 'package:pdf/widgets.dart' as pw;
import 'package:save_points_pdf_templates/pdf/models/pdf_payslip_model.dart';
import 'package:save_points_pdf_templates/pdf/templates/base_template.dart';

/// A payslip (قسيمة راتب): earnings on one side, deductions on the other, and
/// the net beneath them both.
///
/// Two columns rather than one list, because that is the comparison an
/// employee actually makes — what was earned against what was taken off — and
/// a single column of signed numbers hides it.
class PayslipTemplate extends BaseTemplate<PdfPayslipModel> {
  PayslipTemplate({
    required super.data,
    required super.pdfConfig,
    super.title,
    super.qrCode,
    super.qrCodeSize,
    super.theme,
    super.pageFormat,
    this.showSignatures = true,
  });

  final bool showSignatures;

  @override
  pw.Widget? footer(pw.Context context) =>
      sections.pageFooter(context, note: company?.name, reference: data.id);

  @override
  pw.Widget? header(pw.Context context) => sections.documentHeader(
    titleEn: title.isNotEmpty ? title : documentTitle,
    titleAr: title.isNotEmpty ? '' : arabicTitle(documentSubtitle),
    company: company,
    logo: logo,
    logoSize: pdfConfig.logoSize,
    documentNumber: data.id,
    documentNumberLabel: labels.documentNumber,
  );

  /// A payslip has no type of its own in `PdfInvoiceType`, so it names itself.
  String get documentTitle =>
      data.title.isNotEmpty ? data.title : labels.payslip;

  /// Nothing under the title: a payslip has no second name to show.
  String get documentSubtitle => '';

  Map<String, String> get metaFields => {
    if (data.periodLabel?.isNotEmpty ?? false)
      labels.payPeriod: data.periodLabel!,
    if (data.employeeNumber?.isNotEmpty ?? false)
      labels.employeeId: data.employeeNumber!,
    if (data.jobTitle?.isNotEmpty ?? false) labels.jobTitle: data.jobTitle!,
    if (data.paymentMethod.isNotEmpty) labels.method: data.paymentMethod,
  };

  @override
  List<pw.Widget> body(pw.Context context) => [
    ui.gap(1.5),
    sections.partyAndMeta(
      party: data.employee,
      partyLabel: labels.employee,
      meta: metaFields,
      qrData: qrCode,
      qrSize: qrCodeSize,
    ),
    ui.gap(1.8),
    buildColumns(),
    ui.gap(1.6),
    buildNetPay(),
    if (data.notes?.isNotEmpty ?? false) ...[
      ui.gap(1.5),
      sections.notes(data.notes!, label: labels.notes),
    ],
    if (showSignatures) ...[
      ui.gap(2),
      sections.signatures([labels.issuedBy, labels.receivedBy]),
    ],
  ];

  /// Earnings beside deductions, each column totalled at its foot.
  pw.Widget buildColumns() => pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Expanded(
        child: _column(
          labels.earnings,
          data.earnings,
          data.grossPay,
          labels.grossPay,
        ),
      ),
      ui.gapX(2.5),
      pw.Expanded(
        child: _column(
          labels.deductions,
          data.deductions,
          data.totalDeductions,
          labels.totalDeductions,
        ),
      ),
    ],
  );

  pw.Widget _column(
    String heading,
    List<PdfPayLine> lines,
    double total,
    String totalLabel,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        ui.microLabel(heading, color: theme.mutedText),
        pw.SizedBox(height: theme.spacing * 0.5),
        ui.rule(color: theme.accent, thickness: 0.9),
        for (final line in lines)
          pw.Padding(
            padding: pw.EdgeInsets.only(top: theme.spacing * 0.5),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: ui.crossStart,
                    children: [
                      ui.bidiText(line.label),
                      if (line.note?.isNotEmpty ?? false)
                        ui.caption(line.note!),
                    ],
                  ),
                ),
                ui.gapX(0.5),
                ui.text(format.number(line.amount), align: ui.alignEnd),
              ],
            ),
          ),
        pw.SizedBox(height: theme.spacing * 0.7),
        ui.rule(),
        pw.SizedBox(height: theme.spacing * 0.4),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            ui.microLabel(totalLabel, color: theme.mutedText),
            ui.gapX(0.5),
            ui.text(format.number(total), bold: true),
          ],
        ),
      ],
    );
  }

  /// The one figure the employee checks.
  pw.Widget buildNetPay() => sections.totalsPanel(
    lines: const {},
    totalLabel: labels.netPay,
    totalValue: data.netPay,
  );
}
