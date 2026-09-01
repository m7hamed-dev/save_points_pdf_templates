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

  group('PdfConfig', () {
    test('falls back to the built-in font when the asset is missing', () async {
      final config = PdfConfig(fontPath: 'assets/does-not-exist.ttf');
      await config.init();
      expect(config.hasCustomFont, isFalse);
    });

    test('throws with a clear message when strictFonts is on', () async {
      final config = PdfConfig(
        fontPath: 'assets/does-not-exist.ttf',
        strictFonts: true,
      );
      expect(
        config.init,
        throwsA(
          isA<PdfAssetException>().having(
            (e) => e.message,
            'message',
            contains('does-not-exist.ttf'),
          ),
        ),
      );
    });

    test('init is idempotent and invalidate resets it', () async {
      final config = testConfig();
      await config.init();
      await config.init();
      config.invalidate();
      await config.init();
      expect(config.isRtl, isFalse);
    });

    test('the Cairo preset is right-to-left with SAR', () {
      final config = CairoPdfFontConfig();
      expect(config.isRtl, isTrue);
      expect(config.currency, 'SAR');
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
