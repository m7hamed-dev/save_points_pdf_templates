import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Page margins, in points.
///
/// A package-owned type so setting a margin does not force callers to import
/// `package:pdf/widgets.dart` — whose `EdgeInsets` clashes with Flutter's.
class PdfMargin {
  const PdfMargin({
    this.left = 0,
    this.top = 0,
    this.right = 0,
    this.bottom = 0,
  });

  const PdfMargin.all(double value)
    : left = value,
      top = value,
      right = value,
      bottom = value;

  const PdfMargin.symmetric({double horizontal = 0, double vertical = 0})
    : left = horizontal,
      right = horizontal,
      top = vertical,
      bottom = vertical;

  final double left;
  final double top;
  final double right;
  final double bottom;

  /// The renderer's own edge insets.
  pw.EdgeInsets get insets => pw.EdgeInsets.fromLTRB(left, top, right, bottom);

  PdfMargin copyWith({
    double? left,
    double? top,
    double? right,
    double? bottom,
  }) => PdfMargin(
    left: left ?? this.left,
    top: top ?? this.top,
    right: right ?? this.right,
    bottom: bottom ?? this.bottom,
  );
}

/// How the item table's header row is drawn.
enum PdfTableHeaderStyle {
  /// Solid accent bar with reversed text. High contrast, heavier on the page.
  filled,

  /// Pale accent wash with accent-colored labels over a firm accent rule.
  /// Reads lighter and lets the figures dominate — the default.
  soft,

  /// No fill at all; the header sits on a rule. For minimal stationery.
  underlined,
}

/// Visual design tokens shared by every template.
///
/// A theme owns colors, type scale and spacing so that templates never
/// hard-code a color or a font size. Build one with [PdfTheme.modern],
/// [PdfTheme.classic] or [PdfTheme.minimal], then tweak it with [copyWith].
class PdfTheme {
  const PdfTheme({
    this.accent = const PdfColor.fromInt(0xFF1F3A5F),
    this.onAccent = PdfColors.white,
    this.text = const PdfColor.fromInt(0xFF111827),
    this.mutedText = const PdfColor.fromInt(0xFF6B7280),
    this.border = const PdfColor.fromInt(0xFFE4E7EC),
    this.surface = const PdfColor.fromInt(0xFFFAFAFB),
    this.zebra = const PdfColor.fromInt(0xFFF7F8FA),
    this.displaySize = 19.0,
    this.titleSize = 26.0,
    this.headingSize = 12.0,
    this.bodySize = 9.5,
    this.captionSize = 7.6,
    this.spacing = 10.0,
    this.radius = 2.0,
    this.borderWidth = 0.5,
    this.labelTracking = 0.9,
    this.titleTracking = -0.7,
    this.headerStyle = PdfTableHeaderStyle.underlined,
    this.tableHeaderHeight = 24.0,
    this.tableRowHeight = 26.0,
    this.showZebraStripes = false,
    this.showRowRules = true,
    this.margin = const PdfMargin.all(40.0),
  });

  /// Deep navy on white, set with room to breathe. The default.
  ///
  /// Colour is rationed on purpose — the accent appears on one keyline, the
  /// column labels and the amount due, and nowhere else. What organises the
  /// page is space and type size, not boxes.
  const PdfTheme.modern({PdfColor accent = const PdfColor.fromInt(0xFF1F3A5F)})
    : this(accent: accent);

  /// Black on white with a full grid and a filled table header — the
  /// traditional invoice, for a reader who expects ruled paper.
  const PdfTheme.classic()
    : this(
        accent: PdfColors.black,
        surface: const PdfColor.fromInt(0xFFF2F2F2),
        zebra: const PdfColor.fromInt(0xFFF7F7F7),
        border: const PdfColor.fromInt(0xFF8A8A8A),
        borderWidth: 0.7,
        radius: 0.0,
        titleSize: 22.0,
        titleTracking: 0.0,
        tableRowHeight: 24.0,
        spacing: 9.0,
        margin: const PdfMargin.all(38.0),
        headerStyle: PdfTableHeaderStyle.filled,
      );

  /// Sized for a receipt roll: small type, hairline margins, no fills.
  ///
  /// A till receipt is read at arm's length for a few seconds and then filed
  /// or thrown away, and the paper is 80mm wide with no margin to spare — so
  /// this trades every gram of elegance for fitting.
  const PdfTheme.thermal()
    : this(
        accent: const PdfColor.fromInt(0xFF000000),
        text: const PdfColor.fromInt(0xFF000000),
        mutedText: const PdfColor.fromInt(0xFF444444),
        border: const PdfColor.fromInt(0xFF999999),
        surface: PdfColors.white,
        zebra: PdfColors.white,
        displaySize: 12.0,
        titleSize: 13.0,
        headingSize: 9.0,
        bodySize: 7.5,
        captionSize: 6.5,
        spacing: 4.0,
        radius: 0.0,
        borderWidth: 0.4,
        labelTracking: 0.3,
        titleTracking: 0.0,
        tableHeaderHeight: 12.0,
        tableRowHeight: 12.0,
        showZebraStripes: false,
        showRowRules: false,
        margin: const PdfMargin.symmetric(horizontal: 6, vertical: 8),
      );

