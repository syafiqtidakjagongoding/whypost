// ==========================================
// 1. MAIN SEARCH SCREEN
// ==========================================
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:whypost/api/explore_api.dart';
import 'package:whypost/app_theme.dart';
import 'package:whypost/constant/software.dart';
import 'package:whypost/sharedpreferences/credentials.dart';
import 'package:whypost/state/explore.dart';
import 'package:whypost/state/timeline.dart';
import 'package:whypost/state/trends.dart';
import 'package:whypost/ui/posts/post_card.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:url_launcher/url_launcher.dart';
import 'package:whypost/ui/utils/PeopleListTile.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? softwareName;
  bool supportTrends = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final name = await CredentialsRepository.getSoftwareName();
    final isSupportTrends = name == Software.MASTODON;
    setState(() {
      softwareName = name;
      supportTrends = isSupportTrends;
      _tabController = TabController(
        length: isSupportTrends ? 5 : 4,
        vsync: this,
      );
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedColor = isDark ? Colors.white : AppTheme.seed;
    final unselectedColor = isDark
        ? Colors.white60
        : AppTheme.seed.withAlpha(200);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // SEARCH BAR
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                onChanged: (value) {
                  final timer = ref.read(searchDebounceProvider);
                  timer?.cancel();

                  ref.read(searchDebounceProvider.notifier).state = Timer(
                    const Duration(milliseconds: 500),
                    () {
                      ref.read(searchQueryProvider.notifier).state = value;
                    },
                  );
                },
                style: const TextStyle(
                  color: Color.fromARGB(
                    255,
                    8,
                    8,
                    8,
                  ), // warna teks yang diketik
                ),
                decoration: InputDecoration(
                  hintText: "Search instance / users / tags...",
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            // TAB BAR
            TabBar(
              controller: _tabController,
              indicatorColor: selectedColor,
              labelColor: selectedColor,
              unselectedLabelColor: unselectedColor,
              tabs: [
                Tab(text: "All"),
                Tab(text: "Posts"),
                Tab(text: "Tags"),
                Tab(text: "People"),
                if (supportTrends) Tab(text: "Link"),
              ],
            ),

            // TAB VIEWS
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  AllTab(),
                  PostsTab(supportTrends: supportTrends),
                  TagsTab(supportTrends: supportTrends),
                  PeopleTab(),
                  if (supportTrends) LinksTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 2. ALL TAB (Combined Results)
// ==========================================
class AllTab extends ConsumerStatefulWidget {
  const AllTab({super.key});

  @override
  ConsumerState<AllTab> createState() => _AllTabState();
}

class _AllTabState extends ConsumerState<AllTab> {
  final ScrollController _scrollResultSearch = ScrollController();
  List<dynamic> infiniteStatuses = [];
  String? nextMaxId;
  bool isLoadingMore = false;
  bool hasNextPage = true;
  String lastQuery = "";

  @override
  void initState() {
    super.initState();
    _scrollResultSearch.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollResultSearch.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollResultSearch.position.pixels >=
        _scrollResultSearch.position.maxScrollExtent - 200) {
      _loadMoreStatuses();
    }
  }

  Future<void> _loadMoreStatuses() async {
    if (isLoadingMore || !hasNextPage || lastQuery.isEmpty) return;

    setState(() => isLoadingMore = true);

    final cred = await CredentialsRepository.loadCredentials();

    final result = await searchAny(
      cred.instanceUrl!,
      cred.accToken!,
      lastQuery,
      nextMaxId ?? "",
    );

    final List list = result["statuses"] ?? [];

    if (list.isEmpty) {
      hasNextPage = false;
    } else {
      nextMaxId = list.last["id"];
      infiniteStatuses.addAll(list);
    }

    setState(() => isLoadingMore = false);
  }

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(searchResultsProvider);

    return results.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text("Error: $e")),
      data: (data) {
        final accounts = (data["accounts"] is List)
            ? data["accounts"]
            : <dynamic>[];
        final firstStatuses = (data["statuses"] is List)
            ? data["statuses"]
            : <dynamic>[];
        final tags = (data["hashtags"] is List)
            ? data["hashtags"]
            : <dynamic>[];
        final query = ref.watch(searchQueryProvider).trim();

        if (query != lastQuery) {
          lastQuery = query;
          infiniteStatuses = List.of(firstStatuses);
          nextMaxId = firstStatuses.isNotEmpty
              ? firstStatuses.last["id"]
              : null;
          hasNextPage = true;
        }

        return SingleChildScrollView(
          controller: _scrollResultSearch,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // TAGS SECTION
              if (tags.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    "Tags",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                ...tags.map((t) => TagListTile(tag: t)),
              ],

              // PEOPLE SECTION
              if (accounts.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    "People",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                ...accounts.map((u) => PeopleListTile(account: u)),
              ],

              // POSTS SECTION
              if (infiniteStatuses.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    "Posts",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                ListView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: infiniteStatuses.length,
                  itemBuilder: (context, i) {
                    final post = infiniteStatuses[i];
                    return PostCardWrapper(post: post);
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

// ==========================================
// 3. POSTS TAB
// ==========================================
class PostsTab extends ConsumerStatefulWidget {
  final bool supportTrends;
  const PostsTab({super.key, required this.supportTrends});

  @override
  ConsumerState<PostsTab> createState() => _PostsTabState();
}

class _PostsTabState extends ConsumerState<PostsTab> {
  final ScrollController _scrollResultSearch = ScrollController();
  List<dynamic> infiniteStatuses = [];
  String? nextMaxId;
  bool isLoadingMore = false;
  bool hasNextPage = true;
  String lastQuery = "";

  @override
  void initState() {
    super.initState();
    _scrollResultSearch.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollResultSearch.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollResultSearch.position.pixels >=
        _scrollResultSearch.position.maxScrollExtent - 200) {
      _loadMoreStatuses();
    }
  }

  Future<void> _loadMoreStatuses() async {
    if (isLoadingMore || !hasNextPage || lastQuery.isEmpty) return;

    setState(() => isLoadingMore = true);

    final cred = await CredentialsRepository.loadCredentials();

    final result = await searchStatuses(
      cred.instanceUrl!,
      cred.accToken!,
      lastQuery,
      nextMaxId ?? "",
    );

    final List list = result["statuses"] ?? [];

    if (list.isEmpty) {
      hasNextPage = false;
    } else {
      nextMaxId = list.last["id"];
      infiniteStatuses.addAll(list);
    }

    setState(() => isLoadingMore = false);
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider).trim();
    final results = ref.watch(searchResultsProvider);
    final altPost = widget.supportTrends
        ? ref.watch(trendProvider)
        : ref.watch(publicLocalProvider);

    if (query.isEmpty) {
      return altPost.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Failed to load posts"),
                ElevatedButton(
                  onPressed: () {
                    if (widget.supportTrends) {
                      ref.invalidate(trendProvider);
                    } else {
                      ref.invalidate(publicLocalProvider);
                    }
                  },
                  child: Text(
                    "Refresh",
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
              ],
            ),
          );
        },
        data: (posts) {
          if (posts.isEmpty) {
            return const Center(child: Text("There are no alternate posts"));
          }
          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, i) => PostCardWrapper(post: posts[i]),
          );
        },
      );
    }

    return results.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Failed to search posts"),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(searchResultsProvider);
                },
                child: Text(
                  "Refresh",
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
            ],
          ),
        );
      },
      data: (data) {
        final statuses = (data["statuses"] is List)
            ? data["statuses"]
            : <dynamic>[];

        if (query != lastQuery) {
          lastQuery = query;
          infiniteStatuses = List.of(statuses);
          nextMaxId = statuses.isNotEmpty ? statuses.last["id"] : null;
          hasNextPage = true;
        }

        if (infiniteStatuses.isEmpty) {
          return const Center(child: Text("No results"));
        }
        return ListView.builder(
          controller: _scrollResultSearch,
          itemCount: infiniteStatuses.length,
          itemBuilder: (context, i) {
            final post = infiniteStatuses[i];
            return PostCardWrapper(post: post);
          },
        );
      },
    );
  }
}

