import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

Future<List<dynamic>> fetchStatusesUserById(
  String baseUrl,
  String accessToken,
  String? maxId,
  String? sinceId,
  String id,
) async {
  try {
    final uri = Uri.parse(
      "$baseUrl/api/v1/accounts/$id/statuses",
    ).replace(queryParameters: {'max_id': maxId, 'since_id': sinceId, 'limit': "10"});

    final res = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Accept': 'application/json',
      },
    );

    if (res.statusCode != 200) {
      throw Exception("Failed to load home timeline: ${res.body}");
    }

    return jsonDecode(res.body);
  } catch (e) {
    rethrow;
  }
}

Future<List<dynamic>> fetchStatusesUserByIdOnlyMedia(
  String baseUrl,
  String accessToken,
  String? maxId,
  String? sinceId,
  String id,
) async {
  try {
    final uri = Uri.parse("$baseUrl/api/v1/accounts/$id/statuses").replace(
      queryParameters: {
        'max_id': maxId,
        'only_media': 'true',
        'since_id': sinceId,
        'limit': "10"
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
      throw Exception("Failed to load home timeline: ${res.body}");
    }

    return jsonDecode(res.body);
  } catch (e) {
    rethrow;
  }
}

Future<List<dynamic>> fetchCommentarByStatusId(
  String baseUrl,
  String accessToken,
  String statusId,
) async {
  try {
    final uri = Uri.parse('$baseUrl/api/v1/statuses/$statusId/context');

    final res = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (res.statusCode != 200) {
      throw Exception("Failed to load comments: ${res.body}");
    }

    final data = jsonDecode(res.body);
    final replies = data['descendants'] as List<dynamic>;

    return replies;
  } catch (e) {
    rethrow;
  }
}

Future<Map<String, dynamic>> fetchStatusDetail(
  String baseUrl,
  String accessToken,
  String statusId,
) async {
  try {
    final uri = Uri.parse("$baseUrl/api/v1/statuses/$statusId");

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


Future<Map<String, dynamic>> deleteStatusesById(
  String baseUrl,
  String accessToken,
  String statusId,
) async {
  try {
    final uri = Uri.parse("$baseUrl/api/v1/statuses/$statusId");

    final res = await http.delete(
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

Future<Map<String, dynamic>> favouritePost(
  String baseUrl,
  String accessToken,
  String id,
) async {
  try {
    final uri = Uri.parse("$baseUrl/api/v1/statuses/$id/favourite");

    final res = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    );

    if (res.statusCode != 200) {
      throw Exception("Failed to favourite post: ${res.body}");
    }
    return jsonDecode(res.body);
  } catch (e) {
    rethrow;
  }
}

Future<Map<String, dynamic>> unfavouritePost(
  String baseUrl,
  String accessToken,
  String id,
) async {
  try {
    final uri = Uri.parse("$baseUrl/api/v1/statuses/$id/unfavourite");

    final res = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    );

    if (res.statusCode != 200) {
      throw Exception("Failed to unfavourite post: ${res.body}");
    }
    return jsonDecode(res.body);
  } catch (e) {
    rethrow;
  }
}

Future<Map<String, dynamic>> bookmarkPost(
  String baseUrl,
  String accessToken,
  String id,
) async {
  try {
    final uri = Uri.parse("$baseUrl/api/v1/statuses/$id/bookmark");

    final res = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    );

    if (res.statusCode != 200) {
      throw Exception("Failed to bookmark post: ${res.body}");
    }
    return jsonDecode(res.body);
  } catch (e) {
    rethrow;
  }
}

Future<Map<String, dynamic>> reblogPost(
  String baseUrl,
  String accessToken,
  String id,
) async {
  try {
    final uri = Uri.parse("$baseUrl/api/v1/statuses/$id/reblog");

    final res = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    );

    if (res.statusCode != 200) {
      throw Exception("Failed to reblog post: ${res.body}");
    }
    return jsonDecode(res.body);
  } catch (e) {
    rethrow;
  }
}

Future<Map<String, dynamic>> unreblogPost(
  String baseUrl,
  String accessToken,
  String id,
) async {
  try {
    final uri = Uri.parse("$baseUrl/api/v1/statuses/$id/unreblog");

    final res = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    );

    if (res.statusCode != 200) {
      throw Exception("Failed to unreblog post: ${res.body}");
    }
    return jsonDecode(res.body);
  } catch (e) {
    rethrow;
  }
}

Future<Map<String, dynamic>> unbookmarkPost(
  String baseUrl,
  String accessToken,
  String id,
) async {
  try {
    final uri = Uri.parse("$baseUrl/api/v1/statuses/$id/unbookmark");

    final res = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    );

    if (res.statusCode != 200) {
      throw Exception("Failed to unbookmark post: ${res.body}");
    }

    return jsonDecode(res.body);
  } catch (e) {
    rethrow;
  }
}

Future<void> createFediversePost({
  required String instanceUrl,
  required String accessToken,
  required String content,
  String? visibility = "public",
  bool localOnly = false,
  String? spoilerText,
  String? inReplyToId,

  List<File>? images,

  List<String>? pollOptions,
  int? pollExpiresIn,
  bool pollMultiple = false,
  bool pollHideTotals = true,

  Map<String, dynamic>? interactionPolicy,
}) async {
  try {
    final List<String> mediaIds = [];

    // ========================================
    // 1. Upload media
    // ========================================
    if (images != null && images.isNotEmpty) {
      for (var img in images) {
        final uploadUrl = Uri.parse('$instanceUrl/api/v1/media');

        final req = http.MultipartRequest("POST", uploadUrl)
          ..headers['Authorization'] = 'Bearer $accessToken'
          ..files.add(await http.MultipartFile.fromPath('file', img.path));

        final resp = await req.send();

        final body = await resp.stream.bytesToString();

        if (resp.statusCode < 200 || resp.statusCode >= 300) {
          throw Exception("Failed to upload media: ${resp.statusCode}: $body");
        }

        final json = jsonDecode(body);
        mediaIds.add(json['id']);
      }
    }

    // ========================================
    // 2. Build JSON body
    // ========================================
    final Map<String, dynamic> payload = {
      "status": content,
      "visibility": visibility,
      "local_only": localOnly,
    };

    if (spoilerText != null && spoilerText.isNotEmpty) {
      payload["spoiler_text"] = spoilerText;
    }

    if (inReplyToId != null) {
      payload["in_reply_to_id"] = inReplyToId;
    }

    if (mediaIds.isNotEmpty) {
      payload["media_ids"] = mediaIds;
    }

    if (pollOptions != null && pollOptions.isNotEmpty) {
      payload["poll"] = {
        "options": pollOptions,
        "expires_in": pollExpiresIn ?? 3600,
        "multiple": pollMultiple,
        "hide_totals": pollHideTotals,
      };
    }

    if (interactionPolicy != null) {
      payload["interaction_policy"] = interactionPolicy;
    }

    // ========================================
    // 3. Send Status
    // ========================================
    final postUrl = Uri.parse('$instanceUrl/api/v1/statuses');

    final response = await http.post(
      postUrl,
      headers: {
        "Authorization": "Bearer $accessToken",
        "Content-Type": "application/json",
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode != 200) {
      throw Exception("Gagal posting status");
    }
  } catch (e) {
    rethrow;
  }
}
