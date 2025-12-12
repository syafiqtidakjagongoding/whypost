import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whypost/api/accounts_api.dart';
import 'package:whypost/api/relationship_api.dart';
import 'package:whypost/api/user_api.dart';
import 'package:whypost/sharedpreferences/credentials.dart';

final currentUserProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final cred = await CredentialsRepository.loadCredentials();

  return fetchCurrentUser(cred.instanceUrl!, cred.accToken!);
});

final selectedUserProvider = FutureProvider.family<Map<String, dynamic>?, String>((
  ref,
  identifier,
) async {
  final cred = await CredentialsRepository.loadCredentials();

  return fetchUserById(identifier, cred.instanceUrl!, cred.accToken!);
});


final relationshipProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((ref, userId) async {
      final cred = await CredentialsRepository.loadCredentials();
      if (cred.instanceUrl == null || cred.accToken == null) {
        throw Exception("Error");
      }

      return fetchRelationshipById(userId, cred.instanceUrl!, cred.accToken!);
    });

final followUserProvider = FutureProvider.family<Map<String, dynamic>?, String>(
  (ref, userId) async {
    final cred = await CredentialsRepository.loadCredentials();
    if (cred.instanceUrl == null || cred.accToken == null) {
      throw Exception("Error");
    }

    return await followUser(
      instanceUrl: cred.instanceUrl!,
      token: cred.accToken!,
      userId: userId,
    );
  },
);

final unfollowUserProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((ref, userId) async {
      final cred = await CredentialsRepository.loadCredentials();
      if (cred.instanceUrl == null || cred.accToken == null) {
        throw Exception("Error");
      }

      return await unfollowUser(
        instanceUrl: cred.instanceUrl!,
        token: cred.accToken!,
        userId: userId,
      );
    });

final accountFollowersProvider =
    FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>((
      ref,
      accountId,
    ) async {
      final cred = await CredentialsRepository.loadCredentials();
      if (cred.accToken == null || cred.instanceUrl == null) return [];

      return await getAccountFollowers(
        instanceUrl: cred.instanceUrl!,
        accountId: accountId,
        accessToken: cred.accToken!,
        limit: 40,
      );
    });

final accountFollowingProvider =
    FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>((
      ref,
      accountId,
    ) async {
      final cred = await CredentialsRepository.loadCredentials();
      if (cred.accToken == null || cred.instanceUrl == null) return [];

      return await getAccountFollowing(
        instanceUrl: cred.instanceUrl!,
        accountId: accountId,
        accessToken: cred.accToken!,
        limit: 40,
      );
    });
