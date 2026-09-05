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
- `BaseTemplate.fileName`, which decides what a document is saved or shared
  as. The preview page and the headless entry points now both ask it, instead
  of each writing the rule out for itself.
- **`PaymentVoucherTemplate` and `PaymentVoucherModel`.** `PdfInvoiceType` has
  offered `paymentVoucher` since the first release with only the receipt side
  built. Both now share `VoucherTemplate` and `PdfVoucherModel` and differ
  only in what the two parties are called, so a book of receipts and a book of
  payments look like one set.
- `dueDate` on itemized documents, printed beside the issue date. An unpaid
  document past its due date says `OVERDUE` rather than `UNPAID`; judge it
  against a fixed day with `isOverdueOn` when you need a stable render.
- Screenshots — in the README and as pub.dev cards. It is a package about how
  documents look and it had none.
- `CONTRIBUTING.md`, covering how a rendering package is tested.
- **Discount and tax as a rate.** `PdfInvoiceItemModel.taxRate` and
  `discountRate` work the amount out for the line, and
  `PdfItemizedInvoiceModel.taxRate` sets one rate for the whole document
  without repeating it. Absolute amounts still work; a rate wins when both are
  given.
- **A tax breakdown by rate** — `taxBreakdown`, `PdfTaxBand` and
  `PdfSections.taxBreakdown`. A GCC tax invoice that mixes rates has to show
  what was taxed at each; one total headed `Tax` does not. A document charged
  at a single rate names it on the tax line instead — one or the other, never
  both.
- `PdfConfig.currencyDecimals` and `PdfFormatters.decimals`. Two decimals were
  hard-coded, which is wrong for the Kuwaiti and Bahraini dinar (three) and
  the yen (none).
- **`QuotationTemplate`** — priced lines that are offered, not owed: no paid
  figure, no balance due, and a stamp that says whether the offer is still
  valid rather than whether it is paid.
- **`DeliveryNoteTemplate`** — the item table with every trace of money taken
  out. `ItemizedInvoiceTemplate.showPricing` is what makes that possible, so a
  price-free document is now a two-line subclass rather than impossible.
- **`StatementOfAccountTemplate`** — opening balance, movements, a running
  balance column and what is owed at the end. The balances are derived from
  the entries rather than supplied alongside them, so the column a reader
  checks the statement by cannot disagree with the rows above it.
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
- The page footer follows the document's language. `Page 1 / 2` was hard-coded
  in English and sat under every Arabic document.
- `PdfSections.documentHeader` no longer swaps the two titles by direction.
  That was right while the templates chose the language inline; with
  `PdfLabels` doing it, swapping again turned an Arabic purchase order back
  into `Purchase Order` with Arabic underneath. It now prints what it is
  handed, and the label set decides.
- A line break inside a value survives `PdfUi.bidiText`. Runs are trimmed
  before layout, so a mixed-script value lost its breaks and reflowed into one
  line while a single-script one kept them — an item description sat under its
  title in English and beside it in Arabic.

- **`PdfLabels`** — every word the package prints, as a named getter. The
  templates switched between two hard-coded strings inline, which made the
  package bilingual by construction: a third language meant editing every
  template. It is now a subclass, and that covers the document's own name, so
  a French invoice is not headed `Sales Invoice` in the page, in the PDF's
  `/Title` or in the file name. `PdfArabicLabels` is the Arabic set, chosen
  automatically by a right-to-left config whose font can draw it.
- **A watermark behind the page** — `BaseTemplate.watermark` and `background`,
  drawn by `PdfUi.watermark`. A printout carries no metadata to say it is a
  copy, and a diagonal mark is the only thing that survives a photocopier.
  `PdfLabels` names `COPY`, `DRAFT`, `ORIGINAL` and `DUPLICATE`.
- **Carried-forward totals** — `PdfCarryForward` and
  `PdfDataTable.buildPaginated`. A long table breaks between rows and a reader
  who turns the page cannot tell what the lines above added up to; each page
  now closes with `Carried forward` and the next opens with the same figure.
  The split is given rather than measured, and deliberately so: how many rows
  fit depends on the font's metrics, and a carried line placed by a guess
  would claim a total for rows that are not above it.
- `PdfGenerator.generate(compress: false)`, for output whose text can be
  searched in the bytes.
- **`PurchaseOrderTemplate`** — priced lines addressed to a supplier, with a
  delivery address and an expected date. Prices, because the supplier is being
  told what you expect to pay; no balance, because nothing is owed until they
  invoice you.
