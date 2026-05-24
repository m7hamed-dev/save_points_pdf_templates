import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:save_points_pdf_templates/pdf/templates/base_template.dart';

class PdfGenerator {
  /// logo
  static Uint8List? logo;

  /// generate the pdf
  static Future<Uint8List> generate<T>({
    required BaseTemplate<T> template,
  }) async {
    /// get the pdf config
    final pdfConfig = template.pdfConfig;

    ///
    await pdfConfig.init();

    /// get the font and logo path
    final font = pdfConfig.font;
    final logoPath = pdfConfig.logoPath;

    ///
    if (logoPath.isNotEmpty) {
      if (logo == null) {
        final bytes = await rootBundle.load(logoPath);
        final uint8List = bytes.buffer.asUint8List();
        logo = uint8List;
      }
    }

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        // textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: font, bold: font),
        pageFormat: PdfPageFormat.a4,
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        header: (context) => template.header(context, logo: logo),
        build: (context) => [template.body(context)],
        footer: (context) => template.footer(context),
      ),
    );

    return pdf.save();
  }
}
