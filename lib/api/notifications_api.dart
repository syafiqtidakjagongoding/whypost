import 'package:http/http.dart' as http;
import 'dart:convert';

Future<List<Map<String, dynamic>>> fetchAllNotifications(
  String baseUrl,
  String accessToken,
) async {
  try {
    final uri = Uri.parse("$baseUrl/api/v1/notifications");

    final res = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Accept': 'application/json',
      },
    );

    if (res.statusCode != 200) {
      throw Exception(
        "Failed to load status detail: ${res.statusCode} - ${res.body}",
      );
    }

    final data = jsonDecode(res.body);

    return (data as List).cast<Map<String, dynamic>>();
  } catch (e) {
    rethrow;
  }
}

Future<List<Map<String, dynamic>>> fetchNotificationsByType(
  String baseUrl,
  String accessToken,
 String types
) async {
  try {
    final uri = Uri.parse("$baseUrl/api/v1/notifications").replace(
      queryParameters: {
        "types[]": types, 
      },
    );

    final res = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Accept': 'application/json',
      },
    );

    if (res.statusCode != 200) {
      throw Exception(
        "Failed to load status detail: ${res.statusCode} - ${res.body}",
      );
    }

    final data = jsonDecode(res.body);

    return (data as List).cast<Map<String, dynamic>>();
  } catch (e) {
    rethrow;
  }
}

Future<Map<String, dynamic>> fetchNotificationById(
  String baseUrl,
  String accessToken,
  String id,
) async {
  try {
    final uri = Uri.parse("$baseUrl/api/v1/notification/$id");

    final res = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Accept': 'application/json',
      },
    );

    if (res.statusCode != 200) {
      throw Exception(
        "Failed to load status detail: ${res.statusCode} - ${res.body}",
      );
    }

    return jsonDecode(res.body);
  } catch (e) {
    rethrow;
  }
}
