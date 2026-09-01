## 0.2.1

### Changed

- Design pass across every template. Small labels are upper-cased and tracked,
  the item table header is a pale accent wash rather than a solid bar, the last
  column is set in bold, party and notes blocks are held by an accent bar
  instead of a filled box, and the masthead closes on a keyline.
- The area beside the totals panel is no longer blank: itemized templates print
  payment details there via `settlementLines` / `PdfSections.infoBlock`.
- Signatures print the role, the signatory's name and a dated line; receipt
  vouchers add a stamp area and no longer repeat the amount as a field.
- Page footers carry the document number alongside the issuer and page count.

### Added

- `PdfTheme`: `labelTracking`, `titleTracking`, `headerStyle`
  (`PdfTableHeaderStyle.soft` / `filled` / `underlined`), and the derived
  `accentSoft` / `accentMuted` tints with a public `PdfTheme.mix`.
- `PdfUi`: `microLabel`, `stamp`, `stampArea`, `accentBar`, `keyline`, and
  `letterSpacing` on `text`.
- `PdfSections.infoBlock`, and `names` on `signatures`.

### Fixed

- Letter spacing is dropped on any value containing right-to-left script.
  Tracking a connected script pulls it apart — `الوحدة` was rendering as
  `لوحدة ا` in Arabic table headers.
- The QR box beside a voucher's amount bar now matches its height exactly.

## 0.2.0

Reworked release. The public API changed substantially — see **Breaking** below.

### Fixed

- **The package was unusable through its own entry point.** The barrel exported
  templates but none of their models, so `PdfSaleInvoiceModel`,
  `PdfInvoiceType` and `SaleInvoiceTemplate` were all undefined for consumers.
  Everything public is now exported.
- **Long documents failed to render.** A table nested inside a column cannot be
  split, so any document past roughly 30 rows looped until
  `PdfTooBigPageException`. `BaseTemplate.body` now returns a list of blocks
  and the item table paginates with a repeated header row.
- **Receipt vouchers printed a widget's `toString()` where the date belonged**,
  and threw on a null date despite the field being optional.
- **Latin text inside Arabic came out reversed** — `HP ProBook` as `kooBorP PH`,
  `INV-2026-0042` as `2400-6202-VNI`. Values are split into script runs and each
  run keeps its own direction.
- Dead code in `SaleInvoiceTemplate`, a global mutable logo cache in
  `PdfGenerator` that leaked between documents, and a `Total`/`Paid` footer that
  printed the tax as the paid amount.
- Removed five declared-but-unused dependencies: `barcode`,
  `esc_pos_utils_plus`, `intl` is now actually used, `meta`, `qr`.

### Added

- `PdfTheme` design tokens — colors, type scale, spacing, table metrics — with
  `modern`, `classic` and `minimal` presets, `copyWith`, and `PdfMargin`.
- `PdfUi`: themed text, money, cards, badges, fields, QR and barcodes.
- `PdfSections`: masthead, party and meta cards, totals panel, notes,
  signatures, page footer with `Page n / m`.
- `PdfDataTable` with column specs, alignment, zebra striping and pagination.
- `PdfFormatters` — locale-aware money, quantity, percent and date formatting.
- `ItemizedInvoiceTemplate`, the shared layout behind the invoice templates.
- `PdfDocuments` — headless `bytes`, `share`, `printDocument`, `thumbnail`.
- Font fallback chain (`fallbackFontPaths`, `useBuiltInFallback`) and
  ready-made `pw.Font` injection for `PdfGoogleFonts`.
- `strictFonts` and `PdfAssetException` for loud failures on missing assets.
- Per-line `discount`, `tax`, `unit`, `sku` and `description`; computed
  `subtotal`, `totalDiscount`, `totalTax`, `total`, `paid`, `due`.
- A working example app covering every template, and 46 tests.

### Changed

- **Breaking:** `PdfConfig` is a concrete configurable class — no subclass
  needed. `CairoPdfFontConfig` is now a thin preset over it.
- **Breaking:** `BaseTemplate.body` returns `List<pw.Widget>`;
  `header`/`footer` are nullable and take only a `Context`.
- **Breaking:** `InvoiceType` renamed to `PdfInvoiceType` (deprecated alias
  kept) and its Arabic labels corrected — several were duplicated or wrong.
- **Breaking:** `PdfInvoiceItem` is now an alias of `PdfInvoiceItemModel`;
  `PdfInvoiceModel` extends the shared base and gains totals.
- **Breaking:** `total` on itemized models is optional and computed by default.
- `PdfPreviewPage` gained file name, share/print and page-format options.
- The `example/` app is tracked in version control again.

### Removed

- `PdfButtons` — a demo screen with hard-coded sample data that shipped inside
  the published package. It now lives in `example/`.
- The single-use `pdf/core/extensions/*` helpers, superseded by `PdfUi`.

## 0.1.0

- Initial release: document models, five templates, PDF generation.
