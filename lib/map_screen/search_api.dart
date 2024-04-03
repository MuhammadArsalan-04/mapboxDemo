import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:map_box_app/utils/api_key.dart';

Future<List<Map<String, dynamic>>> getSearchPlaces(String searchText) async {
  List<String> placesList = [];
  List<Map<String, dynamic>> data = [];

  try {
    Dio dio = Dio();

    final response = await dio.get(
        "https://api.mapbox.com/geocoding/v5/mapbox.places/$searchText.json?access_token=${APIKEY.accessToken}");

    if (response.statusCode == 200) {
      Map<String, dynamic> placesResponse =
          response.data as Map<String, dynamic>;

      for (Map<String, dynamic> place in placesResponse["features"]) {
        data.add(place);
      }
    } else {
      return [];
    }
  } catch (err) {
    debugPrint(err.toString());
  }
  return data;
}
