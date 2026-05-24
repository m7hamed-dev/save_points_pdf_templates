import 'dart:typed_data';

import 'package:pdf/widgets.dart' as pw;
import 'package:save_points_pdf_templates/pdf/core/extensions/date_table.dart';
import 'package:save_points_pdf_templates/pdf/core/extensions/header_divider.dart';
import 'package:save_points_pdf_templates/pdf/core/extensions/image.dart';
import 'package:save_points_pdf_templates/pdf/core/extensions/pdf_qr.dart';
import 'package:save_points_pdf_templates/pdf/core/extensions/spacing.dart';
import 'package:save_points_pdf_templates/pdf/core/extensions/text.dart';
import 'package:save_points_pdf_templates/pdf/core/extensions/widgets_in_column.dart';
import 'package:save_points_pdf_templates/pdf/core/widgets/pdf_company_to_widget.dart';
import 'package:save_points_pdf_templates/pdf/core/widgets/pdf_customer_to_widget.dart';
import 'package:save_points_pdf_templates/pdf/models/pdf_list_string_model.dart';
import 'package:save_points_pdf_templates/pdf/templates/base_template.dart';

class ListStringsTemplate extends BaseTemplate<PdfListStringsModel> {
  ListStringsTemplate({
    required super.data,
    required super.pdfConfig,
    required super.headers,

    /// super properties
    // super.company,
    super.qrCode,
  });

  /// local variables
  late final fontColor = pdfConfig.primaryColor;
  late final currency = pdfConfig.currency;
  late final company = pdfConfig.company;

  @override
  pw.Widget header(pw.Context context, {Uint8List? logo}) {
    return pw.Column(
      children: [
        /// divier
        // data.type.arabic.headerDivider(fontColor: fontColor),

        // space
        // 24.0.height(),

        /// English type
        data.type.english.headerDivider(
          fontSize: 24.0,
          fontWeight: .bold,
          fontColor: fontColor,
        ),

        // pw.Divider(color: fontColor, thickness: .2),
        8.0.height(),

        // data.id.text(fontSize: 18.0),
        pw.Row(
          children: [
            if (qrCode.isNotEmpty) qrCode.qrCode(qrCodeSize: 50.0),
            if (data.customer.name.isNotEmpty)
              pw.Expanded(child: data.customer.toCustomerWidget()),
          ],
        ),

        8.0.height(),
        pw.Divider(color: fontColor, thickness: .2),
        8.0.height(),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            /// title
            data.title.text(
              fontSize: 24.0,
              fontWeight: .bold,
              color: fontColor,
              textAlign: .center,
            ),
            [
              if (logo != null) logo.toImage(size: 40.0),
              if (company != null) company!.toCompanyWidget(),
              6.0.width(),
            ].inColumn(),
          ],
        ),
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
      // borderColor: pdfConfig.dataTableBorderColor,
      // belowBody: data.toSummeryPaymentWidget(config: pdfConfig),
    );
  }

  @override
  pw.Widget footer(pw.Context context) {
    return pw.Container();
    // return data.toSummeryPaymentWidget(config: pdfConfig);
  }
  // pw.Widget footer(pw.Context context) => data.toSummeryPaymentWidget();

  List<List<String>> getItems() {
    return data.items.map((e) {
      return e.map((e) => e).toList();
    }).toList();
  }
}
