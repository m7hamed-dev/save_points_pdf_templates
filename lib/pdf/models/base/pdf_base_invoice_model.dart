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
    this.taxRate,
    this.paymentMethod = '',
    this.dueDate,
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

  /// The rate every line is charged at, for a document whose lines do not
  /// each carry their own [PdfInvoiceItemModel.taxRate].
  ///
  /// A convenience for the common case — one VAT rate across the whole
  /// invoice — so the caller does not repeat it on every line. A line's own
  /// rate still wins.
  final double? taxRate;

  final String paymentMethod;

  /// When payment is due. Printed beside the issue date and drives
  /// [isOverdueOn].
  final DateTime? dueDate;

  final double? _total;
  final double? _paidAmount;

  /// Sum of `qty * price` across [items], before any discount or tax.
  double get subtotal =>
      chargedItems.fold(0.0, (sum, item) => sum + item.subtotal);

  /// Discount recorded on the lines themselves.
  double get itemsDiscount =>
      chargedItems.fold(0.0, (sum, item) => sum + item.discount);

  /// The lines as they will be charged, with [taxRate] filled in on any line
  /// that does not set its own.
  List<PdfInvoiceItemModel> get chargedItems {
    final rate = taxRate;
    if (rate == null) return items;
    return [
      for (final item in items)
        item.taxRate == null ? item.copyWith(taxRate: rate) : item,
    ];
  }

  /// Tax recorded on the lines themselves.
  double get itemsTax => chargedItems.fold(0.0, (sum, item) => sum + item.tax);

  /// Tax grouped by the rate charged, lowest rate first.
  ///
  /// A tax invoice that mixes rates has to show what was taxed at each. Lines
  /// that carry no tax at all are still listed, at 0% — a zero-rated line is
  /// a statement, not an omission.
  List<PdfTaxBand> get taxBreakdown {
    final bands = <double, ({double base, double tax})>{};
    for (final item in chargedItems) {
      final rate = item.effectiveTaxRate;
      final current = bands[rate] ?? (base: 0.0, tax: 0.0);
      bands[rate] = (
        base: current.base + item.taxableAmount,
        tax: current.tax + item.tax,
      );
    }
    final rates = bands.keys.toList()..sort();
    return [
      for (final rate in rates)
        PdfTaxBand(
          rate: rate,
          taxableAmount: bands[rate]!.base,
          tax: bands[rate]!.tax,
        ),
    ];
  }

  /// True when the lines are not all charged at the same rate, which is when
  /// a breakdown earns its place on the page.
  bool get hasMixedTaxRates => taxBreakdown.length > 1;

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

  /// True when money is still owed and [dueDate] has passed.
  ///
  /// Takes the date to compare against rather than reading the clock, so a
  /// document renders the same whenever it is printed and a test can pin it.
  bool isOverdueOn(DateTime date) {
    final due = dueDate;
    if (due == null || isFullyPaid) return false;
    return date.isAfter(due);
  }

  /// [isOverdueOn] against the current date.
  bool get isOverdue => isOverdueOn(DateTime.now());
}
