import 'package:pdf/widgets.dart' as pw;

extension PdfQrExtension on String {
  ///
  pw.Widget qrCode({double qrCodeSize = 80.0}) {
    return pw.BarcodeWidget(
      data: this,
      barcode: pw.Barcode.qrCode(),
      width: qrCodeSize,
      height: qrCodeSize,
      drawText: false,
    );
  }
}
