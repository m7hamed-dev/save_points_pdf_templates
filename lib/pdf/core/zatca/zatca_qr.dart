import 'dart:convert';
import 'dart:typed_data';

import 'package:save_points_pdf_templates/pdf/models/base/pdf_base_invoice_model.dart';
import 'package:save_points_pdf_templates/pdf/pdf_config/pdf_config.dart';

/// Thrown when a payload cannot be built to spec.
///
/// Loudly rather than quietly: a malformed QR still scans, still prints, and
/// still gets rejected — months later, by an auditor.
class ZatcaException implements Exception {
  const ZatcaException(this.message);

  final String message;

  @override
  String toString() => 'ZatcaException: $message';
}

/// The QR payload a Saudi simplified tax invoice has to carry.
///
/// ZATCA — the Zakat, Tax and Customs Authority — requires every simplified
/// tax invoice (the kind given to an individual) to print a QR code whose
/// contents are five fields in TLV form, Base64 encoded. Not free text: each
/// field is one byte of tag, one byte of length, then the value in UTF-8.
///
/// ```dart
/// SaleInvoiceTemplate(
///   data: invoice,
///   pdfConfig: config,
///   qrCode: ZatcaQr.forInvoice(config: config, invoice: invoice),
/// );
/// ```
///
/// This covers Phase 1, which is a pure function of five values. Phase 2 adds
/// a cryptographic stamp, a certificate obtained by registering with the
/// authority, an XML document and calls to ZATCA's own service — none of
/// which belongs in a package that lays out PDFs. If you compute those
/// yourself, [phaseOne] will carry them in `additionalTags`.
class ZatcaQr {
  const ZatcaQr._();

  /// Seller name.
  static const int tagSellerName = 1;

  /// Seller VAT registration number.
  static const int tagVatNumber = 2;

  /// Invoice timestamp, ISO 8601 in UTC.
  static const int tagTimestamp = 3;

  /// Invoice total, VAT included.
  static const int tagTotalWithVat = 4;

  /// The VAT itself.
  static const int tagVatAmount = 5;

  /// The Base64 payload for a simplified tax invoice.
  ///
  /// [timestamp] is converted to UTC — the spec wants Zulu time, and an
  /// invoice stamped in local time is an invoice stamped wrong.
  ///
  /// [decimals] is how the two amounts are written out; two suits the riyal.
  ///
  /// [additionalTags] are carried verbatim after the five, in ascending tag
  /// order, for a caller who has computed the Phase 2 fields elsewhere.
  static String phaseOne({
    required String sellerName,
    required String vatNumber,
    required DateTime timestamp,
    required double totalWithVat,
    required double vatAmount,
    int decimals = 2,
    Map<int, String> additionalTags = const {},
  }) {
    if (sellerName.trim().isEmpty) {
      throw const ZatcaException('the seller name is required');
    }
    if (vatNumber.trim().isEmpty) {
      throw const ZatcaException(
        'the seller VAT registration number is required',
      );
    }

    final fields = <int, String>{
      tagSellerName: sellerName.trim(),
      tagVatNumber: vatNumber.trim(),
      tagTimestamp: formatTimestamp(timestamp),
      tagTotalWithVat: totalWithVat.toStringAsFixed(decimals),
      tagVatAmount: vatAmount.toStringAsFixed(decimals),
      ...additionalTags,
    };

    final bytes = BytesBuilder();
    for (final tag in fields.keys.toList()..sort()) {
      bytes.add(_encodeField(tag, fields[tag]!));
    }
    return base64Encode(bytes.takeBytes());
  }

  /// Builds the payload from a config and an invoice, which between them
  /// already hold every value the spec asks for.
  static String forInvoice({
    required PdfConfig config,
    required PdfItemizedInvoiceModel invoice,
    Map<int, String> additionalTags = const {},
  }) {
    final company = config.company;
    if (company == null) {
      throw const ZatcaException(
        'PdfConfig.company is required: the payload names the seller',
      );
    }
    return phaseOne(
      sellerName: company.name,
      vatNumber: company.taxNumber ?? '',
      timestamp: invoice.date ?? DateTime.now(),
      totalWithVat: invoice.total,
      vatAmount: invoice.totalTax,
      decimals: config.currencyDecimals,
      additionalTags: additionalTags,
    );
  }

  /// Reads a payload back into its fields.
  ///
  /// Here because the only way to be sure a QR is right is to decode it —
  /// which a caller wants as much as this package's own tests do.
  static Map<int, String> decode(String payload) {
    late final Uint8List bytes;
    try {
      bytes = base64Decode(payload);
    } on FormatException catch (error) {
      throw ZatcaException('not valid Base64: ${error.message}');
    }

    final fields = <int, String>{};
    var offset = 0;
    while (offset < bytes.length) {
      if (offset + 2 > bytes.length) {
        throw const ZatcaException('truncated: a field header is cut short');
      }
      final tag = bytes[offset];
      final length = bytes[offset + 1];
      final start = offset + 2;
      if (start + length > bytes.length) {
        throw ZatcaException('truncated: tag $tag claims $length bytes');
      }
      fields[tag] = utf8.decode(bytes.sublist(start, start + length));
      offset = start + length;
    }
    return fields;
  }

  /// `2026-09-05T12:34:56Z` — ISO 8601 in Zulu time, to the second.
  static String formatTimestamp(DateTime timestamp) {
    final utc = timestamp.toUtc();
    String two(int value) => value.toString().padLeft(2, '0');
    return '${utc.year.toString().padLeft(4, '0')}-${two(utc.month)}-'
        '${two(utc.day)}T${two(utc.hour)}:${two(utc.minute)}:'
        '${two(utc.second)}Z';
  }

  /// Whether [value] looks like a Saudi VAT registration number.
  ///
  /// Fifteen digits beginning and ending with 3. Advisory rather than
  /// enforced by [phaseOne], because the same TLV shape is used outside Saudi
  /// Arabia and a package should not refuse to encode a number it merely does
  /// not recognise.
  static bool isValidSaudiVatNumber(String value) {
    final trimmed = value.trim();
    return trimmed.length == 15 &&
        trimmed.startsWith('3') &&
        trimmed.endsWith('3') &&
        RegExp(r'^\d{15}$').hasMatch(trimmed);
  }

  static Uint8List _encodeField(int tag, String value) {
    if (tag < 0 || tag > 255) {
      throw ZatcaException('tag $tag does not fit in one byte');
    }
    final valueBytes = utf8.encode(value);
    if (valueBytes.length > 255) {
      // The length is a single byte, and an Arabic name costs two bytes a
      // letter in UTF-8 — so this is reachable with a real company name, not
      // only with nonsense. Silently truncating would produce a QR that
      // scans and is wrong.
      throw ZatcaException(
        'tag $tag is ${valueBytes.length} bytes; the length field holds at '
        'most 255. An Arabic value costs two bytes a letter.',
      );
    }
    return Uint8List.fromList([tag, valueBytes.length, ...valueBytes]);
  }
}
