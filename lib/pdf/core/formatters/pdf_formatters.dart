import 'package:intl/intl.dart';

/// Locale-aware money, number and date formatting used by every template.
///
/// Templates never call [DateTime.toIso8601String] or string-interpolate a
/// double directly — everything goes through here so a document rendered in
/// Arabic and the same document rendered in English stay consistent.
class PdfFormatters {
  const PdfFormatters({this.locale = 'en', this.currency = 'SAR'});

  /// BCP 47 locale tag, e.g. `en`, `ar`, `ar_SA`.
  final String locale;

  /// Currency symbol or ISO code appended to money values.
  final String currency;

  bool get isRtl => locale.toLowerCase().startsWith('ar');

  /// `1,234.50 SAR`
  String money(double value) => '${number(value)} $currency';

  /// `1,234.50` — always two decimals, grouped thousands.
  String number(double value) => NumberFormat.decimalPatternDigits(
    locale: 'en',
    decimalDigits: 2,
  ).format(value);

  /// `1,234` — no decimals when the value is whole, two when it is not.
  /// Used for quantities so `3` does not render as `3.00`.
  String quantity(double value) {
    final isWhole = value == value.roundToDouble();
    return NumberFormat.decimalPatternDigits(
      locale: 'en',
      decimalDigits: isWhole ? 0 : 2,
    ).format(value);
  }

  /// `12.5%`
  String percent(double value) => '${quantity(value)}%';

  /// `2026-09-01` — sortable and unambiguous across locales.
  String date(DateTime? value) =>
      value == null ? '-' : DateFormat('yyyy-MM-dd').format(value);

  /// `2026-09-01 14:30`
  String dateTime(DateTime? value) =>
      value == null ? '-' : DateFormat('yyyy-MM-dd HH:mm').format(value);

  /// `01 Sep 2026` / `01 سبتمبر 2026` — for headers where readability wins.
  ///
  /// Falls back to [date] when the locale's date symbols have not been
  /// initialized, so a template never fails to render over formatting alone.
  String longDate(DateTime? value) {
    if (value == null) return '-';
    try {
      return DateFormat('dd MMM yyyy', locale).format(value);
    } on Object {
      return date(value);
    }
  }
}
