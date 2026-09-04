import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:save_points_pdf_templates/pdf/core/formatters/pdf_formatters.dart';
import 'package:save_points_pdf_templates/pdf/pdf_config/pdf_theme.dart';

/// Horizontal alignment of a table column.
enum PdfCellAlign { start, center, end }

/// A maximal run of same-script text, produced by `PdfUi.splitRuns`.
class PdfTextRun {
  const PdfTextRun(this.text, {required this.isRtl});

  final String text;
  final bool isRtl;

  @override
  String toString() => 'PdfTextRun(${isRtl ? 'rtl' : 'ltr'}: "$text")';
}

/// The primitive building blocks every template composes from: text, rules,
/// cards, badges and label/value pairs — all bound to one [PdfTheme] so the
/// output stays visually consistent.
///
/// Templates hold a [PdfUi] rather than styling widgets inline, which is what
/// keeps a template body down to a handful of readable lines.
class PdfUi {
  const PdfUi({
    required this.theme,
    required this.formatters,
    this.isRtl = false,
    this.canRenderArabic = false,
  });

  final PdfTheme theme;
  final PdfFormatters formatters;
  final bool isRtl;

  /// Whether the configured font has Arabic glyphs. When false, bilingual
  /// chrome collapses to English instead of drawing missing-glyph boxes.
  final bool canRenderArabic;

  /// The label for the document's own direction.
  ///
  /// Deliberately returns one language rather than `English / عربي`: mixing
  /// scripts inside a single string is what the renderer lays out badly.
  String bilingual(String english, String arabic) =>
      isRtl && canRenderArabic ? arabic : english;

  pw.TextDirection get direction =>
      isRtl ? pw.TextDirection.rtl : pw.TextDirection.ltr;

  /// Arabic, Hebrew and the Arabic presentation forms.
  static final RegExp _rtlScript = RegExp(
    r'[\u0590-\u08FF\uFB1D-\uFDFF\uFE70-\uFEFF]',
  );

  /// Direction for one specific string.
  ///
  /// Marking a purely Latin string right-to-left makes the renderer lay its
  /// glyphs out backwards, which turns `INV-2026-0042` into `2400-6202-VNI`.
  /// Numbers, document ids and English labels therefore stay left-to-right
  /// even inside an Arabic document; only text that actually contains RTL
  /// script is flagged as such.
  static pw.TextDirection directionOf(String value) =>
      _rtlScript.hasMatch(value) ? pw.TextDirection.rtl : pw.TextDirection.ltr;

  /// Latin letters and digits. Digits count as left-to-right so that
  /// `أمر شراء 8891` splits into an Arabic run and a numeric one.
  static final RegExp _ltrScript = RegExp(r'[A-Za-z0-9À-ɏ]');

  /// Splits [value] into maximal same-script runs. Neutral characters —
  /// spaces, punctuation — stay with the run they follow.
  static List<PdfTextRun> splitRuns(String value) {
    final runs = <PdfTextRun>[];
    final buffer = StringBuffer();
    bool? isRtlRun;

    void flush() {
      if (buffer.isEmpty) return;
      runs.add(PdfTextRun(buffer.toString(), isRtl: isRtlRun ?? false));
      buffer.clear();
    }

    for (final rune in value.runes) {
      final char = String.fromCharCode(rune);
      final bool? kind =
          _rtlScript.hasMatch(char)
              ? true
              : (_ltrScript.hasMatch(char) ? false : null);
      if (kind == null || kind == isRtlRun) {
        buffer.write(char);
        continue;
      }
      if (isRtlRun == null) {
        isRtlRun = kind;
        buffer.write(char);
        continue;
      }
      flush();
      isRtlRun = kind;
      buffer.write(char);
    }
    flush();
    return runs;
  }

  pw.CrossAxisAlignment get crossStart => pw.CrossAxisAlignment.start;

