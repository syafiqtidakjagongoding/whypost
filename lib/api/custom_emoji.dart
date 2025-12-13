import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:whypost/constant/config.dart';

Future<List<CustomEmoji>> fetchCustomEmojis(
  String baseUrl,
  String token,
) async {

    final url = Uri.parse("$baseUrl/api/v1/custom_emojis");

    final headers = {
      "Accept": "application/json",
      "Authorization": "Bearer $token",
    };

    final response = await http.get(url, headers: headers)
        .timeout(
          API_TIMEOUT,
          onTimeout: () {
            throw Exception(
              "Request timed out after ${API_TIMEOUT.inSeconds} seconds",
            );
          },
        );
    ;

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => CustomEmoji.fromJson(e)).toList();
    } else {
      throw Exception("Failed to load custom emojis: ${response.statusCode}");
    }
 
}

class CustomEmoji {
  final String category;
  final String shortcode;
  final String staticUrl;
  final String url;
  final bool visibleInPicker;

  CustomEmoji({
    required this.category,
    required this.shortcode,
    required this.staticUrl,
    required this.url,
    required this.visibleInPicker,
  });
  factory CustomEmoji.fromJson(Map<String, dynamic> json) {
    return CustomEmoji(
      category: json['category'] ?? '',
      shortcode: json['shortcode'] ?? '',
      staticUrl: json['static_url'] ?? '',
      url: json['url'] ?? '',
      visibleInPicker: json['visible_in_picker'] ?? false,
    );
  }
}
