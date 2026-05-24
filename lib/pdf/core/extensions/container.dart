import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

extension PdfContainerExtension on pw.Widget {
  pw.Widget decoratedContainer({
    PdfColor color = PdfColors.grey300,
    double radius = 8,
    double padding = 12,
    double width = double.infinity,
    double? height,
  }) {
    return pw.Container(
      height: height,
      width: width,
      padding: pw.EdgeInsets.all(padding),
      alignment: pw.Alignment.center,
      decoration: pw.BoxDecoration(
        color: color,
        borderRadius: pw.BorderRadius.circular(radius),
      ),
      child: this,
    );
  }
}
