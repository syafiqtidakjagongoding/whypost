import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whypost/api/statuses_api.dart';
import 'package:whypost/sharedpreferences/credentials.dart';

final commentProvider = FutureProvider.family<List<dynamic>?, String>((
  ref,
  statusesId,
) async {
  final cred = await CredentialsRepository.loadCredentials();
  if (cred.instanceUrl == null || cred.accToken == null) {
    throw Exception("Error");
  }

  return fetchCommentarByStatusId(
    cred.instanceUrl!,
    cred.accToken!,
    statusesId,
  );
});
