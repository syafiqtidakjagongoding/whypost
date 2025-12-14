import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:whypost/routing/routes.dart';
import 'package:whypost/sharedpreferences/credentials.dart';
import 'package:whypost/state/action.dart';
import 'package:whypost/state/comment.dart';
import 'package:whypost/state/timeline.dart';
import 'package:whypost/ui/utils/ActionButton.dart';
import 'package:whypost/ui/utils/ContentParsing.dart';
import 'package:whypost/ui/utils/displayNameWithEmoji.dart';
import 'package:timeago/timeago.dart' as timeago;

class CommentListWidget extends ConsumerStatefulWidget {
  final String statusId;
  final Map<String, dynamic>? originalPost;

  const CommentListWidget({
    super.key,
    required this.statusId,
    this.originalPost,
  });

  @override
  ConsumerState<CommentListWidget> createState() => _CommentListWidgetState();
}

class _CommentListWidgetState extends ConsumerState<CommentListWidget> {
  String? currentUserId;
  bool loading = true;
  String? statusId;
  Map<String, dynamic>? originalPost;

  @override
  void initState() {
    super.initState();
    loadCred();
    statusId = widget.statusId;
    originalPost = widget.originalPost;
  }

  Future<void> loadCred() async {
    final result = await CredentialsRepository.getCurrentUserId();
    setState(() {
      currentUserId = result;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final commentAsync = ref.watch(commentProvider(statusId!));

    return Column(
      children: [
        commentAsync.when(
          data: (comments) {
            if (comments == null || comments.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "No comments yet",
                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Be the first to comment!",
                      style: TextStyle(color: Colors.grey[500], fontSize: 14),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: comments.length,
              itemBuilder: (context, index) {
                final c = comments[index];
                final commentId = c['id'];
                final content = c['content'] ?? '';
                final account = c['account'] ?? {};
                final mentions = c['mentions'];
                final emojis = c['emojis'];
                final avatar = account['avatar'] ?? '';
                final createdAt = c['created_at'];
                final timeAgo = createdAt != null
                    ? timeago.format(DateTime.parse(createdAt))
                    : '';
                final mention = originalPost != null
                    ? '@${originalPost!['account']['acct']}'
                    : '';
                final favourite = ref.watch(favouriteProvider);
                final reblogged = ref.watch(rebloggedProvider);
                final isFavourite = favourite[commentId] ?? false;
                final isReblogged = reblogged[commentId] ?? false;

                if (!favourite.containsKey(commentId)) {
                  Future.microtask(() {
                    ref
                        .read(favouriteProvider.notifier)
                        .update(
                          (state) => {
                            ...state,
                            commentId: c['favourited'] ?? false,
                          },
                        );
                  });
                }

                if (!reblogged.containsKey(commentId)) {
                  Future.microtask(() {
                    ref
                        .read(rebloggedProvider.notifier)
                        .update(
                          (state) => {
                            ...state,
                            commentId: c!['reblogged'] ?? false,
                          },
                        );
                  });
                }
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () {
                          context.push('/user/${account!['id']}');
                        },
                        child: CircleAvatar(
                          backgroundImage: NetworkImage(avatar),
                          radius: 18,
                        ),
                      ),
                      const SizedBox(width: 12),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: () {
                                context.push('/user/${account!['id']}');
                              },
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  displayNameWithEmoji(account, context),
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
                                      if (timeAgo != "") ...[
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                          ),
                                          child: Text(
                                            "•",
                                            style: TextStyle(
                                              color: Colors.grey[400],
                                            ),
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
                            const SizedBox(height: 10),

                            Contentparsing(
                              content: content,
                              emojis: emojis,
                              mentions: mentions,
                            ),
                            const SizedBox(height: 8),

                            Row(
                              children: [
                                LabelIconButton(
                                  label: c['replies_count'].toString(),
                                  icon: CupertinoIcons.reply,
                                  onTap: () {
                                    context.push(
                                      "/reply/${c['id']}?mention=$mention ${account['acct']}",
                                    );
                                  },
                                ),
                                const SizedBox(width: 16),

                                LabelIconButton(
                                  icon: isFavourite
                                      ? CupertinoIcons.star_slash_fill
                                      : CupertinoIcons.star_slash,
                                  label:
                                      c['favourites_count']?.toString() ?? '0',
                                  onTap: () async {
                                    final messenger = ScaffoldMessenger.of(
                                      context,
                                    );

                                    try {
                                      final postId = c['id'];

                                      Map<String, dynamic> result;

                                      if (isFavourite) {
                                        // UNFAV
                                        result = await ref.read(
                                          unfavoritePostActionProvider(
                                            postId,
                                          ).future,
                                        );
                                        messenger.showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              "Successfully unfavourite post",
                                            ),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      } else {
                                        // FAV
                                        result = await ref.read(
                                          favoritePostActionProvider(
                                            postId,
                                          ).future,
                                        );
                                        messenger.showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              "Successfully favourite post",
                                            ),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      }

                                      ref
                                          .read(favouriteProvider.notifier)
                                          .update((state) {
                                            return {
                                              ...state,
                                              postId: result['favourited'],
                                            };
                                          });
                                      ref.invalidate(
                                        favouritedTimelineProvider,
                                      );
                                    } catch (e) {
                                      messenger.showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            "Something went wrong.",
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  },
                                ),
                                const SizedBox(width: 16),

                                LabelIconButton(
                                  icon: isReblogged
                                      ? CupertinoIcons.repeat_1
                                      : CupertinoIcons.repeat,
                                  label: c['reblogs_count']?.toString() ?? '0',
                                  onTap: () async {
                                    final messenger = ScaffoldMessenger.of(
                                      context,
                                    );

                                    // Optimistic update
                                    try {
                                      final postId = c['id'];

                                      Map<String, dynamic> result;

                                      if (isReblogged) {
                                        result = await ref.read(
                                          unreblogPostActionProvider(
                                            postId,
                                          ).future,
                                        );
                                        messenger.showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              "Successfully unreblog post",
                                            ),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      } else {
                                        result = await ref.read(
                                          reblogPostActionProvider(
                                            postId,
                                          ).future,
                                        );
                                        messenger.showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              "Successfully reblog post",
                                            ),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      }

                                      ref
                                          .read(rebloggedProvider.notifier)
                                          .update((state) {
                                            return {
                                              ...state,
                                              postId: result['reblogged'],
                                            };
                                          });
                                      ref.invalidate(
                                        statusesTimelineProvider(
                                          currentUserId!,
                                        ),
                                      );
                                    } catch (e) {
                                      messenger.showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            "Something went wrong.",
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  },
                                ),
                                const SizedBox(width: 16),

                                LabelIconButton(
                                  label: "",
                                  icon: Icons.share,
                                  onTap: () async {
                                    // ignore: deprecated_member_use
                                    await SharePlus.instance.share(
                                      ShareParams(text: c['url']),
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
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (err, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                  const SizedBox(height: 12),
                  Text(
                    "Failed to load comments",
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    err.toString(),
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),

      
      ],
    );
  }
}

class LabelIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const LabelIconButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.grey[600]),
            if (label.isNotEmpty) ...[
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
