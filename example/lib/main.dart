import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/src/widgets/font.dart' as pw;
import 'package:save_points_pdf_templates/save_points_pdf_templates.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class NotoSansArabicPdfFontConfig implements PdfConfig {
  NotoSansArabicPdfFontConfig();

  @override
  PdfPartyModel? get company => null;

  @override
  String get currency => 'SAR';

  @override
  PdfColor get dataTableBorderColor => PdfColors.black;

  @override
  double get dataTableBorderWidth => 1;

  @override
  double get dataTableCellHeight => 30;

  @override
  PdfColor get dataTableHeaderBackgroundColor => PdfColors.grey;

  @override
  double get dataTableHeaderHeight => 30;

  @override
  pw.Font? font;

  @override
  Future<void> init() async {
    if (font == null) {
      final bytes = await rootBundle.load(fontPath);
      font = pw.Font.ttf(bytes);
    }
  }

  @override
  String get logoPath => '';

  @override
  String get fontPath => 'assets/fonts/Tajawal/Tajawal-Regular.ttf';

  @override
  PdfColor get primaryColor => PdfColors.green;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // final pdfConfig = NotoSansArabicPdfFontConfig();
    return MaterialApp(home: PdfButtons());
  }
}
