/// The spoken name of a currency and its subunit.
///
/// Not the code printed beside a figure — `SAR` is read aloud as *Saudi
/// Riyals*, and a voucher is signed against the words, not the code.
///
/// [majorIsFeminine] and [minorIsFeminine] are what Arabic needs: a number
/// from three to ten takes the *opposite* gender to the noun it counts, so
/// three riyals is `ثلاثة ريال` while three halalas is `ثلاث هللة`. Getting
/// that wrong is the kind of mistake a bank clerk notices.
class PdfCurrencyWords {
  const PdfCurrencyWords({
    required this.major,
    required this.minor,
    this.majorIsFeminine = false,
    this.minorIsFeminine = false,
  });

  /// `Saudi Riyals`, `ريال سعودي`.
  final String major;

  /// `halalas`, `هللة`.
  final String minor;

  final bool majorIsFeminine;
  final bool minorIsFeminine;

  static const PdfCurrencyWords sar = PdfCurrencyWords(
    major: 'Saudi Riyals',
    minor: 'halalas',
  );

  static const PdfCurrencyWords sarArabic = PdfCurrencyWords(
    major: 'ريال سعودي',
    minor: 'هللة',
    minorIsFeminine: true,
  );

  static const PdfCurrencyWords aed = PdfCurrencyWords(
    major: 'UAE Dirhams',
    minor: 'fils',
  );

  static const PdfCurrencyWords aedArabic = PdfCurrencyWords(
    major: 'درهم إماراتي',
    minor: 'فلس',
  );

  static const PdfCurrencyWords usd = PdfCurrencyWords(
    major: 'US Dollars',
    minor: 'cents',
  );

  static const PdfCurrencyWords egpArabic = PdfCurrencyWords(
    major: 'جنيه مصري',
    minor: 'قرش',
  );
}

/// Spells an amount out in words, the way a cheque or a voucher carries it.
///
/// Vouchers are required to state the amount twice — once in figures and once
/// in words — precisely because figures can be altered by a pen stroke and
/// words cannot. That makes this a place to be exact rather than approximate.
///
/// ```dart
/// const speller = PdfArabicAmountInWords();
/// speller.spell(12500.5, PdfCurrencyWords.sarArabic);
/// // اثنا عشر ألفاً وخمسمائة ريال سعودي وخمسون هللة فقط لا غير
/// ```
abstract class PdfAmountInWords {
  const PdfAmountInWords();

  /// The whole amount, its subunit and the currency, as one line.
  String spell(double amount, PdfCurrencyWords currency);

  /// Just the number, with no currency attached.
  String spellNumber(int value, {bool feminine = false});

  /// Splits an amount into whole units and subunits, rounding the subunit to
  /// [decimals] places rather than truncating — `0.999` is one unit, not zero
  /// units and ninety-nine subunits.
  static (int, int) split(double amount, {int decimals = 2}) {
    final factor = <int, int>{0: 1, 1: 10, 2: 100, 3: 1000}[decimals] ?? 100;
    final total = (amount.abs() * factor).round();
    return (total ~/ factor, total % factor);
  }
}

/// Spells amounts in English, in the form a cheque uses.
class PdfEnglishAmountInWords extends PdfAmountInWords {
  const PdfEnglishAmountInWords({this.suffix = 'only'});

  /// Closes the line — `only` is what stops anything being added after it.
  final String suffix;

  static const List<String> _ones = [
    '',
    'one',
    'two',
    'three',
    'four',
    'five',
    'six',
    'seven',
    'eight',
    'nine',
    'ten',
    'eleven',
    'twelve',
    'thirteen',
    'fourteen',
    'fifteen',
    'sixteen',
    'seventeen',
    'eighteen',
    'nineteen',
  ];

  static const List<String> _tens = [
    '',
    '',
    'twenty',
    'thirty',
    'forty',
    'fifty',
    'sixty',
    'seventy',
    'eighty',
    'ninety',
  ];

