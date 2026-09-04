import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:save_points_pdf_templates/save_points_pdf_templates.dart';

import 'pdf_test_fixtures.dart';

/// A third language, which the package could not express at all while its
/// labels were pairs of strings written inline.
class FrenchLabels extends PdfLabels {
  const FrenchLabels();

  @override
  String get billTo => 'FACTURER À';
  @override
  String get subtotal => 'Sous-total';
  @override
  String get total => 'TOTAL';
  @override
  String get statusPaid => 'PAYÉE';

  // Without this a French invoice is still headed `Sales Invoice`: the
  // document's own name comes from the type, not from a template.
  @override
  String documentType(PdfInvoiceType type) =>
      type == PdfInvoiceType.salesInvoice ? 'Facture de vente' : type.english;

  @override
  String documentSubtitle(PdfInvoiceType type) => '';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('labels', () {
    test('English by default', () {
      final template = SaleInvoiceTemplate(
        data: saleInvoice(),
        pdfConfig: testConfig(),
      );
      expect(template.labels, isA<PdfLabels>());
      expect(template.labels.billTo, 'BILL TO');
      expect(template.partyLabel, 'BILL TO');
    });

    test('Arabic for a right-to-left document that can draw it', () {
      final config = PdfConfig(locale: 'ar');
      // No Arabic-capable font here, so the guard keeps the labels English.
      expect(config.effectiveLabels.billTo, 'BILL TO');
    });

    // The whole point of naming the labels: a third language is a subclass,
    // not a fork of every template.
    test('a custom set reaches the templates', () {
      final template = SaleInvoiceTemplate(
        data: saleInvoice(),
        pdfConfig: PdfConfig(locale: 'fr', labels: const FrenchLabels()),
      );
      expect(template.partyLabel, 'FACTURER À');
      expect(template.labels.subtotal, 'Sous-total');
      expect(template.totalLines.keys.first, 'Sous-total');
      expect(template.statusLabel, 'PAYÉE');
    });

    test('what a custom set leaves alone stays English', () {
      const labels = FrenchLabels();
      expect(labels.billTo, 'FACTURER À');
      expect(labels.reference, 'Reference');
      expect(labels.quantity, 'Qty');
    });

    test('a custom set survives into the rendered document', () async {
      // Uncompressed so the words are readable in the bytes: this is the only
      // assertion here that looks at what was actually drawn.
      final bytes = await PdfGenerator.generate(
        compress: false,
        template: SaleInvoiceTemplate(
          data: saleInvoice(),
          pdfConfig: PdfConfig(labels: const FrenchLabels(), company: company),
        ),
      );
      expect(String.fromCharCodes(bytes), contains('FACTURER'));
      expect(String.fromCharCodes(bytes), contains('Sous-total'));
      expect(String.fromCharCodes(bytes), isNot(contains('BILL TO')));
    });

    test('the document names itself in the same language', () async {
      final bytes = await PdfGenerator.generate(
        compress: false,
        template: SaleInvoiceTemplate(
          data: saleInvoice(),
          pdfConfig: PdfConfig(labels: const FrenchLabels(), company: company),
        ),
      );
      final text = String.fromCharCodes(bytes);
      expect(text, contains('Facture'));
      expect(text, isNot(contains('Sales Invoice')));
    });

    test('the shared blocks use them too', () {
      const ui = PdfUi(
        theme: PdfTheme(),
        formatters: PdfFormatters(),
        labels: FrenchLabels(),
      );
      expect(ui.labels.total, 'TOTAL');
    });
  });

  // `appendix` and a background hook existed with nothing using them; a
  // printout has no metadata to say it is a copy.
  group('watermark', () {
    test('there is none unless the template asks for one', () {
      final plain = SaleInvoiceTemplate(
        data: saleInvoice(),
        pdfConfig: testConfig(),
      );
      expect(plain.watermark, isEmpty);
      expect(plain.background(_context), isNull);
    });

    test('a marked document paints one behind the page', () async {
      final marked = _MarkedInvoice(
        data: saleInvoice(),
        pdfConfig: testConfig(),
      );
      expect(marked.background(_context), isNotNull);

      final bytes = await PdfGenerator.generate(template: marked);
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
      // Drawn with transparency, which a plain document never sets up.
      expect(String.fromCharCodes(bytes), contains('/ExtGState'));
    });

    test('the label set names the usual marks', () {
      const labels = PdfLabels();
      expect(
        [labels.copy, labels.draft, labels.original, labels.duplicate],
        ['COPY', 'DRAFT', 'ORIGINAL', 'DUPLICATE'],
      );
    });
  });

