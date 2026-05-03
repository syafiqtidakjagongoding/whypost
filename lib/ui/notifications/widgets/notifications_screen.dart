import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:whypost/routing/routes.dart';
import 'package:whypost/sharedpreferences/credentials.dart';
import 'package:whypost/state/action.dart';
import 'package:whypost/state/timeline.dart';
import 'package:whypost/ui/posts/post_media.dart';
import 'package:whypost/ui/utils/action_button.dart';
import 'package:whypost/ui/utils/content_parsing.dart';
import 'package:whypost/ui/utils/display_name_with_emoji.dart';
import 'package:whypost/state/notifications.dart';

class NotificationCard extends ConsumerStatefulWidget {
  final Map<String, dynamic> notification;

  const NotificationCard({super.key, required this.notification});

  @override
  ConsumerState<NotificationCard> createState() => _NotificationCardState();
}

class _NotificationCardState extends ConsumerState<NotificationCard> {
  String? currentUserId;

  @override
  void initState() {
    super.initState();
    loadCred();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializePostState();
    });
  }

  void _initializePostState() {
    if (!mounted) return;
    final status = widget.notification['status'];
    if (status == null) return;
    final postId = status['id'];

    final favourite = ref.read(favouriteProvider);
    final reblogged = ref.read(rebloggedProvider);
    final bookmarks = ref.read(bookmarkProvider);

    if (!favourite.containsKey(postId)) {
      ref
          .read(favouriteProvider.notifier)
          .update((state) => {...state, postId: status['favourited'] ?? false});
    }

    if (!reblogged.containsKey(postId)) {
      ref
          .read(rebloggedProvider.notifier)
          .update((state) => {...state, postId: status['reblogged'] ?? false});
    }

    if (!bookmarks.containsKey(postId)) {
      ref
          .read(bookmarkProvider.notifier)
          .update((state) => {...state, postId: status['bookmarked'] ?? false});
    }
  }

  Future<void> loadCred() async {
    final userId = await CredentialsRepository.getCurrentUserId();
    if (!mounted) return;
    setState(() {
      currentUserId = userId;
    });
  }

  List<Widget> buildPostMenu(
    bool isBookmarked,
    String postId,
  ) {
    final menu = <Widget>[];

    menu.add(
      ListTile(
        leading: Icon(
          isBookmarked ? Icons.bookmark : Icons.bookmark_border,
          color: Colors.deepPurple,
        ),
        title: Text(isBookmarked ? 'UnBookmark' : 'Bookmark Post'),
        onTap: () async {
          Map<String, dynamic> result;
          final messenger = ScaffoldMessenger.of(context);

          if (isBookmarked) {
            result = await ref.read(
              unbookmarkPostActionProvider(postId).future,
            );
            messenger.showSnackBar(
              const SnackBar(
                content: Text("Successfully unbookmarked post"),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            result = await ref.read(
              bookmarkPostActionProvider(postId).future,
            );
            messenger.showSnackBar(
              const SnackBar(
                content: Text("Successfully bookmarked post"),
                backgroundColor: Colors.green,
              ),
            );
          }
          ref.read(bookmarkProvider.notifier).update((state) {
            return {...state, postId: result['bookmarked']};
          });

          ref.invalidate(bookmarkedTimelineProvider);
        },
      ),
    );

    return menu;
  }

  @override
  Widget build(BuildContext context) {
    final account = widget.notification['account'];
    final status = widget.notification['status'];
    final postId = status?['id'];
    final bookmarks = ref.watch(bookmarkProvider);
    final isBookmarked = postId != null ? (bookmarks[postId] ?? false) : false;

    return InkWell(
      onTap: () {
        if (status != null) {
          context.push(Routes.viewPost, extra: {"postId": status['id']});
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[900]
              : const Color(0xFFF8FAFC),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.black54
                  : Color(0xFF94A3B8).withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () {
                context.push("/user/${account['id']}");
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            Color.fromRGBO(255, 117, 31, 1),
                            Color.fromRGBO(255, 117, 31, 0.6),
                          ],
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: CircleAvatar(
                          backgroundImage: NetworkImage(
                            account['avatar_static'] ?? account['avatar'],
                          ),
                          radius: 22,
                          backgroundColor: Colors.grey[200],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildNotificationHeader(context),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  "@${account['acct']}",
                                  style: TextStyle(fontSize: 13),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                ),
                                child: Text(
                                  "•",
                                  style: TextStyle(color: Colors.grey[400]),
                                ),
                              ),
                              Text(
                                timeago.format(
                                  DateTime.parse(widget.notification['created_at']),
                                ),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    if (postId != null)
                      IconButton(
                        icon: Icon(Icons.more_horiz, color: Colors.grey[600]),
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(15),
                              ),
                            ),
                            builder: (context) => Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 16,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: buildPostMenu(
                                  isBookmarked,
                                  postId,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
            // =============================
            // STATUS PREVIEW — TAP → VIEW POST
            // =============================
            if (status != null) ...[
              InkWell(
                onTap: () {
                  context.push(
                    Routes.viewPost,
                    extra: {"postId": status['id']},
                  );
                },
                child: _buildStatusPreview(context),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationHeader(BuildContext context) {
    String action;

    switch (widget.notification['type']) {
      case 'favourite':
        action = 'liked your post';
        break;
      case 'reblog':
        action = 'boosted your post';
        break;
      case 'mention':
        action = 'mentioned you';
        break;
      case 'follow':
        action = 'followed you';
        break;
      case 'poll':
        action = 'your poll has ended';
        break;
      case 'status':
        action = 'new post';
        break;
      default:
        action = 'interacted with you';
    }

    return displayNameWithEmoji(widget.notification['account'], context, ' $action');
  }

  Widget _buildStatusPreview(BuildContext context) {
    final status = widget.notification['status'];
    if (status == null) return const SizedBox.shrink();
    final postId = status['id'];
    final account = widget.notification['account'];
    final media = status['media_attachments'] as List<dynamic>? ?? [];
    final favourite = ref.watch(favouriteProvider);
    final reblogged = ref.watch(rebloggedProvider);
    final isFavourite = favourite[postId] ?? false;
    final isReblogged = reblogged[postId] ?? false;

    return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Contentparsing(
              content: status['content'],
              emojis: status['emojis'],
              mentions: status['mentions'],
            ),
          ),
          if (media.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: PostMedia(
                media: media,
                sensitive: status['sensitive'] ?? false,
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ActionButton(
                  icon: CupertinoIcons.reply,
                  onTap: () {
                    context.push(
                      '/reply/$postId?mention=@${account['acct']}',
                    );
                  },
                ),
                ActionButton(
                  icon: isReblogged
                      ? CupertinoIcons.repeat_1
                      : CupertinoIcons.repeat,
                  onTap: () async {
                    final messenger = ScaffoldMessenger.of(context);

                    try {
                      Map<String, dynamic> result;

                      if (isReblogged) {
                        result = await ref.read(
                          unreblogPostActionProvider(postId).future,
                        );
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text("Successfully unreblog post"),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } else {
                        result = await ref.read(
                          reblogPostActionProvider(postId).future,
                        );
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text("Successfully reblog post"),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }

                      ref.read(rebloggedProvider.notifier).update((state) {
                        return {...state, postId: result['reblogged']};
                      });
                      ref.invalidate(statusesTimelineProvider(currentUserId!));
                    } catch (e) {
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text("Something went wrong."),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                ),
                ActionButton(
                  icon: isFavourite
                      ? CupertinoIcons.star_slash_fill
                      : CupertinoIcons.star_slash,
                  onTap: () async {
                    final messenger = ScaffoldMessenger.of(context);

                    try {
                      Map<String, dynamic> result;

                      if (isFavourite) {
                        result = await ref.read(
                          unfavoritePostActionProvider(postId).future,
                        );
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text("Successfully unfavourite post"),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } else {
                        result = await ref.read(
                          favoritePostActionProvider(postId).future,
                        );
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text("Successfully favourite post"),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }

                      ref.read(favouriteProvider.notifier).update((state) {
                        return {
                          ...state,
                          postId: result['favourited'],
                        };
                      });
                      ref.invalidate(favouritedTimelineProvider);
                    } catch (e) {
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text("Something went wrong."),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                ),
                ActionButton(
                  icon: Icons.share,
                  onTap: () async {
                    // ignore: deprecated_member_use
                    await SharePlus.instance.share(
                      ShareParams(text: status['url']),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
    );
  }
}

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(notificationsProvider);
    final mentionsNotificationsAsync = ref.watch(
      notificationsProviderByType("mention"),
    );
    final favouriteNotificationsAsync = ref.watch(
      notificationsProviderByType("favourite"),
    );

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Notifications'),
          centerTitle: true,
          elevation: 0.5,
          bottom: const TabBar(
            tabs: [
              Tab(text: "All"),
              Tab(text: "Mention"),
              Tab(text: "Favourite"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab All
            RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(notificationsProvider);
              },
              child: notificationsAsync.when(
                data: (notifications) {
                  if (notifications.isEmpty) {
                    return Center(child: Text("No notifications yet"));
                  }

                  return ListView.builder(
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      return NotificationCard(
                        notification: notifications[index],
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) {
                  return const Center(
                    child: Text("Failed to load notifications"),
                  );
                },
              ),
            ),

            // Tab Mention
            RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(notificationsProviderByType("mention"));
              },
              child: mentionsNotificationsAsync.when(
                data: (notifications) {
                  if (notifications.isEmpty) {
                    return Center(child: Text("No notifications yet"));
                  }
                  return ListView.builder(
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      return NotificationCard(
                        notification: notifications[index],
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) {
                  return const Center(
                    child: Text("Failed to load notifications"),
                  );
                },
              ),
            ),

            // Tab Favourite
            RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(notificationsProviderByType("favourite"));
              },
              child: favouriteNotificationsAsync.when(
                data: (notifications) {
                  if (notifications.isEmpty) {
                    return Center(child: Text("No notifications yet"));
                  }
                  return ListView.builder(
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      return NotificationCard(
                        notification: notifications[index],
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) {
                  return const Center(
                    child: Text("Failed to load notifications"),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
