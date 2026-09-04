import 'package:flutter/material.dart';
import 'package:save_points_pdf_templates/save_points_pdf_templates.dart';

void main() => runApp(const DemoApp());

class DemoApp extends StatelessWidget {
  const DemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'save_points_pdf_templates',
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF1F3A5F),
        useMaterial3: true,
      ),
      home: const DemoHome(),
    );
  }
}

/// The issuer printed in every document header.
const demoCompany = PdfPartyModel(
  name: 'Save Points',
  phone: '+966 51 234 5678',
  email: 'info@savepoints.com',
  address: 'Riyadh, Saudi Arabia',
  taxNumber: '300000000000003',
  commercialRegister: '1010101010',
);

const demoCustomer = PdfPartyModel(
  name: 'Acme Trading Co.',
  phone: '+966 55 000 1111',
  email: 'billing@acme.example',
  address: 'Jeddah, Saudi Arabia',
  taxNumber: '311111111111113',
);

const demoItems = <PdfInvoiceItemModel>[
  PdfInvoiceItemModel(
    title: 'HP ProBook 450 G10',
    sku: 'HP-450-G10',
    qty: 3,
    price: 3200,
    tax: 480,
    unit: 'pcs',
  ),
  PdfInvoiceItemModel(
    title: 'MacBook Pro 14"',
    qty: 2,
    price: 8900,
    discount: 500,
    tax: 1260,
  ),
  PdfInvoiceItemModel(title: 'On-site setup', qty: 1.5, price: 400, unit: 'hr'),
];

class DemoHome extends StatefulWidget {
  const DemoHome({super.key});

  @override
  State<DemoHome> createState() => _DemoHomeState();
}

class _DemoHomeState extends State<DemoHome> {
  bool _arabic = false;
  PdfTheme _theme = const PdfTheme.modern();

  /// One config per render. In a real app, build it once and keep it — the
  /// font and logo are decoded on the first [PdfConfig.init] and then reused.
  ///
  /// IBM Plex Sans Arabic covers Arabic, Inter covers Latin. Both are declared
  /// as assets in this app's `pubspec.yaml` — the package ships no fonts on
  /// purpose, so you pick the typeface and pay for only the bytes you use.
  ///
  /// The Arabic face is chosen for what it contains, not for how it looks:
  /// the renderer asks a font for the Arabic Presentation Forms-B codepoints,
  /// and a family that leaves those to OpenType shaping — as most Google
  /// Fonts Arabic families do — loses a word-final `ي` after `ر`, `ا`, `د`,
  /// `و` or `ز`. `المتبقي` came out as `المتبق`.
  PdfConfig get _config => PdfConfig(
    company: demoCompany,
    locale: _arabic ? 'ar' : 'en',
    currency: _arabic ? 'ر.س' : 'SAR',
    theme: _theme,
    fontPath:
        _arabic
            ? 'assets/fonts/IBMPlexSansArabic/IBMPlexSansArabic-Regular.ttf'
            : 'assets/fonts/Inter/Inter-Regular.ttf',
    boldFontPath:
        _arabic
            ? 'assets/fonts/IBMPlexSansArabic/IBMPlexSansArabic-SemiBold.ttf'
            : 'assets/fonts/Inter/Inter-Bold.ttf',
  );

  PdfSaleInvoiceModel get _saleInvoice => PdfSaleInvoiceModel(
    id: 'INV-2026-0042',
    date: DateTime.now(),
    customer: demoCustomer,
    items: demoItems,
    paymentMethod: 'Bank transfer',
    dueDate: DateTime.now().add(const Duration(days: 30)),
    reference: 'PO-8891',
    notes: 'Payment due within 30 days of the invoice date.',
    total: 30000,
    paidAmount: 12000,
  );

