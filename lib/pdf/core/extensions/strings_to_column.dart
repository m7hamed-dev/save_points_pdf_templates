import 'package:pdf/widgets.dart' as pw;
import 'package:save_points_pdf_templates/pdf/core/extensions/text.dart';

/// Extension to convert a list of strings to a column
extension PdfColumnExtension on List<String> {
  /// Convert a list of strings to a column
  ///
  /// @returns A column with the strings as children
  pw.Column toColumn() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        ...map((e) {
          return pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 2.0),
            child: e.text(),
          );
        }),
      ],
    );
  }
}
