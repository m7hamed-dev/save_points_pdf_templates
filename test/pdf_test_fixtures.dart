import 'package:save_points_pdf_templates/save_points_pdf_templates.dart';

/// Shared sample data so every test renders the same document.
const company = PdfPartyModel(
  name: 'Save Points',
  phone: '+966 51 234 5678',
  email: 'info@savepoints.com',
  address: 'Riyadh, Saudi Arabia',
  taxNumber: '300000000000003',
  commercialRegister: '1010101010',
);

const customer = PdfPartyModel(
  name: 'Acme Trading Co.',
  phone: '+966 55 000 1111',
  email: 'billing@acme.example',
  address: 'Jeddah, Saudi Arabia',
  taxNumber: '311111111111113',
);

const items = <PdfInvoiceItemModel>[
  PdfInvoiceItemModel(
    title: 'HP ProBook 450 G10',
    qty: 3,
    price: 3200,
    tax: 480,
    unit: 'pcs',
    sku: 'HP-450-G10',
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

PdfConfig testConfig({String locale = 'en'}) =>
    PdfConfig(locale: locale, company: company);

PdfSaleInvoiceModel saleInvoice({double? total, double? paid}) =>
    PdfSaleInvoiceModel(
      id: 'INV-2026-0042',
      date: DateTime(2026, 9, 14),
      customer: customer,
      items: items,
      paymentMethod: 'Bank transfer',
      reference: 'PO-8891',
      notes: 'Payment due within 30 days.',
      total: total,
      paidAmount: paid,
    );
