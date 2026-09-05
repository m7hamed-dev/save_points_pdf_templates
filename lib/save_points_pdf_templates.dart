/// Printable business documents for Flutter — invoices, expense records,
/// vouchers and tabular reports — with Arabic/RTL support.
///
/// ```dart
/// import 'package:save_points_pdf_templates/save_points_pdf_templates.dart';
///
/// final config = PdfConfig(
///   fontPath: 'assets/fonts/Cairo-Regular.ttf',
///   boldFontPath: 'assets/fonts/Cairo-Bold.ttf',
///   locale: 'ar',
///   company: const PdfPartyModel(name: 'Save Points'),
/// );
///
/// final template = SaleInvoiceTemplate(data: invoice, pdfConfig: config);
/// final bytes = await PdfGenerator.generate(template: template);
/// ```
library;

/// Page formats and colors from the underlying `pdf` package, re-exported so
/// callers can set `PdfPageFormat.a5` or `PdfColors.teal` without adding a
/// direct dependency.
export 'package:pdf/pdf.dart' show PdfColor, PdfColors, PdfPageFormat;

// ── Rendering ─────────────────────────────────────────────────────────────
export 'pdf/core/formatters/pdf_amount_in_words.dart';
export 'pdf/core/formatters/pdf_formatters.dart';
export 'pdf/core/widgets/pdf_data_table.dart';
export 'pdf/core/widgets/pdf_sections.dart';
export 'pdf/core/widgets/pdf_ui.dart';
export 'pdf/generator/pdf_generator.dart';

// ── Models ────────────────────────────────────────────────────────────────
export 'pdf/models/base/pdf_base_invoice_model.dart';
export 'pdf/models/base/pdf_invoice_item_model.dart';
export 'pdf/models/base/pdf_party_model.dart';
export 'pdf/models/pdf_adjustment_note_model.dart';
export 'pdf/models/pdf_delivery_note_model.dart';
export 'pdf/models/pdf_expenses_model.dart';
export 'pdf/models/pdf_invoice_item.dart';
export 'pdf/models/pdf_invoice_model.dart';
export 'pdf/models/pdf_invoice_types.dart';
export 'pdf/models/pdf_list_string_model.dart';
export 'pdf/models/pdf_payslip_model.dart';
export 'pdf/models/pdf_purchase_order_model.dart';
export 'pdf/models/pdf_quotation_model.dart';
export 'pdf/models/pdf_receipt_voucher_model.dart';
export 'pdf/models/pdf_sale_invoice_model.dart';
export 'pdf/models/pdf_statement_model.dart';
export 'pdf/models/pdf_voucher_model.dart';

// ── Configuration ─────────────────────────────────────────────────────────
export 'pdf/pdf_config/pdf_cairo_config.dart';
export 'pdf/pdf_config/pdf_config.dart';
export 'pdf/pdf_config/pdf_labels.dart';
export 'pdf/pdf_config/pdf_theme.dart';

// ── Output ────────────────────────────────────────────────────────────────
export 'pdf/pdf_documents.dart';
export 'pdf/pdf_preview_page.dart';

// ── Templates ─────────────────────────────────────────────────────────────
export 'pdf/templates/adjustment_note_template.dart';
export 'pdf/templates/base_template.dart';
export 'pdf/templates/delivery_note_template.dart';
export 'pdf/templates/expenses_invoice_template.dart';
export 'pdf/templates/invoice_template.dart';
export 'pdf/templates/itemized_invoice_template.dart';
export 'pdf/templates/list_strings_template.dart';
export 'pdf/templates/payment_voucher_template.dart';
export 'pdf/templates/payslip_template.dart';
export 'pdf/templates/purchase_order_template.dart';
export 'pdf/templates/quotation_template.dart';
export 'pdf/templates/receipt_voucher_template.dart';
export 'pdf/templates/sale_invoice_template.dart';
export 'pdf/templates/statement_template.dart';
export 'pdf/templates/thermal_receipt_template.dart';
export 'pdf/templates/voucher_template.dart';
