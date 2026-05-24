import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:save_points_pdf_templates/pdf/generator/pdf_generator.dart';
import 'package:save_points_pdf_templates/pdf/templates/base_template.dart';

class PdfPreviewPage<T> extends StatelessWidget {
  const PdfPreviewPage({super.key, required this.template});

  final BaseTemplate<T> template;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(template.title)),
      body: PdfPreview(
        maxPageWidth: 700,
        canChangeOrientation: false,
        canChangePageFormat: false,
        build: (_) => PdfGenerator.generate<T>(template: template),
      ),
    );
  }
}
