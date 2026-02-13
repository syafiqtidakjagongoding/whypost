import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:whypost/api/statuses_api.dart';
import 'package:whypost/routing/routes.dart';
import 'package:whypost/state/action.dart';
import 'package:whypost/sharedpreferences/credentials.dart';
import 'package:whypost/state/timeline.dart';
import 'package:whypost/ui/utils/action_button.dart';
import 'package:whypost/ui/utils/content_parsing.dart';
import 'package:flutter/material.dart';
import 'package:whypost/ui/posts/post_media.dart';
import 'package:whypost/ui/utils/display_name_with_emoji.dart';
import 'package:share_plus/share_plus.dart';

class PostCard extends ConsumerStatefulWidget {
  final Map<String, dynamic> post;
  final Map<String, dynamic> account;
  final String timeAgo;
  final bool isReblog;
  final Map<String, dynamic>? rebloggedBy;

  const PostCard({
    super.key,
    required this.post,
    required this.account,
    required this.timeAgo,
    required this.isReblog,
    required this.rebloggedBy,
  });

  @override
  ConsumerState<PostCard> createState() => _PostCardState();
}

class _PostCardState extends ConsumerState<PostCard> {
  String? currentUserId;
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
            Navigator.pop(context); // tutup bottom sheet/menu dulu

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
                        Navigator.pop(ctx); // close dialog
                      },
                      child: Text(
                        "Cancel",
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx); // close dialog

                        final cred =
                            await CredentialsRepository.loadCredentials();

                        await deleteStatusesById(
                          cred.instanceUrl!,
                          cred.accToken!,
                          postId, // <-- ganti dengan id postinganmu
                        );
                        if (!context.mounted) return;
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text("Post deleted successfully"),
                            backgroundColor: Colors.green,
                          ),
                        );
                        ref.invalidate(
                          statusesTimelineProvider(currentUserId!),
                        );
                      },
                      child: Text(
                        "Delete",
                        style: Theme.of(
                          context,
                        ).textTheme.labelMedium!.copyWith(color: Colors.red),
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
          isBookmarked ? Icons.bookmark : Icons.bookmark_border,
          color: Colors.deepPurple,
        ),
        title: Text(isBookmarked ? 'UnBookmark' : 'Bookmark Post'),
        onTap: () async {
          Map<String, dynamic> result;
          final messenger = ScaffoldMessenger.of(context);

          if (isBookmarked) {
            result = await ref.read(
              unbookmarkPostActionProvider(widget.post['id']).future,
            );
            messenger.showSnackBar(
              const SnackBar(
                content: Text("Successfully unbookmarked post"),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            result = await ref.read(
              bookmarkPostActionProvider(widget.post['id']).future,
            );
            messenger.showSnackBar(
              const SnackBar(
                content: Text("Successfully bookmarked post"),
                backgroundColor: Colors.green,
              ),
            );
          }
          ref.read(bookmarkProvider.notifier).update((state) {
            return {...state, widget.post['id']: result['bookmarked']};
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
    loadCred();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializePostState();
    });
  }

  void _initializePostState() {
    if (!mounted) return;
    final post = widget.post;
    final postId = post['id'];

    // ➜ NOTE: Hanya pakai ref.read() di initState (aman)
    final favourite = ref.read(favouriteProvider);
    final bookmarks = ref.read(bookmarkProvider);
    final reblogged = ref.read(rebloggedProvider);

    if (!favourite.containsKey(postId)) {
      ref
          .read(favouriteProvider.notifier)
          .update((state) => {...state, postId: post['favourited'] ?? false});
    }

    if (!bookmarks.containsKey(postId)) {
      ref
          .read(bookmarkProvider.notifier)
          .update((state) => {...state, postId: post['bookmarked'] ?? false});
    }

    if (!reblogged.containsKey(postId)) {
      ref
          .read(rebloggedProvider.notifier)
          .update((state) => {...state, postId: post['reblogged'] ?? false});
    }
  }

  Future<void> loadCred() async {
    final userId = await CredentialsRepository.getCurrentUserId();
    if (!mounted) return;
    setState(() {
      currentUserId = userId;
    });
  }

  @override
  Widget build(BuildContext context) {
    final postId = widget.post['id'];
    final media = widget.post['media_attachments'] as List<dynamic>? ?? [];
    final bookmarks = ref.watch(bookmarkProvider);
    final favourite = ref.watch(favouriteProvider);
    final reblogged = ref.watch(rebloggedProvider);
    final isBookmarked = bookmarks[postId] ?? false;
    final isFavourite = favourite[postId] ?? false;
    final isReblogged = reblogged[postId] ?? false;
    final inReplyToId = widget.post['in_reply_to_id'];
    final inReplyToAccountId = widget.post['in_reply_to_account_id'];

    String? replyToUsername;
    if (widget.post['mentions'] != null) {
      for (final m in widget.post['mentions']) {
        if (m['id'] == inReplyToAccountId) {
          replyToUsername = m['acct'];
          break;
        }
      }
    }

    return Container(
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.isReblog && widget.rebloggedBy != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 0, 4),
                child: InkWell(
                  onTap: () {
                    context.push(
                      Routes.profile,
                      extra: widget.rebloggedBy!['id'],
                    );
                  },
                  child: Row(
                    children: [
                      Icon(
                        CupertinoIcons.repeat,
                        size: 18,
                        color: Color.fromRGBO(255, 117, 31, 1),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          "Repeated by @${widget.rebloggedBy!['acct']}",
                          style: TextStyle(fontSize: 15),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            if (inReplyToId != null)
              InkWell(
                onTap: () {
                  context.push(Routes.viewPost, extra: {"postId": inReplyToId});
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      const Icon(Icons.reply, color: Colors.orange, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          replyToUsername != null
                              ? "Reply to @$replyToUsername"
                              : "Self-reply",
                          style: TextStyle(fontSize: 15),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            InkWell(
              onTap: () {
                context.push('/user/${widget.account['id']}');
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
                            widget.account['avatar_static'],
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
                          displayNameWithEmoji(widget.account, context),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  "@${widget.account['acct']}",
                                  style: TextStyle(fontSize: 13),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (widget.timeAgo != "") ...[
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
                                  widget.timeAgo,
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
                                widget.account['id'].toString() ==
                                    currentUserId.toString(),
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

            InkWell(
              onTap: () {
                context.push(Routes.viewPost, extra: {"postId": postId});
              },
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Contentparsing(
                      content: widget.post['content'],
                      emojis: widget.post['emojis'],
                      mentions: widget.post['mentions'],
                    ),
                  ),

                  if (media.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: PostMedia(
                        media: media,
                        sensitive: widget.post['sensitive'] ?? false,
                      ),
                    ),
                ],
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
                        '/reply/$postId?mention=@${widget.account['acct']}',
                      );
                    },
                  ),
                  ActionButton(
                    icon: widget.post['reblogged']
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
                  ActionButton(
                    icon: isFavourite
                        ? CupertinoIcons.star_slash_fill
                        : CupertinoIcons.star_slash,
                    onTap: () async {
                      final messenger = ScaffoldMessenger.of(context);

                      try {
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

                        // Update favouriteProvider dari hasil API
                        ref.read(favouriteProvider.notifier).update((state) {
                          return {
                            ...state,
                            postId:
                                result['favourited'], // <- TRUE / FALSE dari server
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
                        ShareParams(text: widget.post['url']),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
