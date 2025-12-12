import 'dart:convert';

import 'package:http/http.dart' as http;
import 'dart:async';

Future<Map<String, dynamic>> getInstanceInfo(String instance) async {
  try {
    final uri = Uri.parse('$instance/api/v1/instance');

    final response = await http.get(uri).timeout(const Duration(seconds: 7));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Couldn't fetch instance info");
    }
  } on TimeoutException catch (_) {
    rethrow;
  } catch (e) {
    rethrow;
  }
}
