import 'package:save_points_pdf_templates/pdf/models/pdf_invoice_types.dart';

/// base model for all invoice models
/// this model is used to store the base information for all invoice models
/// it contains the id, headers, title, date, type, and notes
/// it is used to store the base information for all invoice models
/// it is used to store the base information for all invoice models
abstract class PdfBaseInvoiceModel {
  const PdfBaseInvoiceModel({
    required this.id,
    this.headers = const [],
    this.title = 'Unknown',
    this.date,
    required this.type,
    this.notes,
  });

  final String id;
  final List<String> headers;
  final String title;
  final DateTime? date;
  final InvoiceType type;
  final String? notes;
}
