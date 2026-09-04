import 'package:save_points_pdf_templates/pdf/models/pdf_invoice_types.dart';

/// Every word the package puts on a page.
///
/// The templates used to switch between two hard-coded strings inline —
/// `labels.subtotal` — which made the package bilingual by
/// construction: a third language meant editing every template. Naming the
/// labels here instead means a French or Turkish document is a subclass, and
/// changing `BILL TO` to `INVOICE TO` is one override rather than a fork.
///
/// ```dart
/// class FrenchLabels extends PdfLabels {
///   const FrenchLabels();
///   @override String get billTo => 'FACTURER À';
///   @override String get subtotal => 'Sous-total';
///   // …everything not overridden stays English.
/// }
///
/// final config = PdfConfig(locale: 'fr', labels: const FrenchLabels());
/// ```
///
/// The defaults are English. [PdfArabicLabels] is the Arabic set, and a
/// right-to-left config picks it up on its own.
class PdfLabels {
  const PdfLabels();

  // ── The document's own name ──────────────────────────────────────────────

  /// What the document is called, as the largest words on the page.
  ///
  /// Comes from [PdfInvoiceType] by default, which carries an English and an
  /// Arabic name for each of its 36 kinds. A third language overrides this —
  /// otherwise a French invoice is headed `Sales Invoice`.
  String documentType(PdfInvoiceType type) => type.english;

  /// The smaller name printed under [documentType], empty for none.
  ///
  /// The default pairs the English name with the Arabic one, which is what a
  /// GCC document is expected to carry. A set for a third language should
  /// override this to `''` unless it genuinely has a second name to show.
  String documentSubtitle(PdfInvoiceType type) => type.arabic;

  // ── Masthead ─────────────────────────────────────────────────────────────

  /// Precedes the document number: `No. INV-2026-0042`.
  String get documentNumber => 'No.';
  String get vat => 'VAT';
  String get commercialRegister => 'CR';

  /// `Page 2 / 7`.
  String get page => 'Page';

  // ── Parties ──────────────────────────────────────────────────────────────

  String get billTo => 'BILL TO';
  String get paidTo => 'PAID TO';
  String get deliverTo => 'DELIVER TO';
  String get quotedTo => 'QUOTED TO';
  String get statementFor => 'STATEMENT FOR';

  /// Party label on a free-form tabular report.
  String get reportFor => 'FOR';

  // ── Dates and references ─────────────────────────────────────────────────

  String get date => 'Date';
  String get dueDate => 'Due';
  String get validUntil => 'Valid until';
  String get periodFrom => 'From';
  String get periodTo => 'To';
  String get reference => 'Reference';
  String get address => 'Address';
  String get carrier => 'Carrier';
  String get category => 'Category';

  // ── The item table ───────────────────────────────────────────────────────

  String get description => 'Description';
  String get quantity => 'Qty';
  String get unit => 'Unit';
  String get unitPrice => 'Unit Price';
  String get amount => 'Amount';
  String get discount => 'Discount';
  String get tax => 'Tax';

  /// Shown in place of the table body when there is nothing to list.
  String get noItems => 'No items';
  String get noRows => 'No rows';
  String get noMovements => 'No movements';

  /// Sole column header on a report that supplied none.
  String get value => 'Value';

  /// Row count on a report's meta block.
  String get rowCount => 'Rows';

  // ── Money ────────────────────────────────────────────────────────────────

  String get subtotal => 'Subtotal';
  String get total => 'TOTAL';
  String get paid => 'Paid';
  String get balanceDue => 'Balance Due';
  String get taxBreakdown => 'TAX BREAKDOWN';
  String get taxableAmount => 'Taxable';
  String get taxRate => 'Rate';

  // ── Status ───────────────────────────────────────────────────────────────

  String get statusPaid => 'PAID';
  String get statusUnpaid => 'UNPAID';
  String get statusOverdue => 'OVERDUE';
  String get statusValid => 'VALID';
  String get statusExpired => 'EXPIRED';
  String get settledInFull => 'Settled in full';
  String get partiallySettled => 'Partially settled';

  // ── Blocks ───────────────────────────────────────────────────────────────

  String get notes => 'NOTES';
  String get payment => 'PAYMENT';
  String get paymentMethod => 'Payment';
  String get method => 'Method';
  String get status => 'Status';
  String get terms => 'TERMS';
  String get stamp => 'Stamp';

