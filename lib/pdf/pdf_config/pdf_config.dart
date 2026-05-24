import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:save_points_pdf_templates/pdf/models/base/pdf_party_model.dart';

abstract class PdfConfig {
  const PdfConfig({this.logoPath = '', this.company});
  Future<void> init();

  /// font path
  String get fontPath;
  pw.Font? get font;
  String get currency => 'SAR';

  /// logo
  final String logoPath;

  /// company
  final PdfPartyModel? company;

  /// font color
  PdfColor get primaryColor => PdfColors.black;

  /// DataTable Properties
  final double dataTableBorderWidth = 0.5;
  final double dataTableHeaderHeight = 40.0;
  final double dataTableCellHeight = 40.0;
  final PdfColor dataTableBorderColor = PdfColors.grey300;
  final PdfColor dataTableHeaderBackgroundColor = PdfColors.pink;
}
