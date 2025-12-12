import 'dart:convert';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;

Future<Map<String, dynamic>?> fetchRelationshipById(
  String userId,
  String instanceUrl,
  String token,
) async {
  try {
  final url = Uri.parse(
    '$instanceUrl/api/v1/accounts/relationships',
  ).replace(queryParameters: {'id[]': userId});

  final res = await http.get(url, headers: {"Authorization": "Bearer $token"});

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
   } catch (e) {
    rethrow;
  }
}
