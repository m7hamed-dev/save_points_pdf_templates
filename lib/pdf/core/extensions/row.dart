import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:save_points_pdf_templates/pdf/core/extensions/text.dart';

extension PdfRowExtension on List<String> {
  pw.Widget row({PdfColor color = PdfColors.grey300, double fontSize = 12}) {
    return pw.Row(
      children: map((e) => e.text(color: color, fontSize: fontSize)).toList(),
    );
  }
}
