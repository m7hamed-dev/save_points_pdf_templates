import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:save_points_pdf_templates/pdf/generator/pdf_generator.dart';
import 'package:save_points_pdf_templates/pdf/templates/base_template.dart';

/// Headless entry points: render a template and hand the bytes to the
/// platform without pushing a preview screen.
///
/// ```dart
/// await PdfDocuments.share(template: invoiceTemplate, fileName: 'INV-42');
/// await PdfDocuments.print(template: invoiceTemplate);
/// final bytes = await PdfDocuments.bytes(template: invoiceTemplate);
/// ```
class PdfDocuments {
  const PdfDocuments._();

  /// Renders the template to raw PDF bytes.
  static Future<Uint8List> bytes<T>({required BaseTemplate<T> template}) =>
      PdfGenerator.generate<T>(template: template);

  /// Opens the platform share sheet. Returns false when the user cancels.
  static Future<bool> share<T>({
    required BaseTemplate<T> template,
    String? fileName,
    String? subject,
    List<String> emails = const [],
  }) async {
    final data = await bytes(template: template);
    return Printing.sharePdf(
      bytes: data,
      filename: _withExtension(fileName ?? template.title),
      subject: subject,
      emails: emails,
    );
  }

  /// Opens the platform print dialog. Returns false when the user cancels.
  static Future<bool> printDocument<T>({
    required BaseTemplate<T> template,
    String? jobName,
    PdfPageFormat? format,
  }) async {
    final data = await bytes(template: template);
    return Printing.layoutPdf(
      onLayout: (_) => data,
      name: jobName ?? _withExtension(template.title),
      format: format ?? template.pageFormat,
    );
  }

  /// Renders the first page to a raster image — handy for thumbnails.
  static Future<Uint8List?> thumbnail<T>({
    required BaseTemplate<T> template,
    double dpi = 72,
  }) async {
    final data = await bytes(template: template);
    await for (final page in Printing.raster(
      data,
      dpi: dpi,
      pages: const [0],
    )) {
      return page.toPng();
    }
    return null;
  }

  static String _withExtension(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'document.pdf';
    return trimmed.endsWith('.pdf') ? trimmed : '$trimmed.pdf';
  }
}
