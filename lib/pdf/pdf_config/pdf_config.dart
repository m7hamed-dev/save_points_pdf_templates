import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:save_points_pdf_templates/pdf/core/formatters/pdf_formatters.dart';
import 'package:save_points_pdf_templates/pdf/models/base/pdf_party_model.dart';
import 'package:save_points_pdf_templates/pdf/pdf_config/pdf_theme.dart';

/// Everything a template needs that is *not* document data: fonts, logo,
/// issuer details, locale, currency and the visual [PdfTheme].
///
/// This class is concrete — the common case needs no subclass:
///
/// ```dart
/// final config = PdfConfig(
///   fontPath: 'assets/fonts/Cairo-Regular.ttf',
///   boldFontPath: 'assets/fonts/Cairo-Bold.ttf',
///   logoPath: 'assets/images/logo.png',
///   locale: 'ar',
///   company: const PdfPartyModel(name: 'Save Points'),
/// );
/// ```
///
/// Fonts can also be handed over ready-made — useful with `PdfGoogleFonts`
/// from the `printing` package, or a font you loaded yourself:
///
/// ```dart
/// final config = PdfConfig(
///   font: await PdfGoogleFonts.cairoRegular(),
///   boldFont: await PdfGoogleFonts.cairoBold(),
///   locale: 'ar',
/// );
/// ```
///
/// Subclass only when a value has to be computed at render time (for example
/// a currency that follows the signed-in user). [init] is idempotent: fonts
/// and the logo are decoded once per config instance and then reused.
class PdfConfig {
  PdfConfig({
    this.fontPath = '',
    this.boldFontPath = '',
    this.logoPath = '',
    this.company,
    this.currency = 'SAR',
    this.locale = 'en',
    this.theme = const PdfTheme(),
    this.pageFormat = PdfPageFormat.a4,
    this.strictFonts = false,
    this.logoSize = 46.0,
    this.fallbackFontPaths = const [],
    this.useBuiltInFallback = true,
    pw.Font? font,
    pw.Font? boldFont,
    List<pw.Font> fontFallbacks = const [],
    Uint8List? logoBytes,
  }) : _fontFallbacks = fontFallbacks,
       _font = font,
       _boldFont = boldFont,
       _logo = logoBytes,
       _initialized = font != null;

  /// Asset path of the regular TTF. Leave empty to use the built-in Latin
  /// font — required for Arabic, which the built-in fonts cannot render.
  ///
  /// Ignored when a ready-made `font` was passed to the constructor.
  final String fontPath;

  /// Asset path of the bold TTF. Falls back to [fontPath] when empty.
  final String boldFontPath;

  /// Asset path of the issuer logo (PNG/JPG).
  final String logoPath;

  /// Issuer shown in the document header.
  final PdfPartyModel? company;

  /// Currency appended to every money value.
  final String currency;

  /// BCP 47 locale tag. Anything starting with `ar` renders right-to-left.
  final String locale;

  /// Colors, type scale and spacing.
  final PdfTheme theme;

  /// Default page format; a template may override it.
  final PdfPageFormat pageFormat;

  /// When true, a missing or unreadable font asset throws instead of falling
  /// back to the built-in font. Turn this on in production so a broken asset
  /// declaration fails loudly instead of silently dropping Arabic glyphs.
  final bool strictFonts;

  /// Edge length of the logo box in the header.
  final double logoSize;

  /// Extra TTF assets consulted when the main font has no glyph for a
  /// character — an Arabic font that ships no Latin letters, for example.
  final List<String> fallbackFontPaths;

  /// Appends the built-in Latin font to the fallback chain so digits and
  /// ASCII always render, even behind an Arabic-only typeface.
  final bool useBuiltInFallback;

  final List<pw.Font> _fontFallbacks;
  final List<pw.Font> _loadedFallbacks = [];
  pw.Font? _font;
  pw.Font? _boldFont;
  Uint8List? _logo;
  bool _initialized;

