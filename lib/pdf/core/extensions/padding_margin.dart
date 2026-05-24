import 'package:pdf/widgets.dart' as pw;

extension PdfPaddingExtension on pw.Widget {
  pw.Widget paddingOrMargin({double padding = 12, double margin = 12}) {
    return pw.Container(
      padding: pw.EdgeInsets.all(padding),
      margin: pw.EdgeInsets.all(margin),
      child: this,
    );
  }
}