- **`CreditNoteTemplate` and `DebitNoteTemplate`**, over a shared
  `AdjustmentNoteTemplate`. Both name the invoice they correct and the reason,
  above the signatures rather than after them — an auditor reads why before
  somebody signs. Neither field is optional: a note that names neither cannot
  be reconciled.
- **`PayslipTemplate`** — earnings beside deductions rather than one column of
  signed numbers, because that is the comparison an employee actually makes.
  Net pay is computed; a slip whose net does not reconcile is a dispute.
- **`ThermalReceiptTemplate`** and `PdfTheme.thermal()` — an 80mm or 57mm till
  roll. Not a narrower invoice: one column, no table, nothing boxed (a thermal
  head prints a fill as a solid black band), and each line over two rows. A
  roll has no height, so `PdfGenerator` puts it on a single page that stretches
  instead of asking `MultiPage` to paginate what has no page to fill.
- `ItemizedInvoiceTemplate.extraBlocks`, for a block between the notes and the
  signatures.
- **`ZatcaQr`** — the QR payload a Saudi simplified tax invoice must carry.
  Phase 1 is five fields in TLV form, Base64 encoded, and `qrCode` took a
  string, so every caller was building the byte layout themselves. `forInvoice`
  reads the values off the config and the model; `decode` reads a payload back,
  because the only way to be sure a QR is right is to decode it.

  No field may exceed 255 bytes, the length being one byte — and an Arabic
  name costs two bytes a letter, which puts a real company name within reach.
  It throws rather than truncating: a cut-short payload still scans and is
  rejected months later.

  Phase 2 is not here. The cryptographic stamp, the certificate obtained by
  registering with the authority, the UBL document and the call to ZATCA's
  service do not belong in a package that lays out PDFs; the tags are carried
  through if you compute them elsewhere.
- **Amounts spelled out in words** — `PdfAmountInWords` with an English and an
  Arabic speller, `PdfCurrencyWords` for how a currency is said, and
  `PdfConfig.spellAmount`. A voucher states its amount twice because a figure
  can be altered with a pen and a sentence cannot, and both vouchers now fill
  the words in when the caller supplies none.

  The Arabic speller inflects the number rather than approximating it: three
  to ten take the opposite gender to the noun they count, two is a dual, and a
  scale word goes accusative past eleven — but not after a round hundred,
  which turns on the last element of the count rather than its size. `مائة ألف`
  and `مائة وخمسة وعشرون ألفاً` are both right; reading the whole count instead
  writes `مائة ألفاً`.

### Removed

- `PdfUi.money`'s `alignment` argument, which silently did nothing: a row
  shrunk to its children has no free space to align them in. The amount and
  its currency are one unit; where that unit sits is the surrounding widget's
  business.
- `PdfDataTable.buildHeaderOnly`, which duplicated what the header row's own
  `repeat` already does on every page.

### Notes

- The README's code blocks are compiled and run by
  `test/readme_examples_test.dart`. Documentation rots quietly; the analyzer
  now reads it too.
- Four canonical documents are now held by golden tests — an invoice in each
  direction, a voucher and a till receipt. The rest of the suite asserts facts
  somebody thought to assert; nothing in it noticed a margin moving by a
  point, which in a package about how documents look is the gap that matters.

- `PdfInvoiceType` documents which of its types have a template built around
  them and which are labels to put on a layout that already fits. Four have
  their own; a quotation or a credit note goes through the itemized layout by
  passing the type, and a statement of account through `ListStringsTemplate`.

- `PdfUi`, `PdfSections` and `PdfPreviewPage` are covered by tests for the
  first time. Several primitives are used by no template in the package —
  which is precisely why nothing would have noticed them breaking.
- The layout is now covered by tests that read the drawn output — glyph
  positions in the page's content stream — rather than the widget tree, since
  the tree is identical in both directions and it is the renderer that decides
  what ends up on the right.
- The example app now uses IBM Plex Sans Arabic. The renderer asks a font for
  the legacy Arabic Presentation Forms-B codepoints, and most Google Fonts
  Arabic families — Cairo and Tajawal among them — leave those shapes to
  OpenType and never map the block, so a word-final `ي` after `ر`, `ا`, `د`,
  `و` or `ز` is dropped: `المتبقي` printed as `المتبق`. It is a property of
  how the font is built, not of the package; see Troubleshooting in the README.

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
