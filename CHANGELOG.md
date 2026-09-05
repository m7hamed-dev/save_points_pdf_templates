## 0.1.0

First release.

Fourteen printable business documents for Flutter, rendered to PDF, with
Arabic and right-to-left treated as a first case rather than a translation.

### Documents

Sales invoices, expense records, a minimal invoice, quotations, purchase
orders, delivery notes, credit and debit notes, receipt and payment vouchers,
statements of account, payslips, 80 mm and 57 mm till receipts, and a
free-form table for anything with no model of its own.

Each takes a typed model and works out what it can: totals from the lines,
tax from a rate, a running balance from the movements above it, net pay from
earnings less deductions. Pass an explicit figure only to reproduce one
computed elsewhere.

### Arabic and right-to-left

`locale: 'ar'` mirrors the whole document — masthead, column order, alignment
and the totals panel. Mixed Arabic and Latin values are laid out one script
run at a time, so `حاسب محمول HP ProBook` is not printed with the Latin half
leading. Letter spacing never reaches Arabic, which would pull the connected
script apart.

Every word the package prints is a named getter on `PdfLabels`. English and
Arabic ship; any other language is a subclass, including the document's own
name. Amounts spell out in words for a voucher, with the gender agreement
Arabic needs — three to ten take the opposite gender to the noun they count.

Nothing Arabic is printed that the configured font cannot draw: a Latin-only
face falls the labels, the dates and the spelled amounts back to English
rather than printing rows of blank boxes, and the layout still mirrors.

### Design

Three presets — `modern`, `classic`, `minimal` — meant as three documents
rather than three palettes, plus `thermal` for a roll. Every colour, size and
spacing value is a token on `PdfTheme`; nothing is hard-coded in a template.

`PdfUi` primitives and `PdfSections` blocks are public, so a template of your
own is assembled from the same parts rather than styled from scratch.

### Money and tax

Discount and tax as an amount or a rate, per line or per document, with a
breakdown by rate for a GCC tax invoice that mixes them. Decimal places follow
the currency — three for KWD and BHD, none for JPY. Due dates make a document
say `OVERDUE`. Long tables can close each page with a carried-forward total.

The ZATCA Phase 1 QR payload is built for you from values the invoice already
holds. Phase 2 — the cryptographic stamp, the certificate obtained by
registering with the authority, the UBL document and the call to ZATCA's
service — is deliberately absent, since none of it belongs in a package that
lays out PDFs; its tags are carried through if you compute them elsewhere.

### Before you adopt it

**The package ships no fonts.** The built-in PDF fonts are Latin-only, so
Arabic needs a TTF from your app. Pick one that carries the legacy Arabic
Presentation Forms-B block — IBM Plex Sans Arabic and Noto Naskh Arabic do.
Most Google Fonts Arabic families, Cairo and Tajawal among them, leave those
shapes to OpenType and never map that block, and the renderer then drops a
word-final `ي` after `ر`, `ا`, `د`, `و` or `ز`. See Troubleshooting in the
README.

**The API is young.** It has not been through anyone else's hands yet, and
0.x says so: expect shapes to move before 1.0.
