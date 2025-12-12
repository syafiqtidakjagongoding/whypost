import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:whypost/api/statuses_api.dart';
import 'package:whypost/api/timeline_api.dart';
import 'package:whypost/sharedpreferences/credentials.dart';


abstract class BaseTimelineNotifier extends AsyncNotifier<List<dynamic>> {
  String? maxId;
  String? lastSinceId;

  Future<List<dynamic>> fetchTimeline(
    String instanceUrl,
    String accToken, {
    String? maxId,
  });

  @override
  Future<List<dynamic>> build() async {
    maxId = null;

    final cred = await CredentialsRepository.loadCredentials();
    if (cred.accToken == null || cred.instanceUrl == null) {
      return [];
    }

    return await _loadInitial();
  }

  Future<List<dynamic>> _loadInitial() async {
    final cred = await CredentialsRepository.loadCredentials();
    if (cred.accToken == null || cred.instanceUrl == null) return [];

    final posts = await fetchTimeline(
      cred.instanceUrl!,
      cred.accToken!,
      maxId: null,
    );

    if (posts.isNotEmpty) {
      maxId = posts.last['id'];
    }

    return posts;
  }

  Future<void> loadMore() async {
    try {
      final cred = await CredentialsRepository.loadCredentials();
      if (cred.accToken == null || cred.instanceUrl == null) {
        state = AsyncData([]);
        return;
      }

      final posts = await fetchTimeline(
        cred.instanceUrl!,
        cred.accToken!,
        maxId: maxId,
      );

      final existingIds = state.value!.map((e) => e['id']).toSet();
      final newPosts = posts
          .where((p) => !existingIds.contains(p['id']))
          .toList();
     if (newPosts.isNotEmpty) {
        maxId = newPosts.last['id'].toString();

        state = AsyncData([...state.value ?? [], ...newPosts]);
      }
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

class HomeTimelineNotifier extends BaseTimelineNotifier {
  @override
  Future<List<dynamic>> fetchTimeline(
    String instanceUrl,
    String accToken, {
    String? maxId,
  }) {
    return fetchHomeTimeline(instanceUrl, accToken, 10, maxId, null);
  }
}

class TrendingTimelineNotifier extends AsyncNotifier<List<dynamic>> {
  int offset = 0;
  final int limit = 20;
  bool isLoading = false;

  @override
  Future<List<dynamic>> build() async {
    offset = 0;

    final cred = await CredentialsRepository.loadCredentials();
    if (cred.accToken == null || cred.instanceUrl == null) return [];

    return await _loadInitial();
  }

  Future<List<dynamic>> _loadInitial() async {
    offset = 0;
    isLoading = false;

    final cred = await CredentialsRepository.loadCredentials();

    final posts = await fetchTrendingPost(
      cred.instanceUrl!,
      cred.accToken!,
      limit,
      offset,
    );

    offset += posts.length;

    return posts;
  }

  Future<void> loadMore() async {
    if (isLoading) return; 
    isLoading = true;

    final cred = await CredentialsRepository.loadCredentials();
    if (cred.accToken == null || cred.instanceUrl == null) {
      isLoading = false;
      return;
    }

   final posts = await fetchTrendingPost(
      cred.instanceUrl!,
      cred.accToken!,
      limit,
      offset,
    );

    if (posts.isNotEmpty) {
      offset += posts.length;

      final existing = state.value ?? [];
      final existingIds = existing.map((e) => e['id']).toSet();

      final newPosts = posts
          .where((p) => !existingIds.contains(p['id']))
          .toList();

      state = AsyncData([...existing, ...newPosts]);
    }

    isLoading = false;
  }
}

class PublicFederatedTimelineNotifier extends BaseTimelineNotifier {
  @override
  Future<List<dynamic>> fetchTimeline(
    String instanceUrl,
    String accToken, {
    String? maxId,
  }) {
    return fetchPublicFederatedTimeline(instanceUrl, accToken, 10, maxId, null);
  }
}

class PublicLocalTimelineNotifier extends BaseTimelineNotifier {
  @override
  Future<List<dynamic>> fetchTimeline(
    String instanceUrl,
    String accToken, {
    String? maxId,
  }) {
    return fetchPublicLocalTimeline(instanceUrl, accToken, 10, maxId, null);
  }
}

class FavouritedTimelineNotifier extends BaseTimelineNotifier {
  @override
  Future<List<dynamic>> fetchTimeline(
    String instanceUrl,
    String accToken, {
    String? maxId,
  }) {
    return fetchFavouritedUser(
    instanceUrl,
    accToken,
    maxId,
    null,
  );
  }
}


class BookmarkedTimelineNotifier extends BaseTimelineNotifier {
  @override
  Future<List<dynamic>> fetchTimeline(
    String instanceUrl,
    String accToken, {
    String? maxId,
  }) {
    return fetchBookmarkedUser(instanceUrl, accToken, maxId, null);
  }
}

final homeTimelineProvider =
    AsyncNotifierProvider<HomeTimelineNotifier, List<dynamic>>(
      () => HomeTimelineNotifier(),
    );
final publicFederatedProvider =
    AsyncNotifierProvider<PublicFederatedTimelineNotifier, List<dynamic>>(
      () => PublicFederatedTimelineNotifier(),
    );
final publicLocalProvider =
    AsyncNotifierProvider<PublicLocalTimelineNotifier, List<dynamic>>(
      () => PublicLocalTimelineNotifier(),
    );

final trendProvider =
    AsyncNotifierProvider<TrendingTimelineNotifier, List<dynamic>>(
      () => TrendingTimelineNotifier(),
    );


final favouritedTimelineProvider =
    AsyncNotifierProvider<FavouritedTimelineNotifier, List<dynamic>>(
      () => FavouritedTimelineNotifier(),
    );


final  bookmarkedTimelineProvider =
    AsyncNotifierProvider<BookmarkedTimelineNotifier, List<dynamic>>(
      () => BookmarkedTimelineNotifier(),
    );

class TimelineState {
  final List<dynamic> posts;
  final bool isLoading;
  final bool hasMore;
  final String? maxId;

  TimelineState({
    this.posts = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.maxId,
  });

  TimelineState copyWith({
    List<dynamic>? posts,
    bool? isLoading,
    bool? hasMore,
    String? maxId,
  }) {
    return TimelineState(
      posts: posts ?? this.posts,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      maxId: maxId ?? this.maxId,
    );
  }
}

final tagTimelineProvider =
    StateNotifierProvider.family<TagTimelineNotifier, TimelineState, String>(
      (ref, tag) {
        return TagTimelineNotifier(ref, tag);
      },
    );

class TagTimelineNotifier extends StateNotifier<TimelineState> {
  final Ref ref;
  final String tag;

  TagTimelineNotifier(this.ref, this.tag) : super(TimelineState()) {
    loadInitial();
  }

  Future<void> loadInitial() async {
    final cred = await CredentialsRepository.loadCredentials();
    if (cred.accToken == null || cred.instanceUrl == null) return;

    state = state.copyWith(isLoading: true);

    final posts = await fetchTagTimeline(
      cred.instanceUrl!,
      cred.accToken!,
      tag,
      10,
      null,
      null,
    );


    state = state.copyWith(
      posts: posts,
      isLoading: false,
      hasMore: posts.isNotEmpty,
      maxId: posts.isNotEmpty ? posts.last['id'] : null,
    );
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoading) return;

    final cred = await CredentialsRepository.loadCredentials();

    state = state.copyWith(isLoading: true);

    final more = await fetchTagTimeline(
      cred.instanceUrl!,
      cred.accToken!,
      tag,
      10,
      state.maxId,
      null,
    );

    state = state.copyWith(
      posts: [...state.posts, ...more],
      isLoading: false,
      hasMore: more.isNotEmpty,
      maxId: more.isNotEmpty ? more.last['id'] : state.maxId,
    );
  }
}


final statusesTimelineProvider =
    StateNotifierProvider.family<StatusesTimelineNotifier, TimelineState, String>((
      ref,
      userId,
    ) {
      return StatusesTimelineNotifier(ref, userId);
    });

class StatusesTimelineNotifier extends StateNotifier<TimelineState> {
  final Ref ref;
  final String userId;

  StatusesTimelineNotifier(this.ref, this.userId) : super(TimelineState()) {
    loadInitial();
  }

  Future<void> loadInitial() async {
    final cred = await CredentialsRepository.loadCredentials();
    if (cred.accToken == null || cred.instanceUrl == null) return;

    state = state.copyWith(isLoading: true);

     final posts = await fetchStatusesUserById(
      cred.instanceUrl!,
      cred.accToken!,
      null,
      null,
      userId,
    );

    state = state.copyWith(
      posts: posts,
      isLoading: false,
      hasMore: posts.isNotEmpty,
      maxId: posts.isNotEmpty ? posts.last['id'] : null,
    );
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoading) return;

    final cred = await CredentialsRepository.loadCredentials();

    state = state.copyWith(isLoading: true);


     final more = await fetchStatusesUserById(
      cred.instanceUrl!,
      cred.accToken!,
      state.maxId,
      null,
      userId,
    );

    state = state.copyWith(
      posts: [...state.posts, ...more],
      isLoading: false,
      hasMore: more.isNotEmpty,
      maxId: more.isNotEmpty ? more.last['id'] : state.maxId,
    );
  }
}

final statusesMediaTimelineProvider =
    StateNotifierProvider.family<
      StatusesMediaTimelineNotifier,
      TimelineState,
      String
    >((ref, userId) {
      return StatusesMediaTimelineNotifier(ref, userId);
    });

class StatusesMediaTimelineNotifier extends StateNotifier<TimelineState> {
  final Ref ref;
  final String userId;

