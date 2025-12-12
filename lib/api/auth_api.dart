import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:whypost/constant/instanceConfig.dart';

Future<String?> getAccessToken({
  required String instanceBaseUrl,
  required String clientId,
  required String clientSecret,
  required String code,
}) async {
  try {
    final url = Uri.parse(instanceBaseUrl).resolve("/oauth/token");

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'client_id': clientId,
        'client_secret': clientSecret,
        'grant_type': 'authorization_code',
        'redirect_uri': REDIRECT_URL,
        'code': code,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['access_token'];
    } else {
      print("Gagal exchange token: ${response.body}");
      return null;
    }
  } catch (e) {
    rethrow;
  }
}
