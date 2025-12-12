import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:whypost/api/statuses_api.dart';
import 'package:whypost/sharedpreferences/credentials.dart';


final favoritePostActionProvider = FutureProvider.family((ref, String id) async {
  final cred = await CredentialsRepository.loadCredentials();

  if (cred.accToken == null || cred.instanceUrl == null) {
    throw Exception("No credentials");
  }

  final result = await favouritePost(
    cred.instanceUrl!,
    cred.accToken!,
    id, 
  );

  return result;
});


final unfavoritePostActionProvider = FutureProvider.family((ref, String id) async {
  final cred = await CredentialsRepository.loadCredentials();

  if (cred.accToken == null || cred.instanceUrl == null) {
    throw Exception("No credentials");
  }

  final result = await unfavouritePost(
    cred.instanceUrl!,
    cred.accToken!,
    id, 
  );

  return result;
});



final bookmarkPostActionProvider = FutureProvider.family((ref, String id) async {
  final cred = await CredentialsRepository.loadCredentials();

  if (cred.accToken == null || cred.instanceUrl == null) {
    throw Exception("No credentials");
  }

  final result = await bookmarkPost(
    cred.instanceUrl!,
    cred.accToken!,
    id, 
  );

  return result;
});

final unbookmarkPostActionProvider = FutureProvider.family((ref, String id) async {
  final cred = await CredentialsRepository.loadCredentials();

  if (cred.accToken == null || cred.instanceUrl == null) {
    throw Exception("No credentials");
  }

  final result = await unbookmarkPost(
    cred.instanceUrl!,
    cred.accToken!,
    id,
  );

  return result;
});


final reblogPostActionProvider = FutureProvider.family((
  ref,
  String id,
) async {
  final cred = await CredentialsRepository.loadCredentials();

  if (cred.accToken == null || cred.instanceUrl == null) {
    throw Exception("No credentials");
  }

  final result = await reblogPost(
    cred.instanceUrl!,
    cred.accToken!,
    id, 
  );

  return result;
});


final unreblogPostActionProvider = FutureProvider.family((ref, String id) async {
  final cred = await CredentialsRepository.loadCredentials();

  if (cred.accToken == null || cred.instanceUrl == null) {
    throw Exception("No credentials");
  }

  final result = await unreblogPost(
    cred.instanceUrl!,
    cred.accToken!,
    id, 
  );

  return result;
});

final bookmarkProvider = StateProvider<Map<String, bool>>((ref) => {});
final favouriteProvider = StateProvider<Map<String, bool>>((ref) => {});
final rebloggedProvider = StateProvider<Map<String, bool>>((ref) => {});

final requestedFollowProvider = StateProvider<Map<String, bool>>((ref) => {});
final followProvider = StateProvider<Map<String, bool>>((ref) => {});
