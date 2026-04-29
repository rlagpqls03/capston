import 'package:dio/dio.dart';

import '../models/hospital_place.dart';

class HospitalSearchService {
  HospitalSearchService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  static const String _searchUrl =
      'https://places.googleapis.com/v1/places:searchText';

  static const String _apiKey = String.fromEnvironment(
    'GOOGLE_PLACES_API_KEY',
    defaultValue: 'AIzaSyD1OQhW9Yq7Un5PMQbfGvAaxOEMk0vCynI',
  );

  Future<List<HospitalPlace>> searchHospitals({
    required String query,
    required double latitude,
    required double longitude,
  }) async {
    final textQuery = query.trim().isEmpty ? '병원' : query.trim();

    final response = await _dio.post<Map<String, dynamic>>(
      _searchUrl,
      data: {
        'textQuery': textQuery.contains('병원') ? textQuery : '$textQuery 병원',
        'languageCode': 'ko',
        'regionCode': 'KR',
        'pageSize': 10,
        'locationBias': {
          'circle': {
            'center': {
              'latitude': latitude,
              'longitude': longitude,
            },
            'radius': 5000.0,
          },
        },
      },
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': _apiKey,
          'X-Goog-FieldMask':
              'places.displayName,places.formattedAddress,places.location',
        },
      ),
    );

    final places = (response.data?['places'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(HospitalPlace.fromPlacesJson)
        .where((place) => place.latitude != 0 && place.longitude != 0)
        .toList();

    return places;
  }
}
