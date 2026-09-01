import 'package:save_points_pdf_templates/pdf/models/base/pdf_base_invoice_model.dart';
import 'package:save_points_pdf_templates/pdf/models/base/pdf_party_model.dart';
import 'package:save_points_pdf_templates/pdf/models/pdf_invoice_types.dart';

export 'package:save_points_pdf_templates/pdf/models/base/pdf_invoice_item_model.dart';
export 'package:save_points_pdf_templates/pdf/models/base/pdf_party_model.dart';

/// A free-form tabular document: you supply the header row and the cells,
/// the template supplies the styling, pagination and header/footer.
///
/// Use it for reports, stock counts, statements — anything that is a table
/// and does not map onto the typed invoice models.
class PdfListStringsModel extends PdfBaseInvoiceModel {
  const PdfListStringsModel({
    required this.items,
    super.id = '',
    super.date,
    super.notes,
    super.title,
    super.headers,
    super.reference,
    super.type = PdfInvoiceType.report,
    this.customer = PdfPartyModel.empty,
    this.summary = const {},
    this.columnFlex = const [],
  });

  /// Rows of already-formatted cells. Each row should have as many entries
  /// as [PdfBaseInvoiceModel.headers].
  final List<List<String>> items;

  final PdfPartyModel customer;

  /// Optional label/value pairs rendered in the totals panel, in order.
  final Map<String, String> summary;

  /// Relative column widths. Empty means every column gets equal width.
  final List<double> columnFlex;

  static const PdfListStringsModel empty = PdfListStringsModel(items: []);
}
