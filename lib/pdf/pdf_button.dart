import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:save_points_pdf_templates/pdf/models/pdf_expenses_model.dart';
import 'package:save_points_pdf_templates/pdf/models/pdf_invoice_item.dart';
import 'package:save_points_pdf_templates/pdf/models/pdf_invoice_model.dart';
import 'package:save_points_pdf_templates/pdf/models/pdf_list_string_model.dart';
import 'package:save_points_pdf_templates/pdf/models/pdf_receipt_voucher_model.dart';
import 'package:save_points_pdf_templates/pdf/models/pdf_sale_invoice_model.dart';
import 'package:save_points_pdf_templates/pdf/pdf_config/pdf_cairo_config.dart';
import 'package:save_points_pdf_templates/pdf/pdf_config/pdf_config.dart';
import 'package:save_points_pdf_templates/pdf/pdf_preview_page.dart';
import 'package:save_points_pdf_templates/pdf/templates/expenses_invoice_template.dart';
import 'package:save_points_pdf_templates/pdf/templates/invoice_template.dart';
import 'package:save_points_pdf_templates/pdf/templates/list_strings_template.dart';
import 'package:save_points_pdf_templates/pdf/templates/receipt_voucher_template.dart';
import 'package:save_points_pdf_templates/pdf/templates/sale_invoice_template.dart';

final company = const PdfPartyModel(
  name: 'Save Points',
  address: 'Company Address',
  phone: '0512345678',
  email: 'info@savepoints.com',
  // website: 'www.savepoints.com',
  // logo: 'assets/images/logo.png',
  taxNumber: '1234567890',
);

// final logo = await rootBundle.load('assets/images/logo.png');
// final logoBytes = logo.buffer.asUint8List();

