import 'package:flutter_test/flutter_test.dart';
import 'package:save_points_pdf_templates/save_points_pdf_templates.dart';

import 'pdf_test_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PdfTheme', () {
    test('derived tints sit between the accent and white', () {
      const theme = PdfTheme();
      // A wash is lighter than the accent but is still not plain white.
      expect(theme.accentSoft.red, greaterThan(theme.accent.red));
      expect(theme.accentSoft.red, lessThan(1.0));
      expect(theme.accentMuted.red, greaterThan(theme.accent.red));
      expect(theme.accentMuted.red, lessThan(theme.accentSoft.red));
    });

    test('mix interpolates end to end', () {
      final start = PdfTheme.mix(PdfColors.black, PdfColors.white, 0);
      final end = PdfTheme.mix(PdfColors.black, PdfColors.white, 1);
      expect(start.red, 0);
      expect(end.red, 1);
    });

    test('presets pick different table header treatments', () {
      expect(const PdfTheme().headerStyle, PdfTableHeaderStyle.soft);
      expect(const PdfTheme.classic().headerStyle, PdfTableHeaderStyle.filled);
      expect(
        const PdfTheme.minimal().headerStyle,
        PdfTableHeaderStyle.underlined,
      );
    });

    test('copyWith carries the new tokens', () {
      final theme = const PdfTheme().copyWith(
        labelTracking: 2,
        headerStyle: PdfTableHeaderStyle.filled,
        margin: const PdfMargin.symmetric(horizontal: 40, vertical: 20),
      );
      expect(theme.labelTracking, 2);
      expect(theme.headerStyle, PdfTableHeaderStyle.filled);
      expect(theme.margin.left, 40);
      expect(theme.margin.top, 20);
    });

    test('every header style renders', () async {
      for (final style in PdfTableHeaderStyle.values) {
        final bytes = await PdfGenerator.generate(
          template: SaleInvoiceTemplate(
            data: saleInvoice(),
            pdfConfig: testConfig(),
            theme: const PdfTheme().copyWith(headerStyle: style),
          ),
        );
        expect(String.fromCharCodes(bytes.take(5)), '%PDF-', reason: '$style');
      }
    });
  });

  group('PdfMargin', () {
    test('all sets every edge', () {
      const margin = PdfMargin.all(12);
      expect(
        [margin.left, margin.top, margin.right, margin.bottom],
        [12, 12, 12, 12],
      );
    });

    test('insets hand the renderer the same values', () {
      const margin = PdfMargin(left: 1, top: 2, right: 3, bottom: 4);
      expect(margin.insets.left, 1);
      expect(margin.insets.bottom, 4);
    });
  });
}
