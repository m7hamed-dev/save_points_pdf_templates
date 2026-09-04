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
            pw.Expanded(flex: 5, child: _issuerBlock(company, logo, logoSize)),
            ui.gapX(2),
            // Bounded rather than free: a long type name — `Inventory Count
            // Sheet` — used to push the issuer block off its own half.
            pw.Expanded(
              flex: 4,
              child: _documentIdentityBlock(
                titleEn: titleEn,
                titleAr: titleAr,
                documentNumber: documentNumber,
                documentNumberLabel: documentNumberLabel,
                statusLabel: statusLabel,
                statusColor: statusColor,
              ),
            ),
          ],
        ),
        pw.SizedBox(height: theme.spacing * 1.6),
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
                pw.SizedBox(height: ui.theme.spacing * 0.45),
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
    // Lead with the label in the document's own language. An Arabic invoice
    // whose largest type is `Sales Invoice` reads as an English document that
    // happens to be mirrored. [titleAr] is already empty when the font cannot
    // draw Arabic, which falls the lead back to English on its own.
    final lead = ui.isRtl && titleAr.isNotEmpty ? titleAr : titleEn;
    final secondary = ui.isRtl && titleAr.isNotEmpty ? titleEn : titleAr;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        ui.text(
          lead,
          size: ui.theme.titleSize,
          color: ui.theme.accent,
          bold: true,
          align: ui.alignEnd,
          letterSpacing: ui.theme.titleTracking,
        ),
        if (secondary.isNotEmpty && secondary != lead)
          ui.text(
            secondary,
            size: ui.theme.headingSize,
            color: ui.theme.mutedText,
            align: ui.alignEnd,
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
      if (qrData != null && qrData.isNotEmpty) ui.qr(qrData, size: qrSize),
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

    return pw.Column(
      crossAxisAlignment: ui.crossStart,
      children: [
        ui.microLabel(label, color: theme.mutedText),
        pw.SizedBox(height: theme.spacing * 0.55),
        // The name is the anchor of the block, so it carries the weight
        // instead of a coloured bar drawn beside it.
        ui.bidiText(party.name, bold: true, size: theme.headingSize),
        for (final line in lines) ...[
          pw.SizedBox(height: theme.spacing * 0.3),
          ui.caption(line, color: theme.mutedText),
        ],
        if (party.taxNumber?.isNotEmpty ?? false) ...[
          pw.SizedBox(height: theme.spacing * 0.3),
          _registration(ui.bilingual('VAT', 'الرقم الضريبي'), party.taxNumber!),
        ],
      ],
    );
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
    // Each fact is a small label over its value, and the facts sit beside one
    // another. Ruled label/value rows made three dates look like a form to
    // fill in; stacked fields read as a masthead.
    return pw.Wrap(
      spacing: theme.spacing * 2.4,
      runSpacing: theme.spacing,
      children: [
        for (final entry in meta.entries)
          pw.Column(
            crossAxisAlignment: ui.crossStart,
            children: [
              ui.microLabel(entry.key, color: theme.mutedText),
              pw.SizedBox(height: theme.spacing * 0.35),
              ui.bidiText(entry.value, bold: true),
            ],
          ),
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
          // No rule between the running lines: they are one group, and a
          // hairline after each turned the summary into a ledger.
          for (final entry in lines.entries)
            ui.inlineWidgetField(entry.key, ui.money(entry.value)),
          for (final entry in textLines.entries)
            ui.inlineField(entry.key, entry.value),
          pw.Container(
            margin: pw.EdgeInsets.only(top: theme.spacing * 0.7),
            padding: pw.EdgeInsets.only(top: theme.spacing * 0.7),
            decoration: pw.BoxDecoration(
              border: pw.Border(
                top: pw.BorderSide(color: theme.accent, width: 0.9),
              ),
            ),
            // The amount due carries itself at display size in the accent
            // colour. A solid bar behind it read as a screen button, not as
            // the figure a reader's eye is meant to land on.
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                ui.microLabel(totalLabel, color: theme.mutedText),
                pw.SizedBox(height: theme.spacing * 0.35),
                ui.money(
                  totalValue,
                  color: theme.accent,
                  bold: true,
                  size: theme.displaySize,
                ),
              ],
            ),
          ),
          if (paidValue != null) ...[
            pw.SizedBox(height: theme.spacing * 0.6),
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
          for (final entry in lines.entries)
            ui.inlineField(entry.key, entry.value),
          pw.Container(
            margin: pw.EdgeInsets.only(top: theme.spacing * 0.7),
            padding: pw.EdgeInsets.only(top: theme.spacing * 0.7),
            decoration: pw.BoxDecoration(
              border: pw.Border(
                top: pw.BorderSide(color: theme.accent, width: 0.9),
              ),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                ui.microLabel(totalLabel, color: theme.mutedText),
                pw.SizedBox(height: theme.spacing * 0.35),
                ui.display(totalValue, color: theme.accent),
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
    return pw.Column(
      crossAxisAlignment: ui.crossStart,
      children: [
        ui.microLabel(label, color: theme.mutedText),
        pw.SizedBox(height: theme.spacing * 0.5),
        ui.text(value, color: theme.mutedText, lineSpacing: 2.2),
      ],
    );
  }

  /// A labelled block of short lines — bank details, delivery terms — for the
  /// space beside the totals panel, which is otherwise dead area.
  pw.Widget infoBlock(String label, Map<String, String> lines) {
    if (lines.isEmpty) return pw.SizedBox();
    final theme = ui.theme;
    return pw.Column(
      crossAxisAlignment: ui.crossStart,
      children: [
        ui.microLabel(label, color: theme.mutedText),
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
                pw.SizedBox(height: theme.spacing * 2.1),
                ui.rule(color: theme.border),
                pw.SizedBox(height: theme.spacing * 0.4),
                ui.microLabel(labels[i], color: theme.mutedText),
                if (i < names.length && names[i].isNotEmpty) ...[
                  pw.SizedBox(height: theme.spacing * 0.2),
                  ui.bidiText(names[i]),
                ],
                if (withDate) ...[
                  pw.SizedBox(height: theme.spacing * 1.0),
                  ui.rule(),
                  pw.SizedBox(height: theme.spacing * 0.4),
                  ui.microLabel(
                    ui.bilingual('Date', 'التاريخ'),
                    color: theme.mutedText,
                  ),
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
        pageLabel ??
        '${ui.bilingual('Page', 'صفحة')} '
            '${context.pageNumber} / ${context.pagesCount}';
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
