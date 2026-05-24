import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:save_points_pdf_templates/pdf/pdf_config/pdf_config.dart';

abstract class BaseTemplate<T> {
  const BaseTemplate({
    required this.data,
    required this.pdfConfig,
    this.title = '',
    // this.company,
    this.qrCode = '',
    this.qrCodeSize = 80.0,
    this.primaryColor = const PdfColor(0, 0, 0),
    this.headers = const [],
  });

  final String title;
  final List<String> headers;

  /// properties
  final T data;
  PdfPageFormat get pageFormat => PdfPageFormat.a4;

  /// widgets
  /// 1
  pw.Widget body(pw.Context context);

  /// 2
  pw.Widget footer(pw.Context context);

  /// 3
  pw.Widget header(pw.Context context, {Uint8List? logo});

  /// font color
  final PdfConfig pdfConfig;
  final PdfColor primaryColor;

  // final PdfPartyModel? company;
  final String qrCode;
  final double? qrCodeSize;
}
