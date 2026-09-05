import 'package:flutter_test/flutter_test.dart';
import 'package:save_points_pdf_templates/save_points_pdf_templates.dart';

void main() {
  const english = PdfEnglishAmountInWords();
  const arabic = PdfArabicAmountInWords();

  group('English numbers', () {
    String say(int value) => english.spellNumber(value);

    test('nothing is zero, not empty', () => expect(say(0), 'zero'));

    test('under twenty is one word', () {
      expect(say(1), 'one');
      expect(say(12), 'twelve');
      expect(say(19), 'nineteen');
    });

    test('tens hyphenate their units', () {
      expect(say(20), 'twenty');
      expect(say(21), 'twenty-one');
      expect(say(99), 'ninety-nine');
    });

    test('hundreds take "and" before what follows', () {
      expect(say(100), 'one hundred');
      expect(say(101), 'one hundred and one');
      expect(say(115), 'one hundred and fifteen');
      expect(say(999), 'nine hundred and ninety-nine');
    });

    test('thousands and above', () {
      expect(say(1000), 'one thousand');
      expect(say(1200), 'one thousand two hundred');
      expect(say(12500), 'twelve thousand five hundred');
      expect(say(1000000), 'one million');
      expect(say(2500000), 'two million five hundred thousand');
    });

    // How the amount is read aloud, and what a cheque carries.
    test('"and" joins a trailing group under a hundred', () {
      expect(say(1005), 'one thousand and five');
      expect(say(1205), 'one thousand two hundred and five');
      expect(say(1250), 'one thousand two hundred and fifty');
    });

    test('a round thousand takes no "and"', () {
      expect(say(2000), 'two thousand');
      expect(say(2100), 'two thousand one hundred');
    });
  });

  group('English amounts', () {
    test('whole amounts name the currency and close the line', () {
      expect(
        english.spell(12500, PdfCurrencyWords.sar),
        'Twelve thousand five hundred Saudi Riyals only',
      );
    });

    test('subunits are spelled too', () {
      expect(
        english.spell(12500.5, PdfCurrencyWords.sar),
        'Twelve thousand five hundred Saudi Riyals and fifty halalas only',
      );
    });

    test('the suffix can be dropped', () {
      expect(
        const PdfEnglishAmountInWords(
          suffix: '',
        ).spell(5, PdfCurrencyWords.usd),
        'Five US Dollars',
      );
    });
  });

  // The part worth being exact about: Arabic inverts gender agreement for
  // three to ten, has a dual, and puts a scale word in the accusative past
  // eleven. A bank clerk notices all three.
  group('Arabic numbers', () {
    String say(int value, {bool feminine = false}) =>
        arabic.spellNumber(value, feminine: feminine);

    test('zero', () => expect(say(0), 'صفر'));

    test('one and two', () {
      expect(say(1), 'واحد');
      expect(say(2), 'اثنان');
      expect(say(1, feminine: true), 'واحدة');
      expect(say(2, feminine: true), 'اثنتان');
    });

    // Three to ten take the *opposite* gender to the noun they count.
    test('three to ten invert their gender', () {
      expect(say(3), 'ثلاثة');
      expect(say(3, feminine: true), 'ثلاث');
      expect(say(8), 'ثمانية');
      expect(say(8, feminine: true), 'ثماني');
      expect(say(10), 'عشرة');
      expect(say(10, feminine: true), 'عشر');
    });

    test('the teens', () {
      expect(say(11), 'أحد عشر');
      expect(say(12), 'اثنا عشر');
      expect(say(12, feminine: true), 'اثنتا عشرة');
      expect(say(19), 'تسعة عشر');
    });

    // Units come before tens, joined by و — five and twenty, not twenty-five.
    test('units lead the tens', () {
      expect(say(20), 'عشرون');
      expect(say(21), 'واحد وعشرون');
      expect(say(25), 'خمسة وعشرون');
      expect(say(99), 'تسعة وتسعون');
    });

    test('hundreds', () {
      expect(say(100), 'مائة');
      expect(say(101), 'مائة وواحد');
      expect(say(200), 'مائتان');
      expect(say(300), 'ثلاثمائة');
      expect(say(500), 'خمسمائة');
      expect(say(900), 'تسعمائة');
    });

    // A scale word is masculine, so it takes the ta marbuta form for three to
    // ten, and the accusative from eleven up.
    test('thousands inflect with their count', () {
      expect(say(1000), 'ألف');
      expect(say(2000), 'ألفان');
      expect(say(3000), 'ثلاثة آلاف');
      expect(say(10000), 'عشرة آلاف');
      expect(say(11000), 'أحد عشر ألفاً');
      expect(say(20000), 'عشرون ألفاً');
      expect(say(100000), 'مائة ألف');
      expect(say(200000), 'مائتا ألف');
      expect(say(300000), 'ثلاثمائة ألف');
    });

    // The noun's form follows the last element of the count, not its size.
    test('a hundred thousand is not a hundred thousands', () {
      expect(say(100000), 'مائة ألف');
      expect(say(103000), 'مائة وثلاثة آلاف');
      expect(say(125000), 'مائة وخمسة وعشرون ألفاً');
      expect(say(112000), 'مائة واثنا عشر ألفاً');
    });

    test('millions do the same', () {
      expect(say(1000000), 'مليون');
      expect(say(2000000), 'مليونان');
      expect(say(3000000), 'ثلاثة ملايين');
      expect(say(15000000), 'خمسة عشر مليوناً');
    });

    test('groups are joined by و', () {
      expect(say(12500), 'اثنا عشر ألفاً وخمسمائة');
      expect(say(1234), 'ألف ومائتان وأربعة وثلاثون');
    });
  });

  group('Arabic amounts', () {
    test('the cheque formula', () {
      expect(
        arabic.spell(12500, PdfCurrencyWords.sarArabic),
        'اثنا عشر ألفاً وخمسمائة ريال سعودي فقط لا غير',
      );
    });

    // The riyal is masculine and the halala feminine, so the same count is
    // spelled differently on each side of the same line.
    test('each unit agrees with its own gender', () {
      expect(
        arabic.spell(3.03, PdfCurrencyWords.sarArabic),
        'ثلاثة ريال سعودي وثلاث هللة فقط لا غير',
      );
    });

    test('subunits are spelled when there are any', () {
      expect(
        arabic.spell(12500.5, PdfCurrencyWords.sarArabic),
        'اثنا عشر ألفاً وخمسمائة ريال سعودي وخمسون هللة فقط لا غير',
      );
    });
  });

  // A voucher that leaves the words blank is not carrying the protection the
  // second statement of the amount exists to give.
  group('a voucher spells its own amount', () {
    ReceiptVoucherModel voucher({String? words}) => ReceiptVoucherModel(
      id: 'RV-1',
      date: DateTime(2026, 9, 14),
      payerName: 'Acme Trading Co.',
      amount: 12500.5,
      paymentMethod: 'Bank transfer',
      statement: 'Settlement',
      receiverName: 'Mohamed',
      amountInWords: words,
    );

    test('the caller\'s own wording always wins', () {
      final template = ReceiptVoucherTemplate(
        data: voucher(words: 'Exactly as I wrote it'),
        pdfConfig: PdfConfig(),
      );
      expect(template.amountInWords, 'Exactly as I wrote it');
    });

    test('an empty one is filled in', () {
      final template = ReceiptVoucherTemplate(
        data: voucher(),
        pdfConfig: PdfConfig(),
      );
      expect(
        template.amountInWords,
        'Twelve thousand five hundred Saudi Riyals and fifty halalas only',
      );
    });

    test('the config decides the language and the currency', () {
      final config = PdfConfig(
        locale: 'ar',
        currencyWords: PdfCurrencyWords.aedArabic,
      );
      // No Arabic-capable font here, so the guard keeps it English — the same
      // guard the labels use, for the same reason.
      expect(config.spellAmount(3), startsWith('Three'));
    });

    test('a custom speller is used as given', () {
      final config = PdfConfig(
        amountInWords: const PdfEnglishAmountInWords(suffix: 'net'),
        currencyWords: PdfCurrencyWords.usd,
      );
      expect(config.spellAmount(5), 'Five US Dollars net');
    });
  });

  group('splitting an amount', () {
    test('the subunit rounds rather than truncating', () {
      // 0.999 is one riyal, not zero riyals and ninety-nine halalas.
      expect(PdfAmountInWords.split(0.999), (1, 0));
      expect(PdfAmountInWords.split(12500.5), (12500, 50));
      expect(PdfAmountInWords.split(12500.004), (12500, 0));
      expect(PdfAmountInWords.split(12500.005), (12500, 1));
    });

    test('a negative amount is spelled by its size', () {
      expect(PdfAmountInWords.split(-5.25), (5, 25));
    });

    test('three-decimal currencies split at three', () {
      expect(PdfAmountInWords.split(1.234, decimals: 3), (1, 234));
    });
  });
}
