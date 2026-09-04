import 'package:pdf/widgets.dart' as pw;
import 'package:save_points_pdf_templates/pdf/core/widgets/pdf_data_table.dart';
import 'package:save_points_pdf_templates/pdf/core/widgets/pdf_ui.dart';
import 'package:save_points_pdf_templates/pdf/models/pdf_list_string_model.dart';
import 'package:save_points_pdf_templates/pdf/templates/base_template.dart';

/// A generic tabular document built from raw strings.
///
/// You supply headers and rows, the template supplies the masthead, styling,
/// pagination and footer. Use it for reports, statements and stock counts —
/// anything that is a table and has no dedicated model.
///
/// ```dart
/// ListStringsTemplate(
///   pdfConfig: config,
///   data: PdfListStringsModel(
///     title: 'Stock Count',
///     headers: const ['SKU', 'Item', 'Counted'],
///     items: rows,
///     summary: const {'Lines': '128'},
///   ),
/// );
/// ```
class ListStringsTemplate extends BaseTemplate<PdfListStringsModel> {
  ListStringsTemplate({
    required super.data,
    required super.pdfConfig,
    super.headers,
    super.title,
    super.qrCode,
    super.qrCodeSize,
    super.theme,
    super.pageFormat,
    this.showRowNumbers = true,
  });

  /// Prepends a `#` column to the table.
  final bool showRowNumbers;

  /// Headers passed to the template take precedence over the model's.
  List<String> get effectiveHeaders =>
      headers.isNotEmpty ? headers : data.headers;

  @override
  pw.Widget? footer(pw.Context context) =>
      sections.pageFooter(context, note: company?.name, reference: data.id);

  @override
  pw.Widget? header(pw.Context context) => sections.documentHeader(
    titleEn: title.isNotEmpty ? title : documentTitle,
    // An explicit title is one string in an unknown language, so it
    // stands alone rather than being captioned by the type's Arabic.
    titleAr: title.isNotEmpty ? '' : arabicTitle(documentSubtitle),
    company: company,
    logo: logo,
    logoSize: pdfConfig.logoSize,
    documentNumber: data.id,
    documentNumberLabel: labels.documentNumber,
  );

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
    if (data.customer.isNotEmpty || _meta.isNotEmpty || qrCode.isNotEmpty) ...[
      sections.partyAndMeta(
        party: data.customer,
        partyLabel: labels.reportFor,
        meta: _meta,
        qrData: qrCode,
        qrSize: qrCodeSize,
      ),
      ui.gap(1.5),
    ],
    // Its own block so a long report breaks across pages inside the table.
    _table(),
    if (data.summary.isNotEmpty) ...[ui.gap(1.5), _summary()],
    if (data.notes?.isNotEmpty ?? false) ...[
      ui.gap(1.5),
      sections.notes(data.notes!, label: labels.notes),
    ],
  ];

  Map<String, String> get _meta => {
    if (data.date != null) labels.date: format.longDate(data.date),
    if (data.reference?.isNotEmpty ?? false) labels.reference: data.reference!,
    labels.rowCount: format.quantity(data.items.length.toDouble()),
  };

  pw.Widget _table() {
    final columns =
        effectiveHeaders.isEmpty
            ? <PdfColumnSpec>[PdfColumnSpec(labels.value)]
            : [
              for (var i = 0; i < effectiveHeaders.length; i++)
                PdfColumnSpec(
                  effectiveHeaders[i],
                  flex: i < data.columnFlex.length ? data.columnFlex[i] : 1,
                  align: i == 0 ? PdfCellAlign.start : PdfCellAlign.center,
                ),
            ];

    return PdfDataTable(
      ui: ui,
      columns: columns,
      rows: data.items,
      rowNumbers: showRowNumbers,
      emptyPlaceholder: labels.noRows,
    ).build();
  }

  pw.Widget _summary() {
    final entries = data.summary.entries.toList();
    return sections.totalsPanelText(
      lines: {
        for (final entry in entries.take(entries.length - 1))
          entry.key: entry.value,
      },
      totalLabel: entries.last.key,
      totalValue: entries.last.value,
    );
  }
}
