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
/// Point [PdfConfig.fontPath] somewhere else to use any other TTF — nothing
/// here is Cairo-specific beyond the default paths.
///
/// Worth knowing before you keep the default: Cairo, like most Google Fonts
/// Arabic families, leaves the contextual shapes to OpenType and does not map
/// the legacy Arabic Presentation Forms-B codepoints. The renderer asks for
/// those directly, so a word-final `ي` after `ر`, `ا`, `د`, `و` or `ز` is
/// dropped — `المتبقي` prints as `المتبق`. A family that ships the legacy
/// block, such as IBM Plex Sans Arabic or Noto Naskh Arabic, has no such gap;
/// the example app uses the former.
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
