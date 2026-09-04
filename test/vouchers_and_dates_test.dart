import 'package:flutter_test/flutter_test.dart';
import 'package:save_points_pdf_templates/save_points_pdf_templates.dart';

import 'pdf_test_fixtures.dart';

ReceiptVoucherModel receipt() => ReceiptVoucherModel(
  id: 'RV-2026-0031',
  date: DateTime(2026, 9, 14),
  payerName: 'Acme Trading Co.',
  amount: 12500,
  paymentMethod: 'Bank transfer',
  statement: 'Part settlement of INV-2026-0042',
  receiverName: 'Mohamed',
  amountInWords: 'Twelve thousand five hundred',
);

PaymentVoucherModel payment() => PaymentVoucherModel(
  id: 'PV-2026-0014',
  date: DateTime(2026, 9, 14),
  payeeName: 'Gulf Office Supplies',
  amount: 3200,
  paymentMethod: 'Cheque #4471',
  statement: 'Office furniture',
  disburserName: 'Mohamed',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // The type enum has offered `paymentVoucher` since the first release while
  // only the receipt side had a template.
  group('vouchers come as a matched pair', () {
    test('both models share the voucher contract', () {
      expect(receipt(), isA<PdfVoucherModel>());
      expect(payment(), isA<PdfVoucherModel>());
    });

    test('each names its two parties in its own terms', () {
      expect(receipt().payerName, 'Acme Trading Co.');
      expect(receipt().receiverName, 'Mohamed');
      expect(payment().payeeName, 'Gulf Office Supplies');
      expect(payment().disburserName, 'Mohamed');

      // Both map onto the same two roles underneath.
      expect(receipt().counterparty, receipt().payerName);
      expect(payment().counterparty, payment().payeeName);
      expect(receipt().officer, receipt().receiverName);
      expect(payment().officer, payment().disburserName);
    });

    test('each carries its own type', () {
      expect(receipt().type, PdfInvoiceType.receiptVoucher);
      expect(payment().type, PdfInvoiceType.paymentVoucher);
    });

    test('both render', () async {
      for (final template in <BaseTemplate<PdfVoucherModel>>[
        ReceiptVoucherTemplate(data: receipt(), pdfConfig: testConfig()),
        PaymentVoucherTemplate(data: payment(), pdfConfig: testConfig()),
      ]) {
        final bytes = await PdfGenerator.generate(template: template);
        expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
        expect(bytes.length, greaterThan(1000));
      }
    });

    test('the labels differ by direction of the money', () {
      final incoming = ReceiptVoucherTemplate(
        data: receipt(),
        pdfConfig: testConfig(),
      );
      final outgoing = PaymentVoucherTemplate(
        data: payment(),
        pdfConfig: testConfig(),
      );
      expect(incoming.amountLabel, isNot(outgoing.amountLabel));
      expect(incoming.counterpartyLabel, isNot(outgoing.counterpartyLabel));
      expect(
        incoming.defaultSignatureLabels,
        isNot(outgoing.defaultSignatureLabels),
      );
    });
  });

  group('due dates', () {
    PdfSaleInvoiceModel invoice({DateTime? due, double? paid}) =>
        PdfSaleInvoiceModel(
          id: 'INV-1',
          date: DateTime(2026, 9, 14),
          dueDate: due,
          items: const [PdfInvoiceItemModel(title: 'A', qty: 1, price: 1000)],
          paidAmount: paid,
        );

    test('a document with no due date is never overdue', () {
      expect(invoice(paid: 0).isOverdueOn(DateTime(2030)), isFalse);
    });

    test('a settled document is never overdue', () {
      // paidAmount defaults to the total, so this one is fully paid.
      expect(
        invoice(due: DateTime(2026, 10, 14)).isOverdueOn(DateTime(2030)),
        isFalse,
      );
    });

    test('an unpaid document is overdue only after the date', () {
      final unpaid = invoice(due: DateTime(2026, 10, 14), paid: 0);
      expect(unpaid.isOverdueOn(DateTime(2026, 10, 13)), isFalse);
      expect(unpaid.isOverdueOn(DateTime(2026, 10, 14)), isFalse);
      expect(unpaid.isOverdueOn(DateTime(2026, 10, 15)), isTrue);
    });

    test('the status pill says which of the three states it is in', () {
      String? statusOf(PdfSaleInvoiceModel data, DateTime asOf) =>
          _FixedDateInvoice(
            data: data,
            pdfConfig: testConfig(),
            asOfDate: asOf,
          ).statusLabel;

      expect(
        statusOf(invoice(due: DateTime(2026, 10, 14)), DateTime(2030)),
        'PAID',
      );
      expect(
        statusOf(
          invoice(due: DateTime(2026, 10, 14), paid: 0),
          DateTime(2026, 10, 2),
        ),
        'UNPAID',
      );
      expect(
        statusOf(
          invoice(due: DateTime(2026, 10, 14), paid: 0),
          DateTime(2026, 11, 2),
        ),
        'OVERDUE',
      );
    });

    test('the due date reaches the meta block', () {
      final template = _FixedDateInvoice(
        data: invoice(due: DateTime(2026, 10, 14), paid: 0),
        pdfConfig: testConfig(),
        asOfDate: DateTime(2026, 9, 20),
      );
      expect(template.metaFields.keys, contains('Due'));
      expect(template.metaFields['Due'], contains('2026'));
    });
  });

  group('the page footer follows the document language', () {
    Future<String> footerOf(String locale) async {
      final bytes = await PdfGenerator.generate(
        template: SaleInvoiceTemplate(
          data: saleInvoice(),
          pdfConfig: testConfig(locale: locale),
        ),
      );
      return String.fromCharCodes(bytes);
    }

    test('an English document says Page', () async {
      expect(await footerOf('en'), contains('Page'));
    });

    test('an Arabic document does not fall back to English', () async {
      // The label was hard-coded, so `Page 1 / 1` sat under every Arabic
      // invoice. With no Arabic-capable font the whole document is English,
      // so this asserts on the one case that can be told apart: the label is
      // built from the direction, not pinned to one language.
      const ui = PdfUi(
        theme: PdfTheme(),
        formatters: PdfFormatters(locale: 'ar'),
        isRtl: true,
        canRenderArabic: true,
      );
      expect(ui.bilingual('Page', 'صفحة'), 'صفحة');
    });
  });
}

/// A sale invoice judged against a fixed day, so the tests do not depend on
/// when they run.
class _FixedDateInvoice extends SaleInvoiceTemplate {
  _FixedDateInvoice({
    required super.data,
    required super.pdfConfig,
    required this.asOfDate,
  });

  final DateTime asOfDate;

  @override
  DateTime get asOf => asOfDate;
}
