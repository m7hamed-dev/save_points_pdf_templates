import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:save_points_pdf_templates/save_points_pdf_templates.dart';

/// The code in README.md, compiled.
///
/// A README is the package's front door and its examples rot quietly: a
/// renamed getter or a changed constructor leaves them wrong with nothing to
/// say so. Keeping them here means the analyzer reads the documentation too.
///
/// Each block below is a copy of one in the README. If you change one, change
/// the other.

// ── Quick Start ──────────────────────────────────────────────────────────

PdfConfig quickStartConfig() => PdfConfig(
  fontPath: 'assets/fonts/IBMPlexSansArabic/IBMPlexSansArabic-Regular.ttf',
  boldFontPath: 'assets/fonts/IBMPlexSansArabic/IBMPlexSansArabic-SemiBold.ttf',
  logoPath: 'assets/images/logo.png',
  locale: 'ar',
  currency: 'ر.س',
  company: const PdfPartyModel(
    name: 'Save Points',
    phone: '+966 51 234 5678',
    taxNumber: '300000000000003',
  ),
);

PdfSaleInvoiceModel quickStartInvoice() => PdfSaleInvoiceModel(
  id: 'INV-2026-0042',
  date: DateTime.now(),
  customer: const PdfPartyModel(name: 'Acme Trading Co.'),
  items: const [
    PdfInvoiceItemModel(title: 'HP ProBook 450', qty: 3, price: 3200),
    PdfInvoiceItemModel(
      title: 'On-site setup',
      qty: 1.5,
      price: 400,
      unit: 'hr',
    ),
  ],
  taxRate: 15,
  dueDate: DateTime(2026, 10, 14),
  paymentMethod: 'Bank transfer',
  paidAmount: 5000,
);

// ── Labels & languages ───────────────────────────────────────────────────

class FrenchLabels extends PdfLabels {
  const FrenchLabels();
  @override
  String get billTo => 'FACTURER À';
  @override
  String get subtotal => 'Sous-total';
  @override
  String documentType(PdfInvoiceType type) => 'Facture de vente';
  @override
  String documentSubtitle(PdfInvoiceType type) => '';
}

// ── Custom Templates ─────────────────────────────────────────────────────

class GoodsReceiptTemplate
    extends ItemizedInvoiceTemplate<PdfSaleInvoiceModel> {
  GoodsReceiptTemplate({required super.data, required super.pdfConfig});

  @override
  bool get showPricing => false;

  @override
  String get partyLabel => labels.deliverTo;

  @override
  List<PdfColumnSpec> get columns => [
    PdfColumnSpec(labels.description, flex: 4),
    PdfColumnSpec(labels.quantity, align: PdfCellAlign.center),
  ];

  @override
  List<pw.Widget> extraBlocks(pw.Context context) => [
    ui.gap(1.5),
    sections.notes('Checked against the packing list.', label: 'CONDITION'),
  ];

  @override
  String get watermark => labels.copy;
}

// ── Theming ──────────────────────────────────────────────────────────────

final themedTheme = const PdfTheme.modern().copyWith(
  accent: PdfColors.teal700,
  showRowRules: false,
  headerStyle: PdfTableHeaderStyle.filled,
  labelTracking: 1.0,
  margin: const PdfMargin.all(48),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the quick start builds a document', () async {
    final bytes = await PdfGenerator.generate(
      template: SaleInvoiceTemplate(
        data: quickStartInvoice(),
        pdfConfig: PdfConfig(company: quickStartConfig().company),
      ),
    );
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
  });

  test('the four theme presets exist', () {
    expect(const [
      PdfTheme.modern(),
      PdfTheme.classic(),
      PdfTheme.minimal(),
      PdfTheme.thermal(),
    ], hasLength(4));
    expect(themedTheme.accent, PdfColors.teal700);
  });

  test('the French label set overrides what the README says it does', () {
    const labels = FrenchLabels();
    expect(labels.billTo, 'FACTURER À');
    expect(
      labels.documentType(PdfInvoiceType.salesInvoice),
      'Facture de vente',
    );
    expect(labels.documentSubtitle(PdfInvoiceType.salesInvoice), isEmpty);
    // Untouched getters stay English, which is the claim being made.
    expect(labels.quantity, 'Qty');
  });

  test('the custom template renders without prices', () async {
    final template = GoodsReceiptTemplate(
      data: quickStartInvoice(),
      pdfConfig: PdfConfig(),
    );
    expect(template.showPricing, isFalse);
    expect(template.columns, hasLength(2));
    expect(template.watermark, 'COPY');
    final bytes = await PdfGenerator.generate(template: template);
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
  });

  test('spelling an amount says what the README prints', () {
    final config = PdfConfig(currencyWords: PdfCurrencyWords.sarArabic);
    // The README shows the Arabic line; without an Arabic-capable font the
    // guard falls back to English, so the assertion is on the speller itself.
    expect(
      const PdfArabicAmountInWords().spell(
        12500.75,
        PdfCurrencyWords.sarArabic,
      ),
      'اثنا عشر ألفاً وخمسمائة ريال سعودي وخمس وسبعون هللة فقط لا غير',
    );
    expect(config.spellAmount(12500.75), isNotEmpty);
  });

  test('the carried-forward example is wired the way it is written', () {
    const ui = PdfUi(theme: PdfTheme(), formatters: PdfFormatters());
    final data = quickStartInvoice();
    final columns = <PdfColumnSpec>[
      const PdfColumnSpec('Item', flex: 3),
      const PdfColumnSpec('Amount', align: PdfCellAlign.end),
    ];
    final blocks = PdfDataTable(
      ui: ui,
      columns: columns,
      rows: [
        for (final item in data.items)
          [item.title, ui.formatters.number(item.total)],
      ],
      carryForward: PdfCarryForward(
        column: columns.length - 1,
        values: [for (final item in data.items) item.total],
        format: ui.formatters.number,
      ),
    ).buildPaginated(rowsPerPage: 24);
    expect(blocks, isNotEmpty);
  });

  // ── ZATCA e-invoicing ──────────────────────────────────────────────────

  test('the ZATCA block builds the payload the README shows', () {
    final config = PdfConfig(
      company: const PdfPartyModel(
        name: 'Save Points',
        taxNumber: '310122393500003',
      ),
    );
    final invoice = quickStartInvoice();

    expect(ZatcaQr.forInvoice(config: config, invoice: invoice), isNotEmpty);

    final byHand = ZatcaQr.phaseOne(
      sellerName: 'Save Points',
      vatNumber: '310122393500003',
      timestamp: DateTime.utc(2026, 9, 5, 12),
      totalWithVat: 1150,
      vatAmount: 150,
    );
    expect(ZatcaQr.decode(byHand)[ZatcaQr.tagTotalWithVat], '1150.00');

    // The Phase 2 pass-through, exactly as written.
    final withPhaseTwo = ZatcaQr.forInvoice(
      config: config,
      invoice: invoice,
      additionalTags: const {6: 'xmlHash', 7: 'signature', 8: 'publicKey'},
    );
    expect(ZatcaQr.decode(withPhaseTwo)[8], 'publicKey');
  });

  test('every headless output entry point named in the README exists', () {
    expect(PdfDocuments.bytes, isNotNull);
    expect(PdfDocuments.share, isNotNull);
    expect(PdfDocuments.printDocument, isNotNull);
    expect(PdfDocuments.thumbnail, isNotNull);
  });
}
