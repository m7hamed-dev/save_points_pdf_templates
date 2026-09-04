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
      // The default header sits on a rule with no fill behind it; `soft` and
      // `filled` stay available for a theme that wants a band.
      expect(const PdfTheme().headerStyle, PdfTableHeaderStyle.underlined);
      expect(const PdfTheme.classic().headerStyle, PdfTableHeaderStyle.filled);
      expect(
        const PdfTheme.minimal().headerStyle,
        PdfTableHeaderStyle.underlined,
      );
    });

    test('the presets are three distinct documents, not three palettes', () {
      const modern = PdfTheme.modern();
      const classic = PdfTheme.classic();
      const minimal = PdfTheme.minimal();

      // Rules: classic draws a full grid, minimal draws none between rows.
      expect(modern.showRowRules, isTrue);
      expect(classic.showRowRules, isTrue);
      expect(minimal.showRowRules, isFalse);

      // Air: minimal has the widest margins, classic the tightest.
      expect(minimal.margin.left, greaterThan(modern.margin.left));
      expect(classic.margin.left, lessThan(modern.margin.left));

      // None of them stripes rows any more.
      for (final theme in [modern, classic, minimal]) {
        expect(theme.showZebraStripes, isFalse);
      }
    });

    test('the type scale has real contrast', () {
      const theme = PdfTheme();
      // A flat scale is what made the old documents read as a form. The
      // amount due sits between a heading and the title.
      expect(theme.titleSize, greaterThan(theme.displaySize));
      expect(theme.displaySize, greaterThan(theme.headingSize));
      expect(theme.headingSize, greaterThan(theme.bodySize));
      expect(theme.bodySize, greaterThan(theme.captionSize));
      expect(theme.titleSize / theme.bodySize, greaterThan(2.4));
    });

    test('display type is tracked tighter than body type', () {
      expect(const PdfTheme().titleTracking, lessThan(0));
      expect(const PdfTheme().labelTracking, greaterThan(0));
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