  static const List<String> _scales = ['', 'thousand', 'million', 'billion'];

  @override
  String spellNumber(int value, {bool feminine = false}) {
    if (value == 0) return 'zero';
    final groups = <String>[];
    var remaining = value;
    var scale = 0;
    while (remaining > 0) {
      final group = remaining % 1000;
      if (group != 0) {
        final words = _underThousand(group);
        groups.insert(0, scale == 0 ? words : '$words ${_scales[scale]}');
      }
      remaining ~/= 1000;
      scale++;
    }
    // `and` before the last group only when it is under a hundred, which is
    // how the amount is read aloud: one thousand two hundred and five.
    if (groups.length > 1 && value % 1000 != 0 && value % 1000 < 100) {
      final last = groups.removeLast();
      return '${groups.join(' ')} and $last';
    }
    return groups.join(' ');
  }

  String _underThousand(int value) {
    final hundreds = value ~/ 100;
    final rest = value % 100;
    final parts = <String>[
      if (hundreds > 0) '${_ones[hundreds]} hundred',
      if (rest > 0) _underHundred(rest),
    ];
    return parts.length == 2 ? '${parts[0]} and ${parts[1]}' : parts.join();
  }

  String _underHundred(int value) {
    if (value < 20) return _ones[value];
    final unit = value % 10;
    return unit == 0
        ? _tens[value ~/ 10]
        : '${_tens[value ~/ 10]}-${_ones[unit]}';
  }

  @override
  String spell(double amount, PdfCurrencyWords currency) {
    final (whole, fraction) = PdfAmountInWords.split(amount);
    final parts = <String>[
      '${spellNumber(whole)} ${currency.major}',
      if (fraction > 0) 'and ${spellNumber(fraction)} ${currency.minor}',
      if (suffix.isNotEmpty) suffix,
    ];
    final line = parts.join(' ');
    return line[0].toUpperCase() + line.substring(1);
  }
}

/// Spells amounts in Arabic, in the form a voucher uses.
///
/// Follows the phrasing of a cheque — `<number> <currency> فقط لا غير` — with
/// the currency named once in the singular, which is the financial convention
/// rather than full grammatical inflection of the counted noun. What it does
/// inflect is the number itself, which is where the reader would notice: the
/// gender agreement for three to ten, the dual, and the accusative on a scale
/// word after eleven.
class PdfArabicAmountInWords extends PdfAmountInWords {
  const PdfArabicAmountInWords({this.suffix = 'فقط لا غير'});

  final String suffix;

  /// Numbers as they appear counting a *masculine* noun — carrying the ta
  /// marbuta from three to ten, which is the agreement Arabic inverts.
  static const List<String> _masculine = [
    '',
    'واحد',
    'اثنان',
    'ثلاثة',
    'أربعة',
    'خمسة',
    'ستة',
    'سبعة',
    'ثمانية',
    'تسعة',
    'عشرة',
    'أحد عشر',
    'اثنا عشر',
    'ثلاثة عشر',
    'أربعة عشر',
    'خمسة عشر',
    'ستة عشر',
    'سبعة عشر',
    'ثمانية عشر',
    'تسعة عشر',
  ];

  /// The same numbers counting a *feminine* noun.
  static const List<String> _feminine = [
    '',
    'واحدة',
    'اثنتان',
    'ثلاث',
    'أربع',
    'خمس',
    'ست',
    'سبع',
    'ثماني',
    'تسع',
    'عشر',
    'إحدى عشرة',
    'اثنتا عشرة',
    'ثلاث عشرة',
    'أربع عشرة',
    'خمس عشرة',
    'ست عشرة',
    'سبع عشرة',
    'ثماني عشرة',
    'تسع عشرة',
  ];

  static const List<String> _tens = [
    '',
    '',
    'عشرون',
    'ثلاثون',
    'أربعون',
    'خمسون',
    'ستون',
    'سبعون',
    'ثمانون',
    'تسعون',
  ];

