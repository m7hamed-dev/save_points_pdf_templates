/// Bilingual document labels.
///
/// Every template prints [english] and [arabic] side by side, so a document
/// is readable by an Arabic customer and an English-speaking auditor without
/// generating it twice. Use [label] to pick one for a given direction.
enum PdfInvoiceType {
  // ── Invoices ────────────────────────────────────────────────────────────
  salesInvoice(english: 'Sales Invoice', arabic: 'فاتورة مبيعات'),
  purchaseInvoice(english: 'Purchase Invoice', arabic: 'فاتورة مشتريات'),
  taxInvoice(english: 'Tax Invoice', arabic: 'فاتورة ضريبية'),
  proformaInvoice(english: 'Proforma Invoice', arabic: 'فاتورة مبدئية'),
  returnInvoice(english: 'Return Invoice', arabic: 'فاتورة مرتجع'),
  serviceInvoice(english: 'Service Invoice', arabic: 'فاتورة خدمات'),
  cashInvoice(english: 'Cash Invoice', arabic: 'فاتورة نقدية'),
  creditInvoice(english: 'Credit Invoice', arabic: 'فاتورة آجلة'),
  electronicInvoice(english: 'Electronic Invoice', arabic: 'فاتورة إلكترونية'),
  posInvoice(english: 'POS Invoice', arabic: 'فاتورة نقطة بيع'),
  shippingInvoice(english: 'Shipping Invoice', arabic: 'فاتورة شحن'),
  expensesInvoice(english: 'Expenses Invoice', arabic: 'فاتورة مصروفات'),
  inventoryInvoice(english: 'Inventory Invoice', arabic: 'فاتورة مخزون'),

  // ── Notes ───────────────────────────────────────────────────────────────
  creditNote(english: 'Credit Note', arabic: 'إشعار دائن'),
  debitNote(english: 'Debit Note', arabic: 'إشعار مدين'),
  deliveryNote(english: 'Delivery Note', arabic: 'إشعار تسليم'),
  receivingNote(english: 'Receiving Note', arabic: 'إشعار استلام'),

  // ── Vouchers ────────────────────────────────────────────────────────────
  receiptVoucher(english: 'Receipt Voucher', arabic: 'سند قبض'),
  paymentVoucher(english: 'Payment Voucher', arabic: 'سند صرف'),
  withdrawalVoucher(english: 'Withdrawal Voucher', arabic: 'سند سحب'),
  depositVoucher(english: 'Deposit Voucher', arabic: 'سند إيداع'),
  transferVoucher(english: 'Transfer Voucher', arabic: 'سند تحويل'),
  adjustmentVoucher(english: 'Adjustment Voucher', arabic: 'سند تسوية'),
  custodyVoucher(english: 'Custody Voucher', arabic: 'سند عهدة'),
  cashReceiptVoucher(english: 'Cash Receipt Voucher', arabic: 'سند قبض نقدي'),
  cashPaymentVoucher(english: 'Cash Payment Voucher', arabic: 'سند صرف نقدي'),
  goodsIssueVoucher(english: 'Goods Issue Voucher', arabic: 'سند صرف بضاعة'),
  returnVoucher(english: 'Return Voucher', arabic: 'سند إرجاع بضاعة'),

  // ── Receipts ────────────────────────────────────────────────────────────
  receipt(english: 'Receipt', arabic: 'إيصال'),
  paymentReceipt(english: 'Payment Receipt', arabic: 'إيصال دفع'),
  goodsReceipt(english: 'Goods Receipt', arabic: 'سند استلام بضاعة'),

  // ── Commercial documents ────────────────────────────────────────────────
  purchaseOrder(english: 'Purchase Order', arabic: 'أمر شراء'),
  quotation(english: 'Quotation', arabic: 'عرض سعر'),
  statementOfAccount(english: 'Statement of Account', arabic: 'كشف حساب'),
  billOfLading(english: 'Bill of Lading', arabic: 'بوليصة شحن'),
  inventoryCountSheet(
    english: 'Inventory Count Sheet',
    arabic: 'كشف جرد المخزون',
  ),
  report(english: 'Report', arabic: 'تقرير');

  const PdfInvoiceType({required this.arabic, required this.english});

  final String arabic;
  final String english;

  /// The label matching the document direction: Arabic when [isRtl].
  String label({bool isRtl = false}) => isRtl ? arabic : english;

  /// `Sales Invoice · فاتورة مبيعات`
  String get bilingual => '$english · $arabic';
}

/// Former name of [PdfInvoiceType]. Renamed to avoid clashing with the
/// `InvoiceType` enums that most accounting apps already declare.
@Deprecated('Use PdfInvoiceType instead. Will be removed in 1.0.0.')
typedef InvoiceType = PdfInvoiceType;
