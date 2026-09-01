import 'package:flutter_test/flutter_test.dart';
import 'package:save_points_pdf_templates/save_points_pdf_templates.dart';

import 'pdf_test_fixtures.dart';

void main() {
  group('PdfInvoiceItemModel', () {
    test('subtotal is qty * price, before discount and tax', () {
      const item = PdfInvoiceItemModel(
        title: 'Widget',
        qty: 3,
        price: 100,
        discount: 50,
        tax: 15,
      );
      expect(item.subtotal, 300);
      expect(item.total, 265);
    });

    test('fractional quantities are supported', () {
      const item = PdfInvoiceItemModel(title: 'Hours', qty: 1.5, price: 400);
      expect(item.subtotal, 600);
    });
  });

  group('PdfItemizedInvoiceModel totals', () {
    test('computes totals from items when no explicit total is given', () {
      final invoice = saleInvoice();
      // (3*3200) + (2*8900) + (1.5*400) = 9600 + 17800 + 600
      expect(invoice.subtotal, 28000);
      expect(invoice.itemsDiscount, 500);
      expect(invoice.itemsTax, 1740);
      expect(invoice.total, 28000 - 500 + 1740);
      expect(invoice.hasExplicitTotal, isFalse);
    });

    test('an explicit total wins over the computed one', () {
      final invoice = saleInvoice(total: 30000);
      expect(invoice.total, 30000);
      expect(invoice.hasExplicitTotal, isTrue);
    });

    test('document-level discount and tax stack on the line-level ones', () {
      final invoice = PdfSaleInvoiceModel(
        id: 'INV-1',
        date: DateTime(2026),
        items: const [PdfInvoiceItemModel(title: 'A', qty: 1, price: 1000)],
        discount: 100,
        tax: 150,
      );
      expect(invoice.totalDiscount, 100);
      expect(invoice.totalTax, 150);
      expect(invoice.total, 1050);
    });

    test('defaults to fully paid, and reports the balance otherwise', () {
      expect(saleInvoice().isFullyPaid, isTrue);
      expect(saleInvoice().due, 0);

      final partial = saleInvoice(total: 1000, paid: 400);
      expect(partial.due, 600);
      expect(partial.isFullyPaid, isFalse);
    });

    test('an empty document totals zero instead of throwing', () {
      final empty = PdfSaleInvoiceModel(
        id: 'INV-0',
        date: DateTime(2026),
        items: const [],
      );
      expect(empty.subtotal, 0);
      expect(empty.total, 0);
    });
  });

  group('PdfInvoiceModel', () {
    test('maps invoiceNo and customerName onto the base model', () {
      final invoice = PdfInvoiceModel(
        invoiceNo: 'INV-7',
        customerName: 'Sara',
        date: DateTime(2026, 3, 4),
        items: const [PdfInvoiceItemModel(title: 'X', qty: 2, price: 50)],
      );
      expect(invoice.id, 'INV-7');
      expect(invoice.invoiceNo, 'INV-7');
      expect(invoice.customer.name, 'Sara');
      expect(invoice.customerName, 'Sara');
      expect(invoice.total, 100);
    });
  });

  group('PdfPartyModel', () {
    test('empty is empty, a named party is not', () {
      expect(PdfPartyModel.empty.isEmpty, isTrue);
      expect(customer.isNotEmpty, isTrue);
    });

    test('copyWith replaces only what it is given', () {
      final updated = customer.copyWith(name: 'New Co.');
      expect(updated.name, 'New Co.');
      expect(updated.taxNumber, customer.taxNumber);
    });
  });

  group('PdfInvoiceType', () {
    test('every type carries a distinct Arabic label', () {
      final arabic = PdfInvoiceType.values.map((e) => e.arabic).toList();
      expect(arabic.toSet().length, arabic.length);
    });

    test('label follows the document direction', () {
      expect(PdfInvoiceType.salesInvoice.label(), 'Sales Invoice');
      expect(PdfInvoiceType.salesInvoice.label(isRtl: true), 'فاتورة مبيعات');
    });
  });
}
