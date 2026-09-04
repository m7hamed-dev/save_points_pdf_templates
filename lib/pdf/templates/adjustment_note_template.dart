import 'package:pdf/widgets.dart' as pw;
import 'package:save_points_pdf_templates/pdf/models/pdf_adjustment_note_model.dart';
import 'package:save_points_pdf_templates/pdf/templates/itemized_invoice_template.dart';

/// The shared layout behind a credit and a debit note.
///
/// Both correct an invoice that has already gone out, so both lead with the
/// invoice they are against and the reason for the correction — printed above
/// the lines, where an auditor looks first, not buried in the notes.
abstract class AdjustmentNoteTemplate<T extends PdfAdjustmentNoteModel>
    extends ItemizedInvoiceTemplate<T> {
  AdjustmentNoteTemplate({
    required super.data,
    required super.pdfConfig,
    super.headers,
    super.title,
    super.qrCode,
    super.qrCodeSize,
    super.theme,
    super.pageFormat,
    super.showRowNumbers,
    super.showSignatures,
    super.signatureLabels,
  });

  /// Nothing is settled by a note; it moves a balance on an invoice.
  @override
  bool get showSettlement => false;

  @override
  Map<String, String> get metaFields => {
    ...super.metaFields,
    labels.againstInvoice: [
      data.againstInvoice,
      if (data.againstInvoiceDate != null)
        '(${format.date(data.againstInvoiceDate)})',
    ].join(' '),
  };

  /// Why the note was raised, above the signatures — an auditor reads it
  /// before the amounts, not after somebody has signed.
  @override
  List<pw.Widget> extraBlocks(pw.Context context) => [
    ui.gap(1.5),
    sections.notes(data.reason, label: labels.reason),
  ];
}

/// A credit note (إشعار دائن): value returned to the customer.
class CreditNoteTemplate extends AdjustmentNoteTemplate<PdfCreditNoteModel> {
  CreditNoteTemplate({
    required super.data,
    required super.pdfConfig,
    super.headers,
    super.title,
    super.qrCode,
    super.qrCodeSize,
    super.theme,
    super.pageFormat,
    super.showRowNumbers,
    super.showSignatures,
    super.signatureLabels,
  });

  @override
  String get partyLabel => labels.creditedTo;

  @override
  pw.Widget buildTotals() => sections.totalsPanel(
    leading: sections.infoBlock(settlementLabel, settlementLines),
    lines: totalLines,
    totalLabel: labels.totalCredited,
    totalValue: data.total,
  );
}

/// A debit note (إشعار مدين): value charged on top of an invoice.
class DebitNoteTemplate extends AdjustmentNoteTemplate<PdfDebitNoteModel> {
  DebitNoteTemplate({
    required super.data,
    required super.pdfConfig,
    super.headers,
    super.title,
    super.qrCode,
    super.qrCodeSize,
    super.theme,
    super.pageFormat,
    super.showRowNumbers,
    super.showSignatures,
    super.signatureLabels,
  });

  @override
  String get partyLabel => labels.debitedTo;

  @override
  pw.Widget buildTotals() => sections.totalsPanel(
    leading: sections.infoBlock(settlementLabel, settlementLines),
    lines: totalLines,
    totalLabel: labels.totalDebited,
    totalValue: data.total,
  );
}
