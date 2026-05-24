import 'dart:typed_data';

import 'package:pdf/widgets.dart' as pw;
import 'package:save_points_pdf_templates/pdf/core/extensions/date_table.dart';
import 'package:save_points_pdf_templates/pdf/core/extensions/header_divider.dart';
import 'package:save_points_pdf_templates/pdf/core/extensions/image.dart';
import 'package:save_points_pdf_templates/pdf/core/extensions/pdf_qr.dart';
import 'package:save_points_pdf_templates/pdf/core/extensions/spacing.dart';
import 'package:save_points_pdf_templates/pdf/core/extensions/strings_to_column.dart';
import 'package:save_points_pdf_templates/pdf/core/extensions/text.dart';
import 'package:save_points_pdf_templates/pdf/core/widgets/pdf_customer_to_widget.dart';
import 'package:save_points_pdf_templates/pdf/core/widgets/pdf_summery_payment.dart';
import 'package:save_points_pdf_templates/pdf/models/pdf_sale_invoice_model.dart';
import 'package:save_points_pdf_templates/pdf/templates/base_template.dart';

class SaleInvoiceTemplate extends BaseTemplate<PdfSaleInvoiceModel> {
  SaleInvoiceTemplate({
    required super.data,
    required super.pdfConfig,
    required super.headers,
    this.logo,

    /// super properties
    super.qrCode,
  });

  final Uint8List? logo;

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
              [company!.name, company!.phone].toColumn(),
            ],
          ),

        /// divier
        data.type.arabic.headerDivider(fontColor: fontColor),

        // space
        24.0.height(),

        /// English type
        data.type.english.text(
          fontSize: 24.0,
          fontWeight: .bold,
          color: fontColor,
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
        // DateTime.now().toFormattedString().dateTime(),
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
      headerBackgroundColor: pdfConfig.dataTableHeaderBackgroundColor,
      cellHeight: pdfConfig.dataTableCellHeight,
      belowBody: data.toSummeryPaymentWidget(config: pdfConfig),
      // borderColor: pdfConfig.dataTableBorderColor,
    );
  }

  @override
  pw.Widget footer(pw.Context context) {
    return pw.Container();
    return data.toSummeryPaymentWidget(config: pdfConfig);
  }
  // pw.Widget footer(pw.Context context) => data.toSummeryPaymentWidget();

  List<List<String>> getItems() {
    return items.map((e) {
      return [
        e.title,
        '${e.qty}',
        '${e.price} $currency',
        '${e.total} $currency',
      ];
    }).toList();
  }
}
