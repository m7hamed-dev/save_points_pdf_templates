import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:save_points_pdf_templates/pdf/core/widgets/pdf_ui.dart';
import 'package:save_points_pdf_templates/pdf/models/base/pdf_party_model.dart';

/// The full-width blocks a business document is made of: the masthead, the
/// party cards, the totals panel, notes, signatures and the page footer.
///
/// Every template assembles these in a different order — that composition is
/// what makes one template look different from another, not bespoke styling.
class PdfSections {
  const PdfSections(this.ui);

  final PdfUi ui;

  /// Masthead: issuer identity on one side, document identity on the other,
  /// closed by an accent rule.
  ///
  /// ```
  /// [logo] COMPANY NAME                     SALES INVOICE
  ///        address · phone                  فاتورة مبيعات
  ///        VAT 300000000000003              INV-2026-0042
  /// ═══════════════════════════════════════════════════════
  /// ```
  pw.Widget documentHeader({
    required String titleEn,
    required String titleAr,
    PdfPartyModel? company,
    Uint8List? logo,
    double logoSize = 46,
    String? documentNumber,
    String? documentNumberLabel,
    String? statusLabel,
    PdfColor? statusColor,
  }) {
    final theme = ui.theme;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(child: _issuerBlock(company, logo, logoSize)),
            ui.gapX(2),
            _documentIdentityBlock(
              titleEn: titleEn,
              titleAr: titleAr,
              documentNumber: documentNumber,
              documentNumberLabel: documentNumberLabel,
              statusLabel: statusLabel,
              statusColor: statusColor,
            ),
          ],
        ),
        pw.SizedBox(height: theme.spacing),
        ui.accentRule(),
      ],
    );
  }

  pw.Widget _issuerBlock(
    PdfPartyModel? company,
    Uint8List? logo,
    double logoSize,
  ) {
    if (company == null && logo == null) return pw.SizedBox();
    final details = <String>[
      if (company?.address?.isNotEmpty ?? false) company!.address!,
      if (company?.phone.isNotEmpty ?? false) company!.phone,
      if (company?.email.isNotEmpty ?? false) company!.email,
      if (company?.website?.isNotEmpty ?? false) company!.website!,
    ];

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (logo != null) ...[ui.logo(logo, size: logoSize), ui.gapX()],
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: ui.crossStart,
            children: [
              if (company != null && company.name.isNotEmpty)
                ui.heading(company.name),
              if (details.isNotEmpty) ...[
                pw.SizedBox(height: ui.theme.spacing * 0.3),
                // One line per detail: joining an Arabic address to a Latin
                // phone number would make a single mixed-script run.
                for (final detail in details)
                  ui.caption(detail, align: ui.alignStart),
              ],
              if (company?.taxNumber?.isNotEmpty ?? false) ...[
                pw.SizedBox(height: ui.theme.spacing * 0.2),
                ui.pair(
                  '${ui.bilingual('VAT', 'الرقم الضريبي')}:',
                  company!.taxNumber!,
                  size: ui.theme.captionSize,
                  color: ui.theme.mutedText,
                  boldSecond: false,
                ),
              ],
              if (company?.commercialRegister?.isNotEmpty ?? false)
                ui.pair(
                  '${ui.bilingual('CR', 'السجل التجاري')}:',
                  company!.commercialRegister!,
                  size: ui.theme.captionSize,
                  color: ui.theme.mutedText,
                  boldSecond: false,
                ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _documentIdentityBlock({
    required String titleEn,
    required String titleAr,
    String? documentNumber,
    String? documentNumberLabel,
    String? statusLabel,
    PdfColor? statusColor,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        ui.title(titleEn, align: pw.TextAlign.right),
        if (titleAr.isNotEmpty && titleAr != titleEn)
          ui.text(
            titleAr,
            size: ui.theme.headingSize,
            color: ui.theme.mutedText,
            align: pw.TextAlign.right,
          ),
        if (documentNumber != null && documentNumber.isNotEmpty) ...[
          pw.SizedBox(height: ui.theme.spacing * 0.5),
          ui.pair(
            documentNumberLabel ?? '#',
            documentNumber,
            alignment: pw.MainAxisAlignment.end,
          ),
        ],
        if (statusLabel != null && statusLabel.isNotEmpty) ...[
          pw.SizedBox(height: ui.theme.spacing * 0.5),
          ui.outlinedBadge(statusLabel, color: statusColor),
        ],
      ],
    );
  }

  /// Two side-by-side cards — who the document is for and its key dates —
  /// with an optional QR code pinned to the outer edge.
  pw.Widget partyAndMeta({
    PdfPartyModel? party,
    String partyLabel = 'BILL TO',
    Map<String, String> meta = const {},
    String? qrData,
    double qrSize = 64,
  }) {
    final cards = <pw.Widget>[
      if (party != null && party.isNotEmpty)
        pw.Expanded(flex: 5, child: partyCard(party, partyLabel)),
      if (meta.isNotEmpty) pw.Expanded(flex: 4, child: metaCard(meta)),
      if (qrData != null && qrData.isNotEmpty)
        ui.card(
          padding: ui.theme.spacing * 0.6,
          background: PdfColors.white,
          child: ui.qr(qrData, size: qrSize),
        ),
    ];

    if (cards.isEmpty) return pw.SizedBox();

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < cards.length; i++) ...[
          if (i > 0) ui.gapX(),
          cards[i],
        ],
      ],
    );
  }

  /// A single party block: label, name, then contact lines.
  pw.Widget partyCard(PdfPartyModel party, String label) {
    final lines = <String>[
      if (party.address?.isNotEmpty ?? false) party.address!,
      if (party.phone.isNotEmpty) party.phone,
      if (party.email.isNotEmpty) party.email,
    ];

    return ui.card(
      child: pw.Column(
        crossAxisAlignment: ui.crossStart,
        children: [
          ui.caption(label),
          pw.SizedBox(height: ui.theme.spacing * 0.4),
          ui.bidiText(party.name, bold: true, size: ui.theme.headingSize),
          for (final line in lines) ...[
            pw.SizedBox(height: ui.theme.spacing * 0.2),
            ui.caption(line, color: ui.theme.text),
          ],
          if (party.taxNumber?.isNotEmpty ?? false) ...[
            pw.SizedBox(height: ui.theme.spacing * 0.2),
            ui.pair(
              '${ui.bilingual('VAT', 'الرقم الضريبي')}:',
              party.taxNumber!,
              size: ui.theme.captionSize,
              boldSecond: false,
            ),
          ],
        ],
      ),
    );
  }

  /// Label/value pairs in a card — issue date, due date, payment method.
  pw.Widget metaCard(Map<String, String> meta) {
    return ui.card(
      child: pw.Column(
        crossAxisAlignment: ui.crossStart,
        children: [
          for (final entry in meta.entries)
            ui.inlineField(entry.key, entry.value),
        ],
      ),
    );
  }

  /// The money panel: subtotal, discount and tax on hairline rows, then the
  /// grand total on an accent bar, then payment state when relevant.
  ///
  /// Values are passed as numbers, not strings, so the amount and the
  /// currency render as separate text runs and survive an RTL layout.
  pw.Widget totalsPanel({
    required Map<String, double> lines,
    required String totalLabel,
    required double totalValue,
    String? paidLabel,
    double? paidValue,
    String? dueLabel,
    double? dueValue,
    Map<String, String> textLines = const {},
    double width = 250,
    pw.Widget? leading,
  }) {
    final theme = ui.theme;
    final panel = pw.SizedBox(
      width: width,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          for (final entry in lines.entries) ...[
            ui.inlineWidgetField(entry.key, ui.money(entry.value)),
            ui.rule(),
          ],
          for (final entry in textLines.entries) ...[
            ui.inlineField(entry.key, entry.value),
            ui.rule(),
          ],
          pw.Container(
            margin: pw.EdgeInsets.only(top: theme.spacing * 0.5),
            padding: pw.EdgeInsets.symmetric(
              horizontal: theme.spacing,
              vertical: theme.spacing * 0.7,
            ),
            decoration: pw.BoxDecoration(
              color: theme.accent,
              borderRadius: pw.BorderRadius.circular(theme.radius),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                ui.text(
                  totalLabel,
                  color: theme.onAccent,
                  bold: true,
                  size: theme.headingSize,
                ),
                ui.gapX(0.5),
                ui.money(
                  totalValue,
                  color: theme.onAccent,
                  bold: true,
                  size: theme.headingSize,
                ),
              ],
            ),
          ),
          if (paidValue != null) ...[
            pw.SizedBox(height: theme.spacing * 0.4),
            ui.inlineWidgetField(paidLabel ?? 'Paid', ui.money(paidValue)),
          ],
          if (dueValue != null)
            ui.inlineWidgetField(dueLabel ?? 'Due', ui.money(dueValue)),
        ],
      ),
    );

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(child: leading ?? pw.SizedBox()),
        ui.gapX(),
        panel,
      ],
    );
  }

  /// [totalsPanel] for documents whose summary rows are already-formatted
  /// strings rather than amounts — counts, percentages, free text.
  pw.Widget totalsPanelText({
    required Map<String, String> lines,
    required String totalLabel,
    required String totalValue,
    double width = 250,
    pw.Widget? leading,
  }) {
    final theme = ui.theme;
    final panel = pw.SizedBox(
      width: width,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          for (final entry in lines.entries) ...[
            ui.inlineField(entry.key, entry.value),
            ui.rule(),
          ],
          pw.Container(
            margin: pw.EdgeInsets.only(top: theme.spacing * 0.5),
            padding: pw.EdgeInsets.symmetric(
              horizontal: theme.spacing,
              vertical: theme.spacing * 0.7,
            ),
            decoration: pw.BoxDecoration(
              color: theme.accent,
              borderRadius: pw.BorderRadius.circular(theme.radius),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                ui.text(
                  totalLabel,
                  color: theme.onAccent,
                  bold: true,
                  size: theme.headingSize,
                ),
                ui.gapX(0.5),
                ui.text(
                  totalValue,
                  color: theme.onAccent,
                  bold: true,
                  size: theme.headingSize,
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(child: leading ?? pw.SizedBox()),
        ui.gapX(),
        panel,
      ],
    );
  }

  /// Free-text block, visually quieter than the table above it.
  pw.Widget notes(String value, {String label = 'NOTES'}) {
    return ui.card(
      width: double.infinity,
      background: PdfColors.white,
      child: pw.Column(
        crossAxisAlignment: ui.crossStart,
        children: [
          ui.caption(label),
          pw.SizedBox(height: ui.theme.spacing * 0.4),
          ui.text(value, lineSpacing: 1.6),
        ],
      ),
    );
  }

  /// Evenly spaced signature lines.
  pw.Widget signatures(List<String> labels) {
    if (labels.isEmpty) return pw.SizedBox();
    return pw.Row(
      children: [
        for (var i = 0; i < labels.length; i++) ...[
          if (i > 0) ui.gapX(2),
          pw.Expanded(
            child: pw.Column(
              children: [
                pw.SizedBox(height: ui.theme.spacing * 3),
                ui.rule(color: ui.theme.mutedText),
                pw.SizedBox(height: ui.theme.spacing * 0.4),
                ui.caption(labels[i], align: pw.TextAlign.center),
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// Page footer: an optional legal line on one side, `Page 1 / 3` on the
  /// other, above a hairline.
  pw.Widget pageFooter(pw.Context context, {String? note, String? pageLabel}) {
    final page =
        pageLabel ?? 'Page ${context.pageNumber} / ${context.pagesCount}';
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        ui.rule(),
        pw.SizedBox(height: ui.theme.spacing * 0.5),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Expanded(child: ui.caption(note ?? '')),
            ui.caption(page),
          ],
        ),
      ],
    );
  }
}
