import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:save_points_pdf_templates/save_points_pdf_templates.dart';

import 'pdf_test_fixtures.dart';

/// Cairo carries Arabic and Latin; Inter carries Latin only. Both are custom
/// TTFs, which is exactly the distinction this file is about.
const arabicFontPath = 'example/assets/fonts/Cairo/Cairo-Regular.ttf';
const latinFontPath = 'example/assets/fonts/Inter/Inter-Regular.ttf';

pw.Font loadFont(String path) =>
    pw.Font.ttf(File(path).readAsBytesSync().buffer.asByteData());

/// The renderer reports a character it cannot draw through `print`, inside an
/// assert — so it is visible in a test but not in release. Capturing it is the
/// closest a test gets to reading the printed page.
Future<List<String>> missingGlyphWarnings(
  Future<void> Function() render,
) async {
  final warnings = <String>[];
  await runZoned(
    render,
    zoneSpecification: ZoneSpecification(
      print: (self, parent, zone, line) {
        if (line.contains('Unable to find a font to draw')) {
          warnings.add(line);
        }
      },
    ),
  );
  return warnings;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late pw.Font arabicFont;
  late pw.Font latinFont;

  setUpAll(() {
    arabicFont = loadFont(arabicFontPath);
    latinFont = loadFont(latinFontPath);
  });

  group('PdfConfig.canRenderArabic', () {
    Future<PdfConfig> ready(PdfConfig config) async {
      await config.init();
      return config;
    }

    test('is false with no custom font at all', () async {
      final config = await ready(PdfConfig());
      expect(config.canRenderArabic, isFalse);
    });

    test('is true for a font that carries Arabic', () async {
      final config = await ready(PdfConfig(font: arabicFont));
      expect(config.canRenderArabic, isTrue);
    });

    // The check used to be `hasCustomFont`, which a Latin-only TTF satisfies.
    test('is false for a Latin-only font', () async {
      final config = await ready(PdfConfig(font: latinFont));
      expect(config.hasCustomFont, isTrue, reason: 'Inter is a custom font');
      expect(config.canRenderArabic, isFalse);
    });

    test('a fallback that carries Arabic counts', () async {
      final config = await ready(
        PdfConfig(font: latinFont, fontFallbacks: [arabicFont]),
      );
      expect(config.canRenderArabic, isTrue);
    });

    test('survives invalidate', () async {
      final config = await ready(PdfConfig(font: latinFont));
      config.invalidate();
      await config.init();
      expect(config.canRenderArabic, isFalse);
    });
  });

  group(
    'bilingual chrome collapses to English when Arabic cannot be drawn',
    () {
      SaleInvoiceTemplate templateWith(pw.Font font, {String locale = 'en'}) =>
          SaleInvoiceTemplate(
            data: saleInvoice(),
            pdfConfig: PdfConfig(font: font, locale: locale, company: company),
          );

      test('the Arabic sub-title is dropped under a Latin-only font', () async {
        final template = templateWith(latinFont);
        await template.pdfConfig.init();
        expect(template.arabicTitle('فاتورة مبيعات'), isEmpty);
      });

      test('the Arabic sub-title is kept under an Arabic font', () async {
        final template = templateWith(arabicFont);
        await template.pdfConfig.init();
        expect(template.arabicTitle('فاتورة مبيعات'), 'فاتورة مبيعات');
      });

      // `tr` keyed off direction alone, so an Arabic locale with a Latin-only
      // font printed every label as blank boxes rather than falling back.
      test('tr falls back to English when the font has no Arabic', () async {
        final template = templateWith(latinFont, locale: 'ar');
        await template.pdfConfig.init();
        expect(template.isRtl, isTrue, reason: 'the layout still mirrors');
        expect(template.tr('Subtotal', 'الإجمالي الفرعي'), 'Subtotal');
      });

      test('tr uses Arabic when the font can draw it', () async {
        final template = templateWith(arabicFont, locale: 'ar');
        await template.pdfConfig.init();
        expect(template.tr('Subtotal', 'الإجمالي الفرعي'), 'الإجمالي الفرعي');
      });

      test('tr stays English in an English document', () async {
        final template = templateWith(arabicFont);
        await template.pdfConfig.init();
        expect(template.tr('Subtotal', 'الإجمالي الفرعي'), 'Subtotal');
      });
    },
  );

  // Running the example app on macOS printed 24 of these warnings per render
  // in its default English mode, and the page showed a row of blank boxes
  // under the title.
  group('a document never asks for a glyph its font lacks', () {
    Future<List<String>> renderWith(pw.Font font, String locale) =>
        missingGlyphWarnings(() async {
          await PdfGenerator.generate(
            template: SaleInvoiceTemplate(
              data: saleInvoice(),
              pdfConfig: PdfConfig(
                font: font,
                locale: locale,
                company: company,
              ),
            ),
          );
        });

    test('English document, Latin-only font', () async {
      expect(await renderWith(latinFont, 'en'), isEmpty);
    });

    test('Arabic locale, Latin-only font', () async {
      expect(await renderWith(latinFont, 'ar'), isEmpty);
    });

    test('Arabic document, Arabic font', () async {
      expect(await renderWith(arabicFont, 'ar'), isEmpty);
    });
  });
}
