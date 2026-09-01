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
  pw.Widget? header(pw.Context context) => sections.documentHeader(
    titleEn: title.isNotEmpty ? title : data.displayTitle,
    titleAr: arabicTitle(data.displayTitleAr),
    company: company,
    logo: logo,
    logoSize: pdfConfig.logoSize,
    documentNumber: data.id,
    documentNumberLabel: tr('No.', 'رقم'),
  );

  @override
  List<pw.Widget> body(pw.Context context) => [
    ui.gap(1.5),
    if (data.customer.isNotEmpty || _meta.isNotEmpty || qrCode.isNotEmpty) ...[
      sections.partyAndMeta(
        party: data.customer,
        partyLabel: tr('FOR', 'إلى'),
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
      sections.notes(data.notes!, label: tr('NOTES', 'ملاحظات')),
    ],
  ];

  Map<String, String> get _meta => {
    if (data.date != null) tr('Date', 'التاريخ'): format.longDate(data.date),
    if (data.reference?.isNotEmpty ?? false)
      tr('Reference', 'المرجع'): data.reference!,
    tr('Rows', 'عدد السطور'): format.quantity(data.items.length.toDouble()),
  };

  pw.Widget _table() {
    final columns =
        effectiveHeaders.isEmpty
            ? <PdfColumnSpec>[PdfColumnSpec(tr('Value', 'القيمة'))]
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
      emptyPlaceholder: tr('No rows', 'لا توجد بيانات'),
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
