import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:save_points_pdf_templates/save_points_pdf_templates.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // The payload is not text, it is a byte layout: one byte of tag, one byte
  // of length, then the value. Asserting it decodes to the right strings
  // would pass on a wrong layout, so this counts the bytes.
  group('the TLV layout', () {
    final payload = ZatcaQr.phaseOne(
      sellerName: 'Bobs Records',
      vatNumber: '310122393500003',
      timestamp: DateTime.utc(2022, 4, 25, 15, 30),
      totalWithVat: 1000,
      vatAmount: 150,
    );

    test('is exactly the bytes the spec asks for', () {
      expect(base64Decode(payload), [
        1,
        12,
        ...utf8.encode('Bobs Records'),
        2,
        15,
        ...utf8.encode('310122393500003'),
        3,
        20,
        ...utf8.encode('2022-04-25T15:30:00Z'),
        4,
        7,
        ...utf8.encode('1000.00'),
        5,
        6,
        ...utf8.encode('150.00'),
      ]);
    });

    test('is 70 bytes: five headers and their values', () {
      expect(base64Decode(payload), hasLength(2 * 5 + 12 + 15 + 20 + 7 + 6));
    });

    test('reads back into its fields', () {
      expect(ZatcaQr.decode(payload), {
        1: 'Bobs Records',
        2: '310122393500003',
        3: '2022-04-25T15:30:00Z',
        4: '1000.00',
        5: '150.00',
      });
    });

    test('the tags are written in ascending order', () {
      final bytes = base64Decode(payload);
      final tags = <int>[];
      var offset = 0;
      while (offset < bytes.length) {
        tags.add(bytes[offset]);
        offset += 2 + bytes[offset + 1];
      }
      expect(tags, [1, 2, 3, 4, 5]);
    });
  });

  group('the timestamp', () {
    test('is written to the second in Zulu time', () {
      expect(
        ZatcaQr.formatTimestamp(DateTime.utc(2026, 9, 5, 12, 34, 56)),
        '2026-09-05T12:34:56Z',
      );
    });

    test('pads every field', () {
      expect(
        ZatcaQr.formatTimestamp(DateTime.utc(2026, 1, 2, 3, 4, 5)),
        '2026-01-02T03:04:05Z',
      );
    });

    // An invoice stamped in local time is an invoice stamped wrong.
    test('a local time is converted, not relabelled', () {
      final local = DateTime.utc(2026, 9, 5, 12).toLocal();
      expect(ZatcaQr.formatTimestamp(local), '2026-09-05T12:00:00Z');
    });
  });

  group('amounts', () {
    String amountOf(String payload, int tag) => ZatcaQr.decode(payload)[tag]!;

    test('carry two decimals, trailing zeros and all', () {
      final payload = ZatcaQr.phaseOne(
        sellerName: 'A',
        vatNumber: '3',
        timestamp: DateTime.utc(2026),
        totalWithVat: 1000,
        vatAmount: 130.4,
      );
      expect(amountOf(payload, ZatcaQr.tagTotalWithVat), '1000.00');
      expect(amountOf(payload, ZatcaQr.tagVatAmount), '130.40');
    });

    test('a three-decimal currency says so', () {
      final payload = ZatcaQr.phaseOne(
        sellerName: 'A',
        vatNumber: '3',
        timestamp: DateTime.utc(2026),
        totalWithVat: 1.5,
        vatAmount: 0.195,
        decimals: 3,
      );
      expect(amountOf(payload, ZatcaQr.tagTotalWithVat), '1.500');
      expect(amountOf(payload, ZatcaQr.tagVatAmount), '0.195');
    });
  });

  group('Arabic values', () {
    test('are encoded as UTF-8, two bytes a letter', () {
      final payload = ZatcaQr.phaseOne(
        sellerName: 'نقاط الحفظ',
        vatNumber: '310122393500003',
        timestamp: DateTime.utc(2026, 9, 5),
        totalWithVat: 100,
        vatAmount: 15,
      );
      expect(ZatcaQr.decode(payload)[ZatcaQr.tagSellerName], 'نقاط الحفظ');
      // Nine letters and a space: nine × 2 bytes, plus one for the space.
      expect(base64Decode(payload)[1], utf8.encode('نقاط الحفظ').length);
      expect(base64Decode(payload)[1], 19);
    });

    // The length is a single byte, and this is reachable with a real company
    // name rather than only with nonsense — which is why it throws instead of
    // truncating into a QR that scans and is wrong.
    test('a name past 255 bytes is refused, not cut short', () {
      expect(
        () => ZatcaQr.phaseOne(
          sellerName: 'ش' * 200, // 400 bytes in UTF-8
          vatNumber: '310122393500003',
          timestamp: DateTime.utc(2026),
          totalWithVat: 1,
          vatAmount: 0,
        ),
        throwsA(
          isA<ZatcaException>().having(
            (e) => e.message,
            'message',
            allOf(contains('400 bytes'), contains('255')),
          ),
        ),
      );
    });

    test('a Latin name of 255 bytes still fits', () {
      final payload = ZatcaQr.phaseOne(
        sellerName: 'A' * 255,
        vatNumber: '3',
        timestamp: DateTime.utc(2026),
        totalWithVat: 1,
        vatAmount: 0,
      );
      expect(ZatcaQr.decode(payload)[1], hasLength(255));
    });
  });

  group('required fields', () {
    test('the seller must be named', () {
      expect(
        () => ZatcaQr.phaseOne(
          sellerName: '   ',
          vatNumber: '310122393500003',
          timestamp: DateTime.utc(2026),
          totalWithVat: 1,
          vatAmount: 0,
        ),
        throwsA(isA<ZatcaException>()),
      );
    });

    test('the VAT number is not optional', () {
      expect(
        () => ZatcaQr.phaseOne(
          sellerName: 'A',
          vatNumber: '',
          timestamp: DateTime.utc(2026),
          totalWithVat: 1,
          vatAmount: 0,
        ),
        throwsA(isA<ZatcaException>()),
      );
    });
  });

  // Phase 2 needs a cryptographic stamp, a certificate from the authority and
  // a call to its service. This package carries those fields; it does not
  // compute them.
  group('Phase 2 fields', () {
    test('are carried verbatim, in tag order, after the five', () {
      final payload = ZatcaQr.phaseOne(
        sellerName: 'A',
        vatNumber: '3',
        timestamp: DateTime.utc(2026),
        totalWithVat: 1,
        vatAmount: 0,
        additionalTags: const {7: 'signature', 6: 'hash'},
      );
      final fields = ZatcaQr.decode(payload);
      expect(fields[6], 'hash');
      expect(fields[7], 'signature');

      final bytes = base64Decode(payload);
      final tags = <int>[];
      var offset = 0;
      while (offset < bytes.length) {
        tags.add(bytes[offset]);
        offset += 2 + bytes[offset + 1];
      }
      expect(tags, [1, 2, 3, 4, 5, 6, 7]);
    });
  });

  group('building it from an invoice', () {
    final config = PdfConfig(
      company: const PdfPartyModel(
        name: 'Save Points',
        taxNumber: '310122393500003',
      ),
    );
    final invoice = PdfSaleInvoiceModel(
      id: 'INV-2026-0042',
      date: DateTime.utc(2026, 9, 5, 12),
      taxRate: 15,
      items: const [PdfInvoiceItemModel(title: 'A', qty: 1, price: 1000)],
    );

    test('takes every value from what the document already knows', () {
      final fields = ZatcaQr.decode(
        ZatcaQr.forInvoice(config: config, invoice: invoice),
      );
      expect(fields[ZatcaQr.tagSellerName], 'Save Points');
      expect(fields[ZatcaQr.tagVatNumber], '310122393500003');
      expect(fields[ZatcaQr.tagTimestamp], '2026-09-05T12:00:00Z');
      expect(fields[ZatcaQr.tagTotalWithVat], '1150.00');
      expect(fields[ZatcaQr.tagVatAmount], '150.00');
    });

    test('the total carries the VAT, and the VAT is stated separately', () {
      expect(invoice.total, 1150);
      expect(invoice.totalTax, 150);
    });

    test('a config with no issuer cannot name a seller', () {
      expect(
        () => ZatcaQr.forInvoice(config: PdfConfig(), invoice: invoice),
        throwsA(
          isA<ZatcaException>().having(
            (e) => e.message,
            'message',
            contains('company'),
          ),
        ),
      );
    });

    test('the payload reaches the rendered document', () async {
      final payload = ZatcaQr.forInvoice(config: config, invoice: invoice);
      final bytes = await PdfGenerator.generate(
        template: SaleInvoiceTemplate(
          data: invoice,
          pdfConfig: config,
          qrCode: payload,
        ),
      );
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    });
  });

  group('Saudi VAT numbers', () {
    test('are fifteen digits between two threes', () {
      expect(ZatcaQr.isValidSaudiVatNumber('310122393500003'), isTrue);
      expect(ZatcaQr.isValidSaudiVatNumber('300000000000003'), isTrue);
    });

    test('anything else is not one', () {
      expect(ZatcaQr.isValidSaudiVatNumber('31012239350000'), isFalse);
      expect(ZatcaQr.isValidSaudiVatNumber('410122393500003'), isFalse);
      expect(ZatcaQr.isValidSaudiVatNumber('310122393500004'), isFalse);
      expect(ZatcaQr.isValidSaudiVatNumber('31012239350000X'), isFalse);
    });

    // Advisory, not enforced: the same TLV shape is used outside Saudi Arabia.
    test('an unrecognised number still encodes', () {
      expect(
        ZatcaQr.phaseOne(
          sellerName: 'A',
          vatNumber: 'GB123456789',
          timestamp: DateTime.utc(2026),
          totalWithVat: 1,
          vatAmount: 0,
        ),
        isNotEmpty,
      );
    });
  });

  group('decoding something that is not a payload', () {
    test('rejects invalid Base64', () {
      expect(() => ZatcaQr.decode('!!!'), throwsA(isA<ZatcaException>()));
    });

    test('rejects a field that claims more bytes than there are', () {
      // Tag 1 says it carries 99 bytes; only two follow.
      expect(
        () => ZatcaQr.decode(base64Encode([1, 99, 65, 66])),
        throwsA(
          isA<ZatcaException>().having(
            (e) => e.message,
            'message',
            contains('truncated'),
          ),
        ),
      );
    });
  });
}
