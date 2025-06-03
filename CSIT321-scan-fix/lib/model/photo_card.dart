// ignore_for_file: public_member_api_docs, sort_constructors_first
// To parse this JSON data, do
//
//     final card = cardFromJson(jsonString);

import 'dart:convert';

PhotoCard cardFromJson(String str) => PhotoCard.fromJson(json.decode(str));

String cardToJson(PhotoCard data) => json.encode(data.toJson());

class PhotoCard {
  int? id;
  String? firstName;
  String? address;
  DateTime? dateOfBirth;
  String? cardNumber;
  DateTime? expiryDate;
  String? lastName;
  String? photoCardNumber;
  String? gender;
  String? email;

  PhotoCard({
    this.id,
    this.firstName,
    this.address,
    this.dateOfBirth,
    this.cardNumber,
    this.expiryDate,
    this.lastName,
    this.photoCardNumber,
    this.gender,
    this.email,
  });

  factory PhotoCard.fromJson(Map<String, dynamic> json) => PhotoCard(
    id: json["id"],
    firstName: json["first_name"],
    address: json["address"],
    dateOfBirth: json["date_of_birth"] == null ? null : DateTime.parse(json["date_of_birth"]),
    cardNumber: json["card_number"],
    expiryDate: json["expiry_date"] == null ? null : DateTime.parse(json["expiry_date"]),
    lastName: json["last_name"],
    photoCardNumber: json["photo_card_number"],
    gender: json["gender"],
    email: json["email"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "first_name": firstName,
    "address": address,
    "date_of_birth": "${dateOfBirth!.year.toString().padLeft(4, '0')}-${dateOfBirth!.month.toString().padLeft(2, '0')}-${dateOfBirth!.day.toString().padLeft(2, '0')}",
    "card_number": cardNumber,
    "expiry_date": "${expiryDate!.year.toString().padLeft(4, '0')}-${expiryDate!.month.toString().padLeft(2, '0')}-${expiryDate!.day.toString().padLeft(2, '0')}",
    "last_name": lastName,
    "photo_card_number": photoCardNumber,
    "gender": gender,
    "email": email,
  };

  @override
  String toString() {
    return 'Card(id: $id, firstName: $firstName, address: $address, dateOfBirth: $dateOfBirth, cardNumber: $cardNumber, expiryDate: $expiryDate, lastName: $lastName, photoCardNumber: $photoCardNumber, gender: $gender, email: $email)';
  }
}