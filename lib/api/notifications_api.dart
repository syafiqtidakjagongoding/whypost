import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:whypost/constant/config.dart';

Future<List<Map<String, dynamic>>> fetchAllNotifications(
  String baseUrl,
  String accessToken,
) async {
  final uri = Uri.parse("$baseUrl/api/v1/notifications");

  final res = await http
      .get(
        uri,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Accept': 'application/json',
        },
      )
      .timeout(
        API_TIMEOUT,
        onTimeout: () => throw Exception(
          "Request timed out after ${API_TIMEOUT.inSeconds} seconds",
        ),
      );

  if (res.statusCode != 200) {
    throw Exception(
      "Failed to load notifications: ${res.statusCode} - ${res.body}",
    );
  }

  return (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
}

Future<List<Map<String, dynamic>>> fetchNotificationsByType(
  String baseUrl,
  String accessToken,
  String types,
) async {
  final uri = Uri.parse(
    "$baseUrl/api/v1/notifications",
  ).replace(queryParameters: {"types[]": types});

  final res = await http
      .get(
        uri,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Accept': 'application/json',
        },
      )
      .timeout(
        API_TIMEOUT,
        onTimeout: () => throw Exception(
          "Request timed out after ${API_TIMEOUT.inSeconds} seconds",
        ),
      );

  if (res.statusCode != 200) {
    throw Exception(
      "Failed to load notifications: ${res.statusCode} - ${res.body}",
    );
  }

  return (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
}

Future<Map<String, dynamic>> fetchNotificationById(
  String baseUrl,
  String accessToken,
  String id,
) async {
  final uri = Uri.parse("$baseUrl/api/v1/notification/$id");

  final res = await http
      .get(
        uri,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Accept': 'application/json',
        },
      )
      .timeout(
        API_TIMEOUT,
        onTimeout: () => throw Exception(
          "Request timed out after ${API_TIMEOUT.inSeconds} seconds",
        ),
      );

  if (res.statusCode != 200) {
    throw Exception(
      "Failed to load notification: ${res.statusCode} - ${res.body}",
    );
  }

  return jsonDecode(res.body);
}
