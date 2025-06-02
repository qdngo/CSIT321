import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:sample_assist/model/driver_license.dart';
import 'package:sample_assist/model/photo_card.dart';
import 'package:sample_assist/model/passport.dart';
import 'package:flutter/foundation.dart';

class FetchApi {
  FetchApi._();
  static const String baseUrl = '34.132.238.165:8000';
  static const String getPhotoCard = '/get-photo-card';
  static const String getPassport = '/get-passport';
  static const String getDriverLicense = '/get-driver-license';

  static Future<List<PhotoCard>> getInfoCard(String email) async {
    var uri = Uri.http(baseUrl, getPhotoCard, {'email': email});
    final List<PhotoCard> photoCard = [];
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        for (var item in data) {
          photoCard.add(PhotoCard.fromJson(item));
        }
      } else {
        throw Exception('Failed to load photo card');
      }
    } catch (e) {
      debugPrint('Error in getInfoCard: $e');
      return [];
    }
    return photoCard;
  }

  static Future<List<Passport>> getInfoPassport(String email) async {
    var uri = Uri.http(baseUrl, getPassport, {'email': email});
    final List<Passport> passport = [];
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        for (var item in data) {
          passport.add(Passport.fromJson(item));
        }
      } else {
        throw Exception('Failed to load photo card');
      }
    } catch (e) {
      debugPrint('Error in getInfoCard: $e');
      return [];
    }
    return passport;
  }


  static Future<List<DriverLicense>> getInfoDriverLicense(String email) async {
    var uri = Uri.http(baseUrl, getDriverLicense, {'email': email});
    final List<DriverLicense> driverLicenses = [];
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        for (var item in data) {
          driverLicenses.add(DriverLicense.fromJson(item));
        }
      } else {
        throw Exception('Failed to load photo card');
      }
    } catch (e) {
      debugPrint('Error in getInfoCard: $e');
      return [];
    }
    return driverLicenses;
  }
}