  // ── Signatures ───────────────────────────────────────────────────────────

  String get issuedBy => 'Issued by';
  String get receivedBy => 'Received by';
  String get approvedBy => 'Approved by';
  String get paidBy => 'Paid by';
  String get deliveredBy => 'Delivered by';
  String get quotedBy => 'Quoted by';
  String get acceptedBy => 'Accepted by';
  String get payer => 'Payer';

  // ── Vouchers ─────────────────────────────────────────────────────────────

  String get amountReceived => 'AMOUNT RECEIVED';
  String get amountPaid => 'AMOUNT PAID';
  String get receivedFrom => 'Received from';
  String get disbursedTo => 'Paid to';
  String get inWords => 'In words';
  String get voucherMethod => 'Payment method';
  String get voucherFor => 'For';
  String get voucherDate => 'Date';

  // ── Statement of account ─────────────────────────────────────────────────

  String get details => 'Details';
  String get debit => 'Debit';
  String get credit => 'Credit';
  String get balance => 'Balance';
  String get openingBalance => 'Opening balance';
  String get totalDebit => 'Total debit';
  String get totalCredit => 'Total credit';
  String get balanceOwed => 'BALANCE DUE';
  String get balanceInCredit => 'BALANCE IN CREDIT';

  // ── Purchase order ───────────────────────────────────────────────────────

  String get supplier => 'SUPPLIER';
  String get expectedDelivery => 'Expected';
  String get orderedBy => 'Ordered by';

  // ── Credit and debit notes ───────────────────────────────────────────────

  String get againstInvoice => 'Against invoice';
  String get reason => 'REASON';
  String get creditedTo => 'CREDITED TO';
  String get debitedTo => 'DEBITED TO';
  String get totalCredited => 'TOTAL CREDITED';
  String get totalDebited => 'TOTAL DEBITED';

  // ── Payslip ──────────────────────────────────────────────────────────────

  /// A payslip has no [PdfInvoiceType] of its own, so it is named here.
  String get payslip => 'Payslip';
  String get employee => 'EMPLOYEE';
  String get employeeId => 'Employee no.';
  String get jobTitle => 'Position';
  String get payPeriod => 'Period';
  String get earnings => 'EARNINGS';
  String get deductions => 'DEDUCTIONS';
  String get grossPay => 'Gross pay';
  String get totalDeductions => 'Total deductions';
  String get netPay => 'NET PAY';

  // ── Marks ────────────────────────────────────────────────────────────────

  String get copy => 'COPY';
  String get draft => 'DRAFT';
  String get original => 'ORIGINAL';
  String get duplicate => 'DUPLICATE';
}

/// The Arabic label set, used automatically by a right-to-left `PdfConfig`
/// whose font can actually draw Arabic.
class PdfArabicLabels extends PdfLabels {
  const PdfArabicLabels();

  @override
  String documentType(PdfInvoiceType type) => type.arabic;

  @override
  String documentSubtitle(PdfInvoiceType type) => type.english;

  @override
  String get documentNumber => 'رقم';
  @override
  String get vat => 'الرقم الضريبي';
  @override
  String get commercialRegister => 'السجل التجاري';
  @override
  String get page => 'صفحة';

  @override
  String get billTo => 'فاتورة إلى';
  @override
  String get paidTo => 'صرف إلى';
  @override
  String get deliverTo => 'تسليم إلى';
  @override
  String get quotedTo => 'عرض إلى';
  @override
  String get statementFor => 'كشف حساب';
  @override
  String get reportFor => 'إلى';

  @override
  String get date => 'التاريخ';
  @override
  String get dueDate => 'الاستحقاق';
  @override
  String get validUntil => 'ساري حتى';
  @override
  String get periodFrom => 'من';
  @override
  String get periodTo => 'إلى';
  @override
  String get reference => 'المرجع';
  @override
  String get address => 'العنوان';
  @override
  String get carrier => 'الناقل';
  @override
  String get category => 'التصنيف';

