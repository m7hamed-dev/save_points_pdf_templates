import 'package:flutter_test/flutter_test.dart';
import 'package:save_points_pdf_templates/save_points_pdf_templates.dart';

import 'pdf_test_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('a line can be given a rate instead of an amount', () {
    test('a tax rate is charged on the discounted amount', () {
      const item = PdfInvoiceItemModel(
        title: 'Widget',
        qty: 2,
        price: 1000,
        discountRate: 10,
        taxRate: 15,
      );
      expect(item.subtotal, 2000);
      expect(item.discount, 200);
      expect(item.taxableAmount, 1800);
      expect(item.tax, 270);
      expect(item.total, 2070);
    });

    test('an absolute amount still works', () {
      const item = PdfInvoiceItemModel(
        title: 'Widget',
        qty: 2,
        price: 1000,
        discount: 200,
        tax: 270,
      );
      expect(item.discount, 200);
      expect(item.tax, 270);
      expect(item.total, 2070);
    });

    test('a rate wins over an amount when both are given', () {
      const item = PdfInvoiceItemModel(
        title: 'Widget',
        qty: 1,
        price: 1000,
        tax: 999,
        taxRate: 15,
      );
      expect(item.tax, 150);
    });

    test('the effective rate is read back from an absolute amount', () {
      const rated = PdfInvoiceItemModel(
        title: 'A',
        qty: 1,
        price: 1000,
        taxRate: 15,
      );
      const absolute = PdfInvoiceItemModel(
        title: 'B',
        qty: 1,
        price: 1000,
        tax: 150,
      );
      expect(rated.effectiveTaxRate, 15);
      expect(absolute.effectiveTaxRate, 15);
    });

    test('an untaxed line is zero-rated, not undefined', () {
      const item = PdfInvoiceItemModel(title: 'A', qty: 1, price: 1000);
      expect(item.effectiveTaxRate, 0);
      expect(item.tax, 0);
    });

    test('a free line does not divide by zero', () {
      const item = PdfInvoiceItemModel(title: 'Sample', qty: 1, price: 0);
      expect(item.effectiveTaxRate, 0);
      expect(item.total, 0);
    });
  });

  group('a document rate saves repeating it on every line', () {
    final invoice = PdfSaleInvoiceModel(
      id: 'INV-1',
      date: DateTime(2026, 9, 14),
      taxRate: 15,
      items: const [
        PdfInvoiceItemModel(title: 'A', qty: 1, price: 1000),
        PdfInvoiceItemModel(title: 'B', qty: 1, price: 2000),
      ],
    );

    test('it reaches every line that has none of its own', () {
      expect(invoice.itemsTax, 450);
      expect(invoice.total, 3450);
    });

    test("a line's own rate still wins", () {
      final mixed = PdfSaleInvoiceModel(
        id: 'INV-2',
        date: DateTime(2026, 9, 14),
        taxRate: 15,
        items: const [
          PdfInvoiceItemModel(title: 'Standard', qty: 1, price: 1000),
          PdfInvoiceItemModel(
            title: 'Zero rated',
            qty: 1,
            price: 1000,
            taxRate: 0,
          ),
        ],
      );
      expect(mixed.itemsTax, 150);
    });
  });

  // A tax invoice that mixes rates has to show what was taxed at each; one
  // total headed `Tax` does not satisfy a GCC auditor.
  group('tax breakdown', () {
    final mixed = PdfSaleInvoiceModel(
      id: 'INV-3',
      date: DateTime(2026, 9, 14),
      items: const [
        PdfInvoiceItemModel(
          title: 'Standard',
          qty: 1,
          price: 1000,
          taxRate: 15,
        ),
        PdfInvoiceItemModel(
          title: 'Also standard',
          qty: 2,
          price: 500,
          taxRate: 15,
        ),
        PdfInvoiceItemModel(
          title: 'Zero rated',
          qty: 1,
          price: 800,
          taxRate: 0,
        ),
      ],
    );

    test('groups the lines by the rate charged, lowest first', () {
      final bands = mixed.taxBreakdown;
      expect(bands.map((b) => b.rate), [0, 15]);
      expect(bands.first.taxableAmount, 800);
      expect(bands.first.tax, 0);
      expect(bands.last.taxableAmount, 2000);
      expect(bands.last.tax, 300);
    });

    test('the bands account for every taxable riyal', () {
      final banded = mixed.taxBreakdown.fold(
        0.0,
        (sum, band) => sum + band.taxableAmount,
      );
      expect(banded, mixed.subtotal - mixed.itemsDiscount);
    });

    test('a single-rate document is not mixed', () {
      final single = PdfSaleInvoiceModel(
        id: 'INV-4',
        date: DateTime(2026, 9, 14),
        taxRate: 15,
        items: const [PdfInvoiceItemModel(title: 'A', qty: 1, price: 1000)],
      );
      expect(single.hasMixedTaxRates, isFalse);
      expect(mixed.hasMixedTaxRates, isTrue);
    });

    test('one rate is named on the tax line instead', () {
      final single = SaleInvoiceTemplate(
        pdfConfig: testConfig(),
        data: PdfSaleInvoiceModel(
          id: 'INV-5',
          date: DateTime(2026, 9, 14),
          taxRate: 15,
          items: const [PdfInvoiceItemModel(title: 'A', qty: 1, price: 1000)],
        ),
      );
      expect(single.taxLineLabel, 'Tax (15%)');
      expect(single.showTaxBreakdown, isFalse);

      final several = SaleInvoiceTemplate(pdfConfig: testConfig(), data: mixed);
      expect(several.taxLineLabel, 'Tax');
      expect(several.showTaxBreakdown, isTrue);
    });

    test('the breakdown renders', () async {
      final bytes = await PdfGenerator.generate(
        template: SaleInvoiceTemplate(data: mixed, pdfConfig: testConfig()),
      );
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    });
  });

  group('currencies do not all take two decimals', () {
    test('the default is two', () {
      expect(const PdfFormatters().number(1234.5), '1,234.50');
    });

    test('three for the dinar', () {
      const kwd = PdfFormatters(currency: 'KWD', decimals: 3);
      expect(kwd.money(1234.5), '1,234.500 KWD');
    });

    test('none for the yen', () {
      const jpy = PdfFormatters(currency: 'JPY', decimals: 0);
      expect(jpy.money(1234.5), '1,235 JPY');
    });

    test('the config passes it down', () {
      final config = PdfConfig(currency: 'BHD', currencyDecimals: 3);
      expect(config.formatters.decimals, 3);
      expect(config.formatters.money(10), '10.000 BHD');
    });

    test('quantities are unaffected — they are counts, not money', () {
      const kwd = PdfFormatters(decimals: 3);
      expect(kwd.quantity(3), '3');
      expect(kwd.quantity(1.5), '1.50');
    });
  });
}
