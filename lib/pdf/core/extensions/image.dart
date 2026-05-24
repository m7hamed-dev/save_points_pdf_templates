import 'dart:typed_data';

import 'package:pdf/widgets.dart' as pw;

extension PdfImageExtension on Uint8List {
  ///
  pw.Widget toImage({double size = 60.0}) {
    return pw.Container(
      width: size,
      height: size,
      decoration: pw.BoxDecoration(
        image: pw.DecorationImage(image: pw.MemoryImage(this)),
      ),
    );
  }
}
