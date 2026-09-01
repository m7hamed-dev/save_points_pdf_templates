import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:save_points_pdf_templates/pdf/core/widgets/pdf_ui.dart';

/// One column of a [PdfDataTable].
class PdfColumnSpec {
  const PdfColumnSpec(
    this.label, {
    this.flex = 1,
    this.align = PdfCellAlign.start,
    this.fixedWidth,
  });

  /// Header text.
  final String label;

  /// Relative width. Ignored when [fixedWidth] is set.
  final double flex;

  /// Horizontal alignment applied to the header and every cell below it.
  final PdfCellAlign align;

  /// Absolute width in points. Use for narrow columns such as `#` or `Qty`.
  final double? fixedWidth;
}

/// The document table.
///
/// Built on [pw.Table] rather than nested rows, which is what lets a long
/// document split across pages at row boundaries instead of overflowing.
/// The header row can be repeated on every page by passing it to
/// `MultiPage.header`, and the theme drives the accent header, zebra
/// striping and hairline grid.
class PdfDataTable {
  const PdfDataTable({
    required this.ui,
    required this.columns,
    required this.rows,
    this.rowNumbers = false,
    this.rowNumberLabel = '#',
    this.emptyPlaceholder,
  });

  final PdfUi ui;

  /// Column definitions, in visual order for a left-to-right document. The
  /// table mirrors them automatically when the document is right-to-left.
  final List<PdfColumnSpec> columns;

  /// Already-formatted cell text. Rows shorter than [columns] are padded.
  final List<List<String>> rows;

  /// Prepends an auto-incrementing index column.
  final bool rowNumbers;

  final String rowNumberLabel;

  /// Message shown in place of the body when [rows] is empty.
  final String? emptyPlaceholder;

  /// Builds columns from plain header strings, giving the first column twice
  /// the width and right-aligning every numeric column after it.
  static List<PdfColumnSpec> columnsFromHeaders(List<String> headers) {
    return [
      for (var i = 0; i < headers.length; i++)
        PdfColumnSpec(
          headers[i],
          flex: i == 0 ? 3 : 1,
          align: i == 0 ? PdfCellAlign.start : PdfCellAlign.end,
        ),
    ];
  }

  List<PdfColumnSpec> get _effectiveColumns => [
    if (rowNumbers)
      PdfColumnSpec(rowNumberLabel, fixedWidth: 26, align: PdfCellAlign.center),
    ...columns,
  ];

  List<List<String>> get _effectiveRows => [
    for (var i = 0; i < rows.length; i++)
      [
        if (rowNumbers) '${i + 1}',
        ...rows[i],
        // Pad short rows so the grid never collapses.
        for (var c = rows[i].length; c < columns.length; c++) '',
      ],
  ];

  pw.Widget build() {
    final cols = _effectiveColumns;
    final data = _effectiveRows;

    if (data.isEmpty && emptyPlaceholder != null) {
      return pw.Column(
        children: [
          _table(cols, const []),
          ui.card(
            width: double.infinity,
            alignment: pw.Alignment.center,
            child: ui.caption(emptyPlaceholder!, align: pw.TextAlign.center),
          ),
        ],
      );
    }
    return _table(cols, data);
  }

  /// The header row on its own, for repeating it at the top of every page.
  pw.Widget buildHeaderOnly() => _table(_effectiveColumns, const []);

  pw.Table _table(List<PdfColumnSpec> cols, List<List<String>> data) {
    final order = ui.isRtl ? cols.reversed.toList() : cols;

    return pw.Table(
      columnWidths: {
        for (var i = 0; i < order.length; i++)
          i:
              order[i].fixedWidth != null
                  ? pw.FixedColumnWidth(order[i].fixedWidth!)
                  : pw.FlexColumnWidth(order[i].flex),
      },
      children: [
        _headerRow(order),
        for (var r = 0; r < data.length; r++)
          _bodyRow(order, ui.isRtl ? data[r].reversed.toList() : data[r], r),
      ],
    );
  }

  pw.TableRow _headerRow(List<PdfColumnSpec> cols) {
    final theme = ui.theme;
    return pw.TableRow(
      repeat: true,
      decoration: pw.BoxDecoration(color: theme.accent),
      children: [
        for (final column in cols)
          pw.Container(
            constraints: pw.BoxConstraints(minHeight: theme.tableHeaderHeight),
            alignment: _alignment(column.align),
            padding: pw.EdgeInsets.symmetric(
              horizontal: theme.spacing * 0.6,
              vertical: theme.spacing * 0.4,
            ),
            child: ui.text(
              column.label,
              size: theme.captionSize + 0.5,
              color: theme.onAccent,
              bold: true,
              align: _textAlign(column.align),
              maxLines: 2,
            ),
          ),
      ],
    );
  }

  pw.TableRow _bodyRow(
    List<PdfColumnSpec> cols,
    List<String> cells,
    int index,
  ) {
    final theme = ui.theme;
    final striped = theme.showZebraStripes && index.isOdd;
    return pw.TableRow(
      decoration: pw.BoxDecoration(
        color: striped ? theme.zebra : PdfColors.white,
        border: pw.Border(
          bottom: pw.BorderSide(color: theme.border, width: theme.borderWidth),
        ),
      ),
      children: [
        for (var i = 0; i < cols.length; i++)
          pw.Container(
            constraints: pw.BoxConstraints(minHeight: theme.tableRowHeight),
            alignment: _alignment(cols[i].align),
            padding: pw.EdgeInsets.symmetric(
              horizontal: theme.spacing * 0.6,
              vertical: theme.spacing * 0.4,
            ),
            child: ui.bidiText(
              i < cells.length ? cells[i] : '',
              align: _textAlign(cols[i].align),
            ),
          ),
      ],
    );
  }

  pw.Alignment _alignment(PdfCellAlign align) {
    switch (align) {
      case PdfCellAlign.center:
        return pw.Alignment.center;
      case PdfCellAlign.end:
        return ui.isRtl ? pw.Alignment.centerLeft : pw.Alignment.centerRight;
      case PdfCellAlign.start:
        return ui.isRtl ? pw.Alignment.centerRight : pw.Alignment.centerLeft;
    }
  }

  pw.TextAlign _textAlign(PdfCellAlign align) {
    switch (align) {
      case PdfCellAlign.center:
        return pw.TextAlign.center;
      case PdfCellAlign.end:
        return ui.alignEnd;
      case PdfCellAlign.start:
        return ui.alignStart;
    }
  }
}