  // A reader who turns the page cannot tell what the lines above added up to.
  group('carried forward', () {
    const ui = PdfUi(theme: PdfTheme(), formatters: PdfFormatters());

    List<List<String>> rowsOf(int count) => [
      for (var i = 0; i < count; i++) ['Item $i', '${(i + 1) * 100}.00'],
    ];

    PdfDataTable tableOf(int count) => PdfDataTable(
      ui: ui,
      columns: const [
        PdfColumnSpec('Item', flex: 3),
        PdfColumnSpec('Amount', align: PdfCellAlign.end),
      ],
      rows: rowsOf(count),
      carryForward: PdfCarryForward(
        column: 1,
        values: [for (var i = 0; i < count; i++) (i + 1) * 100.0],
        format: ui.formatters.number,
      ),
    );

    test('the running total is the sum of the rows above', () {
      final carry = PdfCarryForward(
        column: 1,
        values: const [100, 200, 300],
        format: ui.formatters.number,
      );
      expect(carry.totalAfter(0), 0);
      expect(carry.totalAfter(2), 300);
      expect(carry.totalAfter(3), 600);
    });

    test('a table that fits stays one block', () {
      expect(tableOf(5).buildPaginated(rowsPerPage: 10), hasLength(1));
    });

    test('a long table becomes one block per page', () {
      expect(tableOf(25).buildPaginated(rowsPerPage: 10), hasLength(3));
    });

    test('a table with no carry set is never split', () {
      final plain = PdfDataTable(
        ui: ui,
        columns: const [PdfColumnSpec('Item')],
        rows: rowsOf(50),
      );
      expect(plain.buildPaginated(rowsPerPage: 10), hasLength(1));
    });

    test('each chunk closes and opens with the same figure', () {
      final chunks = tableOf(20).buildPaginated(rowsPerPage: 10);
      final first = chunks.first as pw.Table;
      final second = chunks[1] as pw.Table;

      String cell(pw.Table table, int row, int column) =>
          (((table.children[row].children[column] as pw.Container).child!
                          as pw.RichText)
                      .text
                  as pw.TextSpan)
              .text!;

      // Header, ten rows, then the carried line.
      expect(first.children, hasLength(12));
      expect(cell(first, 11, 0), 'Carried forward');
      // Header, the brought line, then ten more rows.
      expect(cell(second, 1, 0), 'Brought forward');
      expect(cell(second, 1, 1), cell(first, 11, 1));
      expect(cell(first, 11, 1), '5,500.00');
    });

    test('the chunks render as a document', () async {
      final bytes =
          await _PaginatedTable(
            data: saleInvoice(),
            pdfConfig: testConfig(),
          ).render();
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    });
  });
}

final _context = _FakeContext();

class _FakeContext implements pw.Context {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _MarkedInvoice extends SaleInvoiceTemplate {
  _MarkedInvoice({required super.data, required super.pdfConfig});

  @override
  String get watermark => labels.copy;
}

/// Exercises a paginated table end to end through the generator.
class _PaginatedTable extends SaleInvoiceTemplate {
  _PaginatedTable({required super.data, required super.pdfConfig});

  @override
  List<pw.Widget> body(pw.Context context) => [
    ...PdfDataTable(
      ui: ui,
      columns: const [
        PdfColumnSpec('Item', flex: 3),
        PdfColumnSpec('Amount', align: PdfCellAlign.end),
      ],
      rows: [
        for (var i = 0; i < 40; i++) ['Item $i', '${(i + 1) * 100}.00'],
      ],
      carryForward: PdfCarryForward(
        column: 1,
        values: [for (var i = 0; i < 40; i++) (i + 1) * 100.0],
        format: format.number,
      ),
    ).buildPaginated(rowsPerPage: 15),
  ];

  Future<Uint8List> render() => PdfGenerator.generate(template: this);
}
