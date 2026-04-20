// import 'dart:convert';
// import 'package:http/http.dart' as http;

// class GooglePlacesService {
//   final String apiKey;

//   GooglePlacesService(this.apiKey);

//   Future<List<String>> getPlaceSuggestions(String input) async {
//     final String url =
//         'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&types=geocode&key=$apiKey';

//     final response = await http.get(Uri.parse(url));

//     if (response.statusCode == 200) {
//       final data = json.decode(response.body);
//       return (data['predictions'] as List)
//           .map((item) => item['description'] as String)
//           .toList();
//     } else {
//       throw Exception('Failed to fetch suggestions');
//     }
//   }
// }
