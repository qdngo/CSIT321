// To parse this JSON data, do
//
//     final passport = passportFromJson(jsonString);

import 'dart:convert';

Passport passportFromJson(String str) => Passport.fromJson(json.decode(str));

String passportToJson(Passport data) => json.encode(data.toJson());

class Passport {
  String? lastName;
  DateTime? dateOfBirth;
  int? id;
  String? firstName;
  DateTime? expiryDate;
  String? email;
  String? documentNumber;
  String? gender;

  Passport({
    this.lastName,
    this.dateOfBirth,
    this.id,
    this.firstName,
    this.expiryDate,
    this.email,
    this.documentNumber,
    this.gender,
  });

  factory Passport.fromJson(Map<String, dynamic> json) => Passport(
    lastName: json["last_name"],
    dateOfBirth: json["date_of_birth"] == null ? null : DateTime.parse(json["date_of_birth"]),
    id: json["id"],
    firstName: json["first_name"],
    expiryDate: json["expiry_date"] == null ? null : DateTime.parse(json["expiry_date"]),
    email: json["email"],
    documentNumber: json["document_number"],
    gender: json["gender"],
  );

  Map<String, dynamic> toJson() => {
    "last_name": lastName,
    "date_of_birth": "${dateOfBirth!.year.toString().padLeft(4, '0')}-${dateOfBirth!.month.toString().padLeft(2, '0')}-${dateOfBirth!.day.toString().padLeft(2, '0')}",
    "id": id,
    "first_name": firstName,
    "expiry_date": "${expiryDate!.year.toString().padLeft(4, '0')}-${expiryDate!.month.toString().padLeft(2, '0')}-${expiryDate!.day.toString().padLeft(2, '0')}",
    "email": email,
    "document_number": documentNumber,
    "gender": gender,
  };
}