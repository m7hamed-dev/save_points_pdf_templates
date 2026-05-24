class PdfPartyModel {
  const PdfPartyModel({
    this.name = '',
    this.phone = '',
    this.email = '',
    this.address,
    this.taxNumber,
  });

  final String name;
  final String phone;
  final String email;
  final String? address;
  final String? taxNumber;

  // empty constructor
  static const PdfPartyModel empty = PdfPartyModel();
}
