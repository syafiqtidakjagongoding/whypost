import 'dart:convert';
import 'package:http/http.dart' as http;

Future<List<CustomEmoji>> fetchCustomEmojis(
  String baseUrl,
  String token,
) async {
  try {
    final url = Uri.parse("$baseUrl/api/v1/custom_emojis");

    final headers = {
      "Accept": "application/json",
      "Authorization": "Bearer $token",
    };

    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => CustomEmoji.fromJson(e)).toList();
    } else {
      throw Exception("Failed to load custom emojis: ${response.statusCode}");
    }
  } catch (e) {
    rethrow;
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
