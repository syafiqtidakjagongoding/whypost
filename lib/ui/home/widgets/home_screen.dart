import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:whypost/constant/software.dart';
import 'package:whypost/routing/routes.dart';
import 'package:whypost/state/instance.dart';
import 'package:whypost/state/timeline.dart';
import 'package:whypost/sharedpreferences/credentials.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:whypost/ui/posts/post_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final String? instanceUrl;
  const HomeScreen({super.key, this.instanceUrl});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final ScrollController _homeScrollListener = ScrollController();
  final ScrollController _trendScrollListener = ScrollController();
  final ScrollController _localScrollListener = ScrollController();
  final ScrollController _publicScrollListener = ScrollController();

  String? softwareName;
  @override
  void initState() {
    super.initState();

    _homeScrollListener.addListener(() {
      final notifier = ref.read(homeTimelineProvider.notifier);

      if (_homeScrollListener.position.pixels >=
          _homeScrollListener.position.maxScrollExtent - 200) {
        notifier.loadMore(); // INFINITE SCROLL TRIGGER
      }
    });
    _trendScrollListener.addListener(() {
      final notifier = ref.read(trendProvider.notifier);

      if (_trendScrollListener.position.pixels >=
          _trendScrollListener.position.maxScrollExtent - 200) {
        notifier.loadMore(); // INFINITE SCROLL TRIGGER
      }
    });
    _localScrollListener.addListener(() {
      final notifier = ref.read(publicLocalProvider.notifier);

      if (_localScrollListener.position.pixels >=
          _localScrollListener.position.maxScrollExtent - 200) {
        notifier.loadMore(); // INFINITE SCROLL TRIGGER
      }
    });
    _publicScrollListener.addListener(() {
      final notifier = ref.read(publicFederatedProvider.notifier);

      if (_publicScrollListener.position.pixels >=
          _publicScrollListener.position.maxScrollExtent - 200) {
        notifier.loadMore(); // INFINITE SCROLL TRIGGER
      }
    });
    _loadInstance();
  }

  Future<void> _loadInstance() async {
    final software = await CredentialsRepository.getSoftwareName();
    setState(() {
      softwareName = software;
    });
  }

  @override
  Widget build(BuildContext context) {
    final homeTimeline = ref.watch(homeTimelineProvider);
    final localTimeline = ref.watch(publicLocalProvider);
    final instance = ref.watch(instanceProvider);
    final trendTimeline = (softwareName == Software.MASTODON)
        ? ref.watch(trendProvider)
        : null;
    final supportTrends = trendTimeline != null ? true : false;
    final publicTimeline = ref.watch(publicFederatedProvider);

    return DefaultTabController(
      length: supportTrends ? 4 : 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('For you'),
          centerTitle: true,
          elevation: 0.5,

          bottom: TabBar(
            tabs: [
              const Tab(text: 'Home'),
              if (supportTrends) const Tab(text: 'Trends'),
              const Tab(text: 'Local'),
              const Tab(text: 'Public'),
            ],
          ),
        ),
        drawer: Drawer(
          child: Column(
            children: [
              instance.when(
                loading: () => const DrawerHeader(
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, st) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Failed to load instance"),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  });

                  return const SizedBox.shrink();
                },
                data: (instance) => DrawerHeader(
                  decoration: BoxDecoration(
                    image: instance['thumbnail'] != null
                        ? DecorationImage(
                            image: NetworkImage(instance['thumbnail']),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (instance['uri'] != null)
                          Text(
                            "https://${instance['uri']}",
                            style: TextStyle(color: Colors.white),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.cloud),
                title: const Text("Instance"),
                onTap: () {
                  context.push(Routes.instanceInfo);
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text("Settings"),
                onTap: () {
                  context.push(Routes.settings);
                },
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text(
                    "Logout",
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () async {
                    final confirm = await showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text("Confirm Logout"),
                          content: const Text(
                            "Are you sure you want to logout?",
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: Text(
                                "Cancel",
                                style: Theme.of(context).textTheme.labelMedium,
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: Text(
                                "OK",
                                style: Theme.of(context).textTheme.labelMedium,
                              ),
                            ),
                          ],
                        );
                      },
                    );
                    if (confirm == true) {
                      await CredentialsRepository.clearAll();
                      if (!context.mounted) return;
                      context.go(Routes.instance);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildTimelineTab(homeTimeline),

            if (supportTrends) _buildTrendsTab(trendTimeline),
            _buildLocalTab(localTimeline),
            _buildPublicTab(publicTimeline),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => context.push(Routes.addPost),
          child: Icon(
            Icons.add,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black
                : Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineTab(AsyncValue timeline) {
    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(homeTimelineProvider);
          },
          child: timeline.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Failed to load home timeline"),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        ref.invalidate(homeTimelineProvider);
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
                return const Center(child: Text('No posts available'));
              }
              return ListView.builder(
                controller: _homeScrollListener,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: posts.length,
                itemBuilder: (context, i) {
                  final post = posts[i];
                  final isReblog = post['reblog'] != null;
                  final displayPost = isReblog ? post['reblog'] : post;
                  final displayAccount = isReblog
                      ? post['reblog']['account']
                      : post['account'];
                  final createdAt = displayPost['created_at'];
                  final timeAgo = createdAt != null
                      ? timeago.format(DateTime.parse(createdAt))
                      : '';
                  return PostCard(
                    post: displayPost,
                    account: displayAccount,
                    timeAgo: timeAgo,
                    isReblog: isReblog,
                    rebloggedBy: isReblog ? post['account'] : null,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _homeScrollListener.dispose();
    _localScrollListener.dispose();
    _trendScrollListener.dispose();
    _publicScrollListener.dispose();
    super.dispose();
  }

  Widget _buildTrendsTab(AsyncValue timeline) {
    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(trendProvider);
          },
          child: timeline.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Failed to load trends timeline"),
                    ElevatedButton(
                      onPressed: () {
                        ref.invalidate(trendProvider);
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
                return const Center(child: Text('No posts available'));
              }
              return ListView.builder(
                controller: _trendScrollListener,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: posts.length,
                itemBuilder: (context, i) {
                  final post = posts[i];
                  final isReblog = post['reblog'] != null;
                  final displayPost = isReblog ? post['reblog'] : post;
                  final displayAccount = isReblog
                      ? post['reblog']['account']
                      : post['account'];
                  final createdAt = displayPost['created_at'];
                  final timeAgo = createdAt != null
                      ? timeago.format(DateTime.parse(createdAt))
                      : '';
                  return PostCard(
                    post: displayPost,
                    account: displayAccount,
                    timeAgo: timeAgo,
                    isReblog: isReblog,
                    rebloggedBy: isReblog ? post['account'] : null,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLocalTab(AsyncValue timeline) {
    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(publicLocalProvider);
          },
          child: timeline.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Failed to load local timeline"),
                    ElevatedButton(
                      onPressed: () {
                        ref.invalidate(publicLocalProvider);
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
                return const Center(child: Text('No posts available'));
              }
              return ListView.builder(
                controller: _localScrollListener,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: posts.length,
                itemBuilder: (context, i) {
                  final post = posts[i];
                  final isReblog = post['reblog'] != null;
                  final displayPost = isReblog ? post['reblog'] : post;
                  final displayAccount = isReblog
                      ? post['reblog']['account']
                      : post['account'];
                  final createdAt = displayPost['created_at'];
                  final timeAgo = createdAt != null
                      ? timeago.format(DateTime.parse(createdAt))
                      : '';
                  return PostCard(
                    post: displayPost,
                    account: displayAccount,
                    timeAgo: timeAgo,
                    isReblog: isReblog,
                    rebloggedBy: isReblog ? post['account'] : null,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPublicTab(AsyncValue timeline) {
    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(publicFederatedProvider);
          },
          child: timeline.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Failed to load public timeline"),
                    ElevatedButton(
                      onPressed: () {
                        ref.invalidate(publicFederatedProvider);
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
                return const Center(child: Text('No posts available'));
              }
              return ListView.builder(
                controller: _publicScrollListener,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: posts.length,
                itemBuilder: (context, i) {
                  final post = posts[i];
                  final isReblog = post['reblog'] != null;
                  final displayPost = isReblog ? post['reblog'] : post;
                  final displayAccount = isReblog
                      ? post['reblog']['account']
                      : post['account'];
                  final createdAt = displayPost['created_at'];
                  final timeAgo = createdAt != null
                      ? timeago.format(DateTime.parse(createdAt))
                      : '';
                  return PostCard(
                    post: displayPost,
                    account: displayAccount,
                    timeAgo: timeAgo,
                    isReblog: isReblog,
                    rebloggedBy: isReblog ? post['account'] : null,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
