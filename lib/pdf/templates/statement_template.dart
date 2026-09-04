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
    titleEn: title.isNotEmpty ? title : data.displayTitle,
    titleAr: title.isNotEmpty ? '' : arabicTitle(data.displayTitleAr),
    company: company,
    logo: logo,
    logoSize: pdfConfig.logoSize,
    documentNumber: data.id,
    documentNumberLabel: tr('No.', 'رقم'),
  );

  /// The period the statement covers, and what was owed going into it.
  Map<String, String> get metaFields => {
    if (data.periodStart != null)
      tr('From', 'من'): format.longDate(data.periodStart),
    if (data.periodEnd != null)
      tr('To', 'إلى'): format.longDate(data.periodEnd),
    tr('Opening balance', 'الرصيد الافتتاحي'): format.number(
      data.openingBalance,
    ),
  };

  @override
  List<pw.Widget> body(pw.Context context) => [
    ui.gap(1.5),
    sections.partyAndMeta(
      party: data.customer,
      partyLabel: tr('STATEMENT FOR', 'كشف حساب'),
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
      sections.notes(data.notes!, label: tr('NOTES', 'ملاحظات')),
    ],
  ];

  List<PdfColumnSpec> get columns => [
    PdfColumnSpec(tr('Date', 'التاريخ'), intrinsic: true),
    PdfColumnSpec(tr('Details', 'البيان'), flex: 3.4),
    PdfColumnSpec(tr('Debit', 'مدين'), flex: 1.4, align: PdfCellAlign.end),
    PdfColumnSpec(tr('Credit', 'دائن'), flex: 1.4, align: PdfCellAlign.end),
    PdfColumnSpec(tr('Balance', 'الرصيد'), flex: 1.6, align: PdfCellAlign.end),
  ];

  /// The opening balance leads the table as a row of its own, so the balance
  /// column starts from a stated figure rather than appearing out of nowhere.
  List<List<String>> get rows {
    final balances = data.runningBalances;
    return [
      [
        '',
        tr('Opening balance', 'الرصيد الافتتاحي'),
        '',
        '',
        format.number(data.openingBalance),
      ],
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
        emptyPlaceholder: tr('No movements', 'لا توجد حركات'),
      ).build();

  /// Totals for the period, then the figure the whole document exists for.
  pw.Widget buildSummary() => sections.totalsPanel(
    lines: {
      tr('Total debit', 'إجمالي المدين'): data.totalDebit,
      tr('Total credit', 'إجمالي الدائن'): data.totalCredit,
    },
    totalLabel:
        data.isInCredit
            ? tr('BALANCE IN CREDIT', 'الرصيد لكم')
            : tr('BALANCE DUE', 'الرصيد المستحق'),
    totalValue: data.closingBalance.abs(),
  );
}
