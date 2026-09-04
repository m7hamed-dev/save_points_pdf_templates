import 'package:flutter_test/flutter_test.dart';
import 'package:save_points_pdf_templates/save_points_pdf_templates.dart';

import 'pdf_test_fixtures.dart';

const lines = [
  PdfInvoiceItemModel(
    title: 'HP ProBook 450',
    qty: 3,
    price: 3200,
    unit: 'pcs',
  ),
  PdfInvoiceItemModel(title: 'MacBook Pro 14"', qty: 2, price: 8900),
];

PdfDeliveryNoteModel deliveryNote() => PdfDeliveryNoteModel(
  id: 'DN-2026-0088',
  date: DateTime(2026, 9, 14),
  customer: customer,
  deliveryAddress: 'Warehouse 4, Industrial City, Jeddah',
  carrier: 'Naqel — plate 4471 ABC',
  items: lines,
);

PdfQuotationModel quotation({DateTime? validUntil}) => PdfQuotationModel(
  id: 'QT-2026-0007',
  date: DateTime(2026, 9, 14),
  validUntil: validUntil,
  customer: customer,
  items: lines,
  taxRate: 15,
  terms: 'Delivery within 10 working days of a signed acceptance.',
);

PdfStatementModel statement() => PdfStatementModel(
  id: 'SOA-2026-09',
  customer: customer,
  periodStart: DateTime(2026, 9),
  periodEnd: DateTime(2026, 9, 30),
  openingBalance: 4200,
  entries: [
    PdfStatementEntry(
      date: DateTime(2026, 9, 3),
      description: 'Invoice',
      reference: 'INV-2026-0042',
      debit: 29240,
    ),
    PdfStatementEntry(
      date: DateTime(2026, 9, 20),
      description: 'Payment received',
      credit: 12000,
    ),
  ],
);

Future<String> renderText(BaseTemplate<Object?> template) async {
  final bytes = await PdfGenerator.generate(template: template);
  expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
  return String.fromCharCodes(bytes);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // A price column on the page a storekeeper signs is a leak, not a service.
  group('DeliveryNoteTemplate', () {
    final template = DeliveryNoteTemplate(
      data: deliveryNote(),
      pdfConfig: testConfig(),
    );

    test('carries no money at all', () {
      expect(template.showPricing, isFalse);
      expect(template.showSettlement, isFalse);

      final headers = template.columns.map((c) => c.label).join(' ');
      expect(headers, contains('Description'));
      expect(headers, contains('Qty'));
      expect(headers, isNot(contains('Price')));
      expect(headers, isNot(contains('Amount')));

      for (final row in template.rows) {
        expect(row, hasLength(template.columns.length));
      }
    });

    test('has no paid or unpaid stamp — it is not a debt', () {
      expect(template.statusLabel, isNull);
    });

    test('says where the goods went and who took them', () {
      expect(template.metaFields.keys, containsAll(['Address', 'Carrier']));
      expect(template.signatureLabels, ['Delivered by', 'Received by']);
    });

    test('renders', () async {
      await renderText(template);
    });
  });

  group('QuotationTemplate', () {
    test('shows prices but owes nothing', () {
      final template = QuotationTemplate(
        data: quotation(),
        pdfConfig: testConfig(),
      );
      expect(template.showPricing, isTrue);
      expect(template.showSettlement, isFalse);
      expect(
        template.columns.map((c) => c.label).join(' '),
        contains('Amount'),
      );
      expect(template.settlementLines.containsKey('Status'), isFalse);
    });

    test('says whether it is still valid, not whether it is paid', () {
      final live = _FixedDayQuotation(
        data: quotation(validUntil: DateTime(2026, 10, 14)),
        pdfConfig: testConfig(),
        today: DateTime(2026, 9, 20),
      );
      final dead = _FixedDayQuotation(
        data: quotation(validUntil: DateTime(2026, 10, 14)),
        pdfConfig: testConfig(),
        today: DateTime(2026, 11, 2),
      );
      expect(live.statusLabel, 'VALID');
      expect(dead.statusLabel, 'EXPIRED');
    });

    test('an open-ended quotation claims no status', () {
      final template = QuotationTemplate(
        data: quotation(),
        pdfConfig: testConfig(),
      );
      expect(template.statusLabel, isNull);
    });

    test('is signed to accept it, not to acknowledge receipt', () {
      final template = QuotationTemplate(
        data: quotation(),
        pdfConfig: testConfig(),
      );
      expect(template.signatureLabels, ['Quoted by', 'Accepted by']);
    });

    test('renders', () async {
      await renderText(
        QuotationTemplate(
          data: quotation(validUntil: DateTime(2026, 10, 14)),
          pdfConfig: testConfig(),
        ),
      );
    });
  });

  // Working the balance out per row is the whole reason this document is
  // tedious by hand, so the model does it and the two cannot disagree.
  group('StatementOfAccountTemplate', () {
    test('the running balance follows the movements', () {
      final data = statement();
      expect(data.runningBalances, [33440, 21440]);
      expect(data.closingBalance, 21440);
      expect(data.totalDebit, 29240);
      expect(data.totalCredit, 12000);
    });

    test('the closing balance is the last running balance', () {
      final data = statement();
      expect(data.closingBalance, data.runningBalances.last);
    });

    test('a customer who has overpaid is in credit', () {
      const data = PdfStatementModel(
        id: 'SOA-1',
        openingBalance: 100,
        entries: [PdfStatementEntry(description: 'Payment', credit: 500)],
      );
      expect(data.closingBalance, -400);
      expect(data.isInCredit, isTrue);

      final template = StatementOfAccountTemplate(
        data: data,
        pdfConfig: testConfig(),
      );
      // The panel states the sign in words rather than printing a minus.
      expect(template.buildSummary, isNotNull);
    });

    test('a statement with no movements still states both balances', () {
      const data = PdfStatementModel(
        id: 'SOA-2',
        openingBalance: 4200,
        entries: [],
      );
      expect(data.runningBalances, isEmpty);
      expect(data.closingBalance, 4200);
    });

    test('the opening balance leads the table', () {
      final template = StatementOfAccountTemplate(
        data: statement(),
        pdfConfig: testConfig(),
      );
      expect(template.rows.first[1], 'Opening balance');
      expect(template.rows.first.last, '4,200.00');
      // One row per entry, plus the opening line.
      expect(template.rows, hasLength(statement().entries.length + 1));
    });

    test('an empty debit or credit cell is left blank, not zeroed', () {
      final template = StatementOfAccountTemplate(
        data: statement(),
        pdfConfig: testConfig(),
      );
      final invoiceRow = template.rows[1];
      expect(invoiceRow[2], '29,240.00');
      expect(invoiceRow[3], isEmpty);
    });

    test('renders', () async {
      await renderText(
        StatementOfAccountTemplate(data: statement(), pdfConfig: testConfig()),
      );
    });
  });
}

class _FixedDayQuotation extends QuotationTemplate {
  _FixedDayQuotation({
    required super.data,
    required super.pdfConfig,
    required this.today,
  });

  final DateTime today;

  @override
  DateTime get asOf => today;
}
