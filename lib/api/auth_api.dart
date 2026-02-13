import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:whypost/constant/config.dart';
import 'package:whypost/constant/instanceConfig.dart';

Future<String?> getAccessToken({
  required String instanceBaseUrl,
  required String clientId,
  required String clientSecret,
  required String code,
}) async {
  final url = Uri.parse(instanceBaseUrl).resolve("/oauth/token");

  final response = await http
      .post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'client_id': clientId,
          'client_secret': clientSecret,
          'grant_type': 'authorization_code',
          'redirect_uri': REDIRECT_URL,
          'code': code,
        }),
      )
      .timeout(
        API_TIMEOUT,
        onTimeout: () {
          throw Exception(
            "Request timed out after ${API_TIMEOUT.inSeconds} seconds",
          );
        },
      );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data['access_token'];
  } else {
    throw Exception("Gagal exchange token: ${response.body}");
  }
}
