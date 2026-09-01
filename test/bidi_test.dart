import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:save_points_pdf_templates/save_points_pdf_templates.dart';

void main() {
  group('directionOf', () {
    test('Latin, digits and ids stay left-to-right', () {
      for (final value in ['Sales Invoice', '1,234.50', 'INV-2026-0042']) {
        expect(
          PdfUi.directionOf(value),
          pw.TextDirection.ltr,
          reason: '"$value" must not be laid out right-to-left',
        );
      }
    });

    test('Arabic is right-to-left', () {
      expect(PdfUi.directionOf('فاتورة مبيعات'), pw.TextDirection.rtl);
    });
  });

  group('splitRuns', () {
    List<String> textsOf(String value) =>
        PdfUi.splitRuns(value).map((run) => run.text).toList();

    test('a single-script value is one run', () {
      expect(PdfUi.splitRuns('Sales Invoice').length, 1);
      expect(PdfUi.splitRuns('فاتورة مبيعات').length, 1);
    });

    test('Arabic followed by Latin splits in two', () {
      final runs = PdfUi.splitRuns('حاسب محمول HP ProBook');
      expect(runs.length, 2);
      expect(runs.first.isRtl, isTrue);
      expect(runs.last.isRtl, isFalse);
      expect(runs.last.text, 'HP ProBook');
    });

    test('digits count as left-to-right', () {
      final runs = PdfUi.splitRuns('أمر شراء 8891');
      expect(runs.length, 2);
      expect(runs.last.text.trim(), '8891');
      expect(runs.last.isRtl, isFalse);
    });

    test('punctuation stays with the run it follows', () {
      expect(textsOf('28,000.00 ر.س').first.trim(), '28,000.00');
    });

    test('runs concatenate back to the original value', () {
      const values = [
        'حاسب محمول HP ProBook',
        'MacBook Pro 14 مقاس',
        'أمر شراء 8891',
        'plain latin',
        'عربي فقط',
        '',
      ];
      for (final value in values) {
        expect(PdfUi.splitRuns(value).map((r) => r.text).join(), value);
      }
    });
  });
}