class PdfButtons extends StatelessWidget {
  const PdfButtons({super.key, this.pdfConfig});
  final PdfConfig? pdfConfig;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(30.0),
        children:
            [
              ElevatedButton(
                child: const Text('Generate Sale Invoice PDF'),
                onPressed: () async {
                  late final saleInvoice = PdfSaleInvoiceModel(
                    discount: 100,
                    tax: 10,
                    total: 1000,
                    paymentMethod: 'Cash',
                    id: 'SI-001',
                    date: DateTime.now(),
                    customer: const PdfPartyModel(
                      name: 'Mohamed',
                      phone: '0512345678',
                      email: 'mohamed@example.com',
                    ),
                    items: [
                      const PdfInvoiceItemModel(
                        title: 'Hp Probook',
                        qty: 230,
                        price: 7000,
                      ),
                      const PdfInvoiceItemModel(
                        title: 'MacBook Pro',
                        qty: 100,
                        price: 6600,
                      ),
                      const PdfInvoiceItemModel(
                        title: 'Dell Probook',
                        qty: 23,
                        price: 5500,
                      ),
                      const PdfInvoiceItemModel(
                        title: 'Lenovo Probook',
                        qty: 23,
                        price: 2000,
                      ),
                    ],
                  );

                  /// TRY TO GENERATE THE PDF
                  try {
                    if (!context.mounted) return;

                    final saleInvoiceTemplate = SaleInvoiceTemplate(
                      qrCode: 'https://www.google.com',
                      headers: ['Item', 'Qty', 'Price', 'Total'],
                      data: saleInvoice,
                      pdfConfig: pdfConfig ?? CairoPdfFontConfig(),
                    );

                    final pdfPreviewPage = PdfPreviewPage<PdfSaleInvoiceModel>(
                      template: saleInvoiceTemplate,
                    );

                    // print('pdfConfig ${pdfConfig?.fontPath}');

                    /// Preview the PDF
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => pdfPreviewPage),
                    );
                  } catch (e) {
                    print('Error generating PDF $e');
                  }
                },
              ),
              ElevatedButton(
                child: const Text('Generate Expenses Invoice PDF'),
                onPressed: () async {
                  late final receipt = ReceiptVoucherModel(
                    id: 'RV-001',
                    date: DateTime.now(),
                    payerName: 'Mohamed',
                    amount: 1000,
                    paymentMethod: 'Cash',
                    statement: 'Payment for invoice',
                    receiverName: 'John',
                  );
                  late final saleInvoice = PdfSaleInvoiceModel(
                    discount: 100,
                    tax: 10,
                    total: 1000,
                    paymentMethod: 'Cash',
                    id: 'SI-001',
                    date: DateTime.now(),
                    customer: const PdfPartyModel(
                      name: 'Mohamed',
                      phone: '0512345678',
                      email: 'mohamed@example.com',
                    ),
                    items: [
                      const PdfInvoiceItemModel(
                        title: 'Hp Probook',
                        qty: 230,
                        price: 7000,
                      ),
                      const PdfInvoiceItemModel(
                        title: 'MacBook Pro',
                        qty: 100,
                        price: 6600,
                      ),
                      const PdfInvoiceItemModel(
                        title: 'Dell Probook',
                        qty: 23,
                        price: 5500,
                      ),
                      const PdfInvoiceItemModel(
                        title: 'Lenovo Probook',
                        qty: 23,
                        price: 2000,
                      ),
                    ],
                  );

                  /// TRY TO GENERATE THE PDF
                  try {
                    // final logo = await rootBundle.load('assets/images/logo.png');
                    // final logoBytes = logo.buffer.asUint8List();
                    if (!context.mounted) return;

                    final expensesInvoice = PdfExpensesInvoiceModel(
                      id: 'EI-001',
                      discount: 100,
                      tax: 10,
                      total: 1000,
                      paymentMethod: 'Cash',
                      date: DateTime.now(),
                      customer: const PdfPartyModel(
                        name: 'Mohamed',
                        phone: '0512345678',
                        email: 'mohamed@example.com',
                      ),
                      items: [
                        const PdfInvoiceItemModel(
                          title: 'Hp Probook',
                          qty: 230,
                          price: 7000,
                        ),
                        const PdfInvoiceItemModel(
                          title: 'MacBook Pro',
                          qty: 100,
                          price: 6600,
                        ),
                        const PdfInvoiceItemModel(
                          title: 'Dell Probook',
                          qty: 23,
                          price: 5500,
                        ),
                      ],
                    );

                    final expensesTemplate = ExpensesInvoiceTemplate(
                      title: 'Expenses Invoice',

                      primaryColor: PdfColors.green,
                      qrCode: 'https://www.google.com',
                      headers: ['Item', 'Qty', 'Price', 'Total'],
                      data: expensesInvoice,
                      pdfConfig: pdfConfig ?? CairoPdfFontConfig(),
                    );

                    // template: InvoicePdfTemplate(invoice),
                    // template: ReceiptVoucherTemplate(
                    //   data: receipt,
                    //   pdfConfig: CairoPdfFontConfig(),
                    // ),

                    final pdfPreviewPage =
                        PdfPreviewPage<PdfExpensesInvoiceModel>(
                          template: expensesTemplate,
                        );

                    /// Preview the PDF
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => pdfPreviewPage),
                    );
                  } catch (e) {
                    print('Error generating PDF $e');
                  }
                },
              ),
              ElevatedButton(
                child: const Text('Generate Receipt Voucher PDF'),
                onPressed: () async {
                  late final receipt = ReceiptVoucherModel(
                    id: 'RV-001',
                    date: DateTime.now(),
                    payerName: 'Mohamed',
                    amount: 1000,
                    paymentMethod: 'Cash',
                    statement: 'Payment for invoice',
                    receiverName: 'John',
                  );

                  /// TRY TO GENERATE THE PDF
                  try {
                    if (!context.mounted) return;

                    final receiptTemplate = ReceiptVoucherTemplate(
                      data: receipt,
                      pdfConfig: pdfConfig ?? CairoPdfFontConfig(),
                    );

                    final pdfPreviewPage = PdfPreviewPage<ReceiptVoucherModel>(
                      template: receiptTemplate,
                    );

                    /// Preview the PDF
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => pdfPreviewPage),
                    );
                  } catch (e) {
                    print('Error generating PDF $e');
                  }
                },
              ),

              /// product invoice pdf
              ElevatedButton(
                child: const Text('Generate Invoice PDF'),
                onPressed: () async {
                  final productInvoice = PdfInvoiceModel(
                    invoiceNo: 'INV-001',
                    customerName: 'Mohamed',
                    date: DateTime.now(),
                    items: [
                      const PdfInvoiceItem(
                        title: 'Samsung Galaxy S23',
                        qty: 1,
                        price: 1000,
                      ),
                      const PdfInvoiceItem(
                        title: 'Samsung Galaxy S24',
                        qty: 1,
                        price: 1000,
                      ),
                      const PdfInvoiceItem(
                        title: 'Samsung Galaxy S25',
                        qty: 1,
                        price: 1000,
                      ),
                    ],
                  );
                  final invoiceTemplate = InvoiceTemplate(
                    title: 'Product Invoice',
                    headers: ['Item', 'Qty', 'Price', 'Total'],
                    data: productInvoice,
                    pdfConfig: pdfConfig ?? CairoPdfFontConfig(),
                  );

                  /// Preview the PDF
                  final pdfPreviewPage = PdfPreviewPage<PdfInvoiceModel>(
                    template: invoiceTemplate,
                  );
                  if (!context.mounted) return;

                  /// Preview the PDF
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => pdfPreviewPage),
                  );
                },
              ),

              /// ListStringsTemplate
              ElevatedButton(
                child: const Text('Generate List Strings PDF'),
                onPressed: () async {
                  final listStrings = PdfListStringsModel(
                    id: 'LS-001',
                    date: DateTime.now(),
                    customer: const PdfPartyModel(
                      name: 'Mohamed',
                      phone: '051235678',
                      email: 'mohamed@example.com',
                    ),
                    discount: 100,
                    tax: 10,
                    total: 1000,
                    paymentMethod: 'Cash',
                    items: [
                      ['Item 1', 'Item 2', 'Item 3'],
                      ['Item 4', 'Item 5', 'Item 6'],
                      ['Item 7', 'Item 8', 'Item 9'],
                    ],
                  );
                  final listStringsTemplate = ListStringsTemplate(
                    headers: ['Item'],
                    data: listStrings,
                    pdfConfig: pdfConfig ?? CairoPdfFontConfig(),
                  );
                  final pdfPreviewPage = PdfPreviewPage<PdfListStringsModel>(
                    template: listStringsTemplate,
                  );
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => pdfPreviewPage),
                  );
                },
              ),
            ].map((e) {
              return Padding(padding: const EdgeInsets.all(8.0), child: e);
            }).toList(),
      ),
    );
  }
}
