import 'dart:typed_data';

import 'package:pdf/widgets.dart' as pw;
import 'package:save_points_pdf_templates/pdf/pdf_config/pdf_config.dart';
import 'package:save_points_pdf_templates/pdf/templates/base_template.dart';

/// Renders a [BaseTemplate] into PDF bytes.
///
/// ```dart
/// final bytes = await PdfGenerator.generate(template: myTemplate);
/// ```
///
/// The generator owns document assembly only. Fonts, the logo and locale
/// data belong to [PdfConfig] and are loaded by [PdfConfig.init], which this
/// method calls for you — repeated renders reuse the same decoded assets
/// instead of hitting the asset bundle again.
class PdfGenerator {
  const PdfGenerator._();

  /// Builds the document and returns its bytes, ready to save, share or print.
  static Future<Uint8List> generate<T>({
    required BaseTemplate<T> template,
    String? title,
    String? author,
    String? subject,
    String? creator,

    /// Safety valve: rendering aborts past this many pages instead of looping
    /// on content that can never fit.
    int maxPages = 200,

    /// Compresses the page content. Turn it off for a larger file whose text
    /// can be searched in the bytes — useful when diffing output, and what an
    /// archival workflow sometimes asks for.
    bool compress = true,
  }) async {
    final config = template.pdfConfig;
    await config.init();

    final document = pw.Document(
      compress: compress,
      title: title ?? template.documentName,
      author: author ?? config.company?.name,
      subject: subject,
      creator: creator ?? 'save_points_pdf_templates',
    );

    document.addPage(
      pw.MultiPage(
        // A page theme rather than the loose arguments, because that is the
        // only place a background can be given — and the background is what
        // carries a watermark under every page.
        pageTheme: pw.PageTheme(
          pageFormat: template.pageFormat,
          margin: template.theme.margin.insets,
          textDirection: config.textDirection,
          theme: pw.ThemeData.withFont(
            base: config.font,
            bold: config.boldFont,
            italic: config.font,
            boldItalic: config.boldFont,
            fontFallback: config.fontFallbacks,
          ),
          buildBackground:
              (context) => template.background(context) ?? pw.SizedBox(),
        ),
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        header: (context) => template.header(context) ?? pw.SizedBox(),
        footer: (context) => template.footer(context) ?? pw.SizedBox(),
        maxPages: maxPages,
        build:
            (context) => [
              ...template.body(context),
              ...template.appendix(context),
            ],
      ),
    );

    return document.save();
  }
}
