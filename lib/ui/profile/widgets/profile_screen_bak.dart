import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:whypost/app_theme.dart';
import 'package:whypost/routing/routes.dart';
import 'package:whypost/sharedpreferences/credentials.dart';
import 'package:whypost/state/action.dart';
import 'package:whypost/state/timeline.dart';
import 'package:whypost/ui/posts/post_card.dart';
import 'package:whypost/ui/profile/widgets/user_info.dart';
import 'package:whypost/ui/utils/ContentParsing.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:whypost/service/FormatNumber.dart';
import 'package:whypost/state/account.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  final String? identifier;
  ProfileScreen({super.key, this.identifier});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  String? currentUserId;
  final ScrollController _statusesController = ScrollController();
  final ScrollController _statusesMediaController = ScrollController();
  final ScrollController _favouriteController = ScrollController();
  final ScrollController _bookmarkedController = ScrollController();
  @override
  void initState() {
    super.initState();
    load();
    _statusesController.addListener(() {
      final notifier = ref.read(
        statusesTimelineProvider(widget.identifier!).notifier,
      );

      if (_statusesController.position.pixels >=
          _statusesController.position.maxScrollExtent - 200) {
        notifier.loadMore(); // INFINITE SCROLL TRIGGER
      }
    });
    _statusesMediaController.addListener(() {
      final notifier = ref.read(
        statusesMediaTimelineProvider(widget.identifier!).notifier,
      );

      if (_statusesMediaController.position.pixels >=
          _statusesMediaController.position.maxScrollExtent - 200) {
        notifier.loadMore(); // INFINITE SCROLL TRIGGER
      }
    });
    _bookmarkedController.addListener(() {
      final notifier = ref.read(bookmarkedTimelineProvider.notifier);

      if (_bookmarkedController.position.pixels >=
          _bookmarkedController.position.maxScrollExtent - 200) {
        notifier.loadMore(); // INFINITE SCROLL TRIGGER
      }
    });
    _favouriteController.addListener(() {
      final notifier = ref.read(favouritedTimelineProvider.notifier);

      if (_favouriteController.position.pixels >=
          _favouriteController.position.maxScrollExtent - 200) {
        notifier.loadMore(); // INFINITE SCROLL TRIGGER
      }
    });
  }

  Future<void> load() async {
    final result = await CredentialsRepository.getCurrentUserId();

    setState(() {
      currentUserId = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(selectedUserProvider(widget.identifier!));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedColor = isDark ? Colors.white : AppTheme.seed;
    final unselectedColor = isDark
        ? Colors.white60
        : AppTheme.seed.withAlpha(200);
    ref.listen(relationshipProvider(widget.identifier!), (prev, next) {
      next.whenData((rel) {
        if (rel == null) return;

        final followingValue = rel['following'];
        final requestedValue = rel['requested'];

        if (followingValue != null) {
          ref
              .read(followProvider.notifier)
              .update((s) => {...s, widget.identifier!: followingValue});
        }

        if (requestedValue != null) {
          ref
              .read(requestedFollowProvider.notifier)
              .update((s) => {...s, widget.identifier!: requestedValue});
        }
      });
    });
    return Scaffold(
      body: userAsync.when(
        loading: () => Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text("Error: $e")),
        data: (user) {
          final userId = user!['id'];
          // Watch timeline AFTER user successfully loaded
          final statusesAsync = ref.watch(statusesTimelineProvider(userId));
          final favouritedAsync = widget.identifier == currentUserId
              ? ref.watch(favouritedTimelineProvider)
              : AsyncValue.data([]);
          final bookmarkedAsync = widget.identifier == currentUserId
              ? ref.watch(bookmarkedTimelineProvider)
              : AsyncValue.data([]);
          final statusesOnlyMediaAsync = ref.watch(
            statusesMediaTimelineProvider(userId),
          );
          final follow = ref.watch(followProvider);
          final requested = ref.watch(requestedFollowProvider);
          final isRequested = requested[userId] ?? false;
          final isFollowed = follow[userId] ?? false;

          return DefaultTabController(
            length: widget.identifier == currentUserId ? 4 : 3,
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        // ===== HEADER =====
                        Stack(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header Image
                                Stack(
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        context.push(
                                          Routes.viewImages,
                                          extra: user['header'],
                                        );
                                      },
                                      child: Container(
                                        width: double.infinity,
                                        height: 150,
                                        color: Colors.grey[300],
                                        child: user['header'] != null
                                            ? Image.network(
                                                user['header'],
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, _, _) {
                                                  return Container(
                                                    color: Colors.grey[300],
                                                  );
                                                },
                                              )
                                            : null,
                                      ),
                                    ),

                                    // Back Button
                                    if (widget.identifier != currentUserId)
                                      Positioned(
                                        top: 12,
                                        left: 8,
                                        child: IconButton(
                                          icon: const Icon(Icons.arrow_back),
                                          onPressed: () => context.pop(),
                                          style: IconButton.styleFrom(
                                            backgroundColor: Colors.black
                                                .withOpacity(0.6),
                                            foregroundColor: Colors.white,
                                          ),
                                        ),
                                      ),

                                    if (widget.identifier == currentUserId)
                                      Positioned(
                                        top: 12,
                                        right: 8,
                                        child: IconButton(
                                          icon: const Icon(Icons.settings),
                                          onPressed: () {
                                            context.push(Routes.editProfile);
                                          },
                                          style: IconButton.styleFrom(
                                            backgroundColor: Colors.black
                                                .withOpacity(0.6),
                                            foregroundColor: Colors.white,
                                          ),
                                        ),
                                      ),

                                    if (widget.identifier != currentUserId)
                                      Positioned(
                                        top: 12,
                                        right: 8,
                                        child: IconButton(
                                          icon: const Icon(Icons.more_vert),
                                          onPressed: () {},
                                          style: IconButton.styleFrom(
                                            backgroundColor: Colors.black
                                                .withOpacity(0.6),
                                            foregroundColor: Colors.white,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),

                                // Profile Info Section
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    0,
                                    16,
                                    16,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(
                                        height: 60,
                                      ), // Space for avatar
                                      // Display Name
                                      displayTitleWithEmoji(user, context),

                                      const SizedBox(height: 2),

                                      // Username
                                      Text(
                                        "@${user['acct']}",
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 15,
                                        ),
                                      ),

                                      const SizedBox(height: 12),

                                      // Bio
                                      if (user['note'] != null &&
                                          user['note'].toString().isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 12,
                                          ),
                                          child: Contentparsing(
                                            content: user['note'],
                                            emojis: user['emojis'],
                                            mentions: [],
                                          ),
                                        ),

                                      // Stats Row
                                      Row(
                                        children: [
                                          _buildStatText(
                                            formatNumber(
                                              user['following_count'],
                                            ),
                                            'Following',
                                            'following',
                                            context,
                                            userId,
                                          ),
                                          const SizedBox(width: 20),
                                          _buildStatText(
                                            formatNumber(
                                              user['followers_count'],
                                            ),
                                            'Followers',
                                            'followers',
                                            context,
                                            userId,
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 16),

                                      // Follow Button
                                      if (widget.identifier != currentUserId)
                                        SizedBox(
                                          width: double.infinity,
                                          height: 38,
                                          child: OutlinedButton(
                                            onPressed: () async {
                                              try {
                                                if (isFollowed == true) {
                                                  // ===== UNFOLLOW =====
                                                  final res = await ref.read(
                                                    unfollowUserProvider(
                                                      userId,
                                                    ).future,
                                                  );

                                                  ref
                                                      .read(
                                                        followProvider.notifier,
                                                      )
                                                      .update(
                                                        (state) => {
                                                          ...state,
                                                          userId:
                                                              res?['following'] ??
                                                              false,
                                                        },
                                                      );
                                                  ref
                                                      .read(
                                                        requestedFollowProvider
                                                            .notifier,
                                                      )
                                                      .update(
                                                        (state) => {
                                                          ...state,
                                                          userId:
                                                              res?['requested'] ??
                                                              false,
                                                        },
                                                      );
                                                } else {
                                                  // ===== FOLLOW =====
                                                  final res = await ref.read(
                                                    followUserProvider(
                                                      userId,
                                                    ).future,
                                                  );
                                                  ref
                                                      .read(
                                                        followProvider.notifier,
                                                      )
                                                      .update(
                                                        (state) => {
                                                          ...state,
                                                          userId:
                                                              res?['following'] ??
                                                              false,
                                                        },
                                                      );
                                                  ref
                                                      .read(
                                                        requestedFollowProvider
                                                            .notifier,
                                                      )
                                                      .update(
                                                        (state) => {
                                                          ...state,
                                                          userId:
                                                              res?['requested'] ??
                                                              false,
                                                        },
                                                      );
                                                }

                                                ref.invalidate(accountFollowingProvider(currentUserId!));
                                                ref.invalidate(
                                                  relationshipProvider(
                                                    widget.identifier!,
                                                  ),
                                                );
                                              } catch (e) {
                                                ScaffoldMessenger
                                                    .of(context)
                                                    .showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          "Something went wrong",
                                                        ),
                                                        backgroundColor:
                                                            Colors.red,
                                                        duration:
                                                            const Duration(
                                                              seconds: 3,
                                                            ),
                                                      ),
                                                    );
                                              }
                                            },
                                            
                                            style: OutlinedButton.styleFrom(
                                              backgroundColor:
                                                  isFollowed == true
                                                  ? Colors.white
                                                  : Colors.black,
                                              foregroundColor:
                                                  isFollowed == true
                                                  ? Colors.black
                                                  : Colors.white,
                                              side: BorderSide(
                                                color: isFollowed == true
                                                    ? Colors.grey[400]!
                                                    : Colors.black,
                                                width: 1,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                            ),
                                            child: Text(
                                              isRequested == true
                                                  ? "Requested"
                                                  : isFollowed == true
                                                  ? "Following"
                                                  : "Follow",
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 15,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            // Avatar positioned absolutely
                            Positioned(
                              top: 115, // Overlapping the header
                              left: 16,
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 4,
                                  ),
                                ),
                                child: GestureDetector(
                                  onTap: () {
                                    context.push(
                                      Routes.viewImages,
                                      extra: user['avatar_static'],
                                    );
                                  },
                                  child: CircleAvatar(
                                    radius: 35,
                                    backgroundImage: NetworkImage(
                                      user['avatar_static'] ?? "",
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        // ===== TAB BAR =====
                        TabBar(
                          indicatorColor: selectedColor,
                          labelColor: selectedColor,
                          unselectedLabelColor: unselectedColor,
                          tabs: [
                            Tab(text: "Statuses"),
                            Tab(
                              text: widget.identifier == currentUserId
                                  ? "Favourites"
                                  : "Media",
                            ),
                            Tab(
                              text: widget.identifier == currentUserId
                                  ? "Saved"
                                  : "About",
                            ),
                            if (widget.identifier == currentUserId)
                              Tab(text: "About"),
                          ],
                        ),
                      ],
                    ),
                  ),
                ];
              },

              // ===== TAB VIEW =====
              body: SafeArea(
                top: false,
                bottom: true,
                child: TabBarView(
                  children: [
                    // ==== TAB 1: STATUS ====
                    RefreshIndicator(
                      onRefresh: () async {
                        ref.invalidate(statusesTimelineProvider(userId));
                      },
                      child: Builder(
                        builder: (context) {
                          final state = statusesAsync;
                          if (state.isLoading && state.posts.isEmpty) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          // ---- NO DATA ----
                          if (state.posts.isEmpty) {
                            return const Center(
                              child: Text("No posts available"),
                            );
                          }

                          return ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: state.posts.length,
                            controller: _statusesController,
                            itemBuilder: (context, i) {
                              final post = state.posts[i];

                              final isReblog = post['reblog'] != null;

                              final displayPost = isReblog
                                  ? post['reblog'] as Map<String, dynamic>
                                  : post;

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

                    // ==== TAB 2: FAVOURITES / MEDIA ====
                    if (widget.identifier == currentUserId)
                      RefreshIndicator(
                        onRefresh: () async {
                          ref.invalidate(favouritedTimelineProvider);
                        },
                        child: favouritedAsync.when(
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (e, _) => Center(child: Text("Failed to load favourite timeline")),
                          data: (posts) {
                            if (posts.isEmpty) {
                              return const Center(
                                child: Text("No liked posts yet"),
                              );
                            }

                            return ListView.builder(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              itemCount: posts.length,
                              controller: _favouriteController,
                              itemBuilder: (context, i) {
                                final post = posts[i];

                                final isReblog = post['reblog'] != null;

                                final displayPost = isReblog
                                    ? post['reblog'] as Map<String, dynamic>
                                    : post;

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
                                  rebloggedBy: isReblog
                                      ? post['account']
                                      : null,
                                );
                              },
                            );
                          },
                        ),
                      ),

                    if (widget.identifier != currentUserId)
                      RefreshIndicator(
                        onRefresh: () async {
                          ref.invalidate(statusesMediaTimelineProvider(userId));
                        },
                        child: Builder(
                          builder: (context) {
                            final state = statusesOnlyMediaAsync;
                            
                            if (state.isLoading && state.posts.isEmpty) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            // ---- NO DATA ----
                            if (state.posts.isEmpty) {
                              return const Center(
                                child: Text("No posts available"),
                              );
                            }

                            return ListView.builder(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              controller: _statusesMediaController,
                              itemCount: state.posts.length,
                              itemBuilder: (context, i) {
                                final post = state.posts[i];

                                final isReblog = post['reblog'] != null;

                                final displayPost = isReblog
                                    ? post['reblog'] as Map<String, dynamic>
                                    : post;

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
                                  rebloggedBy: isReblog
                                      ? post['account']
                                      : null,
                                );
                              },
                            );
                          },
                        ),
                      ),

                    // ==== TAB 3: BOOKMARKS / ABOUT ====
                    if (widget.identifier == currentUserId)
                      RefreshIndicator(
                        onRefresh: () async {
                          ref.invalidate(bookmarkedTimelineProvider);
                        },
                        child: bookmarkedAsync.when(
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (e, _) => Center(child: Text("Failed to load bookmarked timeline")),
                          data: (posts) {
                            if (posts.isEmpty) {
                              return const Center(
                                child: Text("No bookmarked posts yet"),
                              );
                            }

                            return ListView.builder(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              itemCount: posts.length,
                              controller: _bookmarkedController,
                              itemBuilder: (context, i) {
                                final post = posts[i];

                                final isReblog = post['reblog'] != null;

                                final displayPost = isReblog
                                    ? post['reblog'] as Map<String, dynamic>
                                    : post;

                                final displayAccount = isReblog
                                    ? post['account']
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
                                  rebloggedBy: isReblog
                                      ? post['account']
                                      : null,
                                );
                              },
                            );
                          },
                        ),
                      ),

                    if (widget.identifier != currentUserId)
                      RefreshIndicator(
                        onRefresh: () async {
                          ref.invalidate(
                            selectedUserProvider(widget.identifier!),
                          );
                        },
                        child: userAsync.when(
                          data: (user) {
                            if (user!.isEmpty) {
                              return Text("User error");
                            }
                            return SafeArea(
                              top: false,
                              bottom: true,
                              child: SingleChildScrollView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                child: UserInfoTextCard(account: user),
                              ),
                            );
                          },
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (e, _) => Center(child: Text("Failed to load user info")),
                        ),
                      ),

                    // ==== TAB 4: ABOUT (for current user) ====
                    if (widget.identifier == currentUserId)
                      RefreshIndicator(
                        onRefresh: () async {
                          ref.invalidate(
                            selectedUserProvider(widget.identifier!),
                          );
                        },
                        child: userAsync.when(
                          data: (user) {
                            if (user!.isEmpty) {
                              return Text("User error");
                            }
                            return SafeArea(
                              top: false,
                              bottom: true,
                              child: SingleChildScrollView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                child: UserInfoTextCard(account: user),
                              ),
                            );
                          },
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (e, _) => Center(child: Text("Faile to load user")),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
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
    );
  }
}

Widget displayTitleWithEmoji(
  Map<String, dynamic> account,
  BuildContext context,
) {
  final displayName = account['display_name'] == ""
      ? account['username']
      : account['display_name'];
  final emojis = account['emojis'] as List<dynamic>? ?? [];

  final regex = RegExp(r':([a-zA-Z0-9_]+):');

  List<InlineSpan> children = [];

  displayName.splitMapJoin(
    regex,
    onMatch: (m) {
      final shortcode = m.group(1);

      final emoji = emojis.firstWhere(
        (e) => e['shortcode'] == shortcode,
        orElse: () => null,
      );

      if (emoji != null) {
        children.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Image.network(emoji['url'], width: 20, height: 20),
          ),
        );
      } else {
        children.add(TextSpan(text: m.group(0)));
      }

      return '';
    },
    onNonMatch: (text) {
      children.add(TextSpan(text: text));
      return '';
    },
  );

  return RichText(
    maxLines: 1,
    text: TextSpan(
      style: Theme.of(context).textTheme.labelLarge,
      children: children,
    ),
  );
}

Widget _buildStatText(
  String value,
  String label,
  String type,
  BuildContext context,
  String userId,
) {
  return InkWell(
    onTap: () {
      context.push(
        type == "followers" ? Routes.followers : Routes.following,
        extra: {"type": type, "accountId": userId},
      );
    },
    child: RichText(
      text: TextSpan(
        children: [
          TextSpan(text: value, style: Theme.of(context).textTheme.labelMedium),
          TextSpan(
            text: ' $label',
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ],
      ),
    ),
  );
}
