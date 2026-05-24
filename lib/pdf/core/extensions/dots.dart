import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

extension PdfDotsExtension on String {
  ///
  pw.Widget dots({int length = 100, String? value}) {
    ///
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 10.0),
      child: pw.Row(
        children: [
          pw.Text(this, textDirection: pw.TextDirection.rtl),
          pw.Expanded(
            child: pw.Container(
              width: length.toDouble(),
              margin: const pw.EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 4.0,
              ),
              // height: .5,
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(
                    color: PdfColors.grey400,
                    width: 0.5,
                    style: pw.BorderStyle.dashed,
                  ),
                ),
              ),

              /// value
              child: pw.Text(
                value ?? '',
                textDirection: pw.TextDirection.rtl,
                textAlign: pw.TextAlign.left,
                style: pw.TextStyle(
                  fontSize: 14.0,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
