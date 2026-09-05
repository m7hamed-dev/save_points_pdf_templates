import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:save_points_pdf_templates/save_points_pdf_templates.dart';

import 'pdf_test_fixtures.dart';

/// Regenerate the reference files instead of comparing against them:
///
/// ```bash
/// UPDATE_GOLDENS=1 flutter test test/golden_test.dart
/// ```
///
/// Read the diff before committing it. A golden updated without looking is
/// worse than no golden at all — it grants confidence nobody earned.
final updateGoldens = Platform.environment['UPDATE_GOLDENS'] == '1';

const goldenDir = 'test/goldens';

const arabicFontPath =
    'example/assets/fonts/IBMPlexSansArabic/IBMPlexSansArabic-Regular.ttf';
const arabicBoldPath =
    'example/assets/fonts/IBMPlexSansArabic/IBMPlexSansArabic-SemiBold.ttf';

pw.Font loadFont(String path) =>
    pw.Font.ttf(File(path).readAsBytesSync().buffer.asByteData());

/// The drawing operators of every page, and nothing else.
///
/// Not the whole file: `dart_pdf` stamps `/CreationDate` from the clock with
/// no way to override it, so two renders of one document never produce equal
/// bytes. What *is* stable is what was put on the paper — the positions,
/// rules, colours and glyphs — which is also the only part a design change
/// can break.
String contentStreams(Uint8List bytes) {
  final pdf = String.fromCharCodes(bytes);
  final pages = <String>[];
  var cursor = 0;

  while (true) {
    final open = pdf.indexOf('stream', cursor);
    if (open == -1) break;
    final close = pdf.indexOf('endstream', open);
    if (close == -1) break;
    final body = pdf.substring(open + 'stream'.length, close).trim();
    cursor = close + 'endstream'.length;

    // Embedded fonts are streams too, and they are raw binary. A page's
    // content is plain text once the document is written uncompressed —
    // except that a built-in font encodes `—` and friends as single bytes
    // above 126, so a high byte alone does not make a stream binary. A NUL
    // does: font tables are full of them and drawing operators never are.
    if (body.contains('\u0000') || !body.contains('Tf')) continue;
    pages.add(body);
  }

  return [
    for (var i = 0; i < pages.length; i++) ...[
      '% ─── page ${i + 1} of ${pages.length} ───',
      oneOperatorPerLine(pages[i]),
    ],
  ].join('\n');
}

/// Breaks a content stream into one drawing operator per line.
///
/// The renderer writes a whole page as a single line. Stored that way a
/// golden is worth very little: any change at all reports as "1 of 2 lines
/// differ" and hands you twenty thousand characters to compare by eye. One
/// operator per line makes the reference readable, the diff small, and
/// `git diff` able to say what actually moved.
String oneOperatorPerLine(String stream) {
  final tokens = <String>[];
  final buffer = StringBuffer();
  var inString = false;
  var inHex = false;
  var escaped = false;

  void endToken() {
    if (buffer.isNotEmpty) {
      tokens.add(buffer.toString());
      buffer.clear();
    }
  }

  for (final rune in stream.runes) {
    final char = String.fromCharCode(rune);
    if (inString) {
      buffer.write(char);
      if (escaped) {
        escaped = false;
      } else if (char == r'\') {
        escaped = true;
      } else if (char == ')') {
        inString = false;
      }
      continue;
    }
    if (inHex) {
      buffer.write(char);
      if (char == '>') inHex = false;
      continue;
    }
    switch (char) {
      case '(':
        inString = true;
        buffer.write(char);
      case '<':
        inHex = true;
        buffer.write(char);
      case ' ':
      case '\n':
      case '\r':
      case '\t':
        endToken();
      default:
        buffer.write(char);
    }
  }
  endToken();

  // An operator is the alphabetic token that closes its operands — PDF is
  // postfix, so the line ends where the operator is.
  final operator = RegExp(r"^[A-Za-z][A-Za-z0-9*'\x22]*$");
  final lines = <String>[];
  final current = <String>[];
  for (final token in tokens) {
    current.add(token);
    if (operator.hasMatch(token)) {
      lines.add(current.join(' '));
      current.clear();
    }
  }
  if (current.isNotEmpty) lines.add(current.join(' '));
  return lines.join('\n');
}