  static const List<String> _hundreds = [
    '',
    'مائة',
    'مائتان',
    'ثلاثمائة',
    'أربعمائة',
    'خمسمائة',
    'ستمائة',
    'سبعمائة',
    'ثمانمائة',
    'تسعمائة',
  ];

  /// Each scale in the four forms Arabic needs of it: one, two, a few
  /// (three to ten), and many (eleven upwards, which puts it in the
  /// accusative).
  static const List<List<String>> _scales = [
    ['', '', '', ''],
    ['ألف', 'ألفان', 'آلاف', 'ألفاً'],
    ['مليون', 'مليونان', 'ملايين', 'مليوناً'],
    ['مليار', 'ملياران', 'مليارات', 'ملياراً'],
  ];

  @override
  String spellNumber(int value, {bool feminine = false}) {
    if (value == 0) return 'صفر';
    final groups = <String>[];
    var remaining = value;
    var scale = 0;
    while (remaining > 0) {
      final group = remaining % 1000;
      if (group != 0) {
        groups.insert(
          0,
          scale == 0
              ? _underThousand(group, feminine: feminine)
              : _scaled(group, scale),
        );
      }
      remaining ~/= 1000;
      scale++;
    }
    return groups.join(' و');
  }

  /// A group of thousands, millions or milliards, with its scale word in
  /// whichever of the four forms the count calls for.
  ///
  /// Which form that is depends on the *last element* of the count, not on
  /// its size: a hundred thousand is `مائة ألف` while a hundred and
  /// twenty-five thousand is `مائة وخمسة وعشرون ألفاً`. Reading the whole
  /// count instead puts the accusative on every number past ten, which is how
  /// `مائة ألفاً` gets written.
  String _scaled(int count, int scale) {
    final forms = _scales[scale];
    if (count == 1) return forms[0];
    if (count == 2) return forms[1];

    final last = count % 100;
    final number = _underThousand(
      count,
      feminine: false,
      hundredsInIdafa: last == 0,
    );

    // An exact hundred leaves the noun singular: مائتا ألف, ثلاثمائة ألف.
    if (last == 0) return '$number ${forms[0]}';
    if (last == 1) return '$number ${forms[0]}';
    if (last == 2) return '$number ${forms[1]}';
    // A scale word is masculine, so three to ten take the ta marbuta form.
    if (last <= 10) return '$number ${forms[2]}';
    return '$number ${forms[3]}';
  }

  String _underThousand(
    int value, {
    required bool feminine,
    bool hundredsInIdafa = false,
  }) {
    final hundreds = value ~/ 100;
    final rest = value % 100;
    return [
      if (hundreds > 0)
        // The dual drops its nun before the noun it governs: مائتان alone,
        // مائتا ألف in front of one.
        if (hundredsInIdafa && hundreds == 2) 'مائتا' else _hundreds[hundreds],
      if (rest > 0) _underHundred(rest, feminine: feminine),
    ].join(' و');
  }

  String _underHundred(int value, {required bool feminine}) {
    final names = feminine ? _feminine : _masculine;
    if (value < 20) return names[value];
    final unit = value % 10;
    final ten = _tens[value ~/ 10];
    // Units before tens, joined by و — five and twenty, not twenty-five.
    return unit == 0 ? ten : '${names[unit]} و$ten';
  }

  @override
  String spell(double amount, PdfCurrencyWords currency) {
    final (whole, fraction) = PdfAmountInWords.split(amount);
    return [
      '${spellNumber(whole, feminine: currency.majorIsFeminine)} '
          '${currency.major}',
      if (fraction > 0)
        'و${spellNumber(fraction, feminine: currency.minorIsFeminine)} '
            '${currency.minor}',
      if (suffix.isNotEmpty) suffix,
    ].join(' ');
  }
}
