import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:whypost/constant/config.dart';

Future<List<Map<String, dynamic>>> getAccountFollowers({
  required String instanceUrl,
  required String accountId,
  required String accessToken,
  int limit = 40,
}) async {

    final uri = Uri.parse(
      "$instanceUrl/api/v1/accounts/$accountId/followers",
    ).replace(queryParameters: {"limit": "$limit"});

    final response = await http.get(
      uri,
      headers: {"Authorization": "Bearer $accessToken"},
    )
        .timeout(
          apiTimeout,
          onTimeout: () {
            throw Exception(
              "Request timed out after ${apiTimeout.inSeconds} seconds",
            );
          },
        );
    

    if (response.statusCode != 200) {
      throw Exception(
        "Gagal load followers: ${response.statusCode} → ${response.body}",
      );
    }

    final data = jsonDecode(response.body);

    return (data as List).cast<Map<String, dynamic>>();
 
}

Future<List<Map<String, dynamic>>> getAccountFollowing({
  required String instanceUrl,
  required String accountId,
  required String accessToken,
  int limit = 40,
}) async {
    final uri = Uri.parse(
      "$instanceUrl/api/v1/accounts/$accountId/following",
    ).replace(queryParameters: {"limit": "$limit"});
    final response = await http
        .get(uri, headers: {"Authorization": "Bearer $accessToken"})
        .timeout(
          apiTimeout,
          onTimeout: () {
            throw Exception(
              "Request timed out after ${apiTimeout.inSeconds} seconds",
            );
          },
        );

    if (response.statusCode != 200) {
      throw Exception(
        "Gagal load followers: ${response.statusCode} → ${response.body}",
      );
    }

    final data = jsonDecode(response.body);

    return (data as List).cast<Map<String, dynamic>>();
  
}

Future<void> updateProfile({
  required String baseUrl,
  required String token,

  // Text fields
  String? displayName,
  String? note,
  bool? discoverable,
  bool? bot,
  bool? locked,
  String? avatarDescription,
  String? headerDescription,
  String? sourcePrivacy,
  bool? sourceSensitive,
  String? sourceLanguage,
  String? sourceStatusContentType,
  String? theme,
  String? customCss,
  bool? enableRss,
  bool? hideCollections,
  String? webVisibility,

  // File fields
  File? avatar,
  File? header,
}) async {
  final url = Uri.parse("$baseUrl/api/v1/accounts/update_credentials");

  final request = http.MultipartRequest("PATCH", url);

  // Authorization
  request.headers.addAll({
    "Authorization": "Bearer $token",
    "Accept": "application/json",
  });

  // ---- Add text fields only if not null ----
  void addField(String key, dynamic value) {
    if (value != null) request.fields[key] = value.toString();
  }

  addField("display_name", displayName);
  addField("note", note);
  addField("discoverable", discoverable);
  addField("bot", bot);
  addField("locked", locked);
  addField("avatar_description", avatarDescription);
  addField("header_description", headerDescription);
  addField("source[privacy]", sourcePrivacy);
  addField("source[sensitive]", sourceSensitive);
  addField("source[language]", sourceLanguage);
  addField("source[status_content_type]", sourceStatusContentType);
  addField("theme", theme);
  addField("custom_css", customCss);
  addField("enable_rss", enableRss);
  addField("hide_collections", hideCollections);
  addField("web_visibility", webVisibility);

  // ---- Add File: avatar ----
  if (avatar != null) {
    final avatarMultipart = await http.MultipartFile.fromPath(
      "avatar",
      avatar.path,
    );
    request.files.add(avatarMultipart);
  }

  // ---- Add File: header ----
  if (header != null) {
    final headerMultipart = await http.MultipartFile.fromPath(
      "header",
      header.path,
    );
    request.files.add(headerMultipart);
  }

  // Send request
  final streamedResponse = await request.send().timeout(
    apiTimeout,
    onTimeout: () {
      throw Exception(
        "Request timed out after ${apiTimeout.inSeconds} seconds",
      );
    },
  );
  
  final response = await http.Response.fromStream(streamedResponse);

  if (response.statusCode != 200) {
    throw Exception(
      "Failed to update profile: ${response.statusCode} - ${response.body}",
    );
  }
}
