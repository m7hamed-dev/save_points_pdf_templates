import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:save_points_pdf_templates/save_points_pdf_templates.dart';

/// The only Arabic-capable font in the repository. The package deliberately
/// ships none, so the example app's asset stands in for a caller-supplied TTF.
const arabicFontPath = 'example/assets/fonts/Cairo/Cairo-Regular.ttf';

/// One text-showing operation recovered from a page's content stream.
///
/// Reading the drawn output is the only way to catch a mirroring bug: the
/// widget tree is identical in both directions, and it is the renderer that
/// decides which child ends up on the right.
class DrawnRun {
  const DrawnRun({
    required this.x,
    required this.size,
    required this.text,
    required this.isLatin,
  });

  /// Horizontal offset inside the page's content stream. Larger is further
  /// right, in either direction.
  final double x;

  /// Type size the run was set at.
  final double size;

  /// The characters for a Latin run. For an Arabic run this is the raw glyph
  /// id list — a TTF is embedded as Identity-H and does not decode back to
  /// text — which is why runs are told apart by [isLatin] and not by content.
  final String text;

  /// True when the run was drawn with the built-in Latin font. Giving the page
  /// a Latin base font and the Arabic TTF as a *fallback* is what makes the two
  /// halves of a mixed value distinguishable in the output.
  final bool isLatin;

  @override
  String toString() =>
      '${isLatin ? '"$text"' : 'arabic'}'
      '@${x.toStringAsFixed(1)}/${size.toStringAsFixed(0)}pt';
}

/// `… Td [(text)]TJ` for a Latin run, `… Td [<glyphs>]TJ` for an embedded TTF.
final _showText = RegExp(
  r'/F\d+ ([\d.]+) Tf [-\d.]+ Tc (-?[\d.]+) -?[\d.]+ Td '
  r'\[(?:\((.*?)\)|<([0-9A-Fa-f]+)>)\]TJ',
);

/// Lays [child] out on one uncompressed page and returns every run it drew.
Future<List<DrawnRun>> drawnRuns(
  pw.Widget child, {
  required bool rtl,
  pw.Font? fallback,
}) async {
  final document = pw.Document(compress: false);
  document.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      textDirection: rtl ? pw.TextDirection.rtl : pw.TextDirection.ltr,
      theme: pw.ThemeData.withFont(
        base: pw.Font.helvetica(),
        bold: pw.Font.helveticaBold(),
        fontFallback: [if (fallback != null) fallback],
      ),
      build: (_) => child,
    ),
  );

  final bytes = await document.save();
  final pdf = String.fromCharCodes(bytes);
  // The page content is the first stream; everything after it is font data,
  // which must not be scanned for what look like drawing operators.
  final start = pdf.indexOf('stream');
  final end = pdf.indexOf('endstream', start);
  expect(start, isNonNegative, reason: 'no content stream in the document');

  return [
    for (final match in _showText.allMatches(pdf.substring(start, end)))
      DrawnRun(
        size: double.parse(match.group(1)!),
        x: double.parse(match.group(2)!),
        text: match.group(3) ?? match.group(4)!,
        isLatin: match.group(3) != null,
      ),
  ];
}

DrawnRun rightmost(List<DrawnRun> runs) =>
    runs.reduce((a, b) => a.x >= b.x ? a : b);

DrawnRun leftmost(List<DrawnRun> runs) =>
    runs.reduce((a, b) => a.x <= b.x ? a : b);

double xOf(List<DrawnRun> runs, String text) =>
    runs.firstWhere((run) => run.text == text).x;

PdfUi uiFor({required bool rtl}) => PdfUi(
  theme: const PdfTheme(),
  formatters: PdfFormatters(locale: rtl ? 'ar' : 'en'),
  isRtl: rtl,
  canRenderArabic: true,
);

