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
  }) async {
    final config = template.pdfConfig;
    await config.init();

    final document = pw.Document(
      title: title ?? template.documentName,
      author: author ?? config.company?.name,
      subject: subject,
      creator: creator ?? 'save_points_pdf_templates',
    );

    document.addPage(
      pw.MultiPage(
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
