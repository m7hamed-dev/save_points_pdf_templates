import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:save_points_pdf_templates/pdf/core/widgets/pdf_data_table.dart';
import 'package:save_points_pdf_templates/pdf/core/widgets/pdf_ui.dart';
import 'package:save_points_pdf_templates/pdf/models/base/pdf_base_invoice_model.dart';
import 'package:save_points_pdf_templates/pdf/templates/base_template.dart';

/// The shared layout behind every priced document: masthead, party and meta
/// cards, the line-item table, the totals panel, notes and signatures.
///
/// Sales invoices, expense documents and quotations differ only in labels and
/// in which party they address, so they subclass this instead of repeating
/// the layout. Override any of the `build*` hooks to change one block without
/// touching the rest.
abstract class ItemizedInvoiceTemplate<T extends PdfItemizedInvoiceModel>
    extends BaseTemplate<T> {
  ItemizedInvoiceTemplate({
    required super.data,
    required super.pdfConfig,
    super.headers,
    super.title,
    super.qrCode,
    super.qrCodeSize,
    super.theme,
    super.pageFormat,
    this.showRowNumbers = true,
    this.showSignatures = true,
    this.signatureLabels,
  });

  /// Prepends a `#` column to the item table.
  final bool showRowNumbers;

  /// Renders signature lines under the totals.
  final bool showSignatures;

  /// Overrides the default `Issued by` / `Received by` labels.
  final List<String>? signatureLabels;

  /// Label above the party card — `BILL TO` for a sale, `PAID TO` for an
  /// expense.
  String get partyLabel => labels.billTo;

  /// Whether the document deals in money at all.
  ///
  /// A delivery note lists what was sent, not what it cost: turning this off
  /// drops the price, discount, tax and amount columns, the totals panel and
  /// the paid/unpaid stamp in one move, leaving the table, the parties and
  /// the signatures.
  bool get showPricing => true;

  /// Whether to print what has been paid and what is still owed.
  ///
  /// Off for a document that is not owed yet — a quotation is an offer, not a
  /// debt — even when it does show prices.
  bool get showSettlement => showPricing;

  /// The date an overdue document is judged against. Defaults to the issue
  /// date's own clock; override it to render a document as of a fixed day.
  DateTime get asOf => DateTime.now();

  /// Status pill shown next to the document number.
  ///
  /// An unpaid document whose due date has passed says so — that is the whole
  /// reason a reader looks at the top of the page.
  String? get statusLabel {
    if (!showSettlement) return null;
    if (data.isFullyPaid) return labels.statusPaid;
    if (data.isOverdueOn(asOf)) return labels.statusOverdue;
    return labels.statusUnpaid;
  }

  PdfColor? get statusColor =>
      data.isFullyPaid ? PdfColors.green700 : PdfColors.red700;

  /// True when at least one line carries a unit label.
  bool get hasUnits => data.items.any((item) => item.unit?.isNotEmpty ?? false);

  /// Money columns name the currency once in the header — `Unit Price (SAR)` —
  /// so cells stay numeric and the columns stay narrow.
  String moneyHeader(String label) => '$label\n(${pdfConfig.currency})';

  /// Columns of the item table. Override to add or drop a column.
  List<PdfColumnSpec> get columns => [
    PdfColumnSpec(labels.description, flex: 3.6),
    // Sized to their content: these two carry short values under a label that
    // is one unbreakable word in Arabic, and a flex share narrow enough for
    // `Qty` splits `الكمية` down the middle.
    PdfColumnSpec(labels.quantity, align: PdfCellAlign.center, intrinsic: true),
    if (hasUnits)
      PdfColumnSpec(labels.unit, align: PdfCellAlign.center, intrinsic: true),
    if (showPricing) ...[
      PdfColumnSpec(
        moneyHeader(labels.unitPrice),
        flex: 1.5,
        align: PdfCellAlign.end,
      ),
      if (data.itemsDiscount > 0)
        PdfColumnSpec(
          moneyHeader(labels.discount),
          flex: 1.3,
          align: PdfCellAlign.end,
        ),
      if (data.itemsTax > 0)
        PdfColumnSpec(
          moneyHeader(labels.tax),
          flex: 1.3,
          align: PdfCellAlign.end,
        ),
      PdfColumnSpec(
        moneyHeader(labels.amount),
        flex: 1.6,
        align: PdfCellAlign.end,
      ),
    ],
  ];

  /// One row of already-formatted cells per line item.
  List<List<String>> get rows => [
    for (final item in data.chargedItems)
      [
        [
          item.title,
          if (item.sku?.isNotEmpty ?? false) '(${item.sku})',
          if (item.description?.isNotEmpty ?? false) '\n${item.description}',
        ].join(' '),
        format.quantity(item.qty),
        if (hasUnits) item.unit ?? '',
        if (showPricing) ...[
          format.number(item.price),
          if (data.itemsDiscount > 0) format.number(item.discount),
          if (data.itemsTax > 0) format.number(item.tax),
          format.number(item.total),
        ],
      ],
  ];

  /// Key/value pairs in the meta card next to the party.
  Map<String, String> get metaFields => {
    labels.date: format.longDate(data.date),
    if (data.dueDate != null) labels.dueDate: format.longDate(data.dueDate),
    if (data.reference?.isNotEmpty ?? false) labels.reference: data.reference!,
    if (data.paymentMethod.isNotEmpty) labels.paymentMethod: data.paymentMethod,
  };

  /// Lines shown beside the totals panel, in the space that would otherwise
  /// be empty. Override to print bank details or delivery terms.
  ///
  /// An empty key renders the value on its own, unlabelled.
  Map<String, String> get settlementLines => {
    if (data.paymentMethod.isNotEmpty) labels.method: data.paymentMethod,
    if (showSettlement)
      labels.status:
          data.isFullyPaid ? labels.settledInFull : labels.partiallySettled,
  };

  /// Label above [settlementLines].
  String get settlementLabel => labels.payment;

  /// Rows above the accent total bar, as raw amounts. The panel formats them
  /// so the figure and the currency stay separate text runs.
  Map<String, double> get totalLines => {
    labels.subtotal: data.subtotal,
    if (data.totalDiscount > 0) labels.discount: -data.totalDiscount,
    if (data.totalTax > 0) taxLineLabel: data.totalTax,
  };

  /// `Tax (15%)` when one rate covers the document, plain `Tax` when the
  /// breakdown below is going to spell the rates out anyway.
  ///
  /// One or the other, never both: naming the rate here *and* listing it under
  /// the totals says the same thing twice.
  String get taxLineLabel {
    final label = labels.tax;
    if (showTaxBreakdown) return label;
    final charged = data.taxBreakdown.where((band) => band.rate > 0).toList();
    if (charged.length != 1) return label;
    return '$label (${format.percent(charged.first.rate)})';
  }

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
    statusLabel: statusLabel,
    statusColor: statusColor,
  );

  @override
  List<pw.Widget> body(pw.Context context) => [
    ui.gap(1.5),
    buildPartyAndMeta(),
    ui.gap(1.5),
    // Its own block so a long document breaks across pages inside the table.
    buildItemsTable(),
    if (showPricing) ...[
      ui.gap(1.4),
      buildTotals(),
      if (showTaxBreakdown) ...[ui.gap(1.4), buildTaxBreakdown()],
    ],
    if (data.notes?.isNotEmpty ?? false) ...[
      ui.gap(1.5),
      sections.notes(data.notes!, label: labels.notes),
    ],
    if (showSignatures) ...[
      ui.gap(1.5),
      sections.signatures(
        signatureLabels ?? [labels.issuedBy, labels.receivedBy],
      ),
    ],
  ];

  pw.Widget buildPartyAndMeta() => sections.partyAndMeta(
    party: data.customer,
    partyLabel: partyLabel,
    meta: metaFields,
    qrData: qrCode,
    qrSize: qrCodeSize,
  );

  pw.Widget buildItemsTable() =>
      PdfDataTable(
        ui: ui,
        columns:
            headers.isEmpty
                ? columns
                : PdfDataTable.columnsFromHeaders(headers),
        rows: rows,
        rowNumbers: showRowNumbers,
        emptyPlaceholder: labels.noItems,
      ).build();

  /// Whether to spell out what was taxed at each rate. Shown only when the
  /// document actually mixes rates; one rate is already named on the tax line.
  bool get showTaxBreakdown => data.hasMixedTaxRates;

  pw.Widget buildTaxBreakdown() => pw.Row(
    children: [
      pw.Expanded(child: pw.SizedBox()),
      sections.taxBreakdown(
        data.taxBreakdown,
        label: labels.taxBreakdown,
        baseLabel: labels.taxableAmount,
        rateLabel: labels.taxRate,
        taxLabel: labels.tax,
      ),
    ],
  );

  pw.Widget buildTotals() => sections.totalsPanel(
    leading: sections.infoBlock(settlementLabel, settlementLines),
    lines: totalLines,
    totalLabel: labels.total,
    totalValue: data.total,
    paidLabel: labels.paid,
    paidValue: showSettlement ? data.paid : null,
    dueLabel: labels.balanceDue,
    dueValue: showSettlement && !data.isFullyPaid ? data.due : null,
  );
}