/// The text span of one table cell, for reading its content and weight.
pw.TextSpan cellSpan(pw.Widget cell) =>
    ((cell as pw.Container).child! as pw.RichText).text as pw.TextSpan;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late pw.Font arabicFont;

  setUpAll(() {
    final file = File(arabicFontPath);
    expect(
      file.existsSync(),
      isTrue,
      reason:
          'Arabic layout cannot be tested without an Arabic font. Expected the '
          'example app asset at $arabicFontPath.',
    );
    arabicFont = pw.Font.ttf(file.readAsBytesSync().buffer.asByteData());
  });

  // Everything the package does about right-to-left rests on this: the
  // renderer mirrors a Row's and a Wrap's main axis by itself. Widgets are
  // therefore handed their children in logical order and left alone. If a
  // future `pdf` release stops mirroring, these two tests fail first and say
  // why every Arabic document suddenly reads backwards.
  group('the renderer mirrors its own layout widgets', () {
    pw.Widget twoWords(pw.Widget Function(List<pw.Widget>) wrap) =>
        wrap([pw.Text('AAA'), pw.Text('BBB')]);

    test('Row draws its first child on the right in RTL', () async {
      pw.Widget row(List<pw.Widget> children) =>
          pw.Row(mainAxisSize: pw.MainAxisSize.min, children: children);

      final ltr = await drawnRuns(twoWords(row), rtl: false);
      expect(xOf(ltr, 'AAA'), lessThan(xOf(ltr, 'BBB')));

      final rtl = await drawnRuns(twoWords(row), rtl: true);
      expect(xOf(rtl, 'AAA'), greaterThan(xOf(rtl, 'BBB')));
    });

    test('Wrap draws its first child on the right in RTL', () async {
      pw.Widget wrap(List<pw.Widget> children) => pw.Wrap(children: children);

      final ltr = await drawnRuns(twoWords(wrap), rtl: false);
      expect(xOf(ltr, 'AAA'), lessThan(xOf(ltr, 'BBB')));

      final rtl = await drawnRuns(twoWords(wrap), rtl: true);
      expect(xOf(rtl, 'AAA'), greaterThan(xOf(rtl, 'BBB')));
    });
  });

  group('PdfUi.pair', () {
    // Reversing the parts on top of the renderer's own mirroring printed the
    // masthead as `INV-2026-0042 رقم` — the number first, the label after it.
    test('the label is read first in both directions', () async {
      final ltr = await drawnRuns(
        uiFor(rtl: false).pair('No.', 'INV-42'),
        rtl: false,
      );
      expect(xOf(ltr, 'No.'), lessThan(xOf(ltr, 'INV-42')));

      final rtl = await drawnRuns(
        uiFor(rtl: true).pair('No.', 'INV-42'),
        rtl: true,
      );
      expect(
        xOf(rtl, 'No.'),
        greaterThan(xOf(rtl, 'INV-42')),
        reason: 'the label must sit to the right of the value in Arabic',
      );
    });
  });

  group('PdfUi.bidiText', () {
    // `عربي LATIN`: the Arabic run comes first in the source, so it is the run
    // the reader meets first — on the right in Arabic, on the left in English.
    Future<List<DrawnRun>> mixed({required bool rtl}) => drawnRuns(
      uiFor(rtl: rtl).bidiText('عربي LATIN'),
      rtl: rtl,
      fallback: arabicFont,
    );

    test('keeps the source order of the runs in RTL', () async {
      final runs = await mixed(rtl: true);
      expect(runs.any((run) => run.isLatin), isTrue, reason: 'no Latin run');
      expect(runs.any((run) => !run.isLatin), isTrue, reason: 'no Arabic run');

      expect(
        rightmost(runs).isLatin,
        isFalse,
        reason:
            'the Arabic run is first in the source, so it starts on the '
            'right of an Arabic line — got $runs',
      );
      expect(leftmost(runs).isLatin, isTrue);
    });

    test('keeps the source order of the runs in LTR', () async {
      final runs = await mixed(rtl: false);
      expect(leftmost(runs).isLatin, isFalse, reason: 'got $runs');
      expect(rightmost(runs).isLatin, isTrue);
    });

    test('a single-script value stays a plain text widget', () {
      // Only mixed values pay for the run layout; anything else keeps normal
      // line wrapping, which a Wrap of separate words would lose.
      expect(uiFor(rtl: true).bidiText('فاتورة مبيعات'), isA<pw.RichText>());
      expect(uiFor(rtl: false).bidiText('Sales Invoice'), isA<pw.RichText>());
      expect(uiFor(rtl: true).bidiText('عربي LATIN'), isA<pw.Wrap>());
    });
  });

  // The masthead used to print the English label as the largest type in every
  // document, with the Arabic demoted to a muted sub-title — an Arabic invoice
  // that reads as an English one that happens to be mirrored.
  group('PdfSections.documentHeader', () {
    Future<List<DrawnRun>> masthead({required bool rtl}) => drawnRuns(
      PdfSections(
        uiFor(rtl: rtl),
      ).documentHeader(titleEn: 'Sales Invoice', titleAr: 'فاتورة مبيعات'),
      rtl: rtl,
      fallback: arabicFont,
    );

    DrawnRun largest(List<DrawnRun> runs) =>
        runs.reduce((a, b) => a.size >= b.size ? a : b);

    test('leads with Arabic in an Arabic document', () async {
      final runs = await masthead(rtl: true);
      expect(largest(runs).isLatin, isFalse, reason: 'got $runs');
    });

    test('leads with English in an English document', () async {
      final runs = await masthead(rtl: false);
      expect(largest(runs).isLatin, isTrue, reason: 'got $runs');
    });

    test('an unpaired title is not captioned by itself', () async {
      // Templates blank `titleAr` when the caller overrode the title, so the
      // one string they gave stands alone at every size it is drawn.
      final runs = await drawnRuns(
        PdfSections(
          uiFor(rtl: true),
        ).documentHeader(titleEn: 'Stock Count', titleAr: ''),
        rtl: true,
        fallback: arabicFont,
      );
      expect(runs.where((run) => run.isLatin), isNotEmpty);
      expect(runs.map((run) => run.size).toSet(), hasLength(1));
    });
  });

  group('PdfUi.pair', () {
    // A row lays its children out at their natural width whatever the box, so
    // a long value beside a long label was drawn straight out of its column.
    test('stays inside a box narrower than its content', () async {
      final runs = await drawnRuns(
        pw.SizedBox(
          width: 60,
          child: uiFor(rtl: false).pair('COMMERCIAL REGISTER', '1010101010'),
        ),
        rtl: false,
      );
      expect(runs, isNotEmpty);
      for (final run in runs) {
        expect(
          run.x,
          lessThan(60),
          reason: 'run $run escaped the 60pt box — $runs',
        );
      }
    });
  });

  group('PdfDataTable', () {
    pw.Table table({required bool rtl}) =>
        PdfDataTable(
              ui: uiFor(rtl: rtl),
              columns: const [
                PdfColumnSpec('Item'),
                PdfColumnSpec('Qty'),
                PdfColumnSpec('Amount'),
              ],
              rows: const [
                ['Widget', '3', '300.00'],
              ],
              rowNumbers: true,
            ).build()
            as pw.Table;

    test('mirrors its columns in RTL', () {
      expect(
        table(rtl: false).children[1].children.map(cellSpan).map((s) => s.text),
        ['1', 'Widget', '3', '300.00'],
      );
      expect(
        table(rtl: true).children[1].children.map(cellSpan).map((s) => s.text),
        ['300.00', '3', 'Widget', '1'],
      );
    });

    // The emphasized column is the amount — the figure a reader scans for.
    // Anchoring it to the last *visual* cell bolded the row number instead,
    // because mirroring moves the amount to the head of the row.
    test('emphasizes the amount column in both directions', () {
      for (final rtl in [false, true]) {
        final row = table(rtl: rtl).children[1].children.map(cellSpan);
        final bold = row.where(
          (span) => span.style?.fontWeight == pw.FontWeight.bold,
        );
        expect(bold.map((span) => span.text), ['300.00'], reason: 'rtl=$rtl');
      }
    });

    // An Arabic column label is one unbreakable word, so a flex share tuned
    // for `Unit` split `الوحدة` mid-word and reordered the halves.
    test(
      'an intrinsic column is sized to its content, not to a flex share',
      () {
        final table =
            PdfDataTable(
                  ui: uiFor(rtl: true),
                  columns: const [
                    PdfColumnSpec('البيان', flex: 3),
                    PdfColumnSpec('الوحدة', intrinsic: true),
                  ],
                  rows: const [
                    ['قلم', 'قطعة'],
                  ],
                ).build()
                as pw.Table;

        // Columns are mirrored, so the intrinsic one leads the map.
        expect(table.columnWidths![0], isA<pw.IntrinsicColumnWidth>());
        expect(table.columnWidths![1], isA<pw.FlexColumnWidth>());
      },
    );

    test('emphasizeLastColumn: false leaves every cell at normal weight', () {
      final rows = (PdfDataTable(
                ui: uiFor(rtl: true),
                columns: const [PdfColumnSpec('Item'), PdfColumnSpec('Amount')],
                rows: const [
                  ['Widget', '300.00'],
                ],
                emphasizeLastColumn: false,
              ).build()
              as pw.Table)
          .children[1]
          .children
          .map(cellSpan);

      expect(
        rows.every((span) => span.style?.fontWeight != pw.FontWeight.bold),
        isTrue,
      );
    });
  });
}
