import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:save_points_pdf_templates/save_points_pdf_templates.dart';

const regularPath = 'assets/fonts/Cairo-Regular.ttf';
const boldPath = 'assets/fonts/Cairo-Bold.ttf';
const logoPath = 'assets/images/logo.png';
const missingPath = 'assets/does-not-exist.ttf';

/// A 1×1 transparent PNG — enough for [PdfConfig], which stores logo bytes
/// without decoding them.
final logoBytes = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQ'
  'GAhKmMIQAAAABJRU5ErkJggg==',
);

/// Answers the asset channel `rootBundle` reads through.
///
/// [PdfConfig] loads everything from the bundle, so without a stand-in the
/// only observable behaviour is the failure path — which is how a config that
/// skipped loading the logo entirely went unnoticed.
class FakeAssetBundle {
  FakeAssetBundle(this._entries);

  final Map<String, Uint8List> _entries;

  /// Every key asked for, in order, including repeats.
  final List<String> requested = [];

  void install() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (ByteData? message) async {
          final key = utf8.decode(message!.buffer.asUint8List());
          requested.add(key);
          final bytes = _entries[key];
          return bytes == null ? null : ByteData.view(bytes.buffer);
        });
  }

  static void uninstall() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', null);
  }

  int timesRequested(String key) =>
      requested.where((entry) => entry == key).length;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeAssetBundle bundle;

  setUpAll(() {
    // Any real TTF will do; the example app's is the one in the repository.
    final ttf =
        File('example/assets/fonts/Cairo/Cairo-Regular.ttf').readAsBytesSync();
    final bold =
        File('example/assets/fonts/Cairo/Cairo-Bold.ttf').readAsBytesSync();
    bundle = FakeAssetBundle({
      regularPath: ttf,
      boldPath: bold,
      logoPath: logoBytes,
    });
  });

  setUp(() {
    bundle.requested.clear();
    bundle.install();
    rootBundle.clear();
  });

  tearDown(FakeAssetBundle.uninstall);

  group('loading from asset paths', () {
    test(
      'picks up the font, the bold face, the logo and the fallbacks',
      () async {
        final config = PdfConfig(
          fontPath: regularPath,
          boldFontPath: boldPath,
          logoPath: logoPath,
          fallbackFontPaths: const [boldPath],
          useBuiltInFallback: false,
        );
        await config.init();

        expect(config.hasCustomFont, isTrue);
        expect(config.font, isNotNull);
        expect(config.boldFont, isNot(same(config.font)));
        expect(config.logo, logoBytes);
        expect(config.fontFallbacks, hasLength(1));
      },
    );

    test('falls back to the built-in font when the asset is missing', () async {
      final config = PdfConfig(fontPath: missingPath);
      await config.init();
      expect(config.hasCustomFont, isFalse);
    });

    test('throws with a clear message when strictFonts is on', () {
      final config = PdfConfig(fontPath: missingPath, strictFonts: true);
      expect(
        config.init,
        throwsA(
          isA<PdfAssetException>().having(
            (e) => e.message,
            'message',
            contains('does-not-exist.ttf'),
          ),
        ),
      );
    });

    test(
      'the built-in Latin font closes the fallback chain by default',
      () async {
        final config = PdfConfig(fontPath: regularPath);
        await config.init();
        expect(config.fontFallbacks, hasLength(1));
      },
    );
  });

  // A ready-made `pw.Font` — from `PdfGoogleFonts`, or one the app decoded
  // itself — used to mark the whole config as initialized, so `init` returned
  // before touching anything else it was asked to load.
  group('a ready-made font supplied to the constructor', () {
    late PdfConfig config;

    setUp(() async {
      final font = pw.Font.ttf(
        File(
          'example/assets/fonts/Cairo/Cairo-Regular.ttf',
        ).readAsBytesSync().buffer.asByteData(),
      );
      config = PdfConfig(
        font: font,
        boldFontPath: boldPath,
        logoPath: logoPath,
        fallbackFontPaths: const [boldPath],
        useBuiltInFallback: false,
      );
      await config.init();
    });

    test('is used as it is', () {
      expect(config.hasCustomFont, isTrue);
    });

    test('does not stop the logo from loading', () {
      expect(config.logo, logoBytes);
    });

    test('does not stop the bold face from loading', () {
      expect(config.boldFont, isNot(same(config.font)));
    });

    test('does not stop the fallback fonts from loading', () {
      expect(config.fontFallbacks, hasLength(1));
    });

    test('still reports a missing asset when strictFonts is on', () {
      final strict = PdfConfig(
        font: config.font,
        logoPath: 'assets/images/missing.png',
        strictFonts: true,
      );
      expect(strict.init, throwsA(isA<PdfAssetException>()));
    });
  });

  group('caching', () {
    test('init is idempotent — each asset is read once', () async {
      final config = PdfConfig(fontPath: regularPath, logoPath: logoPath);
      await config.init();
      await config.init();

      expect(bundle.timesRequested(regularPath), 1);
      expect(bundle.timesRequested(logoPath), 1);
    });

    test('two renders sharing a config do not stack the fallbacks', () async {
      // `PdfGenerator.generate` calls `init` on every render, so two documents
      // built at once race here.
      final config = PdfConfig(
        fontPath: regularPath,
        fallbackFontPaths: const [boldPath],
        useBuiltInFallback: false,
      );
      await Future.wait([config.init(), config.init(), config.init()]);

      expect(config.fontFallbacks, hasLength(1));
      expect(bundle.timesRequested(boldPath), 1);
    });

    test('invalidate re-reads what came from a path', () async {
      final config = PdfConfig(fontPath: regularPath);
      await config.init();
      config.invalidate();
      await config.init();

      expect(config.hasCustomFont, isTrue);
      expect(bundle.timesRequested(regularPath), 2);
    });

    test('invalidate keeps assets handed to the constructor', () async {
      // Nothing records where a ready-made font came from, so clearing it
      // would leave the config permanently unable to draw Arabic.
      final font = pw.Font.ttf(
        File(
          'example/assets/fonts/Cairo/Cairo-Regular.ttf',
        ).readAsBytesSync().buffer.asByteData(),
      );
      final config = PdfConfig(font: font, logoBytes: logoBytes);
      await config.init();
      config.invalidate();
      await config.init();

      expect(config.font, same(font));
      expect(config.logo, logoBytes);
    });
  });

  group('CairoPdfFontConfig', () {
    test('is right-to-left with SAR', () {
      final config = CairoPdfFontConfig();
      expect(config.isRtl, isTrue);
      expect(config.currency, 'SAR');
    });
  });
}
