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
}