/// Renders [template] and compares it against `test/goldens/[name].txt`.
Future<void> expectMatchesGolden(
  BaseTemplate<Object?> template,
  String name,
) async {
  final bytes = await PdfGenerator.generate(
    compress: false,
    template: template,
  );
  final actual = contentStreams(bytes);
  expect(actual, isNotEmpty, reason: 'no page content found in $name');

  final file = File('$goldenDir/$name.txt');
  if (updateGoldens || !file.existsSync()) {
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(actual);
    return;
  }

  final expected = file.readAsStringSync();
  if (actual == expected) return;

  // Leave the new output beside the reference so it can be diffed by eye or
  // by any tool, rather than only described in a failure message.
  final rejected = File('$goldenDir/$name.actual.txt')
    ..writeAsStringSync(actual);

  final expectedLines = expected.split('\n');
  final actualLines = actual.split('\n');
  final differing = <int>[
    for (
      var i = 0;
      i <
          (expectedLines.length > actualLines.length
              ? expectedLines.length
              : actualLines.length);
      i++
    )
      if (i >= expectedLines.length ||
          i >= actualLines.length ||
          expectedLines[i] != actualLines[i])
        i,
  ];
  final first = differing.first;

  fail(
    '$name differs from its golden in ${differing.length} of '
    '${expectedLines.length} lines.\n'
    '  first at line ${first + 1}:\n'
    '    golden: ${first < expectedLines.length ? expectedLines[first] : '(end of file)'}\n'
    '    actual: ${first < actualLines.length ? actualLines[first] : '(end of file)'}\n'
    '  written to ${rejected.path}\n'
    '  If the change was intended: UPDATE_GOLDENS=1 flutter test '
    '${'test/golden_test.dart'}',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PdfConfig arabic;

  setUpAll(() {
    arabic = PdfConfig(
      locale: 'ar',
      currency: 'ر.س',
      font: loadFont(arabicFontPath),
      boldFont: loadFont(arabicBoldPath),
      company: company,
    );
  });

  // The rest of the suite asserts facts somebody thought to assert: which
  // column is bold, which run sits on the right, how many pages there are.
  // None of it notices a margin moving from 40 to 44, a rule thickening, or a
  // colour drifting — in a package whose whole product is how a document
  // looks, that is the gap. These four hold the shape of the page itself.
  //
  // A failure here is not a bug report. It says the drawn output changed;
  // whether that was intended is for a human to decide.
  group('golden', () {
    // Two of the four use the built-in Latin font, whose text lands in the
    // stream as readable `(Sales Invoice)` rather than glyph ids — so at
    // least half the references can be reviewed by reading them. The other
    // two use a real TTF, which is the path every actual document takes.

    test('a sales invoice in English', () async {
      await expectMatchesGolden(
        SaleInvoiceTemplate(
          data: saleInvoice(total: 30000, paid: 12000),
          pdfConfig: testConfig(),
          qrCode: 'https://example.com/inv/42',
        ),
        'invoice-en',
      );
    });

    test('the same invoice in Arabic', () async {
      await expectMatchesGolden(
        SaleInvoiceTemplate(
          data: saleInvoice(total: 30000, paid: 12000),
          pdfConfig: arabic,
          qrCode: 'https://example.com/inv/42',
        ),
        'invoice-ar',
      );
    });

    test('a receipt voucher in Arabic', () async {
      await expectMatchesGolden(
        ReceiptVoucherTemplate(
          pdfConfig: arabic,
          qrCode: 'RV-2026-0031',
          data: ReceiptVoucherModel(
            id: 'RV-2026-0031',
            date: DateTime(2026, 9, 14),
            payerName: 'شركة أكمي التجارية',
            amount: 12500,
            amountInWords: 'اثنا عشر ألفاً وخمسمائة ريال',
            paymentMethod: 'تحويل بنكي',
            statement: 'سداد جزئي لفاتورة رقم INV-2026-0042',
            receiverName: 'محمد سيد',
          ),
        ),
        'receipt-voucher-ar',
      );
    });

    test('a till receipt on an 80mm roll', () async {
      await expectMatchesGolden(
        ThermalReceiptTemplate(
          pdfConfig: testConfig(),
          qrCode: 'https://example.com/r/7781',
          footerNote: 'Thank you - exchanges within 14 days',
          data: PdfSaleInvoiceModel(
            id: 'R-7781',
            date: DateTime(2026, 9, 14, 18, 42),
            type: PdfInvoiceType.posInvoice,
            items: const [
              PdfInvoiceItemModel(
                title: 'Coffee beans 250g',
                qty: 2,
                price: 45,
                unit: 'bag',
                taxRate: 15,
              ),
              PdfInvoiceItemModel(
                title: 'Travel mug',
                qty: 1,
                price: 65,
                taxRate: 15,
              ),
            ],
          ),
        ),
        'thermal-receipt-en',
      );
    });
  });

  test('the same document renders identically twice', () async {
    // The premise the whole file rests on. If this ever fails, something
    // non-deterministic crept into the render and every golden below it is
    // about to start failing at random.
    Future<String> once() async => contentStreams(
      await PdfGenerator.generate(
        compress: false,
        template: SaleInvoiceTemplate(
          data: saleInvoice(),
          pdfConfig: testConfig(),
        ),
      ),
    );
    expect(await once(), await once());
  });
}
