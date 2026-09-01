/// A company, customer, supplier or employee printed on a document.
class PdfPartyModel {
  const PdfPartyModel({
    this.name = '',
    this.phone = '',
    this.email = '',
    this.address,
    this.taxNumber,
    this.commercialRegister,
    this.website,
  });

  final String name;
  final String phone;
  final String email;
  final String? address;

  /// VAT / tax registration number.
  final String? taxNumber;

  /// Commercial registration (CR) number.
  final String? commercialRegister;

  final String? website;

  /// True when there is nothing worth printing for this party.
  bool get isEmpty =>
      name.isEmpty &&
      phone.isEmpty &&
      email.isEmpty &&
      (address?.isEmpty ?? true) &&
      (taxNumber?.isEmpty ?? true);

  bool get isNotEmpty => !isEmpty;

  static const PdfPartyModel empty = PdfPartyModel();

  PdfPartyModel copyWith({
    String? name,
    String? phone,
    String? email,
    String? address,
    String? taxNumber,
    String? commercialRegister,
    String? website,
  }) {
    return PdfPartyModel(
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      taxNumber: taxNumber ?? this.taxNumber,
      commercialRegister: commercialRegister ?? this.commercialRegister,
      website: website ?? this.website,
    );
  }
}
