import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:whypost/constant/config.dart';

Future<List<dynamic>> fetchStatusesUserById(
  String baseUrl,
  String accessToken,
  String? maxId,
  String? sinceId,
  String id,
) async {
  try {
    final uri = Uri.parse("$baseUrl/api/v1/accounts/$id/statuses").replace(
      queryParameters: {'max_id': maxId, 'since_id': sinceId, 'limit': "10"},
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
        'limit': "10",
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

    final res = await http
        .get(uri, headers: {'Authorization': 'Bearer $accessToken'})
        .timeout(
          apiTimeout,
          onTimeout: () => throw Exception(
            "Request timed out after ${apiTimeout.inSeconds} seconds",
          ),
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

    final res = await http
        .get(
          uri,
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Accept': 'application/json',
          },
        )
        .timeout(
          apiTimeout,
          onTimeout: () => throw Exception(
            "Request timed out after ${apiTimeout.inSeconds} seconds",
          ),
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

    final res = await http
        .delete(
          uri,
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Accept': 'application/json',
          },
        )
        .timeout(
          apiTimeout,
          onTimeout: () => throw Exception(
            "Request timed out after ${apiTimeout.inSeconds} seconds",
          ),
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

    final res = await http
        .post(
          uri,
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        )
        .timeout(
          apiTimeout,
          onTimeout: () => throw Exception(
            "Request timed out after ${apiTimeout.inSeconds} seconds",
          ),
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

    final res = await http
        .post(
          uri,
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        )
        .timeout(
          apiTimeout,
          onTimeout: () => throw Exception(
            "Request timed out after ${apiTimeout.inSeconds} seconds",
          ),
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

    final res = await http
        .post(
          uri,
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        )
        .timeout(
          apiTimeout,
          onTimeout: () => throw Exception(
            "Request timed out after ${apiTimeout.inSeconds} seconds",
          ),
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

    final res = await http
        .post(
          uri,
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        )
        .timeout(
          apiTimeout,
          onTimeout: () => throw Exception(
            "Request timed out after ${apiTimeout.inSeconds} seconds",
          ),
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

    final res = await http
        .post(
          uri,
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        )
        .timeout(
          apiTimeout,
          onTimeout: () => throw Exception(
            "Request timed out after ${apiTimeout.inSeconds} seconds",
          ),
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

    final res = await http
        .post(
          uri,
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        )
        .timeout(
          apiTimeout,
          onTimeout: () => throw Exception(
            "Request timed out after ${apiTimeout.inSeconds} seconds",
          ),
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
        final mediaId = await _uploadMedia(
          image: img,
          instanceUrl: instanceUrl,
          accessToken: accessToken,
        );
        mediaIds.add(mediaId);
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

    final response = await http
        .post(
          postUrl,
          headers: {
            "Authorization": "Bearer $accessToken",
            "Content-Type": "application/json",
          },
          body: jsonEncode(payload),
        )
        .timeout(
          apiTimeout,
          onTimeout: () => throw Exception(
            "Request timed out after ${apiTimeout.inSeconds} seconds",
          ),
        );

    if (response.statusCode != 200) {
      throw Exception("Gagal posting status");
    }
  } catch (e) {
    rethrow;
  }
}

Future<Map<String, dynamic>> editFediversePost({
  required String postId,
  required String content,
  required String visibility,
  required String instanceUrl,
  required String accessToken,
  List<File>? images,
  List<String>? existingMediaIds, // IDs of media to keep
}) async {
  // Start with existing media IDs (media to keep)
  List<String> mediaIds = existingMediaIds != null
      ? List<String>.from(existingMediaIds)
      : [];

  // Upload new images if any
  if (images != null && images.isNotEmpty) {
    for (var image in images) {
      final mediaId = await _uploadMedia(
        image: image,
        instanceUrl: instanceUrl,
        accessToken: accessToken,
      );
      mediaIds.add(mediaId);
    }
  }

  // Edit the status
  final url = Uri.parse('$instanceUrl/api/v1/statuses/$postId');

  final body = {
    'status': content,
    'visibility': visibility,
    // Only include media_ids if there are any (existing or new)
    // If empty array, it will remove all media
    'media_ids': mediaIds,
  };

  final response = await http
      .put(
        url,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      )
      .timeout(
        apiTimeout,
        onTimeout: () => throw Exception(
          "Request timed out after ${apiTimeout.inSeconds} seconds",
        ),
      );

  if (response.statusCode == 200) {
    return json.decode(response.body) as Map<String, dynamic>;
  } else {
    throw Exception(
      'Failed to edit post: ${response.statusCode} - ${response.body}',
    );
  }
}

Future<String> _uploadMedia({
  required File image,
  required String instanceUrl,
  required String accessToken,
}) async {
  final url = Uri.parse('$instanceUrl/api/v2/media');

  var request = http.MultipartRequest('POST', url);
  request.headers['Authorization'] = 'Bearer $accessToken';
  request.files.add(await http.MultipartFile.fromPath('file', image.path));

  final streamedResponse = await request.send().timeout(
    apiTimeout,
    onTimeout: () => throw Exception(
      "Request timed out after ${apiTimeout.inSeconds} seconds",
    ),
  );
  final response = await http.Response.fromStream(streamedResponse);

  if (response.statusCode == 200 || response.statusCode == 202) {
    final data = json.decode(response.body);
    return data['id'] as String;
  } else {
    throw Exception(
      'Failed to upload media: ${response.statusCode} - ${response.body}',
    );
  }
}
