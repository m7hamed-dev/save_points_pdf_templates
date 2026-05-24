import 'dart:typed_data';

import 'package:pdf/widgets.dart' as pw;
import 'package:save_points_pdf_templates/pdf/core/extensions/date_table.dart';
import 'package:save_points_pdf_templates/pdf/core/extensions/header_divider.dart';
import 'package:save_points_pdf_templates/pdf/core/extensions/image.dart';
import 'package:save_points_pdf_templates/pdf/core/extensions/pdf_qr.dart';
import 'package:save_points_pdf_templates/pdf/core/extensions/spacing.dart';
import 'package:save_points_pdf_templates/pdf/core/extensions/text.dart';
import 'package:save_points_pdf_templates/pdf/core/widgets/pdf_company_to_widget.dart';
import 'package:save_points_pdf_templates/pdf/core/widgets/pdf_customer_to_widget.dart';
import 'package:save_points_pdf_templates/pdf/models/pdf_expenses_model.dart';
import 'package:save_points_pdf_templates/pdf/templates/base_template.dart';

class ExpensesInvoiceTemplate extends BaseTemplate<PdfExpensesInvoiceModel> {
  ExpensesInvoiceTemplate({
    required super.data,
    required super.pdfConfig,
    required super.headers,
    // super.company,
    super.title,

    /// Super properties
    super.qrCode,
    super.primaryColor,
  });

  /// local variables
  late final fontColor = pdfConfig.primaryColor;
  late final items = data.items;
  late final currency = pdfConfig.currency;
  late final company = pdfConfig.company;

  @override
  pw.Widget header(pw.Context context, {Uint8List? logo}) {
    return pw.Column(
      children: [
        if (logo != null && company != null)
          pw.Row(
            children: [
              logo.toImage(size: 40.0),
              6.0.width(),
              company!.toCompanyWidget(),
            ],
          ),

        /// divier
        data.type.arabic.headerDivider(fontColor: primaryColor),

        // space
        24.0.height(),

        /// English type
        data.type.english.text(
          fontSize: 24.0,
          fontWeight: .bold,
          color: primaryColor,
          textAlign: .center,
        ),
        pw.Divider(color: fontColor, thickness: .2),

        8.0.height(),

        // data.id.text(fontSize: 18.0),
        pw.Row(
          children: [
            /// qr code
            qrCode.qrCode(qrCodeSize: 50.0),

            /// customer info
            pw.Expanded(child: data.customer.toCustomerWidget()),
          ],
        ),

        8.0.height(),
        pw.Divider(color: fontColor, thickness: .2),

        8.0.height(),

        /// date and time
        DateTime.now().toIso8601String().text(
          fontSize: 16.0,
          color: primaryColor,
        ),
        16.0.height(),
        // pw.Divider(color: fontColor),
      ],
    );
  }

  @override
  pw.Widget body(pw.Context context) {
    final items = getItems();
    return PdfDateTableExtension.customDateTable(
      headers: headers,
      data: items,
      borderWidth: pdfConfig.dataTableBorderWidth,
      borderColor: primaryColor,
      headerHeight: pdfConfig.dataTableHeaderHeight,
      headerBackgroundColor: primaryColor,
      cellHeight: pdfConfig.dataTableCellHeight,
      // borderColor: pdfConfig.dataTableBorderColor,
      // headerBackgroundColor: pdfConfig.dataTableHeaderBackgroundColor,
    );
  }

  @override
  pw.Widget footer(pw.Context context) {
    /// total
    final total = 'Total : ${data.total} $currency';

    ///
    return pw.Row(
      children: [
        total.textWithBackgroundColor(color: fontColor, padding: 12.0),
        8.0.width(),
        'Paid : ${data.tax} $currency'.textWithBackgroundColor(
          color: fontColor,
          padding: 12.0,
        ),
      ],
    );
  }

  List<List<String>> getItems() {
    return items.map((e) {
      return [
        e.title,
        '${e.qty}',
        '${e.price}  $currency',
        '${e.total} $currency',
      ];
    }).toList();
  }
}
