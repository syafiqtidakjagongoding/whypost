import 'dart:convert';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;
import 'package:whypost/constant/config.dart';

Future<Map<String, dynamic>?> fetchRelationshipById(
  String userId,
  String instanceUrl,
  String token,
) async {
  final url = Uri.parse(
    '$instanceUrl/api/v1/accounts/relationships',
  ).replace(queryParameters: {'id[]': userId});

  final res = await http.get(url, headers: {"Authorization": "Bearer $token"})
        .timeout(
          API_TIMEOUT,
          onTimeout: () => throw Exception(
            "Request timed out after ${API_TIMEOUT.inSeconds} seconds",
          ),
        );
    

  if (res.statusCode == 200) {
    final data = jsonDecode(res.body);
    if (data is List && data.isNotEmpty) {
      return data[0] as Map<String, dynamic>;
    }

    return null;
  } else {
    print('Error fetch relationship: ${res.statusCode} ${res.body}');
    return null;
  }
}
