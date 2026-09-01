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
    this.text = const PdfColor.fromInt(0xFF1A1A1A),
    this.mutedText = const PdfColor.fromInt(0xFF6B7280),
    this.border = const PdfColor.fromInt(0xFFDDE1E7),
    this.surface = const PdfColor.fromInt(0xFFF7F8FA),
    this.zebra = const PdfColor.fromInt(0xFFFAFBFC),
    this.titleSize = 22.0,
    this.headingSize = 13.0,
    this.bodySize = 10.0,
    this.captionSize = 8.5,
    this.spacing = 8.0,
    this.radius = 4.0,
    this.borderWidth = 0.6,
    this.labelTracking = 0.7,
    this.titleTracking = 0.0,
    this.headerStyle = PdfTableHeaderStyle.soft,
    this.tableHeaderHeight = 26.0,
    this.tableRowHeight = 22.0,
    this.showZebraStripes = true,
    this.margin = const PdfMargin.all(32.0),
  });

  /// Deep navy on white. The default, reads well in print and on screen.
  const PdfTheme.modern({PdfColor accent = const PdfColor.fromInt(0xFF1F3A5F)})
    : this(accent: accent);

  /// Black and white with heavier rules — closest to a traditional invoice.
  const PdfTheme.classic()
    : this(
        accent: PdfColors.black,
        surface: const PdfColor.fromInt(0xFFEFEFEF),
        zebra: const PdfColor.fromInt(0xFFF5F5F5),
        border: const PdfColor.fromInt(0xFF999999),
        borderWidth: 0.8,
        radius: 0.0,
        headerStyle: PdfTableHeaderStyle.filled,
      );

  /// No fills, hairline rules only. Ideal for pre-printed stationery.
  const PdfTheme.minimal({PdfColor accent = const PdfColor.fromInt(0xFF111111)})
    : this(
        accent: accent,
        surface: PdfColors.white,
        zebra: PdfColors.white,
        border: const PdfColor.fromInt(0xFFCCCCCC),
        showZebraStripes: false,
        radius: 0.0,
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
      margin: margin ?? this.margin,
    );
  }
}
