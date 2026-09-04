import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:printing/printing.dart';
import 'package:save_points_pdf_templates/save_points_pdf_templates.dart';

import 'pdf_test_fixtures.dart';

SaleInvoiceTemplate invoiceTemplate({String title = ''}) => SaleInvoiceTemplate(
  data: saleInvoice(),
  pdfConfig: testConfig(),
  title: title,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Every shared file used to be called `document.pdf`, and the logic that
  // decided so was written out twice — once here and once in the preview page.
  group('file naming', () {
    test('falls back to the document name', () {
      expect(invoiceTemplate().fileName(), 'Sales Invoice INV-2026-0042.pdf');
    });

    test('an override wins', () {
      expect(invoiceTemplate().fileName('INV-42'), 'INV-42.pdf');
    });

    test('an extension is not doubled', () {
      expect(invoiceTemplate().fileName('INV-42.pdf'), 'INV-42.pdf');
    });

    test('blank names fall back rather than producing ".pdf"', () {
      expect(invoiceTemplate().fileName('   '), 'document.pdf');
      final unnamed = ListStringsTemplate(
        data: const PdfListStringsModel(items: []),
        pdfConfig: testConfig(),
      );
      expect(unnamed.fileName(), isNot('.pdf'));
      expect(unnamed.fileName(), endsWith('.pdf'));
    });
  });

  // `PdfPreviewPage` had no test at all, and it is the entry point most
  // callers reach for first.
  group('PdfPreviewPage', () {
    Future<void> pump(WidgetTester tester, PdfPreviewPage<Object?> page) async {
      await tester.pumpWidget(MaterialApp(home: page));
      await tester.pump();
    }

    testWidgets('titles itself after the document', (tester) async {
      await pump(tester, PdfPreviewPage(template: invoiceTemplate()));
      expect(find.text('Sales Invoice INV-2026-0042'), findsOneWidget);
    });

    testWidgets('an explicit app bar title wins', (tester) async {
      await pump(
        tester,
        PdfPreviewPage(template: invoiceTemplate(), appBarTitle: 'Preview'),
      );
      expect(find.text('Preview'), findsOneWidget);
    });

    testWidgets('hands the preview a file name and the page format', (
      tester,
    ) async {
      await pump(
        tester,
        PdfPreviewPage(template: invoiceTemplate(), fileName: 'INV-42'),
      );
      final preview = tester.widget<PdfPreview>(find.byType(PdfPreview));
      expect(preview.pdfFileName, 'INV-42.pdf');
      expect(preview.initialPageFormat, invoiceTemplate().pageFormat);
    });

    testWidgets('carries its actions through', (tester) async {
      await pump(
        tester,
        PdfPreviewPage(
          template: invoiceTemplate(),
          actions: const [Icon(Icons.close)],
        ),
      );
      expect(find.byIcon(Icons.close), findsOneWidget);
    });
  });

  group('PdfDocuments', () {
    test('bytes renders the document', () async {
      final bytes = await PdfDocuments.bytes(template: invoiceTemplate());
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    });

    // `share`, `printDocument` and `thumbnail` hand the bytes to the platform,
    // so they cannot run headlessly. What belongs to this package in them is
    // the name, which `fileName` above covers.
  });
}
