import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:save_points_pdf_templates/save_points_pdf_templates.dart';

/// A 1×1 transparent PNG, enough to exercise the logo box.
final logoBytes = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQ'
  'GAhKmMIQAAAABJRU5ErkJggg==',
);

const party = PdfPartyModel(
  name: 'Acme Trading Co.',
  phone: '+966 55 000 1111',
  email: 'billing@acme.example',
  address: 'Jeddah, Saudi Arabia',
  taxNumber: '311111111111113',
  commercialRegister: '1010101010',
);

/// Renders [build] on a page and returns the bytes, so a widget that throws or
/// lays out to nothing fails loudly.
Future<Uint8List> render(
  pw.Widget Function(PdfUi ui, PdfSections sections) build, {
  required bool rtl,
  PdfTheme theme = const PdfTheme(),
}) {
  final ui = PdfUi(
    theme: theme,
    formatters: PdfFormatters(locale: rtl ? 'ar' : 'en'),
    isRtl: rtl,
    canRenderArabic: true,
  );
  final document = pw.Document();
  document.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      textDirection: rtl ? pw.TextDirection.rtl : pw.TextDirection.ltr,
      build: (_) => [build(ui, PdfSections(ui))],
    ),
  );
  return document.save();
}

void expectValidPdf(Uint8List bytes, {required String reason}) {
  expect(String.fromCharCodes(bytes.take(5)), '%PDF-', reason: reason);
  expect(bytes.length, greaterThan(500), reason: reason);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // `PdfUi` and `PdfSections` are exported so callers can assemble their own
  // templates from the same parts. Several of these are used by no template in
  // the package, which is exactly why they need a test of their own: nothing
  // else would notice them breaking.
  group('every PdfUi primitive renders', () {
    for (final rtl in [false, true]) {
      final label = rtl ? 'rtl' : 'ltr';

      test('text, labels and headings — $label', () async {
        expectValidPdf(
          await render(
            (ui, _) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                ui.text('Body text'),
                ui.caption('Caption'),
                ui.heading('Heading'),
                ui.title('Title'),
                ui.display('30,000.00'),
                ui.microLabel('bill to'),
                ui.bidiText('حاسب محمول HP ProBook'),
                ui.money(1234.5),
                ui.pair('No.', 'INV-42'),
              ],
            ),
            rtl: rtl,
          ),
          reason: label,
        );
      });

      test('rules, containers and badges — $label', () async {
        expectValidPdf(
          await render(
            (ui, _) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                ui.rule(),
                ui.accentRule(),
                ui.keyline(),
                ui.gap(),
                ui.card(child: ui.text('In a card')),
                ui.accentBar(child: ui.text('Behind a bar')),
                pw.Row(
                  children: [
                    ui.badge('PAID'),
                    ui.gapX(),
                    ui.outlinedBadge('COPY'),
                    ui.gapX(),
                    ui.stamp('VOID'),
                  ],
                ),
              ],
            ),
            rtl: rtl,
          ),
          reason: label,
        );
      });

      test('fields and stamp areas — $label', () async {
        expectValidPdf(
          await render(
            (ui, _) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                ui.stackedField('Date', '2026-09-14'),
                ui.inlineField('Subtotal', '28,000.00'),
                ui.inlineWidgetField('Total', ui.money(30000)),
                ui.dottedField('Received from', 'Acme Trading Co.'),
                ui.stampArea('Stamp'),
              ],
            ),
            rtl: rtl,
          ),
          reason: label,
        );
      });

      test('media — $label', () async {
        expectValidPdf(
          await render(
            (ui, _) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                ui.qr('https://example.com/inv/42'),
                ui.barcode('INV-2026-0042'),
                ui.logo(logoBytes),
              ],
            ),
            rtl: rtl,
          ),
          reason: label,
        );
      });
    }
  });

  group('every PdfSections block renders', () {
    for (final rtl in [false, true]) {
      final label = rtl ? 'rtl' : 'ltr';

      test('the masthead and the party blocks — $label', () async {
        expectValidPdf(
          await render(
            (ui, sections) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                sections.documentHeader(
                  titleEn: 'Sales Invoice',
                  titleAr: 'فاتورة مبيعات',
                  company: party,
                  logo: logoBytes,
                  documentNumber: 'INV-2026-0042',
                  documentNumberLabel: 'No.',
                  statusLabel: 'PAID',
                ),
                ui.gap(),
                sections.partyAndMeta(
                  party: party,
                  meta: const {'Date': '2026-09-14', 'Reference': 'PO-8891'},
                  qrData: 'https://example.com/inv/42',
                ),
                ui.gap(),
                sections.partyCard(party, 'BILL TO'),
                ui.gap(),
                sections.metaCard(const {'Payment': 'Bank transfer'}),
              ],
            ),
            rtl: rtl,
          ),
          reason: label,
        );
      });

      test('totals, notes and signatures — $label', () async {
        expectValidPdf(
          await render(
            (ui, sections) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                sections.totalsPanel(
                  lines: const {'Subtotal': 28000, 'Tax': 1740},
                  textLines: const {'Method': 'Bank transfer'},
                  totalLabel: 'TOTAL',
                  totalValue: 29740,
                  paidLabel: 'Paid',
                  paidValue: 12000,
                  dueLabel: 'Balance Due',
                  dueValue: 17740,
                  leading: sections.infoBlock('PAYMENT', const {
                    'Method': 'Bank transfer',
                    '': 'Unlabelled line',
                  }),
                ),
                ui.gap(),
                sections.totalsPanelText(
                  lines: const {'Lines': '128'},
                  totalLabel: 'Variance',
                  totalValue: '-12',
                ),
                ui.gap(),
                sections.notes('Payment due within 30 days.'),
                ui.gap(),
                sections.signatures(
                  const ['Issued by', 'Received by'],
                  names: const ['Mohamed', 'Sara'],
                ),
              ],
            ),
            rtl: rtl,
          ),
          reason: label,
        );
      });
    }
  });

  group('empty and degenerate input does not throw', () {
    test('sections given nothing to draw', () async {
      expectValidPdf(
        await render(
          (ui, sections) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              sections.documentHeader(titleEn: 'Report', titleAr: ''),
              sections.partyAndMeta(),
              sections.metaCard(const {}),
              sections.infoBlock('EMPTY', const {}),
              sections.signatures(const []),
              ui.bidiText(''),
              ui.text(''),
            ],
          ),
          rtl: false,
        ),
        reason: 'empty input',
      );
    });

    test('a table with no columns and a table with no rows', () async {
      expectValidPdf(
        await render(
          (ui, _) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              PdfDataTable(ui: ui, columns: const [], rows: const []).build(),
              PdfDataTable(
                ui: ui,
                columns: const [PdfColumnSpec('Item')],
                rows: const [],
                emptyPlaceholder: 'No rows',
              ).build(),
              PdfDataTable(
                ui: ui,
                columns: const [PdfColumnSpec('Item'), PdfColumnSpec('Qty')],
                // Short rows are padded, long ones truncated to the columns.
                rows: const [
                  ['only one cell'],
                  ['a', 'b', 'c', 'd'],
                ],
              ).build(),
            ],
          ),
          rtl: true,
        ),
        reason: 'degenerate tables',
      );
    });
  });

  test('every theme preset renders every block', () async {
    for (final preset
        in {
          'modern': const PdfTheme.modern(),
          'classic': const PdfTheme.classic(),
          'minimal': const PdfTheme.minimal(),
        }.entries) {
      expectValidPdf(
        await render(
          (ui, sections) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              sections.documentHeader(
                titleEn: 'Sales Invoice',
                titleAr: 'فاتورة مبيعات',
                company: party,
              ),
              ui.gap(),
              PdfDataTable(
                ui: ui,
                columns: const [
                  PdfColumnSpec('Item', flex: 3),
                  PdfColumnSpec('Qty', intrinsic: true),
                  PdfColumnSpec('Amount', align: PdfCellAlign.end),
                ],
                rows: const [
                  ['Widget', '3', '300.00'],
                ],
                rowNumbers: true,
              ).build(),
              ui.gap(),
              sections.totalsPanel(
                lines: const {'Subtotal': 300},
                totalLabel: 'TOTAL',
                totalValue: 300,
              ),
            ],
          ),
          rtl: false,
          theme: preset.value,
        ),
        reason: preset.key,
      );
    }
  });
}