  /// Regular font, available after [init].
  pw.Font? get font => _font;

  /// Bold font, available after [init]. Falls back to [font].
  pw.Font? get boldFont => _boldFont ?? _font;

  /// Decoded logo bytes, available after [init].
  Uint8List? get logo => _logo;

  /// Fonts consulted, in order, for glyphs the main font is missing.
  List<pw.Font> get fontFallbacks => [
    ..._fontFallbacks,
    ..._loadedFallbacks,
    if (useBuiltInFallback) pw.Font.helvetica(),
  ];

  /// True when a custom TTF was loaded. When false, Arabic text will not
  /// render — the built-in fonts have no Arabic glyphs.
  bool get hasCustomFont => _font != null;

  /// True when the document should be laid out right-to-left.
  bool get isRtl => locale.toLowerCase().startsWith('ar');

  /// True when Arabic glyphs can actually be drawn.
  ///
  /// The built-in PDF fonts are Latin-only, so templates check this before
  /// printing an Arabic sub-title: rendering it without a suitable TTF
  /// produces a row of missing-glyph warnings and blank boxes, not text.
  bool get canRenderArabic => hasCustomFont;

  pw.TextDirection get textDirection =>
      isRtl ? pw.TextDirection.rtl : pw.TextDirection.ltr;

  /// Money, number and date formatting bound to [locale] and [currency].
  PdfFormatters get formatters =>
      PdfFormatters(locale: locale, currency: currency);

  /// Accent color, kept for convenience and backwards compatibility.
  PdfColor get primaryColor => theme.accent;

  /// Loads fonts, logo and locale data. Safe to call repeatedly.
  Future<void> init() async {
    if (_initialized) return;
    await _initLocaleData();
    _font ??= await _loadFont(fontPath);
    _boldFont ??= boldFontPath.isEmpty ? _font : await _loadFont(boldFontPath);
    _logo ??= await _loadLogo();
    for (final path in fallbackFontPaths) {
      final fallback = await _loadFont(path);
      if (fallback != null) _loadedFallbacks.add(fallback);
    }
    _initialized = true;
  }

  /// Drops cached assets so the next [init] reloads them. Useful after a
  /// hot reload or when the app swaps its branding at runtime.
  void invalidate() {
    _font = null;
    _boldFont = null;
    _logo = null;
    _loadedFallbacks.clear();
    _initialized = false;
  }

  Future<void> _initLocaleData() async {
    try {
      await initializeDateFormatting(locale);
    } on Object catch (error) {
      debugPrint('[save_points_pdf_templates] locale "$locale": $error');
    }
  }

  Future<pw.Font?> _loadFont(String path) async {
    if (path.isEmpty) return null;
    try {
      return pw.Font.ttf(await rootBundle.load(path));
    } on Object catch (error) {
      if (strictFonts) {
        throw PdfAssetException(
          'Could not load the font asset "$path". Declare it under '
          '`flutter: assets:` in your app pubspec.yaml.',
          error,
        );
      }
      debugPrint(
        '[save_points_pdf_templates] font "$path" not found — falling back to '
        'the built-in Latin font. Arabic text will not render.',
      );
      return null;
    }
  }

  Future<Uint8List?> _loadLogo() async {
    if (logoPath.isEmpty) return null;
    try {
      final data = await rootBundle.load(logoPath);
      return data.buffer.asUint8List();
    } on Object catch (error) {
      if (strictFonts) {
        throw PdfAssetException(
          'Could not load the logo asset "$logoPath".',
          error,
        );
      }
      debugPrint('[save_points_pdf_templates] logo "$logoPath" not found.');
      return null;
    }
  }
}

/// Thrown by [PdfConfig.init] when an asset is missing and
/// [PdfConfig.strictFonts] is enabled.
class PdfAssetException implements Exception {
  const PdfAssetException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() =>
      'PdfAssetException: $message${cause == null ? '' : ' ($cause)'}';
}
