import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:save_points_pdf_templates/pdf/generator/pdf_generator.dart';
import 'package:save_points_pdf_templates/pdf/templates/base_template.dart';

/// Full-screen preview with the platform print and share actions.
///
/// ```dart
/// Navigator.of(context).push(MaterialPageRoute(
///   builder: (_) => PdfPreviewPage(template: template),
/// ));
/// ```
///
/// For a preview embedded in your own layout, use [PdfPreview] directly and
/// pass `build: (_) => PdfGenerator.generate(template: template)`.
class PdfPreviewPage<T> extends StatelessWidget {
  const PdfPreviewPage({
    required this.template,
    super.key,
    this.appBarTitle,
    this.actions,
    this.fileName,
    this.canChangePageFormat = false,
    this.canChangeOrientation = false,
    this.allowSharing = true,
    this.allowPrinting = true,
    this.maxPageWidth = 700,
  });

  final BaseTemplate<T> template;

  /// Defaults to the template's [BaseTemplate.documentName].
  final String? appBarTitle;

  final List<Widget>? actions;

  /// Name suggested by the share sheet. `.pdf` is appended when missing.
  final String? fileName;

  final bool canChangePageFormat;
  final bool canChangeOrientation;
  final bool allowSharing;
  final bool allowPrinting;
  final double maxPageWidth;

  String get _fileName {
    final name = (fileName ?? template.documentName).trim();
    if (name.isEmpty) return 'document.pdf';
    return name.endsWith('.pdf') ? name : '$name.pdf';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle ?? template.documentName),
        actions: actions,
      ),
      body: PdfPreview(
        maxPageWidth: maxPageWidth,
        canChangeOrientation: canChangeOrientation,
        canChangePageFormat: canChangePageFormat,
        allowSharing: allowSharing,
        allowPrinting: allowPrinting,
        pdfFileName: _fileName,
        initialPageFormat: template.pageFormat,
        build: (_) => PdfGenerator.generate<T>(template: template),
      ),
    );
  }
}
