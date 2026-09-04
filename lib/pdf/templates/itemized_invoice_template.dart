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
  String get partyLabel => tr('BILL TO', 'فاتورة إلى');

  /// The date an overdue document is judged against. Defaults to the issue
  /// date's own clock; override it to render a document as of a fixed day.
  DateTime get asOf => DateTime.now();

  /// Status pill shown next to the document number.
  ///
  /// An unpaid document whose due date has passed says so — that is the whole
  /// reason a reader looks at the top of the page.
  String? get statusLabel {
    if (data.isFullyPaid) return tr('PAID', 'مدفوعة');
    if (data.isOverdueOn(asOf)) return tr('OVERDUE', 'متأخرة');
    return tr('UNPAID', 'غير مدفوعة');
  }

  PdfColor? get statusColor =>
      data.isFullyPaid ? PdfColors.green700 : PdfColors.red700;

  /// True when at least one line carries a unit label.
  bool get hasUnits => data.items.any((item) => item.unit?.isNotEmpty ?? false);

  /// Money columns name the currency once in the header — `Unit Price (SAR)` —
  /// so cells stay numeric and the columns stay narrow.
  String moneyHeader(String english, String arabic) =>
      '${tr(english, arabic)}\n(${pdfConfig.currency})';

  /// Columns of the item table. Override to add or drop a column.
  List<PdfColumnSpec> get columns => [
    PdfColumnSpec(tr('Description', 'البيان'), flex: 3.6),
    // Sized to their content: these two carry short values under a label that
    // is one unbreakable word in Arabic, and a flex share narrow enough for
    // `Qty` splits `الكمية` down the middle.
    PdfColumnSpec(
      tr('Qty', 'الكمية'),
      align: PdfCellAlign.center,
      intrinsic: true,
    ),
    if (hasUnits)
      PdfColumnSpec(
        tr('Unit', 'الوحدة'),
        align: PdfCellAlign.center,
        intrinsic: true,
      ),
    PdfColumnSpec(
      moneyHeader('Unit Price', 'سعر الوحدة'),
      flex: 1.5,
      align: PdfCellAlign.end,
    ),
    if (data.itemsDiscount > 0)
      PdfColumnSpec(
        moneyHeader('Discount', 'الخصم'),
        flex: 1.3,
        align: PdfCellAlign.end,
      ),
    if (data.itemsTax > 0)
      PdfColumnSpec(
        moneyHeader('Tax', 'الضريبة'),
        flex: 1.3,
        align: PdfCellAlign.end,
      ),
    PdfColumnSpec(
      moneyHeader('Amount', 'الإجمالي'),
      flex: 1.6,
      align: PdfCellAlign.end,
    ),
  ];

  /// One row of already-formatted cells per line item.
  List<List<String>> get rows => [
    for (final item in data.items)
      [
        [
          item.title,
          if (item.sku?.isNotEmpty ?? false) '(${item.sku})',
          if (item.description?.isNotEmpty ?? false) '\n${item.description}',
        ].join(' '),
        format.quantity(item.qty),
        if (hasUnits) item.unit ?? '',
        format.number(item.price),
        if (data.itemsDiscount > 0) format.number(item.discount),
        if (data.itemsTax > 0) format.number(item.tax),
        format.number(item.total),
      ],
  ];

  /// Key/value pairs in the meta card next to the party.
  Map<String, String> get metaFields => {
    tr('Date', 'التاريخ'): format.longDate(data.date),
    if (data.dueDate != null)
      tr('Due', 'الاستحقاق'): format.longDate(data.dueDate),
    if (data.reference?.isNotEmpty ?? false)
      tr('Reference', 'المرجع'): data.reference!,
    if (data.paymentMethod.isNotEmpty)
      tr('Payment', 'طريقة الدفع'): data.paymentMethod,
  };

  /// Lines shown beside the totals panel, in the space that would otherwise
  /// be empty. Override to print bank details or delivery terms.
  ///
  /// An empty key renders the value on its own, unlabelled.
  Map<String, String> get settlementLines => {
    if (data.paymentMethod.isNotEmpty)
      tr('Method', 'الطريقة'): data.paymentMethod,
    tr('Status', 'الحالة'):
        data.isFullyPaid
            ? tr('Settled in full', 'مسددة بالكامل')
            : tr('Partially settled', 'مسددة جزئياً'),
  };

  /// Label above [settlementLines].
  String get settlementLabel => tr('PAYMENT', 'الدفع');

  /// Rows above the accent total bar, as raw amounts. The panel formats them
  /// so the figure and the currency stay separate text runs.
  Map<String, double> get totalLines => {
    tr('Subtotal', 'الإجمالي الفرعي'): data.subtotal,
    if (data.totalDiscount > 0) tr('Discount', 'الخصم'): -data.totalDiscount,
    if (data.totalTax > 0) tr('Tax', 'الضريبة'): data.totalTax,
  };

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
    ui.gap(1.4),
    buildTotals(),
    if (data.notes?.isNotEmpty ?? false) ...[
      ui.gap(1.5),
      sections.notes(data.notes!, label: tr('NOTES', 'ملاحظات')),
    ],
    if (showSignatures) ...[
      ui.gap(1.5),
      sections.signatures(
        signatureLabels ??
            [tr('Issued by', 'المحرر'), tr('Received by', 'المستلم')],
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
        emptyPlaceholder: tr('No items', 'لا توجد عناصر'),
      ).build();

  pw.Widget buildTotals() => sections.totalsPanel(
    leading: sections.infoBlock(settlementLabel, settlementLines),
    lines: totalLines,
    totalLabel: tr('TOTAL', 'الإجمالي'),
    totalValue: data.total,
    paidLabel: tr('Paid', 'المدفوع'),
    paidValue: data.paid,
    dueLabel: tr('Balance Due', 'المتبقي'),
    dueValue: data.isFullyPaid ? null : data.due,
  );
}
