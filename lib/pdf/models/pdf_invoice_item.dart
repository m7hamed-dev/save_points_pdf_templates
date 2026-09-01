import 'package:save_points_pdf_templates/pdf/models/base/pdf_invoice_item_model.dart';

/// Former duplicate of [PdfInvoiceItemModel]. Kept as an alias so existing
/// call sites keep compiling; the two classes had identical required
/// parameters, so no migration is needed beyond renaming the type.
@Deprecated('Use PdfInvoiceItemModel instead. Will be removed in 1.0.0.')
typedef PdfInvoiceItem = PdfInvoiceItemModel;
