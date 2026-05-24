import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:save_points_pdf_templates/pdf/core/extensions/spacing.dart';
import 'package:save_points_pdf_templates/pdf/core/extensions/text.dart';
import 'package:save_points_pdf_templates/pdf/models/pdf_sale_invoice_model.dart';
import 'package:save_points_pdf_templates/pdf/pdf_config/pdf_config.dart';

extension PdfSummeryPayment on PdfSaleInvoiceModel {
  pw.Widget toSummeryPaymentWidget({
    PdfColor color = PdfColors.black,
    double fontSize = 12,
    pw.TextDirection textDirection = pw.TextDirection.rtl,
    pw.Font? font,
    pw.TextAlign textAlign = pw.TextAlign.right,
    pw.FontWeight fontWeight = pw.FontWeight.bold,
    required PdfConfig config,
  }) {
    final currency = config.currency;
    final fontSize = 15.0;
    final height = 25.0;
    final width = 120.0;

    /// title and value row
    return pw.Column(
      children: [
        // divider
        pw.Divider(
          color: PdfColors.black,
          thickness: 0.5,
          endIndent: 300.0,
          indent: 0.0,
        ),
        4.0.height(),
        pw.Row(
          children: [
            'Total : '.text(),
            '$total $currency'.text(fontSize: fontSize, fontWeight: .bold),
          ],
        ),
        4.0.height(),
        pw.Row(
          children: [
            'Discount : '.text(),
            '$discount $currency'.text(fontSize: fontSize, fontWeight: .bold),
          ],
        ),
        4.0.height(),
        pw.Row(
          children: [
            'Tax : '.text(),
            '$tax $currency'.text(fontSize: fontSize, fontWeight: .bold),
          ],
        ),
        4.0.height(),
        pw.Row(
          children: [
            pw.Container(
              width: width,
              height: height,
              alignment: pw.Alignment.center,
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 10.0,
                vertical: 5.0,
              ),
              decoration: pw.BoxDecoration(color: config.primaryColor),
              child: 'Total : '.text(color: PdfColors.white),
            ),
            4.0.width(),
            pw.Container(
              width: width,
              height: height,
              alignment: pw.Alignment.center,
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 10.0,
                vertical: 5.0,
              ),
              decoration: pw.BoxDecoration(color: config.primaryColor),
              child: '$total $currency'.text(
                fontSize: fontSize,
                fontWeight: .bold,
                color: PdfColors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
