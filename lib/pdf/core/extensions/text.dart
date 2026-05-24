import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

extension PdfTextExtension on String {
  ///
  pw.Widget text({
    PdfColor color = PdfColors.black,
    double fontSize = 12,
    pw.FontWeight fontWeight = pw.FontWeight.normal,
    pw.TextDirection textDirection = pw.TextDirection.rtl,
    pw.Font? font,
    pw.TextAlign textAlign = pw.TextAlign.right,
  }) {
    ///
    return pw.Text(
      this,
      textDirection: textDirection,
      textAlign: textAlign,
      style: pw.TextStyle(
        font: font,
        // font: font ?? pw.Font.helvetica(),
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        // decoration: pw.TextDecoration.lineThrough,
        decorationColor: PdfColors.black,
        decorationStyle: pw.TextDecorationStyle.solid,
      ),
    );
  }

  /// withBackgroundColor
  pw.Widget textWithBackgroundColor({
    PdfColor color = PdfColors.white,
    double padding = 4.0,
    double borderRadius = 2.0,
  }) {
    return pw.Container(
      padding: pw.EdgeInsets.symmetric(horizontal: padding),
      decoration: pw.BoxDecoration(
        color: color,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(borderRadius)),
      ),
      child: pw.Text(this, style: const pw.TextStyle(color: PdfColors.white)),
    );
  }
}
