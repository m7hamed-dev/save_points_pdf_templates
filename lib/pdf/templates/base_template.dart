import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:save_points_pdf_templates/pdf/core/formatters/pdf_formatters.dart';
import 'package:save_points_pdf_templates/pdf/core/widgets/pdf_sections.dart';
import 'package:save_points_pdf_templates/pdf/core/widgets/pdf_ui.dart';
import 'package:save_points_pdf_templates/pdf/models/base/pdf_base_invoice_model.dart';
import 'package:save_points_pdf_templates/pdf/models/base/pdf_party_model.dart';
import 'package:save_points_pdf_templates/pdf/pdf_config/pdf_config.dart';
import 'package:save_points_pdf_templates/pdf/pdf_config/pdf_labels.dart';
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

  /// Overrides the document title derived from the model. Empty by default —
  /// read [documentName] rather than this field for the document's own name.
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
    labels: pdfConfig.effectiveLabels,
    isRtl: pdfConfig.isRtl,
    canRenderArabic: pdfConfig.canRenderArabic,
  );

  /// Composite document blocks — masthead, party cards, totals, footer.
  late final PdfSections sections = PdfSections(ui);

  /// Money, number and date formatting for the configured locale.
  PdfFormatters get format => pdfConfig.formatters;

  bool get isRtl => pdfConfig.isRtl;

  /// A sub-title, dropped when the configured font cannot draw it.
  ///
  /// Only right-to-left text is at risk — that is what the built-in fonts and
  /// most Latin faces have no glyphs for — so a Latin sub-title from a custom
  /// [PdfLabels] passes through untouched. See [PdfConfig.canRenderArabic].
  String arabicTitle(String value) {
    if (value.isEmpty || pdfConfig.canRenderArabic) return value;
    return PdfUi.directionOf(value) == pw.TextDirection.rtl ? '' : value;
  }

  /// Every word this template prints, from [PdfConfig.labels].
  ///
  /// Prefer this over [tr] for anything the package itself says: a label named
  /// here can be reworded or translated by overriding one getter, while a pair
  /// of strings written inline can only be changed by forking the template.
  PdfLabels get labels => pdfConfig.effectiveLabels;

  /// Picks between two strings by document direction, for a label of your own
  /// that [labels] does not name.
  ///
  /// Bilingual by construction — it takes exactly two languages — so it is a
  /// convenience for a custom template, not the way the package speaks.
  ///
  /// Falls back to [english] when the configured font cannot draw Arabic, the
  /// same guard [PdfUi.bilingual] applies: an Arabic label the font has no
  /// glyphs for is a row of blank boxes, and a readable English document beats
  /// an unreadable Arabic one.
  String tr(String english, String arabic) =>
      isRtl && pdfConfig.canRenderArabic ? arabic : english;

  /// What this document is called outside the page: the PDF's `/Title`
  /// metadata, the name the share sheet suggests and the preview page's app
  /// bar all come from here.
  ///
  /// [title] is an optional override for the printed heading, so it is empty
  /// on almost every document; reading it directly named every file
  /// `document.pdf` and left the preview app bar blank. This falls back to the
  /// model's own label and number instead.
  ///
  /// Override it for a model that is not a [PdfBaseInvoiceModel], or to name
  /// documents some other way.
  String get documentName {
    if (title.isNotEmpty) return title;
    final model = data;
    if (model is! PdfBaseInvoiceModel) return 'Document';
    // Through the labels, not the type directly: a French document should not
    // be filed away as `Sales Invoice`.
    final label =
        model.title.isNotEmpty ? model.title : labels.documentType(model.type);
    return model.id.isEmpty ? label : '$label ${model.id}';
  }

  /// The name to save or share this document under, `.pdf` appended when it
  /// is missing. [override] wins when given.
  ///
  /// Lives here rather than at each call site so the preview page and the
  /// headless entry points cannot drift apart on what a file is called.
  String fileName([String? override]) {
    final name = (override ?? documentName).trim();
    if (name.isEmpty) return 'document.pdf';
    return name.endsWith('.pdf') ? name : '$name.pdf';
  }

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

  /// Blocks appended after [body]. Override to add terms or an annex.
  List<pw.Widget> appendix(pw.Context context) => const [];

  /// A word set diagonally behind every page — `DRAFT`, `COPY`, `VOID`.
  ///
  /// Empty by default. Set it when the document must not be mistaken for the
  /// original: a printout has no metadata to say so, and a diagonal mark is
  /// the only thing that survives a photocopier.
  String get watermark => '';

  /// Painted behind the page content, under the header and the footer.
  ///
  /// Override for a letterhead or a pre-printed background; the default draws
  /// [watermark] when there is one.
  pw.Widget? background(pw.Context context) =>
      watermark.isEmpty ? null : ui.watermark(watermark);
}