  void _preview(BaseTemplate<Object?> template) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PdfPreviewPage<Object?>(template: template),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PDF templates')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            value: _arabic,
            onChanged: (value) => setState(() => _arabic = value),
            title: const Text('Arabic / RTL'),
            subtitle: const Text(
              'Switches font, currency and layout direction',
            ),
          ),
          const Divider(),
          _ThemePicker(
            selected: _theme,
            onChanged: (theme) => setState(() => _theme = theme),
          ),
          const Divider(height: 32),
          _DocumentTile(
            title: 'Sales invoice',
            subtitle: 'Line items, totals, partially paid',
            onTap:
                () => _preview(
                  SaleInvoiceTemplate(
                    data: _saleInvoice,
                    pdfConfig: _config,
                    qrCode: 'https://example.com/inv/INV-2026-0042',
                  ),
                ),
          ),
          _DocumentTile(
            title: 'Expense document',
            subtitle: 'Payee card and expense category',
            onTap:
                () => _preview(
                  ExpensesInvoiceTemplate(
                    data: PdfExpensesInvoiceModel(
                      id: 'EXP-2026-0007',
                      date: DateTime.now(),
                      customer: demoCustomer,
                      items: demoItems,
                      category: 'Equipment',
                      paymentMethod: 'Cash',
                    ),
                    pdfConfig: _config,
                  ),
                ),
          ),
          _DocumentTile(
            title: 'Receipt voucher',
            subtitle: 'Amount block, dotted fields, signatures',
            onTap:
                () => _preview(
                  ReceiptVoucherTemplate(
                    data: ReceiptVoucherModel(
                      id: 'RV-2026-0031',
                      date: DateTime.now(),
                      payerName: 'Acme Trading Co.',
                      amount: 12500,
                      amountInWords:
                          'Twelve thousand five hundred Saudi Riyals',
                      paymentMethod: 'Bank transfer',
                      statement: 'Part settlement of invoice INV-2026-0042',
                      receiverName: 'Mohamed Syed',
                    ),
                    pdfConfig: _config,
                    qrCode: 'RV-2026-0031',
                  ),
                ),
          ),
          _DocumentTile(
            title: 'Payment voucher',
            subtitle: 'The receipt voucher mirrored — money out',
            onTap:
                () => _preview(
                  PaymentVoucherTemplate(
                    data: PaymentVoucherModel(
                      id: 'PV-2026-0014',
                      date: DateTime.now(),
                      payeeName: 'Gulf Office Supplies',
                      amount: 3200,
                      amountInWords: 'Three thousand two hundred Saudi Riyals',
                      paymentMethod: 'Cheque #4471',
                      statement: 'Office furniture for the Jeddah branch',
                      disburserName: 'Mohamed Syed',
                    ),
                    pdfConfig: _config,
                    qrCode: 'PV-2026-0014',
                  ),
                ),
          ),
          _DocumentTile(
            title: 'Minimal invoice',
            subtitle: 'Number, customer name, lines',
            onTap:
                () => _preview(
                  InvoiceTemplate(
                    data: PdfInvoiceModel(
                      invoiceNo: 'INV-001',
                      customerName: 'Mohamed',
                      date: DateTime.now(),
                      items: demoItems,
                    ),
                    pdfConfig: _config,
                  ),
                ),
          ),
          _DocumentTile(
            title: 'Delivery note',
            subtitle: 'The item table with every price taken out',
            onTap:
                () => _preview(
                  DeliveryNoteTemplate(
                    data: PdfDeliveryNoteModel(
                      id: 'DN-2026-0088',
                      date: DateTime.now(),
                      customer: demoCustomer,
                      deliveryAddress: 'Warehouse 4, Industrial City, Jeddah',
                      carrier: 'Naqel — plate 4471 ABC',
                      items: demoItems,
                    ),
                    pdfConfig: _config,
                  ),
                ),
          ),
          _DocumentTile(
            title: 'Quotation',
            subtitle: 'Priced but not owed — valid until a date',
            onTap:
                () => _preview(
                  QuotationTemplate(
                    data: PdfQuotationModel(
                      id: 'QT-2026-0007',
                      date: DateTime.now(),
                      validUntil: DateTime.now().add(const Duration(days: 30)),
                      customer: demoCustomer,
                      items: const [
                        PdfInvoiceItemModel(
                          title: 'HP ProBook 450 G10',
                          qty: 3,
                          price: 3200,
                          unit: 'pcs',
                          taxRate: 15,
                        ),
                        PdfInvoiceItemModel(
                          title: 'Training (exempt)',
                          qty: 1,
                          price: 2000,
                          taxRate: 0,
                        ),
                      ],
                      terms:
                          'Delivery within 10 working days of a signed '
                          'acceptance.',
                    ),
                    pdfConfig: _config,
                  ),
                ),
          ),
          _DocumentTile(
            title: 'Statement of account',
            subtitle: 'Opening balance, movements, running balance',
            onTap:
                () => _preview(
                  StatementOfAccountTemplate(
                    data: PdfStatementModel(
                      id: 'SOA-2026-09',
                      customer: demoCustomer,
                      periodStart: DateTime(2026, 9),
                      periodEnd: DateTime(2026, 9, 30),
                      openingBalance: 4200,
                      currencyNote: 'All amounts in SAR.',
                      entries: [
                        PdfStatementEntry(
                          date: DateTime(2026, 9, 3),
                          description: 'Sales invoice',
                          reference: 'INV-2026-0042',
                          debit: 29240,
                        ),
                        PdfStatementEntry(
                          date: DateTime(2026, 9, 12),
                          description: 'Credit note',
                          reference: 'CN-2026-0003',
                          credit: 1500,
                        ),
                        PdfStatementEntry(
                          date: DateTime(2026, 9, 20),
                          description: 'Payment received',
                          credit: 12000,
                        ),
                      ],
                    ),
                    pdfConfig: _config,
                  ),
                ),
          ),
          _DocumentTile(
            title: 'Tabular report',
            subtitle: 'Raw rows, paginated over multiple pages',
            onTap:
                () => _preview(
                  ListStringsTemplate(
                    data: PdfListStringsModel(
                      id: 'RPT-2026-09',
                      title: 'Monthly Stock Count',
                      date: DateTime.now(),
                      headers: const ['SKU', 'Item', 'On hand', 'Counted'],
                      columnFlex: const [1.4, 3, 1, 1],
                      items: List.generate(
                        40,
                        (i) => [
                          'SKU-${1000 + i}',
                          'Product $i',
                          '${20 + i}',
                          '$i',
                        ],
                      ),
                      summary: const {'Lines': '40', 'Variance': '-12'},
                    ),
                    pdfConfig: _config,
                  ),
                ),
          ),
          const Divider(height: 32),
          FilledButton.tonalIcon(
            onPressed: () async {
              await PdfDocuments.share(
                template: SaleInvoiceTemplate(
                  data: _saleInvoice,
                  pdfConfig: _config,
                ),
                fileName: 'INV-2026-0042',
              );
            },
            icon: const Icon(Icons.ios_share),
            label: const Text('Share the sales invoice'),
          ),
        ],
      ),
    );
  }
}

class _ThemePicker extends StatelessWidget {
  const _ThemePicker({required this.selected, required this.onChanged});

  final PdfTheme selected;
  final ValueChanged<PdfTheme> onChanged;

  static const _options = <String, PdfTheme>{
    'Modern': PdfTheme.modern(),
    'Classic': PdfTheme.classic(),
    'Minimal': PdfTheme.minimal(),
    'Teal': PdfTheme.modern(accent: PdfColor.fromInt(0xFF00695C)),
  };

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: [
        for (final entry in _options.entries)
          ChoiceChip(
            label: Text(entry.key),
            selected: identical(selected, entry.value),
            onSelected: (_) => onChanged(entry.value),
          ),
      ],
    );
  }
}

class _DocumentTile extends StatelessWidget {
  const _DocumentTile({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.picture_as_pdf_outlined),
        onTap: onTap,
      ),
    );
  }
}