  /// Text alignment that follows the document direction.
  pw.TextAlign get alignStart => isRtl ? pw.TextAlign.right : pw.TextAlign.left;

  pw.TextAlign get alignEnd => isRtl ? pw.TextAlign.left : pw.TextAlign.right;

  // ── Text ────────────────────────────────────────────────────────────────

  /// Body text in the theme's default color and size.
  pw.Widget text(
    String value, {
    double? size,
    PdfColor? color,
    bool bold = false,
    pw.TextAlign? align,
    int? maxLines,
    double? lineSpacing,
    double? letterSpacing,
  }) {
    return pw.Text(
      value,
      textDirection: directionOf(value),
      textAlign: align ?? alignStart,
      maxLines: maxLines,
      overflow: maxLines == null ? null : pw.TextOverflow.clip,
      style: pw.TextStyle(
        fontSize: size ?? theme.bodySize,
        color: color ?? theme.text,
        fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        lineSpacing: lineSpacing,
        // Letter spacing disconnects Arabic glyphs, so it is dropped for any
        // value containing RTL script regardless of what the caller asked for.
        letterSpacing: _rtlScript.hasMatch(value) ? null : letterSpacing,
      ),
    );
  }

  /// A small label — `BILL TO`, `NOTES`, a column header.
  ///
  /// Latin text is upper-cased and tracked. Arabic gets neither: it has no
  /// case, and letter spacing pulls a connected script apart — `الوحدة`
  /// comes out as `لوحدة ا` — so tracking is applied only where the script
  /// can take it.
  pw.Widget microLabel(
    String value, {
    PdfColor? color,
    pw.TextAlign? align,
    double? size,
  }) {
    final isRtlText = _rtlScript.hasMatch(value);
    return text(
      isRtlText ? value : value.toUpperCase(),
      size: size ?? theme.captionSize,
      color: color ?? theme.mutedText,
      bold: true,
      align: align,
      letterSpacing: isRtlText ? null : theme.labelTracking,
    );
  }

  /// An outlined stamp — `PAID`, `COPY`, `VOID` — heavier than a [badge] and
  /// tracked, so it reads as a mark applied to the document rather than a UI
  /// chip.
  pw.Widget stamp(String value, {PdfColor? color, PdfColor? background}) {
    final tint = color ?? theme.accent;
    return pw.Container(
      padding: pw.EdgeInsets.symmetric(
        horizontal: theme.spacing * 0.9,
        vertical: theme.spacing * 0.35,
      ),
      decoration: pw.BoxDecoration(
        color: background,
        border: pw.Border.all(color: tint, width: theme.borderWidth * 2.2),
        borderRadius: pw.BorderRadius.circular(theme.radius),
      ),
      child: microLabel(value, color: tint, size: theme.captionSize + 0.5),
    );
  }

  /// The rule that closes the masthead: one accent line, nothing more.
  ///
  /// A single confident rule reads as a deliberate device; the stack of bars
  /// it replaced read as a border someone forgot to remove.
  pw.Widget keyline({double thickness = 0.9}) =>
      pw.Container(height: thickness, color: theme.accent);

  /// The one figure a reader looks for — the amount due. Set between a
  /// heading and the title so it carries on its own, with no filled bar
  /// behind it.
  pw.Widget display(String value, {PdfColor? color, pw.TextAlign? align}) =>
      text(
        value,
        size: theme.displaySize,
        color: color ?? theme.text,
        bold: true,
        align: align,
        letterSpacing: theme.titleTracking * 0.5,
      );

