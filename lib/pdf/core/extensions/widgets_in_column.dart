import 'package:pdf/widgets.dart' as pw;

/// Extension to convert a list of widgets to a column
extension PdfWidgetsInColumnExtension on List<pw.Widget> {
  /// Convert a list of widgets to a column
  ///
  /// @returns A column with the widgets as children
  pw.Column inColumn() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        ...map((e) {
          return pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 2.0),
            child: e,
          );
        }),
      ],
    );
  }
}
