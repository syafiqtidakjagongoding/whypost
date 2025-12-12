import 'dart:convert';
import 'package:http/http.dart' as http;
Future<Map<String, dynamic>?> fetchUserById(
  String id,
  String instanceUrl,
  String token,
) async {
  final url = Uri.parse('$instanceUrl/api/v1/accounts/$id');

  try {
    final res = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception("Failed to fetch user: ${res.body}");
    }
  } catch (e) {
    rethrow;
  }
}

Future<Map<String, dynamic>?> fetchUserByAcct(
  String acct,
  String instanceUrl,
  String token,
) async {
  final url = Uri.parse(
    '$instanceUrl/api/v1/accounts/lookup',
  ).replace(queryParameters: {'acct': acct});

  try {
    final res = await http.get(
      url,
      headers: {"Authorization": "Bearer $token"},
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    } else {
      throw Exception("Failed to lookup user: ${res.body}");
    }
  } catch (e) {
    rethrow;
  }
}

Future<Map<String, dynamic>?> fetchCurrentUser(
  String instanceUrl,
  String token,
) async {
  final url = Uri.parse('$instanceUrl/api/v1/accounts/verify_credentials');

  try {
    final res = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception("Failed to fetch current user: ${res.body}");
    }
  } catch (e) {
    rethrow;
  }
}
Future<Map<String, dynamic>?> followUser({
  required String instanceUrl,
  required String token,
  required String userId,
  bool reblogs = true,
  bool notify = true,
}) async {
  final url = Uri.parse('$instanceUrl/api/v1/accounts/$userId/follow');

  try {
    final res = await http.post(
      url,
      headers: {'Authorization': 'Bearer $token'},
      body: {'reblogs': reblogs.toString(), 'notify': notify.toString()},
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception("Failed to follow user: ${res.body}");
    }
  } catch (e) {
    rethrow;
  }
}
Future<Map<String, dynamic>?> unfollowUser({
  required String instanceUrl,
  required String token,
  required String userId,
}) async {
  final url = Uri.parse('$instanceUrl/api/v1/accounts/$userId/unfollow');

  try {
    final res = await http.post(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception("Failed to unfollow user: ${res.body}");
    }
  } catch (e) {
    rethrow;
  }
}



