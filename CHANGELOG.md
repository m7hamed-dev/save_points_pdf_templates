## 0.2.0

### Added

- ZATCA Phase 2 QR encoding (TLV tags 6–9: invoice hash, ECDSA signature, public key, stamp).
- `ZatcaPhase2Data`, `ZatcaQrPhase`, and `ZatcaQrEncoder.encodePhase2`.
- `PrintDocuments` — `sharePdf`, `previewPdf`, and payload helpers.
- GitHub Actions CI (format, analyze, test).

### Changed

- `ZatcaInvoiceData.toQrBase64()` uses Phase 2 when `phase2` is complete.
- Package no longer bundles fonts — apps provide TTF via `PdfFontSet.loadFromAssets`.
- `PdfPrintTheme` for customizable PDF accent colors.

## 0.1.0

- Initial release: document models, `ModernArabicTemplate`, PDF/ESC-POS, ZATCA Phase 1 QR.
