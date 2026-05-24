import 'dart:typed_data';

import 'package:pdf/widgets.dart' as pw;
import 'package:save_points_pdf_templates/pdf/core/extensions/dots.dart';
import 'package:save_points_pdf_templates/pdf/core/extensions/spacing.dart';
import 'package:save_points_pdf_templates/pdf/core/extensions/text.dart';
import 'package:save_points_pdf_templates/pdf/models/pdf_receipt_voucher_model.dart';
import 'package:save_points_pdf_templates/pdf/templates/base_template.dart';

class ReceiptVoucherTemplate extends BaseTemplate<ReceiptVoucherModel> {
  ReceiptVoucherTemplate({
    required super.data,
    required super.pdfConfig,
    super.title,
  });

  late final fontColor = pdfConfig.primaryColor;

  pw.Widget get date =>
      data.date!.toIso8601String().text(fontSize: 16.0, color: primaryColor);

  @override
  pw.Widget body(pw.Context context) {
    /// amount with currency
    final amount = '${data.amount} ${pdfConfig.currency}';

    ///
    return pw.Column(
      // crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        12.0.height(),
        'تاريخ الاستلام'.dots(value: date.toString()),
        12.0.height(),
        'استلمنا من السيد / السيدة'.dots(value: data.payerName),
        12.0.height(),
        'وذلك عن عن طريق'.dots(value: data.paymentMethod),
        12.0.height(),
        'المبلغ'.dots(value: amount),
      ],
    );
  }

  @override
  pw.Widget footer(pw.Context context) {
    return pw.Column(children: [pw.Text('Footer')]);
  }

  @override
  pw.Widget header(pw.Context context, {Uint8List? logo}) {
    return pw.Column(
      children: [
        /// divier
        pw.Divider(color: fontColor, thickness: 18.0),
        22.0.height(),

        /// English type
        data.type.english.text(
          fontSize: 24.0,
          fontWeight: pw.FontWeight.bold,
          color: fontColor,
        ),

        12.0.height(),

        /// Arabic type
        data.type.arabic.text(
          fontSize: 24.0,
          fontWeight: pw.FontWeight.bold,
          color: fontColor,
          // font: font,
        ),
        data.id.text(fontSize: 18.0),
        pw.Divider(color: fontColor),

        /// date and time
        date.toString().text(color: fontColor),

        /// notes
        if (data.notes != null) data.notes!.text(),
        pw.Divider(color: fontColor),
      ],
    );
  }
}
