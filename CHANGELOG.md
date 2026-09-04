## 0.3.0

Every Arabic document the package produced was laid out back to front, and the
design has been rebuilt around type and space instead of boxes and rules.

### Changed

- **Redesigned every template.** The type scale carries the hierarchy — a
  larger, tighter document title, a new `displaySize` for the amount due, and
  more contrast down to the caption. Rules and fills gave way to whitespace:
  wider margins, taller rows, no zebra striping, no hairline between every
  summary line, and one accent keyline where there were three stacked bars.
- **The amount due is no longer a filled bar.** It sits at display size in the
  accent colour over a keyline, on invoices and on vouchers alike. A solid slab
  reads as a screen component, not as the figure a reader's eye should land on.
- **The three presets are three documents, not three palettes.** `modern`
  rations colour and lets space organise the page; `classic` rules everything,
  for a reader who expects ruled paper; `minimal` is ink on paper, with nothing
  between rows but their own height.
- Party details, the meta block and notes lost their boxes: a tracked label
  over its content, with the name or the value carrying the weight.
- `PdfTheme()` defaults moved with the design — `headerStyle` is now
  `underlined`, `showZebraStripes` is `false`, and the sizes, spacing and
  margins changed. A theme built with `copyWith` keeps whatever it set.
- The masthead leads with the label in the document's own language. An Arabic
  invoice whose largest type was `Sales Invoice` read as an English document
  that happened to be mirrored.
- `PdfBaseInvoiceModel.displayTitleAr` is empty when `title` is set. A custom
  title is one string in a language the model does not know, so it replaces the
  bilingual pair rather than being captioned by the type's Arabic.
- `PdfFormatters` falls back to English formatting when the font cannot draw
  Arabic, so `longDate` stops returning a month name that prints as blank
  boxes. Layout direction is unaffected.

### Added

- `PdfTheme.displaySize` and `PdfTheme.showRowRules`.
- `PdfColumnSpec.intrinsic`, which sizes a column to its content instead of a
  flex share.
- `PdfUi.display`, the type style behind the amount due.
- `BaseTemplate.documentName`.

### Fixed

- **Mixed Arabic and Latin text was printed back to front in Arabic
  documents.** The renderer already mirrors a `Row` and a `Wrap` on a
  right-to-left page; `PdfUi.bidiText` and `PdfUi.pair` reversed their children
  on top of that, which cancelled it out. `حاسب محمول HP ProBook` came out with
  the Latin run leading, and every document number printed as
  `INV-2026-0042 رقم`.
- `PdfUi.bidiText` folds a visual text alignment into the logical one a wrap
  expects, instead of pushing right-aligned content to the far side of its box.
- The item table emphasized the wrong column in Arabic. The bold column was
  anchored to the last visual cell, and mirroring moves the line amount to the
  head of the row — so the row number was set in bold and the amount was not.
- `PdfUi.pair` no longer draws outside its box. A row lays its children out at
  their natural width whatever the space, with no clipping, so a long value
  beside a long label overran the column it was in.
- Arabic column labels are no longer broken mid-word. A flex share tuned for
  `Unit` is too narrow for `الوحدة`, which is one unbreakable word.
- **A ready-made `font` stopped `PdfConfig.init` from loading anything else.**
  The logo, the bold face, the fallback fonts and the locale data were all
  skipped, and `strictFonts` never fired — the documented
  `font: await PdfGoogleFonts.cairoRegular()` path silently lost its logo and
  its Arabic dates.
- `PdfConfig.invalidate` restores fonts and logo bytes passed to the
  constructor instead of clearing them. Nothing records where they came from,
  so dropping them left the config permanently without a font.
- Two documents rendered at once no longer make `PdfConfig` load its assets
  twice and stack duplicate fallback fonts.
- **`PdfConfig.canRenderArabic` asks the font what it contains** rather than
  assuming any custom TTF can set Arabic. A Latin-only face such as Inter is a
  custom font too, and treating it as Arabic-capable printed a row of blank
  boxes under the title of every English document.
- `BaseTemplate.tr` falls back to English when the font cannot draw Arabic, the
  same guard `PdfUi.bilingual` already applied.
- **Documents had no name.** `BaseTemplate.title` is an optional override for
  the printed heading and is empty on almost every document, so the PDF's
  `/Title` was blank, the preview page's app bar was blank, and every shared
  file was called `document.pdf`. `documentName` falls back to the model's
  label and number.
- A long document type no longer pushes the issuer block out of the masthead.

### Notes

- The layout is now covered by tests that read the drawn output — glyph
  positions in the page's content stream — rather than the widget tree, since
  the tree is identical in both directions and it is the renderer that decides
  what ends up on the right.
- A font without the isolated Arabic presentation forms drops a word-final
  letter after `ر`, `ا`, `د`, `و` or `ز`. That is a property of the font file,
  not of the package; see Troubleshooting in the README.

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