  StatusesMediaTimelineNotifier(this.ref, this.userId) : super(TimelineState()) {
    loadInitial();
  }

  Future<void> loadInitial() async {
    final cred = await CredentialsRepository.loadCredentials();
    if (cred.accToken == null || cred.instanceUrl == null) return;

    state = state.copyWith(isLoading: true);

    final posts = await fetchStatusesUserByIdOnlyMedia(
      cred.instanceUrl!,
      cred.accToken!,
      null,
      null,
      userId,
    );

    state = state.copyWith(
      posts: posts,
      isLoading: false,
      hasMore: posts.isNotEmpty,
      maxId: posts.isNotEmpty ? posts.last['id'] : null,
    );
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoading) return;

    final cred = await CredentialsRepository.loadCredentials();

    state = state.copyWith(isLoading: true);

    final more = await fetchStatusesUserByIdOnlyMedia(
      cred.instanceUrl!,
      cred.accToken!,
      state.maxId,
      null,
      userId,
    );

    state = state.copyWith(
      posts: [...state.posts, ...more],
      isLoading: false,
      hasMore: more.isNotEmpty,
      maxId: more.isNotEmpty ? more.last['id'] : state.maxId,
    );
  }
}


final searchPostsTimelineProvider =
    StateNotifierProvider.family<
      SearchPostsTimelineNotifier,
      TimelineState,
      String
    >((ref, userId) {
      return SearchPostsTimelineNotifier(ref, userId);
    });

