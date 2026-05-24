import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:save_points_pdf_templates/pdf/models/base/pdf_party_model.dart';
import 'package:save_points_pdf_templates/pdf/pdf_config/pdf_config.dart';

class CairoPdfFontConfig implements PdfConfig {
  CairoPdfFontConfig();

  @override
  String get logoPath => '';

  @override
  pw.Font? font;

  @override
  Future<void> init() async {
    /// init the font
    if (font == null) {
      final bytes = await rootBundle.load(fontPath);
      font = pw.Font.ttf(bytes);
    }

    if (logoPath.isNotEmpty) return;
  }

  @override
  String get fontPath => 'assets/fonts/Tajawal/Tajawal-Regular.ttf';

  @override
  String get currency => 'SAR';

  @override
  PdfColor get primaryColor => PdfColors.pink;

  @override
  double get dataTableBorderWidth => 0.5;

  @override
  double get dataTableHeaderHeight => 40.0;

  @override
  double get dataTableCellHeight => 40.0;

  @override
  PdfColor get dataTableBorderColor => PdfColors.grey300;

  @override
  PdfColor get dataTableHeaderBackgroundColor => PdfColors.pink;

  @override
  PdfPartyModel? get company => const PdfPartyModel(
    name: 'mohamed Points',
    address: '123 Main St, Anytown, USA',
    phone: '123-456-7890',
    email: 'info@mohamed.com',
    taxNumber: '1234567890',
  );
}
