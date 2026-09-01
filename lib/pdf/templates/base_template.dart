import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:save_points_pdf_templates/pdf/core/formatters/pdf_formatters.dart';
import 'package:save_points_pdf_templates/pdf/core/widgets/pdf_sections.dart';
import 'package:save_points_pdf_templates/pdf/core/widgets/pdf_ui.dart';
import 'package:save_points_pdf_templates/pdf/models/base/pdf_party_model.dart';
import 'package:save_points_pdf_templates/pdf/pdf_config/pdf_config.dart';
import 'package:save_points_pdf_templates/pdf/pdf_config/pdf_theme.dart';

/// Contract every document template implements.
///
/// A template turns one typed model `T` into three page regions. Only [body]
/// is required — [header] and [footer] have sensible defaults built from
/// [sections], so a new template is often 30 lines:
///
/// ```dart
/// class MyTemplate extends BaseTemplate<MyModel> {
///   MyTemplate({required super.data, required super.pdfConfig});
///
///   @override
///   List<pw.Widget> body(pw.Context context) => [ui.text(data.something)];
/// }
/// ```
///
/// [body] returns a *list* of blocks rather than one widget on purpose: the
/// renderer can only break a page between top-level blocks, so a table
/// returned as its own block flows across pages, while the same table nested
/// inside a column would be forced onto a single page.
///
/// [header] and [footer] are re-invoked on every page, so keep them cheap and
/// free of per-page state.
abstract class BaseTemplate<T> {
  BaseTemplate({
    required this.data,
    required this.pdfConfig,
    this.title = '',
    this.headers = const [],
    this.qrCode = '',
    this.qrCodeSize = 64.0,
    PdfTheme? theme,
    PdfPageFormat? pageFormat,
  }) : _theme = theme,
       _pageFormat = pageFormat;

  /// The typed document model this template renders.
  final T data;

  /// Fonts, logo, issuer, locale, currency and theme.
  final PdfConfig pdfConfig;

  /// Overrides the document title derived from the model.
  final String title;

  /// Column headers for table-driven templates.
  final List<String> headers;

  /// Payload encoded into the header QR code. Empty hides it.
  final String qrCode;

  final double qrCodeSize;

  final PdfTheme? _theme;
  final PdfPageFormat? _pageFormat;

  /// Theme passed to this template, falling back to the config's.
  PdfTheme get theme => _theme ?? pdfConfig.theme;

  /// Page size, falling back to the config's.
  PdfPageFormat get pageFormat => _pageFormat ?? pdfConfig.pageFormat;

  /// Primitive widgets bound to [theme].
  late final PdfUi ui = PdfUi(
    theme: theme,
    formatters: pdfConfig.formatters,
    isRtl: pdfConfig.isRtl,
    canRenderArabic: pdfConfig.canRenderArabic,
  );

  /// Composite document blocks — masthead, party cards, totals, footer.
  late final PdfSections sections = PdfSections(ui);

  /// Money, number and date formatting for the configured locale.
  PdfFormatters get format => pdfConfig.formatters;

  bool get isRtl => pdfConfig.isRtl;

  /// The Arabic sub-title to print, or an empty string when the configured
  /// font cannot draw Arabic. See [PdfConfig.canRenderArabic].
  String arabicTitle(String value) => pdfConfig.canRenderArabic ? value : '';

  /// Picks the label matching the document direction. Templates use it for
  /// their own chrome — `tr('Subtotal', 'الإجمالي الفرعي')` — so one template
  /// serves both languages instead of shipping two.
  String tr(String english, String arabic) => isRtl ? arabic : english;

  /// The issuer, from the config.
  PdfPartyModel? get company => pdfConfig.company;

  /// Decoded logo bytes, available once [PdfConfig.init] has run.
  Uint8List? get logo => pdfConfig.logo;

  /// The page content, as a list of blocks laid out top to bottom. Required.
  ///
  /// Return long, splittable content — tables above all — as its own entry so
  /// the renderer can break pages inside it.
  List<pw.Widget> body(pw.Context context);

  /// Repeated at the top of every page. Return `null` for no header.
  pw.Widget? header(pw.Context context) => null;

  /// Repeated at the bottom of every page. Defaults to a hairline with the
  /// page number and the issuer name.
  pw.Widget? footer(pw.Context context) =>
      sections.pageFooter(context, note: company?.name);

  /// Blocks appended after [body]. Override to add terms, an annex or a
  /// second copy of the document.
  List<pw.Widget> appendix(pw.Context context) => const [];
}
