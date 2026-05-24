import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:save_points_pdf_templates/pdf/core/extensions/spacing.dart';
import 'package:save_points_pdf_templates/pdf/core/extensions/title_value.dart';
import 'package:save_points_pdf_templates/pdf/models/base/pdf_party_model.dart';

extension PdfCustomerToWidgetExtension on PdfPartyModel {
  pw.Widget toCustomerWidget({
    PdfColor color = PdfColors.black,
    double fontSize = 12,
    pw.TextDirection textDirection = pw.TextDirection.rtl,
    pw.Font? font,
    pw.TextAlign textAlign = pw.TextAlign.right,
    pw.FontWeight fontWeight = pw.FontWeight.bold,
  }) {
    final name = ['Customer Name : ', this.name];
    final phone = ['Customer Phone : ', this.phone];
    final email = ['Customer Email : ', this.email];

    /// title and value row
    return pw.Column(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        name.titleAndValueText(),
        4.0.height(),
        phone.titleAndValueText(),
        4.0.height(),
        email.titleAndValueText(),
        // email.titleAndValueText(isRow: isRow),
      ],
    );
  }
}