// ==========================================
// 4. TAGS TAB
// ==========================================
class TagsTab extends ConsumerWidget {
  final bool supportTrends;

  const TagsTab({super.key, required this.supportTrends});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(searchQueryProvider).trim();
    final results = ref.watch(searchResultsProvider);

    if (!supportTrends) {
      if (query.isEmpty) {
        return const Center(
          child: Text("use search to find tags.", textAlign: TextAlign.center),
        );
      }

      return results.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) {
          {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Failed to search hashtags"),
                  ElevatedButton(
                    onPressed: () {
                      ref.invalidate(searchResultsProvider);
                    },
                    child: Text(
                      "Refresh",
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ),
                ],
              ),
            );
          }
        },
        data: (data) {
          final tags = (data["hashtags"] is List)
              ? data["hashtags"]
              : <dynamic>[];

          if (tags.isEmpty) {
            return const Center(child: Text("No hashtags found"));
          }

          return ListView.builder(
            itemCount: tags.length,
            itemBuilder: (context, i) => TagListTile(tag: tags[i]),
          );
        },
      );
    }

    // -----------------------------------------------------
    // 2. Server supports trends → load trending tags provider
    // -----------------------------------------------------
    final trendingTags = ref.watch(trendingTagsProvider);

    // If query empty → show trending tags
    if (query.isEmpty) {
      return trendingTags.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) {
          {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Failed to load trending tags"),
                  ElevatedButton(
                    onPressed: () {
                      ref.invalidate(trendingTagsProvider);
                    },
                    child: Text(
                      "Refresh",
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ),
                ],
              ),
            );
          }
        },
        data: (list) {
          if (list.isEmpty) {
            return const Center(child: Text("Trending tags are empty"));
          }

          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (context, i) => TagListTile(tag: list[i]),
          );
        },
      );
    }

    // -----------------------------------------------------
    // 3. Query is not empty → show hashtag search results
    // -----------------------------------------------------
    return results.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) {
        {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Failed to search hashtags"),
                ElevatedButton(
                  onPressed: () {
                    ref.invalidate(searchResultsProvider);
                  },
                  child: Text(
                    "Refresh",
                    style: TextStyle(color: Colors.black87, fontSize: 15),
                  ),
                ),
              ],
            ),
          );
        }
      },
      data: (data) {
        final tags = (data["hashtags"] is List)
            ? data["hashtags"]
            : <dynamic>[];

        if (tags.isEmpty) {
          return const Center(child: Text("No hashtags found"));
        }

        return ListView.builder(
          itemCount: tags.length,
          itemBuilder: (context, i) => TagListTile(tag: tags[i]),
        );
      },
    );
  }
}

