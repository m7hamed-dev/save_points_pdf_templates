import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:save_points_pdf_templates/pdf/core/extensions/spacing.dart';
import 'package:save_points_pdf_templates/pdf/core/extensions/text.dart';

extension PdfHeaderDividerExtension on String {
  pw.Widget headerDivider({
    PdfColor fontColor = PdfColors.black,
    double fontSize = 12,
    pw.FontWeight fontWeight = pw.FontWeight.normal,
    pw.TextDirection textDirection = pw.TextDirection.rtl,
    pw.Font? font,
    pw.TextAlign textAlign = pw.TextAlign.right,
  }) {
    return pw.Row(
      children: [
        pw.Expanded(
          flex: 8,
          child: pw.Divider(color: fontColor, thickness: 22.0),
        ),

        24.0.width(),

        /// Arabic type
        text(
          fontSize: 24.0,
          fontWeight: pw.FontWeight.bold,
          color: fontColor,
          // font: font,
        ),
        24.0.width(),

        pw.Expanded(child: pw.Divider(color: fontColor, thickness: 22.0)),
      ],
    );
  }
}
