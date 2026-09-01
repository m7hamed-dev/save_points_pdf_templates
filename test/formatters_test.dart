import 'package:flutter_test/flutter_test.dart';
import 'package:save_points_pdf_templates/save_points_pdf_templates.dart';

void main() {
  const en = PdfFormatters();
  const ar = PdfFormatters(locale: 'ar', currency: 'ر.س');

  group('numbers', () {
    test('money groups thousands and keeps two decimals', () {
      expect(en.money(1234.5), '1,234.50 SAR');
      expect(ar.money(1234.5), '1,234.50 ر.س');
    });

    test('quantity drops decimals for whole values', () {
      expect(en.quantity(3), '3');
      expect(en.quantity(1.5), '1.50');
    });

    test('percent appends a sign', () {
      expect(en.percent(15), '15%');
    });
  });

  group('dates', () {
    test('date is sortable and null-safe', () {
      expect(en.date(DateTime(2026, 9, 14)), '2026-09-14');
      expect(en.date(null), '-');
    });

    test('dateTime includes the clock', () {
      expect(en.dateTime(DateTime(2026, 9, 1, 14, 30)), '2026-09-01 14:30');
    });

    test('longDate never throws on an uninitialized locale', () {
      expect(ar.longDate(DateTime(2026, 9, 14)), isNotEmpty);
    });
  });

  test('isRtl follows the locale tag', () {
    expect(en.isRtl, isFalse);
    expect(ar.isRtl, isTrue);
    expect(const PdfFormatters(locale: 'ar_SA').isRtl, isTrue);
  });
}
