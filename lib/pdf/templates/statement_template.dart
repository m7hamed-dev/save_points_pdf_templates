import 'package:pdf/widgets.dart' as pw;
import 'package:save_points_pdf_templates/pdf/core/widgets/pdf_data_table.dart';
import 'package:save_points_pdf_templates/pdf/core/widgets/pdf_ui.dart';
import 'package:save_points_pdf_templates/pdf/models/pdf_statement_model.dart';
import 'package:save_points_pdf_templates/pdf/templates/base_template.dart';

/// A statement of account (كشف حساب): opening balance, every movement in the
/// period with a running balance beside it, and what is owed at the end.
///
/// ```dart
/// StatementOfAccountTemplate(
///   pdfConfig: config,
///   data: PdfStatementModel(
///     id: 'SOA-2026-09',
///     customer: const PdfPartyModel(name: 'Acme Trading Co.'),
///     periodStart: DateTime(2026, 9),
///     periodEnd: DateTime(2026, 9, 30),
///     openingBalance: 4200,
///     entries: [
///       PdfStatementEntry(
///         date: DateTime(2026, 9, 3),
///         description: 'Invoice INV-2026-0042',
///         debit: 29240,
///       ),
///       PdfStatementEntry(
///         date: DateTime(2026, 9, 20),
///         description: 'Payment received',
///         credit: 12000,
///       ),
///     ],
///   ),
/// );
/// ```
class StatementOfAccountTemplate extends BaseTemplate<PdfStatementModel> {
  StatementOfAccountTemplate({
    required super.data,
    required super.pdfConfig,
    super.title,
    super.qrCode,
    super.qrCodeSize,
    super.theme,
    super.pageFormat,
    this.showRowNumbers = false,
  });

  final bool showRowNumbers;

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

  /// The period the statement covers, and what was owed going into it.
  Map<String, String> get metaFields => {
    if (data.periodStart != null)
      labels.periodFrom: format.longDate(data.periodStart),
    if (data.periodEnd != null)
      labels.periodTo: format.longDate(data.periodEnd),
    labels.openingBalance: format.number(data.openingBalance),
  };

  /// The document's own name: the model's `title` when it set one, otherwise
  /// the name the label set gives its type.
  String get documentTitle =>
      data.title.isNotEmpty ? data.title : labels.documentType(data.type);

  /// The smaller name under it, empty when the model named itself.
  String get documentSubtitle =>
      data.title.isNotEmpty ? '' : labels.documentSubtitle(data.type);

  @override
  List<pw.Widget> body(pw.Context context) => [
    ui.gap(1.5),
    sections.partyAndMeta(
      party: data.customer,
      partyLabel: labels.statementFor,
      meta: metaFields,
      qrData: qrCode,
      qrSize: qrCodeSize,
    ),
    ui.gap(1.5),
    // Its own block so a long period breaks across pages inside the table.
    buildEntriesTable(),
    ui.gap(1.4),
    buildSummary(),
    if (data.currencyNote?.isNotEmpty ?? false) ...[
      ui.gap(1.2),
      ui.caption(data.currencyNote!),
    ],
    if (data.notes?.isNotEmpty ?? false) ...[
      ui.gap(1.5),
      sections.notes(data.notes!, label: labels.notes),
    ],
  ];

  List<PdfColumnSpec> get columns => [
    PdfColumnSpec(labels.date, intrinsic: true),
    PdfColumnSpec(labels.details, flex: 3.4),
    PdfColumnSpec(labels.debit, flex: 1.4, align: PdfCellAlign.end),
    PdfColumnSpec(labels.credit, flex: 1.4, align: PdfCellAlign.end),
    PdfColumnSpec(labels.balance, flex: 1.6, align: PdfCellAlign.end),
  ];

  /// The opening balance leads the table as a row of its own, so the balance
  /// column starts from a stated figure rather than appearing out of nowhere.
  List<List<String>> get rows {
    final balances = data.runningBalances;
    return [
      ['', labels.openingBalance, '', '', format.number(data.openingBalance)],
      for (var i = 0; i < data.entries.length; i++)
        [
          format.date(data.entries[i].date),
          [
            data.entries[i].description,
            if (data.entries[i].reference?.isNotEmpty ?? false)
              '(${data.entries[i].reference})',
          ].join(' '),
          data.entries[i].debit == 0
              ? ''
              : format.number(data.entries[i].debit),
          data.entries[i].credit == 0
              ? ''
              : format.number(data.entries[i].credit),
          format.number(balances[i]),
        ],
    ];
  }

  pw.Widget buildEntriesTable() =>
      PdfDataTable(
        ui: ui,
        columns: columns,
        rows: rows,
        rowNumbers: showRowNumbers,
        emptyPlaceholder: labels.noMovements,
      ).build();

  /// Totals for the period, then the figure the whole document exists for.
  pw.Widget buildSummary() => sections.totalsPanel(
    lines: {
      labels.totalDebit: data.totalDebit,
      labels.totalCredit: data.totalCredit,
    },
    totalLabel: data.isInCredit ? labels.balanceInCredit : labels.balanceOwed,
    totalValue: data.closingBalance.abs(),
  );
}
