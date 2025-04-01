class ScanModel {
  String? firstName;
  String? lastName;
  String? address;
  String? cardNumber;
  String? dateOfBirth;
  String? expiredDate;
  String? gender;
  String? licenseNumber;
  String? filePath;

  ScanModel({
    this.firstName,
    this.lastName,
    this.address,
    this.cardNumber,
    this.dateOfBirth,
    this.expiredDate,
    this.gender,
    this.licenseNumber,
    this.filePath,
  });

  @override
  String toString() {
    return 'ScanModel{firstName: $firstName, lastName: $lastName, address: $address, cardNumber: $cardNumber, dateOfBirth: $dateOfBirth, expiredDate: $expiredDate, gender: $gender, licenseNumber: $licenseNumber}';
  }
}
