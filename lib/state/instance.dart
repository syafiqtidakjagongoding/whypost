import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whypost/api/instance_api.dart';
import 'package:whypost/sharedpreferences/credentials.dart';

final instanceProvider = FutureProvider<Map<String,dynamic>>((ref) async {
  final cred = await CredentialsRepository.loadCredentials();
  if (cred.instanceUrl == null || cred.accToken == null) {
    throw Exception("Error");
  }

  return getInstanceInfo(cred.instanceUrl!);
});
