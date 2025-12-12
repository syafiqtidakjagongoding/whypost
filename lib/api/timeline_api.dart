import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

Future<List<dynamic>> fetchHomeTimeline(
  String baseUrl,
  String accessToken,
  int limit,
  String? maxId,
  String? sinceId,
) async {
  final uri = Uri.parse("$baseUrl/api/v1/timelines/home").replace(
    queryParameters: {
      'limit': limit.toString(),
      'max_id': maxId,
      'since_id': sinceId,
    },
  );

  try {
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
    print(e);
    rethrow;
  }
}

Future<List<dynamic>> fetchPublicFederatedTimeline(
  String baseUrl,
  String accessToken,
  int limit,
  String? maxId,
  String? sinceId,
) async {
  final uri = Uri.parse("$baseUrl/api/v1/timelines/public").replace(
    queryParameters: {
      'limit': limit.toString(),
      'max_id': maxId,
      'since_id': sinceId,
    },
  );

  try {
    final res = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Accept': 'application/json',
      },
    );

    if (res.statusCode != 200) {
      throw Exception("Failed to load federated timeline: ${res.body}");
    }

    return jsonDecode(res.body);
  } catch (e) {
    rethrow;
  }
}

Future<List<dynamic>> fetchPublicLocalTimeline(
  String baseUrl,
  String accessToken,
  int limit,
  String? maxId,
  String? sinceId,
) async {
  final uri = Uri.parse("$baseUrl/api/v1/timelines/public").replace(
    queryParameters: {
      'limit': limit.toString(),
      'max_id': maxId,
      'since_id': sinceId,
      'local': 'true',
    },
  );

  try {
    final res = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Accept': 'application/json',
      },
    );

    if (res.statusCode != 200) {
      throw Exception("Failed to load local timeline: ${res.body}");
    }

    return jsonDecode(res.body);
  } catch (e) {
    rethrow;
  }
}

Future<List<dynamic>> fetchTagTimeline(
  String baseUrl,
  String accessToken,
  String tag,
  int limit,
  String? maxId,
  String? sinceId,
) async {
  final uri = Uri.parse("$baseUrl/api/v1/timelines/tag/$tag").replace(
    queryParameters: {
      'limit': limit.toString(),
      'max_id': maxId,
      'since_id': sinceId,
    },
  );

  try {
    final res = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Accept': 'application/json',
      },
    );

    if (res.statusCode != 200) {
      throw Exception("Failed to load tag timeline: ${res.body}");
    }

    return jsonDecode(res.body);
  } catch (e) {
    rethrow;
  }
}

Future<List<dynamic>> fetchFavouritedUser(
  String baseUrl,
  String accessToken,
  String? maxId,
  String? sinceId,
) async {
  final uri = Uri.parse("$baseUrl/api/v1/favourites").replace(
    queryParameters: {'max_id': maxId, 'since_id': sinceId, 'limit': "10"},
  );

  try {
    final res = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Accept': 'application/json',
      },
    );

    if (res.statusCode != 200) {
      throw Exception("Failed to load favourites: ${res.body}");
    }

    return jsonDecode(res.body);
  } catch (e) {
    rethrow;
  }
}

Future<List<dynamic>> fetchBookmarkedUser(
  String baseUrl,
  String accessToken,
  String? maxId,
  String? sinceId,
) async {
  final uri = Uri.parse(
    "$baseUrl/api/v1/bookmarks",
  ).replace(queryParameters: {'max_id': maxId, 'since_id': sinceId});

  try {
    final res = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Accept': 'application/json',
      },
    );

    if (res.statusCode != 200) {
      throw Exception("Failed to load bookmarks: ${res.body}");
    }

    return jsonDecode(res.body);
  } catch (e) {
    rethrow;
  }
}

Future<List<dynamic>> fetchTrendingPost(
  String baseUrl,
  String accessToken,
  int limit,
  int offset,
) async {
  final uri = Uri.parse("$baseUrl/api/v1/trends/statuses").replace(
    queryParameters: {'limit': limit.toString(), 'offset': offset.toString()},
  );

  try {
    final res = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Accept': 'application/json',
      },
    );

    if (res.statusCode != 200) {
      throw Exception("Failed to load trending posts: ${res.body}");
    }

    return jsonDecode(res.body);
  } catch (e) {
    rethrow;
  }
}
