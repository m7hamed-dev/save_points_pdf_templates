import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:save_points_pdf_templates/save_points_pdf_templates.dart';
import 'package:save_points_pdf_templates_example/main.dart';

void main() {
  testWidgets('every document tile is reachable', (tester) async {
    await tester.pumpWidget(const DemoApp());
    expect(find.text('Sales invoice'), findsOneWidget);
    expect(find.text('Receipt voucher'), findsOneWidget);
    expect(find.byType(SwitchListTile), findsOneWidget);
  });

  testWidgets('the bundled Arabic font renders a document', (tester) async {
    // Proves the asset paths in pubspec.yaml are correct: a wrong path would
    // fall back to the built-in Latin font and hasCustomFont would be false.
    final config = PdfConfig(
      fontPath: 'assets/fonts/IBMPlexSansArabic/IBMPlexSansArabic-Regular.ttf',
      boldFontPath:
          'assets/fonts/IBMPlexSansArabic/IBMPlexSansArabic-SemiBold.ttf',
      locale: 'ar',
      currency: 'ر.س',
      company: demoCompany,
      strictFonts: true,
    );
    await config.init();
    expect(config.hasCustomFont, isTrue);
    // Not merely a custom TTF: the face has to carry Arabic, or every label
    // in this app's Arabic mode collapses back to English.
    expect(config.canRenderArabic, isTrue);

    final bytes = await PdfGenerator.generate(
      template: SaleInvoiceTemplate(
        data: PdfSaleInvoiceModel(
          id: 'INV-1',
          date: DateTime(2026, 9, 1),
          customer: demoCustomer,
          items: demoItems,
        ),
        pdfConfig: config,
      ),
    );
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
  });

  // The tiles build their templates inside callbacks, where no test can reach
  // them — so the documents this app demonstrates are rendered here through
  // the same Arabic config the app uses. A template that throws on the
  // bundled font fails the build rather than the first person to tap it.
  testWidgets('every kind of document this app shows renders', (tester) async {
    final config = PdfConfig(
      fontPath: 'assets/fonts/IBMPlexSansArabic/IBMPlexSansArabic-Regular.ttf',
      boldFontPath:
          'assets/fonts/IBMPlexSansArabic/IBMPlexSansArabic-SemiBold.ttf',
      locale: 'ar',
      currency: 'ر.س',
      company: demoCompany,
      strictFonts: true,
    );
    await config.init();

    final date = DateTime(2026, 9, 14);
    final documents = <String, BaseTemplate<Object?>>{
      'purchase order': PurchaseOrderTemplate(
        pdfConfig: config,
        data: PdfPurchaseOrderModel(
          id: 'PO-1',
          date: date,
          supplier: demoCustomer,
          items: demoItems,
          expectedDate: date,
          deliveryAddress: 'Warehouse 4',
        ),
      ),
      'credit note': CreditNoteTemplate(
        pdfConfig: config,
        data: PdfCreditNoteModel(
          id: 'CN-1',
          date: date,
          customer: demoCustomer,
          items: demoItems,
          againstInvoice: 'INV-1',
          reason: 'Returned.',
        ),
      ),
      'payslip': PayslipTemplate(
        pdfConfig: config,
        data: const PdfPayslipModel(
          id: 'PS-1',
          employee: PdfPartyModel(name: 'Mohamed Syed'),
          earnings: [PdfPayLine(label: 'Basic salary', amount: 12000)],
          deductions: [PdfPayLine(label: 'GOSI', amount: 1350)],
        ),
      ),
      'till receipt': ThermalReceiptTemplate(
        pdfConfig: config,
        qrCode: 'https://example.com/r/1',
        footerNote: 'Thank you',
        data: PdfSaleInvoiceModel(id: 'R-1', date: date, items: demoItems),
      ),
      'delivery note': DeliveryNoteTemplate(
        pdfConfig: config,
        data: PdfDeliveryNoteModel(
          id: 'DN-1',
          date: date,
          customer: demoCustomer,
          items: demoItems,
        ),
      ),
      'quotation': QuotationTemplate(
        pdfConfig: config,
        data: PdfQuotationModel(
          id: 'QT-1',
          date: date,
          validUntil: date,
          customer: demoCustomer,
          items: demoItems,
        ),
      ),
      'statement': StatementOfAccountTemplate(
        pdfConfig: config,
        data: PdfStatementModel(
          id: 'SOA-1',
          customer: demoCustomer,
          openingBalance: 4200,
          entries: [
            PdfStatementEntry(date: date, description: 'Invoice', debit: 500),
          ],
        ),
      ),
      'payment voucher': PaymentVoucherTemplate(
        pdfConfig: config,
        data: PaymentVoucherModel(
          id: 'PV-1',
          date: date,
          payeeName: 'Gulf Office Supplies',
          amount: 3200,
          paymentMethod: 'Cheque',
          statement: 'Furniture',
          disburserName: 'Mohamed',
        ),
      ),
    };

    for (final entry in documents.entries) {
      final bytes = await PdfGenerator.generate(template: entry.value);
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-', reason: entry.key);
      expect(bytes.length, greaterThan(1000), reason: entry.key);
    }
  });
}
