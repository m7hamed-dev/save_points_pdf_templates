import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:save_points_pdf_templates/save_points_pdf_templates.dart';

import 'pdf_test_fixtures.dart';

/// A PDF file always starts with the `%PDF-` magic bytes.
void expectValidPdf(Uint8List bytes) {
  expect(bytes.length, greaterThan(1000), reason: 'document looks empty');
  expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SaleInvoiceTemplate', () {
    test('renders a valid PDF in English', () async {
      final bytes = await PdfGenerator.generate(
        template: SaleInvoiceTemplate(
          data: saleInvoice(),
          pdfConfig: testConfig(),
          qrCode: 'https://example.com/inv/42',
        ),
      );
      expectValidPdf(bytes);
    });

    test('renders a valid PDF in Arabic / RTL', () async {
      final bytes = await PdfGenerator.generate(
        template: SaleInvoiceTemplate(
          data: saleInvoice(),
          pdfConfig: testConfig(locale: 'ar'),
        ),
      );
      expectValidPdf(bytes);
    });

    test('renders a partially paid invoice', () async {
      final bytes = await PdfGenerator.generate(
        template: SaleInvoiceTemplate(
          data: saleInvoice(total: 30000, paid: 10000),
          pdfConfig: testConfig(),
        ),
      );
      expectValidPdf(bytes);
    });

    test('paginates a long document instead of overflowing', () async {
      final many = List.generate(
        120,
        (i) => PdfInvoiceItemModel(title: 'Item $i', qty: i + 1, price: 99.5),
      );
      final bytes = await PdfGenerator.generate(
        template: SaleInvoiceTemplate(
          data: PdfSaleInvoiceModel(
            id: 'INV-LONG',
            date: DateTime(2026, 9, 14),
            customer: customer,
            items: many,
          ),
          pdfConfig: testConfig(),
        ),
      );
      expectValidPdf(bytes);
    });

    test('renders with no items at all', () async {
      final bytes = await PdfGenerator.generate(
        template: SaleInvoiceTemplate(
          data: PdfSaleInvoiceModel(
            id: 'INV-EMPTY',
            date: DateTime(2026, 9, 14),
            items: const [],
          ),
          pdfConfig: testConfig(),
        ),
      );
      expectValidPdf(bytes);
    });
  });

  test('ExpensesInvoiceTemplate renders', () async {
    final bytes = await PdfGenerator.generate(
      template: ExpensesInvoiceTemplate(
        data: PdfExpensesInvoiceModel(
          id: 'EXP-2026-0007',
          date: DateTime(2026, 9, 14),
          customer: customer,
          items: items,
          category: 'Equipment',
          paymentMethod: 'Cash',
        ),
        pdfConfig: testConfig(),
      ),
    );
    expectValidPdf(bytes);
  });

  test('InvoiceTemplate renders from the minimal model', () async {
    final bytes = await PdfGenerator.generate(
      template: InvoiceTemplate(
        data: PdfInvoiceModel(
          invoiceNo: 'INV-001',
          customerName: 'Mohamed',
          date: DateTime(2026, 9, 14),
          items: items,
        ),
        pdfConfig: testConfig(),
      ),
    );
    expectValidPdf(bytes);
  });

  group('ReceiptVoucherTemplate', () {
    test('renders with a null-safe date', () async {
      final bytes = await PdfGenerator.generate(
        template: ReceiptVoucherTemplate(
          data: const ReceiptVoucherModel(
            id: 'RV-001',
            date: null,
            payerName: 'Acme Trading Co.',
            amount: 12500,
            paymentMethod: 'Cash',
            statement: 'Settlement of invoice INV-2026-0042',
            receiverName: 'Mohamed',
          ),
          pdfConfig: testConfig(),
        ),
      );
      expectValidPdf(bytes);
    });

    test('renders in Arabic with an amount in words', () async {
      final bytes = await PdfGenerator.generate(
        template: ReceiptVoucherTemplate(
          data: ReceiptVoucherModel(
            id: 'RV-002',
            date: DateTime(2026, 9, 14),
            payerName: 'شركة أكمي',
            amount: 12500,
            amountInWords: 'اثنا عشر ألفاً وخمسمائة ريال',
            paymentMethod: 'تحويل بنكي',
            statement: 'سداد فاتورة رقم INV-2026-0042',
            receiverName: 'محمد',
          ),
          pdfConfig: testConfig(locale: 'ar'),
          qrCode: 'RV-002',
        ),
      );
      expectValidPdf(bytes);
    });
  });

  test('ListStringsTemplate renders a report table', () async {
    final bytes = await PdfGenerator.generate(
      template: ListStringsTemplate(
        data: const PdfListStringsModel(
          id: 'RPT-01',
          title: 'Stock Count',
          headers: ['SKU', 'Item', 'Counted'],
          items: [
            ['HP-450', 'HP ProBook', '12'],
            ['MBP-14', 'MacBook Pro', '4'],
          ],
          summary: {'Lines': '2', 'Total units': '16'},
        ),
        pdfConfig: testConfig(),
      ),
    );
    expectValidPdf(bytes);
  });

  // `title` is an optional override for the printed heading and is empty on
  // almost every document, so reading it as the document's name left the PDF
  // metadata blank, the preview app bar blank, and every shared file called
  // `document.pdf`.
  group('document name', () {
    test('falls back to the model label and number', () {
      final template = SaleInvoiceTemplate(
        data: saleInvoice(),
        pdfConfig: testConfig(),
      );
      expect(template.documentName, 'Sales Invoice INV-2026-0042');
    });

    test('an explicit title wins', () {
      final template = SaleInvoiceTemplate(
        data: saleInvoice(),
        pdfConfig: testConfig(),
        title: 'Tax Invoice',
      );
      expect(template.documentName, 'Tax Invoice');
    });

    test('a model with no number is named by its label alone', () {
      final template = ListStringsTemplate(
        data: const PdfListStringsModel(items: [], title: 'Stock Count'),
        pdfConfig: testConfig(),
      );
      expect(template.documentName, 'Stock Count');
    });

    test('reaches the PDF metadata', () async {
      final bytes = await PdfGenerator.generate(
        template: SaleInvoiceTemplate(
          data: saleInvoice(),
          pdfConfig: testConfig(),
        ),
      );
      final title = RegExp(
        r'/Title\s*\(([^)]*)\)',
      ).firstMatch(String.fromCharCodes(bytes))?.group(1);
      expect(title, 'Sales Invoice INV-2026-0042');
    });
  });

  group('PdfTheme', () {
    test('presets differ from the default', () {
      expect(const PdfTheme.classic().accent, isNot(const PdfTheme().accent));
      expect(const PdfTheme.minimal().showZebraStripes, isFalse);
    });

    test('copyWith preserves untouched tokens', () {
      const base = PdfTheme();
      final themed = base.copyWith(accent: PdfColors.teal);
      expect(themed.accent, PdfColors.teal);
      expect(themed.bodySize, base.bodySize);
    });

    test('a custom theme reaches the rendered document', () async {
      final bytes = await PdfGenerator.generate(
        template: SaleInvoiceTemplate(
          data: saleInvoice(),
          pdfConfig: testConfig(),
          theme: const PdfTheme.minimal(),
          pageFormat: PdfPageFormat.a5,
        ),
      );
      expectValidPdf(bytes);
    });
  });

  // The design pass traded rules for whitespace, and whitespace is what
  // pushes a signature block onto a second page. A short invoice that spills
  // just to carry its signatures looks like a mistake, so the vertical rhythm
  // is held to this.
  test('an ordinary invoice fits on one page in every preset', () async {
    for (final preset
        in {
          'modern': const PdfTheme.modern(),
          'classic': const PdfTheme.classic(),
          'minimal': const PdfTheme.minimal(),
        }.entries) {
      final bytes = await PdfGenerator.generate(
        template: SaleInvoiceTemplate(
          data: saleInvoice(total: 30000, paid: 12000),
          pdfConfig: testConfig(),
          theme: preset.value,
          qrCode: 'https://example.com/inv/42',
        ),
      );
      final pages =
          RegExp(
            r'/Type\s*/Page[^s]',
          ).allMatches(String.fromCharCodes(bytes)).length;
      expect(pages, 1, reason: preset.key);
    }
  });

  test('PdfDocuments.bytes renders the same document', () async {
    final bytes = await PdfDocuments.bytes(
      template: SaleInvoiceTemplate(
        data: saleInvoice(),
        pdfConfig: testConfig(),
      ),
    );
    expectValidPdf(bytes);
  });
}
