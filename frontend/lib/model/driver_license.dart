// To parse this JSON data, do
//
//     final driverLicense = driverLicenseFromJson(jsonString);

import 'dart:convert';

DriverLicense driverLicenseFromJson(String str) => DriverLicense.fromJson(json.decode(str));

String driverLicenseToJson(DriverLicense data) => json.encode(data.toJson());

class DriverLicense {
  int? id;
  String? firstName;
  String? lastName;
  String? licenseNumber;
  DateTime? expiryDate;
  String? address;
  String? cardNumber;
  DateTime? dateOfBirth;
  String? email;

  DriverLicense({
    this.id,
    this.firstName,
    this.lastName,
    this.licenseNumber,
    this.expiryDate,
    this.address,
    this.cardNumber,
    this.dateOfBirth,
    this.email,
  });

  factory DriverLicense.fromJson(Map<String, dynamic> json) => DriverLicense(
    id: json["id"],
    firstName: json["first_name"],
    lastName: json["last_name"],
    licenseNumber: json["license_number"],
    expiryDate: json["expiry_date"] == null ? null : DateTime.parse(json["expiry_date"]),
    address: json["address"],
    cardNumber: json["card_number"],
    dateOfBirth: json["date_of_birth"] == null ? null : DateTime.parse(json["date_of_birth"]),
    email: json["email"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "first_name": firstName,
    "last_name": lastName,
    "license_number": licenseNumber,
    "expiry_date": "${expiryDate!.year.toString().padLeft(4, '0')}-${expiryDate!.month.toString().padLeft(2, '0')}-${expiryDate!.day.toString().padLeft(2, '0')}",
    "address": address,
    "card_number": cardNumber,
    "date_of_birth": "${dateOfBirth!.year.toString().padLeft(4, '0')}-${dateOfBirth!.month.toString().padLeft(2, '0')}-${dateOfBirth!.day.toString().padLeft(2, '0')}",
    "email": email,
  };
}