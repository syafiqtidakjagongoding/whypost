import 'dart:convert';

import 'package:http/http.dart' as http;
import 'dart:async';

import 'package:whypost/constant/config.dart';

Future<Map<String, dynamic>> getInstanceInfo(String instance) async {
 
    final uri = Uri.parse('$instance/api/v1/instance');

    final response = await http.get(uri)
      .timeout(
        API_TIMEOUT,
        onTimeout: () => throw Exception(
          "Request timed out after ${API_TIMEOUT.inSeconds} seconds",
        ),
      );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Couldn't fetch instance info");
    }
}
