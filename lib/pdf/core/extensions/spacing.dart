import 'package:pdf/widgets.dart' as pw;

extension PdfSpacingExtension on double {
  pw.Widget height() => pw.SizedBox(height: this);
  pw.Widget width() => pw.SizedBox(width: this);
}
