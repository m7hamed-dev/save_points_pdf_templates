import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:save_points_pdf_templates/pdf/core/extensions/spacing.dart';
import 'package:save_points_pdf_templates/pdf/core/extensions/text.dart';

extension PdfDateTimeExtension on String {
  pw.Widget dateTime({
    PdfColor fontColor = PdfColors.black,
    double fontSize = 12,
    pw.FontWeight fontWeight = pw.FontWeight.normal,
    pw.TextDirection textDirection = pw.TextDirection.rtl,
    pw.Font? font,
    pw.TextAlign textAlign = pw.TextAlign.right,
  }) {
    return pw.Row(
      children: [
        /// Date label
        'Date : '.text(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: fontColor,
          textDirection: textDirection,
          // font: font,
        ),

        /// Space
        12.0.width(),

        /// Date
        text(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: fontColor,
          textDirection: textDirection,
          font: font,
        ),
      ],
    );
  }
}