class SearchPostsTimelineNotifier extends StateNotifier<TimelineState> {
  final Ref ref;
  final String userId;

  SearchPostsTimelineNotifier(this.ref, this.userId)
    : super(TimelineState()) {
    loadInitial();
  }

  Future<void> loadInitial() async {
    final cred = await CredentialsRepository.loadCredentials();
    if (cred.accToken == null || cred.instanceUrl == null) return;

    state = state.copyWith(isLoading: true);

    final posts = await fetchStatusesUserByIdOnlyMedia(
      cred.instanceUrl!,
      cred.accToken!,
      null,
      null,
      userId,
    );

    state = state.copyWith(
      posts: posts,
      isLoading: false,
      hasMore: posts.isNotEmpty,
      maxId: posts.isNotEmpty ? posts.last['id'] : null,
    );
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoading) return;

    final cred = await CredentialsRepository.loadCredentials();

    state = state.copyWith(isLoading: true);

    final more = await fetchStatusesUserByIdOnlyMedia(
      cred.instanceUrl!,
      cred.accToken!,
      state.maxId,
      null,
      userId,
    );

    state = state.copyWith(
      posts: [...state.posts, ...more],
      isLoading: false,
      hasMore: more.isNotEmpty,
      maxId: more.isNotEmpty ? more.last['id'] : state.maxId,
    );
  }
}
