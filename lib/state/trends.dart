import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whypost/api/explore_api.dart';
import 'package:whypost/sharedpreferences/credentials.dart';

class TrendingTagsNotifier extends AsyncNotifier<List<dynamic>> {
  @override
  Future<List<dynamic>> build() async {
    final cred = await CredentialsRepository.loadCredentials();
    if (cred.accToken == null || cred.instanceUrl == null) {
      return [];
    }

    return await fetchTrendingTags(cred.instanceUrl!, cred.accToken!);
  }
}

final trendingTagsProvider =
    AsyncNotifierProvider<TrendingTagsNotifier, List<dynamic>>(
  () => TrendingTagsNotifier(),
);

class TrendingLinksNotifier extends AsyncNotifier<List<dynamic>> {
  @override
  Future<List<dynamic>> build() async {
    final cred = await CredentialsRepository.loadCredentials();
    if (cred.accToken == null || cred.instanceUrl == null) {
      return [];
    }

    return await fetchTrendingLinks(cred.instanceUrl!, cred.accToken!);
  }
}

final trendingLinksProvider =
    AsyncNotifierProvider<TrendingLinksNotifier, List<dynamic>>(
  () => TrendingLinksNotifier(),
);
  