  @override
  String get description => 'البيان';
  @override
  String get quantity => 'الكمية';
  @override
  String get unit => 'الوحدة';
  @override
  String get unitPrice => 'سعر الوحدة';
  @override
  String get amount => 'الإجمالي';
  @override
  String get discount => 'الخصم';
  @override
  String get tax => 'الضريبة';
  @override
  String get noItems => 'لا توجد عناصر';
  @override
  String get noRows => 'لا توجد بيانات';
  @override
  String get noMovements => 'لا توجد حركات';
  @override
  String get value => 'القيمة';
  @override
  String get rowCount => 'عدد السطور';

  @override
  String get subtotal => 'الإجمالي الفرعي';
  @override
  String get total => 'الإجمالي';
  @override
  String get paid => 'المدفوع';
  @override
  String get balanceDue => 'المتبقي';
  @override
  String get taxBreakdown => 'تفصيل الضريبة';
  @override
  String get taxableAmount => 'الوعاء';
  @override
  String get taxRate => 'النسبة';

  @override
  String get statusPaid => 'مدفوعة';
  @override
  String get statusUnpaid => 'غير مدفوعة';
  @override
  String get statusOverdue => 'متأخرة';
  @override
  String get statusValid => 'ساري';
  @override
  String get statusExpired => 'منتهي';
  @override
  String get settledInFull => 'مسددة بالكامل';
  @override
  String get partiallySettled => 'مسددة جزئياً';

  @override
  String get notes => 'ملاحظات';
  @override
  String get payment => 'الدفع';
  @override
  String get paymentMethod => 'طريقة الدفع';
  @override
  String get method => 'الطريقة';
  @override
  String get status => 'الحالة';
  @override
  String get terms => 'الشروط';
  @override
  String get stamp => 'الختم';

  @override
  String get issuedBy => 'المحرر';
  @override
  String get receivedBy => 'المستلم';
  @override
  String get approvedBy => 'المعتمد';
  @override
  String get paidBy => 'الصارف';
  @override
  String get deliveredBy => 'المُسلِّم';
  @override
  String get quotedBy => 'المُعِد';
  @override
  String get acceptedBy => 'الموافقة';
  @override
  String get payer => 'المسلّم';

  @override
  String get amountReceived => 'المبلغ المستلم';
  @override
  String get amountPaid => 'المبلغ المصروف';
  @override
  String get receivedFrom => 'استلمنا من السيد / السيدة';
  @override
  String get disbursedTo => 'صرفنا إلى السيد / السيدة';
  @override
  String get inWords => 'فقط وقدره';
  @override
  String get voucherMethod => 'وذلك عن طريق';
  @override
  String get voucherFor => 'وذلك عن';
  @override
  String get voucherDate => 'بتاريخ';

  @override
  String get details => 'البيان';
  @override
  String get debit => 'مدين';
  @override
  String get credit => 'دائن';
  @override
  String get balance => 'الرصيد';
  @override
  String get openingBalance => 'الرصيد الافتتاحي';
  @override
  String get totalDebit => 'إجمالي المدين';
  @override
  String get totalCredit => 'إجمالي الدائن';
  @override
  String get balanceOwed => 'الرصيد المستحق';
  @override
  String get balanceInCredit => 'الرصيد لكم';

  @override
  String get supplier => 'المورّد';
  @override
  String get expectedDelivery => 'التسليم المتوقع';
  @override
  String get orderedBy => 'الطالب';

  @override
  String get againstInvoice => 'بخصوص الفاتورة';
  @override
  String get reason => 'السبب';
  @override
  String get creditedTo => 'إشعار دائن إلى';
  @override
  String get debitedTo => 'إشعار مدين إلى';
  @override
  String get totalCredited => 'إجمالي الإشعار الدائن';
  @override
  String get totalDebited => 'إجمالي الإشعار المدين';

  @override
  String get payslip => 'قسيمة راتب';
  @override
  String get employee => 'الموظف';
  @override
  String get employeeId => 'الرقم الوظيفي';
  @override
  String get jobTitle => 'المسمى الوظيفي';
  @override
  String get payPeriod => 'الفترة';
  @override
  String get earnings => 'الاستحقاقات';
  @override
  String get deductions => 'الاستقطاعات';
  @override
  String get grossPay => 'إجمالي الاستحقاق';
  @override
  String get totalDeductions => 'إجمالي الاستقطاع';
  @override
  String get netPay => 'صافي الراتب';

  @override
  String get copy => 'نسخة';
  @override
  String get draft => 'مسودة';
  @override
  String get original => 'أصل';
  @override
  String get duplicate => 'صورة';
}