  /// Text that mixes Arabic and Latin, laid out one script run at a time.
  ///
  /// The renderer reverses whichever run does not match the paragraph
  /// direction, so `حاسب محمول HP ProBook` comes out as `kooBorP PH` when
  /// drawn as a single right-to-left string. Splitting the value into runs
  /// and giving each its own direction keeps both scripts readable.
  ///
  /// Single-script values fall through to [text] and keep normal line
  /// wrapping; only genuinely mixed values pay the layout cost.
  ///
  /// A line break the caller put in the value is honoured either way. Runs are
  /// trimmed before layout, so a mixed-script value used to lose its breaks
  /// and reflow into one line while a single-script one kept them — an item
  /// description sat under its title in English and beside it in Arabic.
  pw.Widget bidiText(
    String value, {
    double? size,
    PdfColor? color,
    bool bold = false,
    pw.TextAlign? align,
  }) {
    if (value.contains('\n')) {
      return pw.Column(
        mainAxisSize: pw.MainAxisSize.min,
        crossAxisAlignment: _columnAlignment(align ?? alignStart),
        children: [
          for (final line in value.split('\n'))
            bidiText(line, size: size, color: color, bold: bold, align: align),
        ],
      );
    }

    final runs = [
      for (final run in splitRuns(value))
        if (run.text.trim().isNotEmpty)
          PdfTextRun(run.text.trim(), isRtl: run.isRtl),
    ];
    if (runs.length < 2) {
      return text(value, size: size, color: color, bold: bold, align: align);
    }

    final effectiveAlign = align ?? alignStart;
    final widgets = [
      for (final run in runs)
        pw.Text(
          run.text,
          textDirection:
              run.isRtl ? pw.TextDirection.rtl : pw.TextDirection.ltr,
          style: pw.TextStyle(
            fontSize: size ?? theme.bodySize,
            color: color ?? theme.text,
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
    ];

    return pw.Wrap(
      alignment: _wrapAlignment(effectiveAlign),
      crossAxisAlignment: pw.WrapCrossAlignment.center,
      // Runs are trimmed, so the gap between them is reinstated here — the
      // original spacing would otherwise end up outside the run.
      spacing: (size ?? theme.bodySize) * 0.3,
      runSpacing: (size ?? theme.bodySize) * 0.25,
      // Logical order, never reversed: `Wrap` mirrors its own main axis on a
      // right-to-left page, so reversing here as well would undo it and print
      // the runs back to front — `حاسب محمول HP ProBook` with the Latin run
      // on the right.
      children: widgets,
    );
  }

  /// Folds a *visual* text alignment into the *logical* one [pw.Wrap] wants.
  ///
  /// The renderer mirrors a wrap's main axis on a right-to-left page, so
  /// `WrapAlignment.start` already means the right edge there. Passing a
  /// right-aligned value straight through as `end` would push the content to
  /// the far side of its box.
  pw.WrapAlignment _wrapAlignment(pw.TextAlign align) {
    switch (align) {
      case pw.TextAlign.center:
      case pw.TextAlign.justify:
        return pw.WrapAlignment.center;
      case pw.TextAlign.right:
        return isRtl ? pw.WrapAlignment.start : pw.WrapAlignment.end;
      case pw.TextAlign.left:
        return isRtl ? pw.WrapAlignment.end : pw.WrapAlignment.start;
      case pw.TextAlign.end:
        return pw.WrapAlignment.end;
      case pw.TextAlign.start:
        return pw.WrapAlignment.start;
    }
  }

  /// Small muted text used for field labels and captions.
  pw.Widget caption(String value, {PdfColor? color, pw.TextAlign? align}) =>
      text(
        value,
        size: theme.captionSize,
        color: color ?? theme.mutedText,
        align: align,
      );

  /// Section heading — bold, slightly larger than body text.
  pw.Widget heading(String value, {PdfColor? color, pw.TextAlign? align}) =>
      text(
        value,
        size: theme.headingSize,
        color: color ?? theme.text,
        bold: true,
        align: align,
      );

  /// Document title — the largest type on the page.
  pw.Widget title(String value, {PdfColor? color, pw.TextAlign? align}) => text(
    value,
    size: theme.titleSize,
    color: color ?? theme.accent,
    bold: true,
    align: align,
  );

  /// A money value with the amount and the currency as separate text runs.
  ///
  /// `'28,000.00 ر.س'` as one string would be laid out as mixed script and
  /// come out with the digits reversed; two runs render correctly in both
  /// directions.
  ///
  /// The amount and its currency are one unit, sized to their content — where
  /// that unit sits is the surrounding widget's business. (An `alignment`
  /// argument used to be accepted here and silently did nothing: a row shrunk
  /// to its children has no free space to align them in.)
  pw.Widget money(
    double value, {
    double? size,
    PdfColor? color,
    bool bold = false,
  }) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        text(
          formatters.number(value),
          size: size,
          color: color,
          bold: bold,
          align: pw.TextAlign.left,
        ),
        // Scaled to the type size, not the layout grid: at 22pt a fixed
        // 3pt gap reads as no gap at all.
        pw.SizedBox(width: (size ?? theme.bodySize) * 0.3),
        text(
          formatters.currency,
          size: size,
          color: color,
          bold: bold,
          align: pw.TextAlign.left,
        ),
      ],
    );
  }

  /// Two text runs on one line, each keeping its own script direction.
  ///
  /// Use instead of `'$label $value'` whenever one part is Arabic and the
  /// other is Latin — a document number, a reference, a labelled figure.
  ///
  /// [first] is always the run read first, in either direction: the renderer
  /// mirrors the layout on a right-to-left page, so passing the parts in
  /// logical order is what puts the label on the right there. Reversing them
  /// here as well would cancel that out and print `INV-2026-0042 رقم`.
  ///
  /// Built on a wrap rather than a row because a row lays its children out at
  /// their natural width even when the box is narrower, with no clipping: a
  /// long value beside an Arabic label — `السجل التجاري 1010101010` in a
  /// masthead column — was drawn on top of the label instead of moving to the
  /// next line.
  pw.Widget pair(
    String first,
    String second, {
    double? size,
    PdfColor? color,
    bool bold = false,
    bool boldSecond = true,
    pw.MainAxisAlignment alignment = pw.MainAxisAlignment.start,
  }) {
    return pw.Wrap(
      alignment: _pairAlignment(alignment),
      crossAxisAlignment: pw.WrapCrossAlignment.center,
      spacing: theme.spacing * 0.4,
      runSpacing: theme.spacing * 0.15,
      children: [
        text(first, size: size, color: color, bold: bold),
        text(second, size: size, color: color, bold: boldSecond),
      ],
    );
  }

  /// Where a stack of lines sits on the cross axis, folded from a visual
  /// alignment the same way [_wrapAlignment] folds one — a column's `start` is
  /// the right edge on a right-to-left page.
  pw.CrossAxisAlignment _columnAlignment(pw.TextAlign align) {
    switch (align) {
      case pw.TextAlign.center:
      case pw.TextAlign.justify:
        return pw.CrossAxisAlignment.center;
      case pw.TextAlign.right:
        return isRtl ? pw.CrossAxisAlignment.start : pw.CrossAxisAlignment.end;
      case pw.TextAlign.left:
        return isRtl ? pw.CrossAxisAlignment.end : pw.CrossAxisAlignment.start;
      case pw.TextAlign.end:
        return pw.CrossAxisAlignment.end;
      case pw.TextAlign.start:
        return pw.CrossAxisAlignment.start;
    }
  }

  /// A wrap's alignment is logical — it mirrors its own main axis — so the
  /// row alignment a caller asks for maps across directly.
  pw.WrapAlignment _pairAlignment(pw.MainAxisAlignment alignment) {
    switch (alignment) {
      case pw.MainAxisAlignment.end:
        return pw.WrapAlignment.end;
      case pw.MainAxisAlignment.center:
        return pw.WrapAlignment.center;
      case pw.MainAxisAlignment.spaceBetween:
        return pw.WrapAlignment.spaceBetween;
      case pw.MainAxisAlignment.spaceAround:
        return pw.WrapAlignment.spaceAround;
      case pw.MainAxisAlignment.spaceEvenly:
        return pw.WrapAlignment.spaceEvenly;
      case pw.MainAxisAlignment.start:
        return pw.WrapAlignment.start;
    }
  }

  // ── Spacing & rules ─────────────────────────────────────────────────────

  /// Vertical gap of `factor × theme.spacing`.
  pw.Widget gap([double factor = 1]) =>
      pw.SizedBox(height: theme.spacing * factor);

  /// Horizontal gap of `factor × theme.spacing`.
  pw.Widget gapX([double factor = 1]) =>
      pw.SizedBox(width: theme.spacing * factor);

  /// Hairline divider in the theme's border color.
  pw.Widget rule({PdfColor? color, double? thickness}) => pw.Container(
    height: thickness ?? theme.borderWidth,
    color: color ?? theme.border,
  );

  /// Thicker accent rule used to close the header block.
  pw.Widget accentRule({double thickness = 2.0}) =>
      pw.Container(height: thickness, color: theme.accent);

  // ── Containers ──────────────────────────────────────────────────────────

  /// Outlined surface used for meta blocks, notes and party details.
  pw.Widget card({
    required pw.Widget child,
    PdfColor? background,
    PdfColor? borderColor,
    double? padding,
    pw.Alignment? alignment,
    double? width,
    double? height,
  }) {
    return pw.Container(
      width: width,
      height: height,
      alignment: alignment,
      padding: pw.EdgeInsets.all(padding ?? theme.spacing),
      decoration: pw.BoxDecoration(
        color: background ?? theme.surface,
        border: pw.Border.all(
          color: borderColor ?? theme.border,
          width: theme.borderWidth,
        ),
        borderRadius: pw.BorderRadius.circular(theme.radius),
      ),
      child: child,
    );
  }

  /// Content held by a coloured bar on the leading edge.
  ///
  /// Drawn as a border rather than a sibling widget: a `Row` with a stretched
  /// child has no bounded height here, so a separate bar would be infinitely
  /// tall.
  pw.Widget accentBar({
    required pw.Widget child,
    PdfColor? color,
    double width = 2.4,
    double? padding,
  }) {
    final side = pw.BorderSide(color: color ?? theme.accent, width: width);
    return pw.Container(
      padding: pw.EdgeInsets.symmetric(
        horizontal: padding ?? theme.spacing * 0.9,
        vertical: theme.spacing * 0.2,
      ),
      decoration: pw.BoxDecoration(
        border: isRtl ? pw.Border(right: side) : pw.Border(left: side),
      ),
      child: child,
    );
  }

  /// Filled pill used for the document type and status stamps.
  pw.Widget badge(
    String value, {
    PdfColor? background,
    PdfColor? foreground,
    double? size,
  }) {
    return pw.Container(
      padding: pw.EdgeInsets.symmetric(
        horizontal: theme.spacing,
        vertical: theme.spacing * 0.4,
      ),
      decoration: pw.BoxDecoration(
        color: background ?? theme.accent,
        borderRadius: pw.BorderRadius.circular(theme.radius),
      ),
      child: text(
        value,
        size: size ?? theme.captionSize,
        color: foreground ?? theme.onAccent,
        bold: true,
      ),
    );
  }

  /// Outlined pill — same footprint as [badge] without the fill.
  pw.Widget outlinedBadge(String value, {PdfColor? color}) {
    final tint = color ?? theme.accent;
    return pw.Container(
      padding: pw.EdgeInsets.symmetric(
        horizontal: theme.spacing,
        vertical: theme.spacing * 0.4,
      ),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: tint, width: theme.borderWidth * 2),
        borderRadius: pw.BorderRadius.circular(theme.radius),
      ),
      child: text(value, size: theme.captionSize, color: tint, bold: true),
    );
  }

  // ── Label / value pairs ─────────────────────────────────────────────────

  /// `Label` above `value`, stacked. Used inside meta cards.
  pw.Widget stackedField(String label, String value) {
    return pw.Column(
      crossAxisAlignment: crossStart,
      children: [
        microLabel(label),
        pw.SizedBox(height: theme.spacing * 0.25),
        text(value, bold: true),
      ],
    );
  }

  /// `Label   value` on one line, label muted, value bold and pushed to the
  /// far edge. Used in party cards and the totals panel.
  pw.Widget inlineField(
    String label,
    String value, {
    bool emphasize = false,
    PdfColor? color,
  }) {
    return pw.Padding(
      padding: pw.EdgeInsets.symmetric(vertical: theme.spacing * 0.2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(flex: 4, child: caption(label, color: color)),
          gapX(0.5),
          pw.Expanded(
            flex: 6,
            child: bidiText(
              value,
              bold: emphasize,
              color: color,
              align: alignEnd,
              size: emphasize ? theme.headingSize : theme.bodySize,
            ),
          ),
        ],
      ),
    );
  }

  /// [inlineField] with an arbitrary widget on the value side.
  pw.Widget inlineWidgetField(String label, pw.Widget value) {
    return pw.Padding(
      padding: pw.EdgeInsets.symmetric(vertical: theme.spacing * 0.2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(flex: 4, child: caption(label)),
          gapX(0.5),
          pw.Expanded(
            flex: 6,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [value],
            ),
          ),
        ],
      ),
    );
  }

  /// A dotted fill-in line — `label ......... value` — for vouchers that are
  /// signed by hand.
  pw.Widget dottedField(String label, String value, {double labelWidth = 130}) {
    return pw.Padding(
      padding: pw.EdgeInsets.symmetric(vertical: theme.spacing * 0.6),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.SizedBox(width: labelWidth, child: microLabel(label)),
          gapX(0.5),
          pw.Expanded(
            child: pw.Container(
              padding: pw.EdgeInsets.only(bottom: theme.spacing * 0.3),
              decoration: pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(
                    color: theme.border,
                    width: theme.borderWidth,
                    style: pw.BorderStyle.dashed,
                  ),
                ),
              ),
              child: bidiText(value, bold: true),
            ),
          ),
        ],
      ),
    );
  }

  /// An empty bordered area to stamp or seal, labelled in the corner.
  pw.Widget stampArea(String label, {double height = 90, double? width}) {
    return pw.Container(
      width: width,
      height: height,
      padding: pw.EdgeInsets.all(theme.spacing * 0.7),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(
          color: theme.border,
          width: theme.borderWidth,
          style: pw.BorderStyle.dashed,
        ),
        borderRadius: pw.BorderRadius.circular(theme.radius),
      ),
      child: pw.Align(
        alignment: isRtl ? pw.Alignment.topRight : pw.Alignment.topLeft,
        child: microLabel(label),
      ),
    );
  }

  // ── Media ───────────────────────────────────────────────────────────────

  /// QR code sized to [size], with no caption underneath.
  pw.Widget qr(String data, {double size = 64}) => pw.BarcodeWidget(
    data: data,
    barcode: pw.Barcode.qrCode(),
    width: size,
    height: size,
    drawText: false,
    color: theme.text,
  );

  /// Code 128 barcode, useful for SKUs and document numbers.
  pw.Widget barcode(String data, {double width = 140, double height = 34}) =>
      pw.BarcodeWidget(
        data: data,
        barcode: pw.Barcode.code128(),
        width: width,
        height: height,
        drawText: false,
        color: theme.text,
      );

  /// Logo box that keeps the image inside [size] without distorting it.
  pw.Widget logo(Uint8List bytes, {double size = 46}) => pw.SizedBox(
    width: size,
    height: size,
    child: pw.Image(pw.MemoryImage(bytes)),
  );
}
