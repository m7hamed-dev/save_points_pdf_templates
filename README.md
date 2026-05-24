# save_points_pdf_templates

Production-ready Flutter package for rendering and printing business documents — invoices, receipts, vouchers, inventory reports, and POS output — with **Arabic / RTL** support and thermal ESC/POS output.

[![pub package](https://img.shields.io/pub/v/save_points_pdf_templates.svg)](https://pub.dev/packages/save_points_pdf_templates)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

---

## Why this package?

Building printable documents in Flutter usually means wiring `pdf`, `printing`, fonts, locales, and printer transports yourself. This package gives you:

- **Typed domain models** for common business documents (sales/purchase invoices, receipts, vouchers, stock moves, labels, custom layouts).
- **Template engine** that renders to **PDF** or **ESC/POS** from the same document model.
- **Arabic-first layout** with RTL, bilingual fields (`name` / `nameAr`), and explicit font injection (you provide TTF files).
- **Print orchestration** via `PrintService` — preview, system print dialog, network/bluetooth thermal printers.
- **Clean architecture** — domain, application, infrastructure, and presentation layers you can extend.

---

## Features

| Area | Details |
|------|---------|
| **Documents** | Sales & purchase invoices, receipts, expense/revenue vouchers, inventory reports, stock documents, product labels, custom documents |
| **Output** | PDF (A4, A5, Letter, 58/80 mm roll) and ESC/POS thermal |
| **Templates** | `ModernArabicTemplate` (RTL Arabic), `CompactEnglishTemplate` (LTR English), custom presets via `ContextualPrintTemplate` |
| **Layout** | `PdfLayoutConfig` margins & compact density; per-print toggles on `TemplateContext` / `PrintOptions` |
| **Arabic / RTL** | Bilingual fields (`name` / `nameAr`), app-provided Arabic + Latin TTF fonts |
| **Codes** | QR and Code 128 barcodes (ZATCA-style invoice QR, SKU barcodes, etc.) |
| **Money & tax** | `Money` value type, line-level tax/discount, document totals |
| **Printers** | System PDF share/print, network ESC/POS, Bluetooth thermal (platform-dependent) |
| **Preview** | Native PDF preview via `printing` |
| **Validation** | Document validation with typed `PrintFailure` / `PrintResult` |

---

## Installation

Add to `pubspec.yaml`:

```yaml
dependencies:
  save_points_pdf_templates: ^0.1.0
```

Or use a path/git dependency while developing:

```yaml
dependencies:
  save_points_pdf_templates:
    path: ../save_points_pdf_templates
```

Then:

```bash
flutter pub get
```

**Requirements:** Dart SDK `^3.11.5`, Flutter `>=3.16.0`.

---

## Fonts (required — you provide them)

This package **does not ship font files**. PDF rendering needs four TTF faces (Arabic regular/bold + Latin regular/bold). Each app that installs the package must add them.

### Step 1 — Download fonts

Use [Noto Sans Arabic](https://fonts.google.com/noto/specimen/Noto+Sans+Arabic) and [Noto Sans](https://fonts.google.com/noto/specimen/Noto+Sans) (or any Unicode TTF that covers Arabic and Latin), then place in your project:

```
your_app/
  assets/fonts/
    NotoSansArabic-Regular.ttf
    NotoSansArabic-Bold.ttf
    NotoSans-Regular.ttf
    NotoSans-Bold.ttf
```

### Step 2 — Declare in your app `pubspec.yaml`

```yaml
flutter:
  assets:
    - assets/fonts/NotoSansArabic-Regular.ttf
    - assets/fonts/NotoSansArabic-Bold.ttf
    - assets/fonts/NotoSans-Regular.ttf
    - assets/fonts/NotoSans-Bold.ttf
```

### Step 3 — Load and pass on every print

```dart
const fontPaths = PdfFontAssetPaths(
  arabicRegular: 'assets/fonts/NotoSansArabic-Regular.ttf',
  arabicBold: 'assets/fonts/NotoSansArabic-Bold.ttf',
  latinRegular: 'assets/fonts/NotoSans-Regular.ttf',
  latinBold: 'assets/fonts/NotoSans-Bold.ttf',
);

final fonts = await PdfFontSet.loadFromAssets(fontPaths);
```

See [`example/lib/app_fonts.dart`](example/lib/app_fonts.dart) for a copy-paste pattern.

---

## Quick start

### 1. Initialize at app launch

```dart
import 'package:flutter/widgets.dart';
import 'package:save_points_pdf_templates/save_points_pdf_templates.dart';

late final PdfFontSet appFonts;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  appFonts = await PdfFontSet.loadFromAssets(const PdfFontAssetPaths(
    arabicRegular: 'assets/fonts/NotoSansArabic-Regular.ttf',
    arabicBold: 'assets/fonts/NotoSansArabic-Bold.ttf',
    latinRegular: 'assets/fonts/NotoSans-Regular.ttf',
    latinBold: 'assets/fonts/NotoSans-Bold.ttf',
  ));
  await DocumentDateFormatter.warmUp();

  runApp(const MyApp());
}
```

### 2. Build a document

```dart
final invoice = SalesInvoice(
  documentId: 'INV-2026-0042',
  issuedAt: DateTime.now(),
  company: const CompanyInfo(
    name: 'Save Points Trading',
    nameAr: 'شركة نقاط الحفظ للتجارة',
    address: 'King Fahd Rd, Riyadh',
    addressAr: 'طريق الملك فهد، الرياض',
    taxNumber: '300000000000003',
  ),
  customerName: 'Ahmed Ali',
  customerNameAr: 'أحمد علي',
  lineItems: const [
    LineItem(
      description: 'Wireless Mouse',
      descriptionAr: 'فأرة لاسلكية',
      quantity: 2,
      unitPrice: Money(75),
      taxRate: 15,
    ),
  ],
  subtotal: const Money(150),
  taxTotal: const Money(22.5),
  grandTotal: const Money(172.5),
  zatca: ZatcaInvoiceData(
    sellerName: 'Save Points Trading',
    vatRegistrationNumber: '300000000000003',
    timestamp: DateTime.now(),
    invoiceTotalWithVat: const Money(172.5),
    vatAmount: const Money(22.5),
    invoiceType: ZatcaInvoiceType.standard,
    buyerVatNumber: '310000000000001',
  ),
);
```

### 3. Preview or print

```dart
final printer = PrintService.create(fonts: appFonts);

// Open native PDF preview (context is optional for contextual templates)
await printer.print(
  invoice,
  template: const ModernArabicTemplate(),
  options: const PrintOptions(previewOnly: true),
);

// LTR compact English invoice
await printer.print(
  invoice,
  template: const CompactEnglishTemplate(),
  options: const PrintOptions(previewOnly: true),
);

// Send to system print dialog
await printer.print(
  invoice,
  template: const ModernArabicTemplate(),
);
```

When `fonts` are on `PrintService` and the template implements `ContextualPrintTemplate`, you can omit `context` — the service calls `buildContext` automatically.

Handle results explicitly:

```dart
final result = await printer.print(invoice, template: const ModernArabicTemplate());

result.fold(
  onSuccess: (_) => debugPrint('Printed'),
  onFailure: (e) => debugPrint('Print failed: ${e.message}'),
);
```

---

## Supported documents

| Model | Use case |
|-------|----------|
| `SalesInvoice` | Customer invoices, VAT, QR |
| `PurchaseInvoice` | Supplier bills |
| `Receipt` | POS / cash receipts |
| `ExpenseVoucher` / `RevenueVoucher` | Petty cash & income vouchers |
| `InventoryReport` | Stock valuation / movement summary |
| `StockDocument` | Transfers, adjustments |
| `ProductLabel` | Shelf / barcode labels |
| `CustomDocument` | Arbitrary title, sections, line items |

All implement `PrintableDocument` with shared fields: `documentId`, `issuedAt`, `company`, `lineItems`, totals, `notes` / `notesAr`, `qrPayload`, `barcodePayload`.

---

## Templates

Built-in presets live under `lib/src/templates/presets/`. Both ship a `buildContext` method and work with `PrintService` without a manual `TemplateContext` when `fonts` are configured.

| Template | ID | Direction | Best for |
|----------|-----|-----------|----------|
| `ModernArabicTemplate` | `modern_arabic` | RTL (`ar`) | Saudi/Gulf invoices, vouchers, full catalog |
| `CompactEnglishTemplate` | `compact_english` | LTR (`en`) | English invoices, receipts, purchase orders |

### `ModernArabicTemplate`

Default RTL template with Arabic UI labels (invoice title, column headers, totals, footer).

```dart
const template = ModernArabicTemplate(
  paperSize: PaperSize.a4, // or a5, letter, roll80, roll58
  locale: 'ar',            // use 'en' for English labels, still RTL
  theme: PdfPrintTheme(primaryHex: '#1565C0'),
);

await printer.print(invoice, template: template);
```

### `CompactEnglishTemplate`

LTR English layout with compact margins and no logo by default. Supports sales/purchase invoices, receipts, and custom documents.

```dart
const template = CompactEnglishTemplate(
  paperSize: PaperSize.a4,
  theme: PdfPrintTheme(primaryHex: '#37474F'),
  layout: PdfLayoutConfig.compact(),
  showLogo: true, // off by default
);

await printer.print(invoice, template: template);
```

Thermal PDF / ESC/POS uses `PdfLayoutConfig.thermal()` and 80 mm roll automatically in `renderEscPos`.

### Layout config (`PdfLayoutConfig`)

Controls PDF page margins and slightly smaller typography when `compact` is true.

| Preset | Margins (H × V) | `compact` |
|--------|-----------------|-----------|
| `PdfLayoutConfig()` | 40 × 36 | false |
| `PdfLayoutConfig.compact()` | 24 × 20 | true |
| `PdfLayoutConfig.thermal()` | 8 × 12 | true |

**On the template** (e.g. `CompactEnglishTemplate(layout: …)`).

**On the context**:

```dart
final context = const ModernArabicTemplate()
    .buildContext(invoice, fonts: appFonts)
    .copyWith(layout: PdfLayoutConfig.compact());
```

**Per print via `PrintOptions`** (merged by `PrintService`):

```dart
await printer.print(
  invoice,
  template: const ModernArabicTemplate(),
  options: const PrintOptions(
    previewOnly: true,
    layout: PdfLayoutConfig.compact(),
    showQr: false,
    showBarcode: false,
  ),
);
```

### PDF accent color (`PdfPrintTheme`)

Customize the primary accent used in PDFs (header bar, title band, table header, notes highlight). Default is Material blue `#1565C0`.

**On the template** (same color for every document):

```dart
const template = ModernArabicTemplate(
  theme: PdfPrintTheme(
    primaryHex: '#2E7D32',       // main accent (e.g. brand green)
    primaryLightHex: '#E8F5E9',  // optional; auto-lightened if omitted
  ),
);

final context = template.buildContext(invoice, fonts: appFonts);
```

**Per document** via `copyWith`:

```dart
final context = const ModernArabicTemplate()
    .buildContext(invoice, fonts: appFonts)
    .copyWith(
      theme: const PdfPrintTheme(primaryHex: '#6A1B9A'),
    );
```

| `PdfPrintTheme` field | Used for |
|-----------------------|----------|
| `primaryHex` | Header accent bar, table header background, title band border tone |
| `primaryLightHex` | Title band fill, notes box background (derived from primary when omitted) |

Use any `#RRGGBB` hex string. ESC/POS thermal output is unaffected (text-only).

Override individual labels:

```dart
final context = template
    .buildContext(invoice, fonts: fonts)
    .withLabels({'thanks': 'Thank you — شكراً'});
```

Or merge with `copyWith(labels: …)`.

Toggle visibility via `TemplateContext.copyWith`:

```dart
final context = template.buildContext(invoice, fonts: fonts).copyWith(
  showLogo: true,
  showQr: true,
  showBarcode: false,
  paperSize: PaperSize.a5,
  layout: PdfLayoutConfig.compact(),
);
```

### Custom templates

Implement `PrintTemplate` or extend `BasePrintTemplate` to reuse `PdfDocumentBuilder` / `EscPosDocumentBuilder`.

For presets with defaults, extend `ContextualPrintTemplate` so `PrintService` can call `buildContext`:

```dart
class MyTemplate extends ContextualPrintTemplate {
  const MyTemplate();

  @override
  String get id => 'my_template';

  @override
  String get name => 'My Template';

  @override
  TemplateContext buildContext(
    PrintableDocument document, {
    required PdfFontSet fonts,
  }) {
    return TemplateContext(
      document: document,
      fonts: fonts,
      locale: 'en',
      textDirection: TextDirection.ltr,
      layout: const PdfLayoutConfig.compact(),
    );
  }
}
```

Lower-level only (no auto context):

```dart
class MyTemplate extends BasePrintTemplate {
  // … same renderPdf delegation as above, but pass TemplateContext manually
}
```

---

## ZATCA / Saudi e-invoicing (Phase 1 QR)

[Saudi ZATCA](https://zatca.gov.sa) Phase 1 requires a **TLV-encoded, Base64** QR on tax invoices with five fields:

| Tag | Field |
|-----|--------|
| 1 | Seller name |
| 2 | VAT registration (15 digits) |
| 3 | Invoice date/time (ISO 8601) |
| 4 | Invoice total **with** VAT |
| 5 | VAT amount |

### Encode QR payload

```dart
final zatca = ZatcaInvoiceData(
  sellerName: company.name,
  vatRegistrationNumber: company.taxNumber!, // e.g. 300000000000003
  timestamp: invoice.issuedAt,
  invoiceTotalWithVat: invoice.grandTotal,
  vatAmount: invoice.taxTotal!,
  invoiceType: ZatcaInvoiceType.standard, // or simplified (B2C)
  buyerVatNumber: invoice.customerTaxNumber,
);

final qrBase64 = zatca.toQrBase64(); // pass to QR renderer
```

Or build from a [SalesInvoice](lib/src/domain/entities/documents/sales_invoice.dart):

```dart
final invoice = SalesInvoice(
  // ... line items, totals, company with taxNumber ...
  zatca: zatcaDataFromSalesInvoice(
    invoice,
    invoiceType: ZatcaInvoiceType.standard,
  ),
);

// PDF uses effectiveQrPayload = qrPayload ?? zatca.toQrBase64()
```

### PDF layout

When `SalesInvoice.zatca` is set, the template adds:

- Tax invoice type label (فاتورة ضريبية / مبسطة)
- Seller VAT (+ buyer VAT for standard invoices)
- ZATCA Phase 1 QR (scannable TLV, not a URL)

### Phase 2 QR (tags 6–9)

After your Fatoora / CSID backend signs the XML UBL invoice, pass the cryptographic fields:

| Tag | Field |
|-----|--------|
| 6 | Invoice hash (SHA-256 of signed XML, Base64) |
| 7 | ECDSA signature (Base64) |
| 8 | ECDSA public key (Base64) |
| 9 | ZATCA cryptographic stamp (Base64) |

```dart
final zatca = ZatcaInvoiceData(
  sellerName: company.name,
  vatRegistrationNumber: company.taxNumber!,
  timestamp: invoice.issuedAt,
  invoiceTotalWithVat: invoice.grandTotal,
  vatAmount: invoice.taxTotal!,
  invoiceType: ZatcaInvoiceType.standard,
  phase2: ZatcaPhase2Data(
    invoiceHash: signingResult.invoiceHashBase64,
    ecdsaSignature: signingResult.signatureBase64,
    ecdsaPublicKey: signingResult.publicKeyBase64,
    cryptographicStamp: signingResult.stampBase64,
  ),
);

// Automatically uses encodePhase2 when phase2.isComplete
final qrBase64 = zatca.toQrBase64();
```

Or attach Phase 2 when mapping from a sales invoice:

```dart
zatca: zatcaDataFromSalesInvoice(
  invoice,
  phase2: phase2FromBackend,
),
```

> **XML UBL generation and CSID onboarding** are not part of this package — only TLV QR encoding and PDF layout. Use your ZATCA SDK for signing; pass the resulting Base64 strings here.

---

## Save & share PDF

```dart
final bytes = await printer.previewBytes(
  invoice,
  template: const ModernArabicTemplate(),
  fonts: appFonts,
);

await PrintDocuments.sharePdf(bytes, filename: 'INV-2026-0042.pdf');
// or
await PrintDocuments.previewPdf(bytes, name: 'Invoice');
```

---

## Paper sizes & formats

| `PaperSize` | Typical use |
|-------------|-------------|
| `a4` | Standard invoices (default) |
| `a5` | Compact invoices |
| `letter` | US letter |
| `roll80` | 80 mm thermal PDF / ESC/POS |
| `roll58` | 58 mm thermal |

```dart
await printer.print(
  invoice,
  template: const ModernArabicTemplate(paperSize: PaperSize.roll80),
  options: const PrintOptions(format: RenderFormat.escPos),
);
```

---

## Printer connections

```dart
// PDF via system share sheet / print dialog (default)
const PrintOptions(connection: PrinterConnection.system());

// Network thermal (ESC/POS port 9100)
const PrintOptions(
  connection: PrinterConnection.network(host: '192.168.1.50'),
  format: RenderFormat.escPos,
);

// Bluetooth thermal
const PrintOptions(
  connection: PrinterConnection.bluetooth(deviceId: 'AA:BB:CC:DD:EE:FF'),
  format: RenderFormat.escPos,
);
```

Configure a default connection on the service:

```dart
final printer = PrintService.create(
  connection: const PrinterConnection.network(host: '192..168.1.50'),
);
```

---

## Arabic & locales

Pass fonts as described in [Fonts (required)](#fonts-required--you-provide-them). You can supply them via:

- `TemplateContext.fonts`
- `PrintService.create(fonts: …)`
- the `fonts:` argument on `print` / `preview`

Or build `PdfFontSet` directly from bytes (network, file picker, etc.):

```dart
final fonts = PdfFontSet(
  arabicRegular: arabicBytes,
  arabicBold: arabicBoldBytes,
  latinRegular: latinBytes,
  latinBold: latinBoldBytes,
);
```

### Bilingual fields

Use `*Ar` fields on entities for Arabic copy; the template picks the right string based on `TemplateContext.isRtl`:

| Field | Example |
|-------|---------|
| `CompanyInfo.nameAr` | Company name |
| `LineItem.descriptionAr` | Line description |
| `notesAr` | Footer notes |
| `customerNameAr` | Customer on invoices |

### Dates & numbers

- Dates respect `locale` (`ar` / `en`) after `DocumentDateFormatter.warmUp()`.
- Amounts render as Western digits with currency suffix, e.g. `516.35 SAR`.

---

## API overview

| Type | Role |
|------|------|
| `PrintService` | Main entry: `print`, `preview`, `previewBytes`, `showPreview` |
| `PrintOptions` | `previewOnly`, `format`, `paperSize`, `locale`, `layout`, `showLogo`, `showQr`, `showBarcode`, `connection` |
| `TemplateContext` | Per-render locale, direction, theme, layout, labels, QR/barcode/logo toggles |
| `PdfLayoutConfig` | PDF margins and compact typography |
| `ContextualPrintTemplate` | Presets with `buildContext` (used by `PrintService`) |
| `CompactEnglishTemplate` | LTR English compact preset |
| `ModernArabicTemplate` | RTL Arabic default preset |
| `TemplateEngine` | Low-level render to `PrintPayload` |
| `PrintPayload` | Raw PDF or ESC/POS bytes |
| `PrintResult<T>` | Success/failure with `PrintFailure` |
| `PdfFontSet` / `PdfFontAssetPaths` | Required TTF bytes (`loadFromAssets` or constructor) |
| `PdfPrintTheme` | PDF accent colors (`primaryHex`, optional `primaryLightHex`) |
| `ZatcaInvoiceData` / `ZatcaQrEncoder` | Saudi Phase 1 & 2 TLV QR (Base64) |
| `ZatcaPhase2Data` | Phase 2 cryptographic TLV fields |
| `zatcaDataFromSalesInvoice` | Map [SalesInvoice] → ZATCA fields |
| `PrintDocuments` | `sharePdf`, `previewPdf` helpers |
| `DocumentDateFormatter` | Locale-safe date formatting |

### Preview bytes without UI

```dart
final bytes = await printer.previewBytes(
  invoice,
  template: const ModernArabicTemplate(),
);
// Save or share bytes as application/pdf
```

### ESC/POS only

```dart
final payload = await printer.preview(
  receipt,
  template: const ModernArabicTemplate(),
  options: const PrintOptions(format: RenderFormat.escPos),
);
```

---

## Example app

A full demo catalog lives in [`example/`](example/). Every **code block in this README** is implemented as a runnable recipe you can trigger from the app.

```bash
cd example
flutter pub get
flutter run
```

| File | Role |
|------|------|
| [`example/lib/main.dart`](example/lib/main.dart) | App entry, catalog UI, README recipe runner |
| [`example/lib/app_fonts.dart`](example/lib/app_fonts.dart) | Font loading (README [Fonts](#fonts-required--you-provide-them)) |
| [`example/lib/readme_recipes.dart`](example/lib/readme_recipes.dart) | **All README snippets** — quick start, templates, ZATCA, share PDF, ESC/POS, printers |
| [`example/lib/my_template.dart`](example/lib/my_template.dart) | Custom `MyTemplate` from [Custom templates](#custom-templates) |
| [`example/lib/demo_data.dart`](example/lib/demo_data.dart) | Extra document catalog (invoices, vouchers, stock, labels) |

In the app:

- **README code examples** — one tile per README section (quick start, `PrintOptions`, ZATCA Phase 1/2, `previewBytes`, `sharePdf`, printer connections, etc.). Tap to run the same code as in the docs.
- **Catalog tiles** — additional document previews with per-case `template` / `options` / `context`.
- **Shortcut buttons** — Compact English sample and Modern Arabic green theme + layout overrides.

---

## Architecture

```
lib/
├── domain/           # Entities: invoices, line items, money
├── application/      # PrintService, PrintOptions
├── templates/        # Template engine, PDF/ESC builders, presets
├── infrastructure/   # Printer adapters (system, network, bluetooth)
├── presentation/     # PrintPreview
└── core/             # Failures, results, date formatting
```

Extend the package by adding document types in `domain`, new templates in `templates/presets`, or printer adapters in `infrastructure/printers/adapters`.

---

## Troubleshooting

| Issue | Fix |
|-------|-----|
| Arabic shows as boxes | Add Noto (or similar) TTFs to **your** app assets; pass `PdfFontSet` on every print |
| `TemplateRenderFailure` (fonts required) | `await PdfFontSet.loadFromAssets(...)` then pass `fonts:` / `context.fonts` |
| Unable to load font asset | Declare TTF paths in **your** `pubspec.yaml` `flutter.assets`, then full restart |
| `LocaleDataException` | Call `DocumentDateFormatter.warmUp()` at startup |
| Asset load error after `flutter clean` | Run `flutter pub get` in app **and** package; full restart (not hot reload) |
| `Courier has no Unicode support` log | Harmless internal barcode font warning; suppressed in current template for QR/Code128 captions |

---

## Dependencies

Uses [`pdf`](https://pub.dev/packages/pdf), [`printing`](https://pub.dev/packages/printing), [`intl`](https://pub.dev/packages/intl), [`barcode`](https://pub.dev/packages/barcode), and [`esc_pos_utils_plus`](https://pub.dev/packages/esc_pos_utils_plus).

---

## Printer integration

See [docs/PRINTERS.md](docs/PRINTERS.md) for network thermal, Bluetooth, and PDF share workflows.

---

## Contributing

Issues and pull requests are welcome at [github.com/savepoints/save_points_pdf_templates](https://github.com/savepoints/save_points_pdf_templates).

1. Fork the repo  
2. Create a feature branch  
3. Add tests in `test/`  
4. Run `flutter test` and `dart analyze`  
5. Open a PR  

---

## License

See [LICENSE](LICENSE) for details.
# save_points_pdf_templates
# save_points_pdf_templates
# save_points_pdf_templates
