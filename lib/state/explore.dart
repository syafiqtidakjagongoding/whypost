import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:whypost/api/explore_api.dart';
import 'package:whypost/sharedpreferences/credentials.dart';

class SuggestedPeopleNotifier extends AsyncNotifier<List<dynamic>> {
  @override
  Future<List<dynamic>> build() async {
    final cred = await CredentialsRepository.loadCredentials();
    if (cred.accToken == null || cred.instanceUrl == null) {
      return [];
    }

    return await fetchSuggestedPeople(cred.instanceUrl!, cred.accToken!);
  }
}

final suggestedPeopleProvider =
    AsyncNotifierProvider<SuggestedPeopleNotifier, List<dynamic>>(
  () => SuggestedPeopleNotifier(),
);



class SearchResultsNotifier extends AsyncNotifier<Map<String, dynamic>> {
  Timer? _debounce;

  @override
  Future<Map<String, dynamic>> build() async {
    final query = ref.watch(searchQueryProvider);

    _debounce?.cancel();

    final completer = Completer<Map<String, dynamic>>();

    _debounce = Timer(const Duration(seconds: 1), () async {
      if (query.trim().isEmpty) {
        completer.complete({
          "accounts": [],
          "statuses": [],
          "hashtags": [],
        });
        return;
      }

      final cred = await CredentialsRepository.loadCredentials();
      if (cred.accToken == null || cred.instanceUrl == null) {
        completer.complete({});
        return;
      }

      final result = await searchAny(
        cred.instanceUrl!,
        cred.accToken!,
        query,
        ""
      );
      print("search result $result");

      completer.complete(result);
    });

    return completer.future;
  }
}

final searchResultsProvider = AsyncNotifierProvider<SearchResultsNotifier, Map<String, dynamic>>(
  () => SearchResultsNotifier(),
);

final searchDebounceProvider = StateProvider<Timer?>((ref) => null);
final searchQueryProvider = StateProvider<String>((ref) => "");
