import 'package:flutter/cupertino.dart';
import 'package:whypost/api/statuses_api.dart';
import 'package:whypost/sharedpreferences/credentials.dart';
import 'package:whypost/state/timeline.dart';
import 'package:whypost/ui/posts/post_media.dart';
import 'package:whypost/ui/utils/content_parsing.dart';
import 'package:whypost/ui/posts/comment_list.dart';
import 'package:whypost/ui/utils/display_name_with_emoji.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:whypost/state/action.dart';
import 'package:timeago/timeago.dart' as timeago;

class ViewpostScreen extends ConsumerStatefulWidget {
  final String postId;

  const ViewpostScreen({super.key, required this.postId});

  @override
  ConsumerState<ViewpostScreen> createState() => _ViewpostScreenState();
}

class _ViewpostScreenState extends ConsumerState<ViewpostScreen> {
  String? currentUserId;
  Map<String, dynamic>? post;
  Map<String, dynamic>? account;
  List<Widget> buildPostMenu(
    bool isUserPost,
    bool isBookmarked,
    String postId,
  ) {
    final menu = <Widget>[];

    if (isUserPost) {
      menu.add(
        ListTile(
          leading: const Icon(Icons.edit, color: Colors.blue),
          title: const Text('Edit Post'),
          onTap: () {
            context.push("/edit-post/$postId");
          },
        ),
      );
      menu.add(
        ListTile(
          leading: const Icon(Icons.delete, color: Colors.red),
          title: const Text('Delete Post'),
          onTap: () {
            Navigator.pop(context);

            showDialog(
              context: context,
              builder: (ctx) {
                return AlertDialog(
                  title: const Text("Delete Post"),
                  content: const Text(
                    "Are you sure you want to delete this post?",
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                      },
                      child: const Text("Cancel"),
                    ),
                    TextButton(
                      onPressed: () async {
                        context.pop();

                        final cred =
                            await CredentialsRepository.loadCredentials();

                        await deleteStatusesById(
                          cred.instanceUrl!,
                          cred.accToken!,
                          postId,
                        );
                        if (!mounted) return;
                        final messenger = ScaffoldMessenger.of(context);
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text("Post deleted successfully"),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                      child: const Text(
                        "Delete",
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      );

      menu.add(const Divider());
    }

    menu.add(
      ListTile(
        leading: Icon(
          isBookmarked ? CupertinoIcons.bookmark_fill : CupertinoIcons.bookmark,
          color: Colors.deepPurple,
        ),
        title: Text(isBookmarked ? 'UnBookmark' : 'Bookmark Post'),
        onTap: () async {
          final messenger = ScaffoldMessenger.of(context);

          Map<String, dynamic> result;
          if (isBookmarked) {
            result = await ref.read(
              unbookmarkPostActionProvider(widget.postId).future,
            );
            messenger.showSnackBar(
              const SnackBar(
                content: Text("Successfully unbookmarked post"),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            result = await ref.read(
              bookmarkPostActionProvider(widget.postId).future,
            );
            messenger.showSnackBar(
              const SnackBar(
                content: Text("Successfully bookmarked post"),
                backgroundColor: Colors.green,
              ),
            );
          }
          ref.read(bookmarkProvider.notifier).update((state) {
            return {...state, widget.postId: result['bookmarked']};
          });
          ref.invalidate(bookmarkedTimelineProvider);
        },
      ),
    );
    return menu;
  }

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final cred = await CredentialsRepository.loadAllCredentials();
      if (cred.accToken != null && cred.instanceUrl != null) {
        final result = await fetchStatusDetail(
          cred.instanceUrl!,
          cred.accToken!,
          widget.postId,
        );

        if (!mounted) return;

        setState(() {
          currentUserId = cred.currentUserId;
          post = result;
          account = result['account'];
        });
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to load post"),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (post == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final media = post!['media_attachments'] as List<dynamic>? ?? [];
    final bookmarks = ref.watch(bookmarkProvider);
    final favourite = ref.watch(favouriteProvider);
    final reblogged = ref.watch(rebloggedProvider);
    final isFavourite = favourite[widget.postId] ?? false;
    final isReblogged = reblogged[widget.postId] ?? false;
    final isBookmarked = bookmarks[widget.postId] ?? false;
    final isReblogPost = post!['reblog'] != null;
    final displayPost = isReblogPost ? post!['reblog'] : post;
    final createdAt = displayPost['created_at'];
    final timeAgo = createdAt != null
        ? timeago.format(DateTime.parse(createdAt))
        : '';

    if (!favourite.containsKey(widget.postId)) {
      Future.microtask(() {
        ref
            .read(favouriteProvider.notifier)
            .update(
              (state) => {
                ...state,
                widget.postId: post!['favourited'] ?? false,
              },
            );
      });
    }

    if (!reblogged.containsKey(widget.postId)) {
      Future.microtask(() {
        ref
            .read(rebloggedProvider.notifier)
            .update(
              (state) => {...state, widget.postId: post!['reblogged'] ?? false},
            );
      });
    }

    if (!bookmarks.containsKey(widget.postId)) {
      Future.microtask(() {
        ref
            .read(bookmarkProvider.notifier)
            .update(
              (state) => {
                ...state,
                widget.postId: post!['bookmarked'] ?? false,
              },
            );
      });
    }

    return Scaffold(
      appBar: AppBar(title: Text("Post from ${account!['username']}")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
             InkWell(
                onTap: () {
                  context.push('/user/${account!['id']}');
                },
                child: Padding(
                  padding: const EdgeInsets.all(1),
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
                              account!['avatar_static'],
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
                            displayNameWithEmoji(account!, context),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    "@${account!['acct']}",
                                    style: TextStyle(fontSize: 13),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (timeAgo != "") ...[
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
                                    timeAgo,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),

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
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: buildPostMenu(
                                  account!['id'].toString() ==
                                      currentUserId.toString(),
                                  isBookmarked,
                                  post!['id'],
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

              const SizedBox(height: 8),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Contentparsing(
                  mentions: post!['mentions'],
                  content: post!['content'],
                  emojis: post!['emojis'],
                ),
              ),

              const SizedBox(height: 8),

              if (media.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: PostMedia(
                    media: media,
                    sensitive: post!['sensitive'] ?? false,
                  ),
                ),

              const SizedBox(height: 8),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  LabelIconButton(
                    label: post!['replies_count'].toString(),
                    icon: CupertinoIcons.reply,
                    onTap: () {
                      context.push(
                        "/reply/${widget.postId}?mention=@${account!['acct']}",
                      );
                    },
                  ),
                  LabelIconButton(
                    label: post!['reblogs_count'].toString(),
                    icon: isReblogged
                        ? CupertinoIcons.repeat_1
                        : CupertinoIcons.repeat,
                    onTap: () async {
                      final messenger = ScaffoldMessenger.of(context);

                      // Optimistic update
                      try {
                        final postId = widget.postId;

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
                        ref.invalidate(
                          statusesTimelineProvider(currentUserId!),
                        );
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
                  LabelIconButton(
                    label: post!['favourites_count'].toString(),
                    icon: isFavourite
                        ? CupertinoIcons.star_slash_fill
                        : CupertinoIcons.star_slash,
                    onTap: () async {
                      final messenger = ScaffoldMessenger.of(context);

                      try {
                        final postId = widget.postId;

                        Map<String, dynamic> result;

                        if (isFavourite) {
                          // UNFAV
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
                          // FAV
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
                          return {...state, postId: result['favourited']};
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
                  LabelIconButton(
                    label: "",
                    icon: Icons.share,
                    onTap: () async {
                      // ignore: deprecated_member_use
                      await SharePlus.instance.share(
                        ShareParams(text: post!['url']),
                      );
                    },
                  ),
                ],
              ),

              const Divider(
                color: Colors.black45,
                thickness: 1.5,
                indent: 10,
                endIndent: 10,
              ),

              CommentListWidget(statusId: widget.postId, originalPost: post),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: GestureDetector(
            onTap: () {
              final mention = post != null
                  ? '@${post!['account']['acct']}'
                  : '';
              context.push("/reply/${post!['id']}?mention=$mention");
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Write a comment...',
                      style: TextStyle(color: Colors.grey[600], fontSize: 15),
                    ),
                  ),
                  Icon(Icons.send, color: Colors.grey[400], size: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
