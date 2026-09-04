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
    this.currencyDecimals = 2,
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
       _givenFont = font,
       _givenBoldFont = boldFont,
       _givenLogo = logoBytes,
       _font = font,
       _boldFont = boldFont,
       _logo = logoBytes;

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

  /// Decimal places on money. Three for KWD and BHD, none for JPY.
  final int currencyDecimals;

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

  /// Assets handed to the constructor ready-made. Held apart from the cache so
  /// [invalidate] can drop what was loaded without discarding what it could
  /// never load again — there is no asset path behind a `pw.Font` the caller
  /// decoded itself.
  final pw.Font? _givenFont;
  final pw.Font? _givenBoldFont;
  final Uint8List? _givenLogo;

  pw.Font? _font;
  pw.Font? _boldFont;
  Uint8List? _logo;
  bool _initialized = false;
  Future<void>? _initializing;

  /// Cached once the fonts are loaded; parsing a face's character map is not
  /// something to redo on every label.
  bool? _canRenderArabic;

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
  /// Templates check this before printing anything Arabic: drawing it with a
  /// font that has no Arabic produces a row of blank boxes and a missing-glyph
  /// warning per character, not text.
  ///
  /// This asks the loaded faces what they actually contain rather than
  /// assuming a custom font implies Arabic — a Latin-only TTF such as Inter is
  /// a custom font too, and treating it as Arabic-capable printed tofu under
  /// the title of every English document.
  bool get canRenderArabic => _canRenderArabic ?? _textFonts.any(_drawsArabic);

  /// The faces that can contribute glyphs to the document: the main font and
  /// the fallbacks behind it. The built-in Latin font is left out — it is what
  /// a missing glyph falls through to, not a source of coverage.
  Iterable<pw.Font> get _textFonts => [
    if (_font != null) _font!,
    ..._fontFallbacks,
    ..._loadedFallbacks,
  ];

  /// Two letters every Arabic face carries. Checking both rather than one
  /// keeps a Latin font that happens to define a stray glyph in the Arabic
  /// block from passing.
  static const List<int> _arabicProbe = [0x0627, 0x0645]; // ا, م

  static bool _drawsArabic(pw.Font font) {
    if (font is! pw.TtfFont) return false;
    try {
      final glyphs = TtfParser(font.data).charToGlyphIndexMap;
      return _arabicProbe.every(glyphs.containsKey);
    } on Object {
      // An unparseable face cannot be counted on for anything.
      return false;
    }
  }

  pw.TextDirection get textDirection =>
      isRtl ? pw.TextDirection.rtl : pw.TextDirection.ltr;

  /// Money, number and date formatting bound to [locale] and [currency].
  ///
  /// The formatting locale degrades to English when the font cannot draw
  /// Arabic: `longDate` would otherwise return `14 سبتمبر 2026`, a month name
  /// the font has no glyphs for. Layout direction is unaffected — it comes
  /// from [isRtl], so the document still mirrors.
  ///
  /// Only text the package generates degrades this way. [currency], party
  /// names and notes are the caller's own data and are printed as given, since
  /// there is nothing to substitute them with.
  PdfFormatters get formatters => PdfFormatters(
    locale: canRenderArabic ? locale : 'en',
    currency: currency,
    decimals: currencyDecimals,
  );

  /// Accent color, kept for convenience and backwards compatibility.
  PdfColor get primaryColor => theme.accent;

  /// Loads fonts, logo and locale data. Safe to call repeatedly, and safe to
  /// call from two renders at once — the second awaits the first rather than
  /// loading everything a second time.
  ///
  /// Assets supplied to the constructor are kept as they are; only what is
  /// still missing is fetched, so passing a ready-made `font` does not stop
  /// the logo, the bold face or the fallbacks from loading.
  Future<void> init() {
    if (_initialized) return Future<void>.value();
    return _initializing ??= _load().whenComplete(() => _initializing = null);
  }

  Future<void> _load() async {
    await _initLocaleData();
    _font ??= await _loadFont(fontPath);
    _boldFont ??= boldFontPath.isEmpty ? _font : await _loadFont(boldFontPath);
    _logo ??= await _loadLogo();
    for (final path in fallbackFontPaths) {
      final fallback = await _loadFont(path);
      if (fallback != null) _loadedFallbacks.add(fallback);
    }
    _canRenderArabic = _textFonts.any(_drawsArabic);
    _initialized = true;
  }

  /// Drops loaded assets so the next [init] fetches them again. Useful after a
  /// hot reload or when the app swaps its branding at runtime.
  ///
  /// Fonts and logo bytes passed to the constructor are restored rather than
  /// cleared: nothing records where they came from, so dropping them would
  /// leave the config permanently without a font.
  void invalidate() {
    _font = _givenFont;
    _boldFont = _givenBoldFont;
    _logo = _givenLogo;
    _loadedFallbacks.clear();
    _canRenderArabic = null;
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
