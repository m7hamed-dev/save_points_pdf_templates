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
        ui.keyline(),
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
                _registration(
                  ui.bilingual('VAT', 'الرقم الضريبي'),
                  company!.taxNumber!,
                ),
              ],
              if (company?.commercialRegister?.isNotEmpty ?? false)
                _registration(
                  ui.bilingual('CR', 'السجل التجاري'),
                  company!.commercialRegister!,
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
        ui.text(
          titleEn,
          size: ui.theme.titleSize,
          color: ui.theme.accent,
          bold: true,
          align: pw.TextAlign.right,
          letterSpacing: ui.theme.titleTracking,
        ),
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
          pw.SizedBox(height: ui.theme.spacing * 0.6),
          ui.stamp(statusLabel, color: statusColor),
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

  /// A single party block: a tracked label, the name, then contact lines,
  /// held together by an accent bar rather than a filled box.
  pw.Widget partyCard(PdfPartyModel party, String label) {
    final theme = ui.theme;
    final lines = <String>[
      if (party.address?.isNotEmpty ?? false) party.address!,
      if (party.phone.isNotEmpty) party.phone,
      if (party.email.isNotEmpty) party.email,
    ];

    final content = pw.Column(
      crossAxisAlignment: ui.crossStart,
      children: [
        ui.microLabel(label, color: theme.accent),
        pw.SizedBox(height: theme.spacing * 0.45),
        ui.bidiText(party.name, bold: true, size: theme.headingSize),
        for (final line in lines) ...[
          pw.SizedBox(height: theme.spacing * 0.22),
          ui.caption(line, color: theme.text),
        ],
        if (party.taxNumber?.isNotEmpty ?? false) ...[
          pw.SizedBox(height: theme.spacing * 0.22),
          _registration(ui.bilingual('VAT', 'الرقم الضريبي'), party.taxNumber!),
        ],
      ],
    );

    return ui.accentBar(child: content);
  }

  /// `VAT  300000000000003` — a tracked label with the number beside it.
  pw.Widget _registration(String label, String value) => ui.pair(
    label,
    value,
    size: ui.theme.captionSize,
    color: ui.theme.mutedText,
    boldSecond: false,
  );

  /// Label/value rows separated by hairlines — issue date, reference,
  /// payment method. Quieter than a filled card, and it lines up with the
  /// party block beside it.
  pw.Widget metaCard(Map<String, String> meta) {
    final theme = ui.theme;
    final entries = meta.entries.toList();
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < entries.length; i++) ...[
          if (i > 0) ui.rule(),
          pw.Padding(
            padding: pw.EdgeInsets.symmetric(vertical: theme.spacing * 0.35),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(flex: 4, child: ui.microLabel(entries[i].key)),
                ui.gapX(0.5),
                pw.Expanded(
                  flex: 6,
                  child: ui.bidiText(
                    entries[i].value,
                    bold: true,
                    align: ui.alignEnd,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
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

  /// Free-text block, held by an accent bar so it reads as an aside rather
  /// than another boxed field.
  pw.Widget notes(String value, {String label = 'NOTES'}) {
    final theme = ui.theme;
    final content = pw.Column(
      crossAxisAlignment: ui.crossStart,
      children: [
        ui.microLabel(label, color: theme.accent),
        pw.SizedBox(height: theme.spacing * 0.4),
        ui.text(value, lineSpacing: 1.8),
      ],
    );
    return ui.accentBar(color: theme.accentMuted, child: content);
  }

  /// A labelled block of short lines — bank details, delivery terms — for the
  /// space beside the totals panel, which is otherwise dead area.
  pw.Widget infoBlock(String label, Map<String, String> lines) {
    if (lines.isEmpty) return pw.SizedBox();
    final theme = ui.theme;
    return pw.Column(
      crossAxisAlignment: ui.crossStart,
      children: [
        ui.microLabel(label, color: theme.accent),
        pw.SizedBox(height: theme.spacing * 0.5),
        for (final entry in lines.entries)
          pw.Padding(
            padding: pw.EdgeInsets.only(bottom: theme.spacing * 0.25),
            child:
                entry.key.isEmpty
                    ? ui.bidiText(entry.value)
                    : ui.pair(
                      entry.key,
                      entry.value,
                      size: theme.bodySize,
                      color: theme.mutedText,
                    ),
          ),
      ],
    );
  }

  /// Signature blocks: a space to sign, a rule, the role, and a dated line.
  ///
  /// A bare rule with a caption reads as an afterthought; giving each one a
  /// role and a date line is what makes a printed document look official.
  pw.Widget signatures(
    List<String> labels, {
    List<String> names = const [],
    bool withDate = true,
  }) {
    if (labels.isEmpty) return pw.SizedBox();
    final theme = ui.theme;
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < labels.length; i++) ...[
          if (i > 0) ui.gapX(3),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: ui.crossStart,
              children: [
                pw.SizedBox(height: theme.spacing * 3.5),
                ui.rule(color: theme.mutedText),
                pw.SizedBox(height: theme.spacing * 0.45),
                ui.microLabel(labels[i]),
                if (i < names.length && names[i].isNotEmpty) ...[
                  pw.SizedBox(height: theme.spacing * 0.2),
                  ui.bidiText(names[i]),
                ],
                if (withDate) ...[
                  pw.SizedBox(height: theme.spacing * 1.6),
                  ui.rule(),
                  pw.SizedBox(height: theme.spacing * 0.45),
                  ui.microLabel(ui.bilingual('Date', 'التاريخ')),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// Page footer: the issuer on one side, the document id in the middle and
  /// `Page 1 / 3` on the other, over a hairline.
  pw.Widget pageFooter(
    pw.Context context, {
    String? note,
    String? reference,
    String? pageLabel,
  }) {
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
            if (reference != null && reference.isNotEmpty)
              ui.caption(reference, align: pw.TextAlign.center),
            pw.Expanded(child: ui.caption(page, align: ui.alignEnd)),
          ],
        ),
      ],
    );
  }
}
