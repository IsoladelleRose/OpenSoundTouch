import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/radio_station.dart';

class RadioSearchService {
  final String backendBaseUrl;
  final http.Client _http;

  RadioSearchService({required this.backendBaseUrl, http.Client? httpClient})
      : _http = httpClient ?? http.Client();

  Future<List<RadioStation>> search({
    String? name,
    String? country,
    String? language,
    int limit = 25,
  }) async {
    final uri = Uri.parse('$backendBaseUrl/api/radio/search').replace(
      queryParameters: {
        if (name != null && name.isNotEmpty) 'name': name,
        if (country != null && country.isNotEmpty) 'country': country,
        if (language != null && language.isNotEmpty) 'language': language,
        'limit': '$limit',
      },
    );
    final response = await _http.get(uri).timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw Exception('Radio search failed: ${response.statusCode} ${response.body}');
    }
    final List<dynamic> list = json.decode(response.body) as List<dynamic>;
    return list
        .map((e) => RadioStation.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }
}
