import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whypost/api/notifications_api.dart';
import 'package:whypost/api/relationship_api.dart';
import 'package:whypost/api/user_api.dart';
import 'package:whypost/sharedpreferences/credentials.dart';

final notificationsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final cred = await CredentialsRepository.loadCredentials();
  if (cred.instanceUrl == null || cred.accToken == null) {
    throw Exception("Error");
  }

  return fetchAllNotifications(cred.instanceUrl!, cred.accToken!);
});


final notificationsProviderById =
    FutureProvider.family<Map<String, dynamic>, String>((ref, id) async {
      final cred = await CredentialsRepository.loadCredentials();
      if (cred.instanceUrl == null || cred.accToken == null) {
        throw Exception("Error");
      }

      return fetchNotificationById(cred.instanceUrl!, cred.accToken!,id);
    });


final notificationsProviderByType =
    FutureProvider.family<List<Map<String, dynamic>>, String>((ref, type) async {
      final cred = await CredentialsRepository.loadCredentials();
      if (cred.instanceUrl == null || cred.accToken == null) {
        throw Exception("Error");
      }

      return fetchNotificationsByType(cred.instanceUrl!, cred.accToken!, type);
    });
