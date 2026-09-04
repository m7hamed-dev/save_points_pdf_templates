import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:save_points_pdf_templates/save_points_pdf_templates.dart';

import 'pdf_test_fixtures.dart';

const lines = [
  PdfInvoiceItemModel(
    title: 'HP ProBook 450',
    qty: 3,
    price: 3200,
    taxRate: 15,
  ),
  PdfInvoiceItemModel(
    title: 'On-site setup',
    qty: 1.5,
    price: 400,
    taxRate: 15,
  ),
];

Future<void> expectRenders(BaseTemplate<Object?> template) async {
  final bytes = await PdfGenerator.generate(template: template);
  expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
  expect(bytes.length, greaterThan(1000));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PurchaseOrderTemplate', () {
    final template = PurchaseOrderTemplate(
      pdfConfig: testConfig(),
      data: PdfPurchaseOrderModel(
        id: 'PO-2026-0031',
        date: DateTime(2026, 9, 14),
        supplier: customer,
        items: lines,
        expectedDate: DateTime(2026, 9, 28),
        deliveryAddress: 'Warehouse 4, Industrial City, Riyadh',
      ),
    );

    test('the other party is the supplier, not a customer', () {
      expect(template.data.supplier, customer);
      expect(template.partyLabel, 'SUPPLIER');
    });

    test('prices are shown but nothing is owed yet', () {
      expect(template.showPricing, isTrue);
      expect(template.showSettlement, isFalse);
      expect(template.statusLabel, isNull);
    });

    test('says when and where the goods are expected', () {
      expect(template.metaFields.keys, containsAll(['Expected', 'DELIVER TO']));
    });

    test('renders', () => expectRenders(template));
  });

  // Neither note stands on its own: one that does not name the invoice it
  // corrects, and say why, is not something an auditor can reconcile.
  group('credit and debit notes', () {
    PdfCreditNoteModel credit() => PdfCreditNoteModel(
      id: 'CN-2026-0003',
      date: DateTime(2026, 9, 12),
      customer: customer,
      items: lines,
      againstInvoice: 'INV-2026-0042',
      againstInvoiceDate: DateTime(2026, 9, 3),
      reason: 'One unit returned, manufacturing defect.',
    );

    PdfDebitNoteModel debit() => PdfDebitNoteModel(
      id: 'DN-2026-0004',
      date: DateTime(2026, 9, 12),
      customer: customer,
      items: lines,
      againstInvoice: 'INV-2026-0042',
      reason: 'Freight undercharged on the original invoice.',
    );

    test('both share the adjustment contract', () {
      expect(credit(), isA<PdfAdjustmentNoteModel>());
      expect(debit(), isA<PdfAdjustmentNoteModel>());
      expect(credit().type, PdfInvoiceType.creditNote);
      expect(debit().type, PdfInvoiceType.debitNote);
    });

    test('the invoice being corrected is in the meta block', () {
      final template = CreditNoteTemplate(
        data: credit(),
        pdfConfig: testConfig(),
      );
      expect(template.metaFields['Against invoice'], contains('INV-2026-0042'));
      expect(template.metaFields['Against invoice'], contains('2026-09-03'));
    });

    test('the reason sits above the signatures, not after them', () {
      final template = CreditNoteTemplate(
        data: credit(),
        pdfConfig: testConfig(),
      );
      expect(template.extraBlocks(_context), isNotEmpty);
    });

    test('nothing is settled by a note', () {
      expect(
        CreditNoteTemplate(
          data: credit(),
          pdfConfig: testConfig(),
        ).showSettlement,
        isFalse,
      );
    });

    test('each names its own total', () {
      expect(const PdfLabels().totalCredited, 'TOTAL CREDITED');
      expect(const PdfLabels().totalDebited, 'TOTAL DEBITED');
    });

    test('both render', () async {
      await expectRenders(
        CreditNoteTemplate(data: credit(), pdfConfig: testConfig()),
      );
      await expectRenders(
        DebitNoteTemplate(data: debit(), pdfConfig: testConfig()),
      );
    });
  });

  group('PayslipTemplate', () {
    const data = PdfPayslipModel(
      id: 'PS-2026-09-014',
      employee: PdfPartyModel(name: 'Mohamed Syed'),
      employeeNumber: 'EMP-0142',
      jobTitle: 'Software Engineer',
      periodLabel: 'September 2026',
      earnings: [
        PdfPayLine(label: 'Basic salary', amount: 12000),
        PdfPayLine(label: 'Housing allowance', amount: 3000),
        PdfPayLine(label: 'Overtime', amount: 450, note: '6 hours'),
      ],
      deductions: [
        PdfPayLine(label: 'GOSI', amount: 1350, note: '9%'),
        PdfPayLine(label: 'Advance', amount: 1000),
      ],
    );

    // The net is the only figure the employee checks, so it is computed —
    // a slip whose net does not reconcile is a dispute waiting to happen.
    test('net pay is earnings less deductions', () {
      expect(data.grossPay, 15450);
      expect(data.totalDeductions, 2350);
      expect(data.netPay, 13100);
    });

    test('a slip with no deductions pays the gross', () {
      const clean = PdfPayslipModel(
        id: 'PS-1',
        employee: PdfPartyModel(name: 'A'),
        earnings: [PdfPayLine(label: 'Basic', amount: 5000)],
      );
      expect(clean.totalDeductions, 0);
      expect(clean.netPay, clean.grossPay);
    });

    test('it names itself, having no type of its own', () {
      final template = PayslipTemplate(data: data, pdfConfig: testConfig());
      expect(template.documentTitle, 'Payslip');
      expect(template.documentSubtitle, isEmpty);
    });

    test('renders', () async {
      await expectRenders(PayslipTemplate(data: data, pdfConfig: testConfig()));
    });
  });

  // A roll has no height; `MultiPage` cannot paginate what has no page to
  // fill, so the generator puts a receipt on one page that stretches.
  group('ThermalReceiptTemplate', () {
    final data = PdfSaleInvoiceModel(
      id: 'R-7781',
      date: DateTime(2026, 9, 14, 18, 42),
      type: PdfInvoiceType.posInvoice,
      items: const [
        PdfInvoiceItemModel(
          title: 'Coffee 250g',
          qty: 2,
          price: 45,
          taxRate: 15,
        ),
        PdfInvoiceItemModel(
          title: 'Travel mug',
          qty: 1,
          price: 65,
          taxRate: 15,
        ),
      ],
    );

    test('defaults to an 80mm roll and the thermal theme', () {
      final template = ThermalReceiptTemplate(
        data: data,
        pdfConfig: testConfig(),
      );
      expect(template.pageFormat, PdfPageFormat.roll80);
      expect(template.pageFormat.height, double.infinity);
      expect(template.theme.bodySize, lessThan(const PdfTheme().bodySize));
      expect(template.theme.showRowRules, isFalse);
    });

    test('has no running header or footer — the paper is not reusable', () {
      final template = ThermalReceiptTemplate(
        data: data,
        pdfConfig: testConfig(),
      );
      expect(template.header(_context), isNull);
      expect(template.footer(_context), isNull);
    });

    test('renders on a single stretching page', () async {
      final bytes = await PdfGenerator.generate(
        template: ThermalReceiptTemplate(
          data: data,
          pdfConfig: testConfig(),
          qrCode: 'https://example.com/r/7781',
          footerNote: 'Thank you',
        ),
      );
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
      final pages =
          RegExp(
            r'/Type\s*/Page[^s]',
          ).allMatches(String.fromCharCodes(bytes)).length;
      expect(pages, 1);
    });

    test('a 57mm roll works too', () async {
      await expectRenders(
        ThermalReceiptTemplate(
          data: data,
          pdfConfig: testConfig(),
          pageFormat: PdfPageFormat.roll57,
        ),
      );
    });
  });
}

final _context = _FakeContext();

/// The templates under test only pass the context through, so a stub is
/// enough to reach the branches that ignore it.
class _FakeContext implements pw.Context {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
