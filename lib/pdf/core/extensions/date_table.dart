import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:save_points_pdf_templates/pdf/core/extensions/text.dart';

// typedef PdfDateTableType = List<List<String>>;

class PdfDateTableExtension {
  static pw.Table dateTable({
    required List<String> headers,
    required List<List<String>> data,

    /// Header
    double borderWidth = 0.5,
    PdfColor borderColor = PdfColors.grey300,
    double headerHeight = 40.0,
    PdfColor headerBackgroundColor = PdfColors.grey100,
    double fontSize = 12,

    /// Cell
    double cellHeight = 40.0,
  }) {
    /// Table
    return pw.Table(
      // border: pw.TableBorder.symmetric(
      //   inside: pw.BorderSide.none,
      //   outside: pw.BorderSide.none,
      // ),
      columnWidths: {
        for (var i = 0; i < headers.length; i++) i: const pw.FlexColumnWidth(),
      },
      defaultColumnWidth: const pw.FlexColumnWidth(),
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(border: pw.Border.symmetric()),
          children: [
            ...headers.map((header) {
              return pw.Container(
                height: headerHeight,
                alignment: pw.Alignment.center,
                decoration: pw.BoxDecoration(
                  border: const pw.Border.symmetric(),
                  // border: pw.Border.all(color: borderColor, width: borderWidth),
                  color: headerBackgroundColor,
                ),
                child: header.text(
                  fontSize: 14.0,
                  fontWeight: pw.FontWeight.bold,
                  textAlign: pw.TextAlign.center,
                  color: PdfColors.white,
                ),
              );
            }),
          ],
        ),

        /// Body
        ...data.map(
          (item) => pw.TableRow(
            decoration: const pw.BoxDecoration(
              border: pw.Border.symmetric(
                horizontal: pw.BorderSide(width: 0.2, color: PdfColors.grey300),
                vertical: pw.BorderSide(width: 0.3, color: PdfColors.grey300),
              ),
            ),
            children: [
              ...item.map((cell) {
                return pw.Container(
                  height: cellHeight,
                  alignment: pw.Alignment.center,
                  // decoration: pw.BoxDecoration(
                  //   border: pw.Border.all(color: PdfColors.grey300, width: 0.2),
                  // ),
                  child: cell.text(
                    fontSize: 14.0,
                    textAlign: pw.TextAlign.center,
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget customDateTable({
    required List<String> headers,
    required List<List<String>> data,

    pw.Widget? belowHeader,
    pw.Widget? belowBody,

    /// Header
    double borderWidth = 0.5,
    PdfColor borderColor = PdfColors.grey300,
    double headerHeight = 40.0,
    PdfColor headerBackgroundColor = PdfColors.grey100,
    double fontSize = 12,

    /// Cell
    double cellHeight = 40.0,
  }) {
    /// Table
    return pw.Column(
      children: [
        /// Header
        pw.Row(
          children: [
            ...headers.map((header) {
              return pw.Expanded(
                child: pw.Container(
                  height: headerHeight,
                  alignment: pw.Alignment.center,
                  decoration: pw.BoxDecoration(
                    border: const pw.Border.symmetric(),
                    // border: pw.Border.all(color: borderColor, width: borderWidth),
                    color: headerBackgroundColor,
                  ),
                  child: header.text(
                    fontSize: 14.0,
                    fontWeight: pw.FontWeight.bold,
                    textAlign: pw.TextAlign.center,
                    color: PdfColors.white,
                  ),
                ),
              );
            }),
          ],
        ),

        /// Body
        ...data.map((cells) {
          return pw.Row(
            children: [
              ...cells.map((cell) {
                return pw.Expanded(
                  child: pw.Container(
                    decoration: const pw.BoxDecoration(
                      border: pw.Border.symmetric(
                        horizontal: pw.BorderSide(
                          width: 0.2,
                          color: PdfColors.grey300,
                        ),
                        // vertical: pw.BorderSide(
                        //   width: 0.3,
                        //   color: PdfColors.grey300,
                        // ),
                      ),
                    ),
                    height: cellHeight,
                    alignment: pw.Alignment.center,
                    child: cell.text(
                      fontSize: 14.0,
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                );
              }),
            ],
          );
        }),

        /// Below Body
        ?belowBody,
      ],
    );
  }
}
