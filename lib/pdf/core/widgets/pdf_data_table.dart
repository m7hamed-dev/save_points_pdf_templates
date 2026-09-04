import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:save_points_pdf_templates/pdf/core/widgets/pdf_ui.dart';
import 'package:save_points_pdf_templates/pdf/pdf_config/pdf_theme.dart';

/// One column of a [PdfDataTable].
class PdfColumnSpec {
  const PdfColumnSpec(
    this.label, {
    this.flex = 1,
    this.align = PdfCellAlign.start,
    this.fixedWidth,
    this.intrinsic = false,
  });

  /// Header text.
  final String label;

  /// Relative width. Ignored when [fixedWidth] is set.
  final double flex;

  /// Horizontal alignment applied to the header and every cell below it.
  final PdfCellAlign align;

  /// Absolute width in points. Use for narrow columns such as `#` or `Qty`.
  final double? fixedWidth;

  /// Sizes the column to its widest cell instead of taking a [flex] share of
  /// the row.
  ///
  /// Use it wherever the label cannot be broken. A flex tuned for `Unit` is
  /// too narrow for `الوحدة`, which is one unbreakable word: the renderer
  /// splits it across two lines as `لوحدة` / `ا` and reorders the halves.
  /// Ignored when [fixedWidth] is set.
  final bool intrinsic;
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
    this.emphasizeLastColumn = true,
    this.carryForward,
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

  /// Sets the final column in bold. On an invoice that column is the line
  /// amount, which is what a reader scans for.
  final bool emphasizeLastColumn;

  /// Labels for the carried-forward rows on a table that spans pages.
  ///
  /// A long document breaks between rows, and a reader who turns the page has
  /// no idea what the lines above it added up to. Supplying this closes each
  /// page with a `Carried forward` row and opens the next with `Brought
  /// forward`, the way a ledger does.
  final PdfCarryForward? carryForward;

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

  pw.Table _table(List<PdfColumnSpec> cols, List<List<String>> data) {
    final order = ui.isRtl ? cols.reversed.toList() : cols;
    // The emphasized column is the last one in *logical* order — the line
    // amount. Mirroring moves it to the head of the row, so the index has to
    // travel with it; leaving it at `length - 1` bolds whatever ended up last
    // after the flip, which on an Arabic invoice is the row-number column.
    final emphasized =
        !emphasizeLastColumn || cols.isEmpty
            ? -1
            : (ui.isRtl ? 0 : cols.length - 1);

    return pw.Table(
      columnWidths: {
        for (var i = 0; i < order.length; i++) i: _widthOf(order[i]),
      },
      children: [
        _headerRow(order),
        for (var r = 0; r < data.length; r++)
          _bodyRow(
            order,
            ui.isRtl ? data[r].reversed.toList() : data[r],
            r,
            isLast: r == data.length - 1,
            emphasized: emphasized,
          ),
      ],
    );
  }

  /// The table split into chunks of [rowsPerPage], each closing with a
  /// `Carried forward` row and the next opening with `Brought forward`.
  ///
  /// Returned as separate blocks so the renderer breaks between them, and
  /// meant to be spread into a template's `body`:
  ///
  /// ```dart
  /// @override
  /// List<pw.Widget> body(pw.Context context) => [
  ///   ...buildItemsTable().buildPaginated(rowsPerPage: 24),
  /// ];
  /// ```
  ///
  /// The split is yours to choose rather than measured, and deliberately so:
  /// how many rows fit depends on the font's metrics and on how tall the
  /// header and footer come out, and a carried-forward line placed by a guess
  /// is worse than none — it would claim a total for rows that are not above
  /// it. Set it once for your layout and the figures are exact.
  List<pw.Widget> buildPaginated({required int rowsPerPage}) {
    assert(rowsPerPage > 0, 'a page has to hold at least one row');
    final carry = carryForward;
    final data = _effectiveRows;
    if (carry == null || data.length <= rowsPerPage) return [build()];

    final cols = _effectiveColumns;
    final chunks = <pw.Widget>[];
    for (var start = 0; start < data.length; start += rowsPerPage) {
      final end = (start + rowsPerPage).clamp(0, data.length);
      chunks.add(
        _table(cols, [
          if (start > 0)
            _carryRow(cols, carry, carry.broughtLabel, carry.totalAfter(start)),
          ...data.sublist(start, end),
          if (end < data.length)
            _carryRow(cols, carry, carry.carriedLabel, carry.totalAfter(end)),
        ]),
      );
    }
    return chunks;
  }

