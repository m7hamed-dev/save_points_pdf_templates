import 'package:save_points_pdf_templates/pdf/pdf_config/pdf_config.dart';
import 'package:save_points_pdf_templates/pdf/pdf_config/pdf_theme.dart';

/// Arabic-first preset: right-to-left layout, `SAR` currency and the Cairo
/// font family, which the *app* must declare as an asset.
///
/// ```yaml
/// flutter:
///   assets:
///     - assets/fonts/Cairo-Regular.ttf
///     - assets/fonts/Cairo-Bold.ttf
/// ```
///
/// ```dart
/// final config = CairoPdfFontConfig(company: myCompany);
/// ```
///
/// Point [PdfConfig.fontPath] somewhere else to use Tajawal, Almarai or any
/// other TTF — nothing here is Cairo-specific beyond the default paths.
class CairoPdfFontConfig extends PdfConfig {
  CairoPdfFontConfig({
    super.fontPath = 'assets/fonts/Cairo-Regular.ttf',
    super.boldFontPath = 'assets/fonts/Cairo-Bold.ttf',
    super.logoPath,
    super.company,
    super.currency = 'SAR',
    super.locale = 'ar',
    super.theme = const PdfTheme.modern(),
    super.pageFormat,
    super.strictFonts,
    super.logoSize,
  });
}
