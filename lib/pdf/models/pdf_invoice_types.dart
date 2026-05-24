enum InvoiceType {
  salesInvoice(english: 'Sales Invoice', arabic: 'فاتورة البيع'),
  purchaseInvoice(english: 'Purchase Invoice', arabic: 'فاتورة الشراء'),
  taxInvoice(english: 'Tax Invoice', arabic: 'فاتورة الضريبة'),
  proformaInvoice(english: 'Proforma Invoice', arabic: 'فاتورة المبدئية'),
  returnInvoice(english: 'Return Invoice', arabic: 'فاتورة الإعادة'),
  serviceInvoice(english: 'Service Invoice', arabic: 'فاتورة الخدمة'),
  cashInvoice(english: 'Cash Invoice', arabic: 'فاتورة النقد'),
  creditInvoice(english: 'Credit Invoice', arabic: 'فاتورة الائتمان'),
  creditNote(english: 'Credit Note', arabic: 'بيان الائتمان'),
  debitNote(english: 'Debit Note', arabic: 'بيان الديون'),
  receiptVoucher(english: 'Receipt Voucher', arabic: 'سند قبض'),
  paymentVoucher(english: 'Payment Voucher', arabic: 'فاتورة الدفع'),
  withdrawalVoucher(english: 'Withdrawal Voucher', arabic: 'سند سحب'),
  depositVoucher(english: 'Deposit Voucher', arabic: 'سند تحويل'),
  transferVoucher(english: 'Transfer Voucher', arabic: 'سند تحويل'),
  adjustmentVoucher(english: 'Adjustment Voucher', arabic: 'سند تعديل'),
  purchaseOrder(english: 'Purchase Order', arabic: 'طلب شراء'),
  quotation(english: 'Quotation', arabic: 'عرض سعر'),
  statementOfAccount(english: 'Statement of Account', arabic: 'بيان الحساب'),
  goodsReceipt(english: 'Goods Receipt', arabic: 'سند قبض المنتجات'),
  goodsIssueVoucher(
    english: 'Goods Issue Voucher',
    arabic: 'سند إصدار المنتجات',
  ),
  returnVoucher(english: 'Return Voucher', arabic: 'سند إعادة المنتجات'),
  inventoryCountSheet(
    english: 'Inventory Count Sheet',
    arabic: 'جدول عدد المخزون',
  ),
  inventoryInvoice(english: 'Inventory Invoice', arabic: 'فاتورة المخزون'),
  custodyVoucher(english: 'Custody Voucher', arabic: 'سند الصلاحية'),
  cashReceiptVoucher(english: 'Cash Receipt Voucher', arabic: 'سند قبض النقد'),
  cashPaymentVoucher(english: 'Cash Payment Voucher', arabic: 'سند دفع النقد'),
  receipt(english: 'Receipt', arabic: 'قبض'),
  paymentReceipt(english: 'Payment Receipt', arabic: 'سند قبض الدفع'),
  electronicInvoice(english: 'Electronic Invoice', arabic: 'فاتورة الكترونية'),
  posInvoice(english: 'POS Invoice', arabic: 'فاتورة البيع بالنقطة'),
  shippingInvoice(english: 'Shipping Invoice', arabic: 'فاتورة الشحن'),
  billOfLading(english: 'Bill of Lading', arabic: 'بيان الشحن'),
  deliveryNote(english: 'Delivery Note', arabic: 'بيان التسليم'),
  expensesInvoice(english: 'Expenses Invoice', arabic: 'فاتورة المصروفات'),
  receivingNote(english: 'Receiving Note', arabic: 'بيان الاستلام');

  final String arabic;
  final String english;
  const InvoiceType({required this.arabic, required this.english});
}