  /// Ink on paper and nothing else: no fills, no row rules, the widest
  /// margins of the three. For pre-printed stationery and letterheads.
  const PdfTheme.minimal({PdfColor accent = const PdfColor.fromInt(0xFF111827)})
    : this(
        accent: accent,
        surface: PdfColors.white,
        zebra: PdfColors.white,
        border: const PdfColor.fromInt(0xFFD8DBE0),
        showZebraStripes: false,
        showRowRules: false,
        radius: 0.0,
        spacing: 10.0,
        margin: const PdfMargin.all(42.0),
        headerStyle: PdfTableHeaderStyle.underlined,
      );

  /// Brand color used for the title bar, table header and total row.
  final PdfColor accent;

  /// Foreground drawn on top of [accent].
  final PdfColor onAccent;

  /// Default body text color.
  final PdfColor text;

  /// Secondary text: labels, captions, footer.
  final PdfColor mutedText;

  /// Hairline color for rules, table grid and card outlines.
  final PdfColor border;

  /// Fill for cards and meta boxes.
  final PdfColor surface;

  /// Fill applied to every other table row when [showZebraStripes] is true.
  final PdfColor zebra;

  /// Type scale.
  ///
  /// The figure a reader looks for first — the amount due — is set at
  /// [displaySize], between the title and a heading, so the total carries
  /// weight without a filled bar behind it.
  final double displaySize;
  final double titleSize;
  final double headingSize;
  final double bodySize;
  final double captionSize;

  /// Base spacing unit. Layouts use multiples of this value.
  final double spacing;

  /// Corner radius for cards, badges and the totals panel.
  final double radius;

  /// Hairline thickness.
  final double borderWidth;

  /// Extra space between letters of small uppercase labels — `BILL TO`,
  /// `NOTES`, column headers. Tracking is what makes short caps read as a
  /// deliberate label rather than shouted body text.
  final double labelTracking;

  /// Tracking applied to the document title. Large type usually wants a
  /// slightly negative value; the default leaves it alone.
  final double titleTracking;

  /// How the item table header is drawn.
  final PdfTableHeaderStyle headerStyle;

  /// A pale wash of [accent], used behind soft table headers and stamps.
  PdfColor get accentSoft => mix(accent, PdfColors.white, 0.92);

  /// A muted wash of [accent] for keylines that should read as brand color
  /// without competing with text.
  PdfColor get accentMuted => mix(accent, PdfColors.white, 0.55);

  /// Linear blend of two colors, `t` running from [a] to [b].
  static PdfColor mix(PdfColor a, PdfColor b, double t) => PdfColor(
    a.red + (b.red - a.red) * t,
    a.green + (b.green - a.green) * t,
    a.blue + (b.blue - a.blue) * t,
  );

  /// Table metrics.
  final double tableHeaderHeight;
  final double tableRowHeight;
  final bool showZebraStripes;

  /// Draws a hairline under every table row. Turn it off to separate rows by
  /// their height alone, which needs [tableRowHeight] to be generous.
  final bool showRowRules;

  /// Page margin applied by the generator.
  final PdfMargin margin;

  PdfTheme copyWith({
    PdfColor? accent,
    PdfColor? onAccent,
    PdfColor? text,
    PdfColor? mutedText,
    PdfColor? border,
    PdfColor? surface,
    PdfColor? zebra,
    double? displaySize,
    double? titleSize,
    double? headingSize,
    double? bodySize,
    double? captionSize,
    double? spacing,
    double? radius,
    double? borderWidth,
    double? labelTracking,
    double? titleTracking,
    PdfTableHeaderStyle? headerStyle,
    double? tableHeaderHeight,
    double? tableRowHeight,
    bool? showZebraStripes,
    bool? showRowRules,
    PdfMargin? margin,
  }) {
    return PdfTheme(
      accent: accent ?? this.accent,
      onAccent: onAccent ?? this.onAccent,
      text: text ?? this.text,
      mutedText: mutedText ?? this.mutedText,
      border: border ?? this.border,
      surface: surface ?? this.surface,
      zebra: zebra ?? this.zebra,
      displaySize: displaySize ?? this.displaySize,
      titleSize: titleSize ?? this.titleSize,
      headingSize: headingSize ?? this.headingSize,
      bodySize: bodySize ?? this.bodySize,
      captionSize: captionSize ?? this.captionSize,
      spacing: spacing ?? this.spacing,
      radius: radius ?? this.radius,
      borderWidth: borderWidth ?? this.borderWidth,
      labelTracking: labelTracking ?? this.labelTracking,
      titleTracking: titleTracking ?? this.titleTracking,
      headerStyle: headerStyle ?? this.headerStyle,
      tableHeaderHeight: tableHeaderHeight ?? this.tableHeaderHeight,
      tableRowHeight: tableRowHeight ?? this.tableRowHeight,
      showZebraStripes: showZebraStripes ?? this.showZebraStripes,
      showRowRules: showRowRules ?? this.showRowRules,
      margin: margin ?? this.margin,
    );
  }
}
