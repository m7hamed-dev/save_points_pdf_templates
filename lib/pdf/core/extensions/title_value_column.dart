import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:save_points_pdf_templates/pdf/core/extensions/spacing.dart';

extension PdfTitleValueColumnExtension on List<String> {
  pw.Widget titleAndValueColumn({
    PdfColor color = PdfColors.black,
    double fontSize = 12,
    pw.TextDirection textDirection = pw.TextDirection.rtl,
    pw.Font? font,
    // pw.TextAlign textAlign = pw.TextAlign.right,
    pw.FontWeight fontWeight = pw.FontWeight.bold,
  }) {
    ///
    final title = this[0];
    final value = this[1];

    /// title and value row
    return pw.Column(
      // mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        /// title
        pw.Text(
          title,
          textDirection: textDirection,
          // textAlign: textAlign,
          style: pw.TextStyle(
            font: font,
            // font: font ?? pw.Font.helvetica(),
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: PdfColors.grey600,
          ),
        ),

        /// space
        8.0.height(),

        /// value
        pw.Text(
          value,
          textDirection: textDirection,
          // textAlign: textAlign,
          style: pw.TextStyle(
            font: font,
            // font: font ?? pw.Font.helvetica(),
            fontSize: fontSize,
          ),
        ),
      ],
    );
  }
}