// ==========================================
// 5. PEOPLE TAB
// ==========================================
class PeopleTab extends ConsumerWidget {
  const PeopleTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(searchQueryProvider).trim();
    final results = ref.watch(searchResultsProvider);
    final suggested = ref.watch(suggestedPeopleProvider);

    if (query.isEmpty) {
      return suggested.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) =>
            const Center(child: Text("Failed to load suggested people")),
        data: (list) {
          if (list.isEmpty) {
            return const Center(child: Text("No suggested people available"));
          }
          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (context, i) => PeopleListTile(account: list[i]),
          );
        },
      );
    }

    return results.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) {
        {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Failed to search people"),
                ElevatedButton(
                  onPressed: () {
                    ref.invalidate(searchResultsProvider);
                  },
                  child: Text(
                    "Refresh",
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
              ],
            ),
          );
        }
      },
      data: (data) {
        final accounts = (data["accounts"] is List)
            ? data["accounts"]
            : <dynamic>[];
        if (accounts.isEmpty) {
          return const Center(child: Text("Couldn't find people"));
        }
        return ListView.builder(
          itemCount: accounts.length,
          itemBuilder: (context, i) => PeopleListTile(account: accounts[i]),
        );
      },
    );
  }
}

// ==========================================
// 6. LINKS TAB
// ==========================================
class LinksTab extends ConsumerWidget {
  const LinksTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trendingLinks = ref.watch(trendingLinksProvider);

    return trendingLinks.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) {
        {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Failed to load trending links timeline"),
                ElevatedButton(
                  onPressed: () {
                    ref.invalidate(trendingLinksProvider);
                  },
                  child: Text(
                    "Refresh",
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
              ],
            ),
          );
        }
      },
      data: (list) {
        if (list.isEmpty) {
          return const Center(child: Text("Couldn't find trending links"));
        }
        return ListView.builder(
          itemCount: list.length,
          itemBuilder: (context, i) => LinkListTile(link: list[i]),
        );
      },
    );
  }
}

// ==========================================
// REUSABLE WIDGETS
// ==========================================

class TagListTile extends ConsumerWidget {
  final Map<String, dynamic> tag;

  const TagListTile({super.key, required this.tag});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = tag['history'] as List<dynamic>? ?? [];
    final todayUses = history.isNotEmpty
        ? int.tryParse(history[0]['uses'].toString()) ?? 0
        : 0;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      title: Text(
        "#${tag['name']}",
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        "$todayUses uses today",
        style: const TextStyle(fontSize: 13, color: Colors.black54),
      ),
      onTap: () => context.push("/tags/${tag['name']}"),
    );
  }
}

class LinkListTile extends StatelessWidget {
  final Map<String, dynamic> link;

  const LinkListTile({super.key, required this.link});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(link["title"] ?? "Untitled"),
      subtitle: Text(link["url"]),
      leading: const Icon(Icons.link),
      onTap: () async {
        final uri = Uri.parse(link["url"]);

        await launchUrl(uri, mode: LaunchMode.externalApplication);
      },
    );
  }
}

class PostCardWrapper extends StatelessWidget {
  final Map<String, dynamic> post;

  const PostCardWrapper({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    final isReblog = post['reblog'] != null;
    final displayPost = isReblog ? post['reblog'] : post;
    final account = post['account'];
    final createdAt = displayPost['created_at'] ?? "";
    final timeAgo = createdAt.isNotEmpty
        ? timeago.format(DateTime.parse(createdAt))
        : "";

    return PostCard(
      post: displayPost,
      account: account,
      timeAgo: timeAgo,
      isReblog: isReblog,
      rebloggedBy: isReblog ? post['account'] : null,
    );
  }
}
