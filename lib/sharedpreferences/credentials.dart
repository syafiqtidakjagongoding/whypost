import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class AllCredentials {
  final String? accToken;
  final String? instanceUrl;
  final String? clientId;
  final String? clientSecret;
  final String? softwareName;
  final String? currentUserId;

  const AllCredentials({
    required this.accToken,
    required this.instanceUrl,
    required this.clientId,
    required this.clientSecret,
    required this.softwareName,
    required this.currentUserId,
  });
}

class Credentials {
  final String? accToken;
  final String? instanceUrl;

  const Credentials({required this.accToken, required this.instanceUrl});
}

class CredentialsRepository {
  static const _keyToken = "access_token";
  static const _instanceurl = "instance_url";
  static const _clientId = "client_id";
  static const _clientSecret = "client_secret";

  static Future<void> saveCredentials(
    String? token,
    String url,
    String clientId,
    String clientSecret,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    if (token != null) {
      await prefs.setString(_keyToken, token);
    }
    await prefs.setString(_instanceurl, url);
    await prefs.setString(_clientId, clientId);
    await prefs.setString(_clientSecret, clientSecret);
  }

  static Future<void> setCurrentUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
   
    await prefs.setString("current_user_id", userId);
  }

  static Future<void> setSoftwareName(String softwareName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("software_name", softwareName);
  }

  static Future<String?> getSoftwareName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("software_name");
  }

  static Future<AllCredentials> loadAllCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_keyToken);
    final instanceUrl = prefs.getString(_instanceurl);
    final clientId = prefs.getString(_clientId);
    final clientSecret = prefs.getString(_clientSecret);
    final softwareName = prefs.getString("software_name");
    final currentUserId = prefs.getString("current_user_id");

    return AllCredentials(
      accToken: token,
      instanceUrl: instanceUrl,
      clientId: clientId,
      clientSecret: clientSecret,
      softwareName: softwareName,
      currentUserId: currentUserId,
    );
  }

  static Future<String?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("current_user_id");
  }

  static Future<String?> getInstanceUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_instanceurl);
  }

  static Future<Credentials> loadCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_keyToken);
    final instanceUrl = prefs.getString(_instanceurl);

    return Credentials(accToken: token, instanceUrl: instanceUrl);
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    final instanceUrl = prefs.getString(_instanceurl);
    final clientId = prefs.getString(_clientId);
    final clientSecret = prefs.getString(_clientSecret);
    final token = prefs.getString(_keyToken);

    await http.post(
      Uri.parse('$instanceUrl/oauth/revoke'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'token': token,
        'client_id': clientId,
        'client_secret': clientSecret,
      }),
    );

    await prefs.clear();
  }
}
