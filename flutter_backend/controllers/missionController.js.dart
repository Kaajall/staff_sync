import 'dart:convert';
import 'package:http/http.dart' as http;

Future<Map<String, double>> getCoordinates(String locationName, String apiKey) async {
  final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(locationName)}&key=$apiKey');

  try {
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data['status'] == 'OK') {
        final location = data['results'][0]['geometry']['location'];
        return {
          'latitude': location['lat'],
          'longitude': location['lng'],
        };
      } else {
        throw Exception('Geocoding failed: ${data['status']}');
      }
    } else {
      throw Exception('Failed to connect to Google Maps API: ${response.statusCode}');
    }
  } catch (err) {
    throw Exception('Error connecting to Google Maps API: $err');
  }
}