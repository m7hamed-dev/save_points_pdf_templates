import 'package:save_points_pdf_templates/pdf/models/base/pdf_invoice_item_model.dart';
import 'package:save_points_pdf_templates/pdf/models/base/pdf_party_model.dart';
import 'package:save_points_pdf_templates/pdf/models/pdf_invoice_types.dart';

/// Fields every printable document shares: an identifier, a date, a typed
/// title and optional notes.
abstract class PdfBaseInvoiceModel {
  const PdfBaseInvoiceModel({
    required this.id,
    required this.type,
    this.headers = const [],
    this.title = '',
    this.date,
    this.notes,
    this.reference,
  });

  /// Document number as printed, e.g. `INV-2026-0042`.
  final String id;

  /// Optional column headers, used by table-driven documents.
  final List<String> headers;

  /// Overrides the label taken from [type] when not empty.
  final String title;

  /// Issue date. Templates print `-` when null instead of throwing.
  final DateTime? date;

  /// Drives the bilingual document label.
  final PdfInvoiceType type;

  /// Free text printed in a bordered block under the table.
  final String? notes;

  /// Optional cross-reference — a purchase order, a returned invoice number.
  final String? reference;

  /// The English label to print: [title] when set, otherwise [type].
  String get displayTitle => title.isNotEmpty ? title : type.english;

  /// The Arabic label to print, empty when [title] is set.
  ///
  /// A custom title is one string in a language the model does not know, so it
  /// replaces the pair rather than joining it — printing it beside [type]'s
  /// Arabic would caption `Stock Count` as `تقرير`.
  String get displayTitleAr => title.isNotEmpty ? '' : type.arabic;
}

/// Base class for documents made of priced line items.
///
/// Totals are computed from [items] unless an explicit `total` is supplied,
/// so a caller can either let the package do the math or pass server-side
/// figures that must be reproduced exactly.
abstract class PdfItemizedInvoiceModel extends PdfBaseInvoiceModel {
  const PdfItemizedInvoiceModel({
    required super.id,
    required super.type,
    super.date,
    super.notes,
    super.title,
    super.headers,
    super.reference,
    this.customer = PdfPartyModel.empty,
    this.items = const [],
    this.discount = 0.0,
    this.tax = 0.0,
    this.paymentMethod = '',
    double? total,
    double? paidAmount,
  }) : _total = total,
       _paidAmount = paidAmount;

  /// The other party — customer, supplier or beneficiary.
  final PdfPartyModel customer;

  final List<PdfInvoiceItemModel> items;

  /// Document-level discount, on top of any per-line discount.
  final double discount;

  /// Document-level tax, on top of any per-line tax.
  final double tax;

  final String paymentMethod;

  final double? _total;
  final double? _paidAmount;

  /// Sum of `qty * price` across [items], before any discount or tax.
  double get subtotal => items.fold(0.0, (sum, item) => sum + item.subtotal);

  /// Discount recorded on the lines themselves.
  double get itemsDiscount =>
      items.fold(0.0, (sum, item) => sum + item.discount);

  /// Tax recorded on the lines themselves.
  double get itemsTax => items.fold(0.0, (sum, item) => sum + item.tax);

  /// Line discounts plus the document-level [discount].
  double get totalDiscount => discount + itemsDiscount;

  /// Line tax plus the document-level [tax].
  double get totalTax => tax + itemsTax;

  /// The amount due: the explicit total when one was supplied, otherwise
  /// `subtotal - totalDiscount + totalTax`.
  double get total => _total ?? (subtotal - totalDiscount + totalTax);

  /// Amount already settled. Defaults to [total] — a fully paid document.
  double get paid => _paidAmount ?? total;

  /// Outstanding balance, never negative in display terms.
  double get due => total - paid;

  /// True when [paid] covers [total].
  bool get isFullyPaid => due <= 0;

  /// True when an explicit total was provided instead of a computed one.
  bool get hasExplicitTotal => _total != null;
}