  /// A row that states the running total and nothing else.
  List<String> _carryRow(
    List<PdfColumnSpec> cols,
    PdfCarryForward carry,
    String label,
    double total,
  ) {
    // The label sits in the first column that carries text — past the row
    // number, which would be meaningless on a total.
    final labelIndex = rowNumbers ? 1 : 0;
    final valueIndex = carry.column + (rowNumbers ? 1 : 0);
    return [
      for (var i = 0; i < cols.length; i++)
        if (i == labelIndex)
          label
        else if (i == valueIndex)
          carry.format(total)
        else
          '',
    ];
  }

  pw.TableColumnWidth _widthOf(PdfColumnSpec column) {
    if (column.fixedWidth != null) {
      return pw.FixedColumnWidth(column.fixedWidth!);
    }
    return column.intrinsic
        ? const pw.IntrinsicColumnWidth()
        : pw.FlexColumnWidth(column.flex);
  }

  pw.TableRow _headerRow(List<PdfColumnSpec> cols) {
    final theme = ui.theme;
    final filled = theme.headerStyle == PdfTableHeaderStyle.filled;
    final background = switch (theme.headerStyle) {
      PdfTableHeaderStyle.filled => theme.accent,
      PdfTableHeaderStyle.soft => theme.accentSoft,
      PdfTableHeaderStyle.underlined => PdfColors.white,
    };

    return pw.TableRow(
      repeat: true,
      decoration: pw.BoxDecoration(
        color: background,
        border: pw.Border(
          bottom: pw.BorderSide(color: theme.accent, width: 0.9),
        ),
      ),
      children: [
        for (final column in cols)
          pw.Container(
            constraints: pw.BoxConstraints(minHeight: theme.tableHeaderHeight),
            alignment: _alignment(column.align),
            padding: pw.EdgeInsets.symmetric(
              horizontal: theme.spacing * 0.55,
              vertical: theme.spacing * 0.5,
            ),
            child: ui.microLabel(
              column.label,
              color: filled ? theme.onAccent : theme.accent,
              align: _textAlign(column.align),
            ),
          ),
      ],
    );
  }

  pw.TableRow _bodyRow(
    List<PdfColumnSpec> cols,
    List<String> cells,
    int index, {
    required int emphasized,
    bool isLast = false,
  }) {
    final theme = ui.theme;
    final striped = theme.showZebraStripes && index.isOdd;
    // The closing rule is always drawn: it is what ends the table. The rules
    // between rows are optional, because rows set on a generous height
    // separate themselves without them.
    final ruled = theme.showRowRules || isLast;
    return pw.TableRow(
      decoration: pw.BoxDecoration(
        color: striped ? theme.zebra : PdfColors.white,
        border:
            ruled
                ? pw.Border(
                  bottom: pw.BorderSide(
                    color: isLast ? theme.accent : theme.border,
                    width: isLast ? 0.9 : theme.borderWidth,
                  ),
                )
                : null,
      ),
      children: [
        for (var i = 0; i < cols.length; i++)
          pw.Container(
            constraints: pw.BoxConstraints(minHeight: theme.tableRowHeight),
            alignment: _alignment(cols[i].align),
            padding: pw.EdgeInsets.symmetric(
              horizontal: theme.spacing * 0.55,
              vertical: theme.spacing * 0.55,
            ),
            child: ui.bidiText(
              i < cells.length ? cells[i] : '',
              align: _textAlign(cols[i].align),
              bold: i == emphasized,
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

/// How a table that spans pages carries its running total across the break.
///
/// A two-hundred-line invoice breaks between rows, and a reader who turns the
/// page cannot tell what the lines above added up to. An accountant expects
/// the page to close with a subtotal and the next to open with the same
/// figure — without it the pages after the first are unauditable on their own.
class PdfCarryForward {
  const PdfCarryForward({
    required this.column,
    required this.values,
    required this.format,
    this.carriedLabel = 'Carried forward',
    this.broughtLabel = 'Brought forward',
  });

  /// Index of the column the running total belongs in, in logical order —
  /// usually the amount column, the last one.
  final int column;

  /// The value of each row, in the same order as the table's rows.
  final List<double> values;

  /// How to render the running figure. Pass the document's own money format
  /// so the carried figure matches the column above it.
  final String Function(double) format;

  final String carriedLabel;
  final String broughtLabel;

  /// The running total after [count] rows.
  double totalAfter(int count) =>
      values.take(count).fold(0.0, (sum, value) => sum + value);
}
