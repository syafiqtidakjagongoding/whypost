import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whypost/state/timeline.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:whypost/ui/posts/post_card.dart';

class TagpostsScreen extends ConsumerStatefulWidget {
  final String tag;
  const TagpostsScreen({super.key, required this.tag});

  @override
  ConsumerState<TagpostsScreen> createState() => _TagpostsScreenState();
}

class _TagpostsScreenState extends ConsumerState<TagpostsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(() {
      final notifier = ref.read(tagTimelineProvider(widget.tag).notifier);

      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        notifier.loadMore(); // INFINITE SCROLL TRIGGER
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final timeline = ref.watch(tagTimelineProvider(widget.tag));
    return Scaffold(
      appBar: AppBar(
        title: Text('#${widget.tag}'),
        centerTitle: true,
        backgroundColor: Color.fromRGBO(255, 117, 31, 1),
        titleTextStyle: const TextStyle(
          fontSize: 23,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(tagTimelineProvider(widget.tag));
        },
        child: Builder(
          builder: (_) {
            final state = timeline;

            if (state.isLoading && state.posts.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.posts.isEmpty) {
              return const Center(child: Text('No posts available'));
            }

            return ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: state.posts.length + 1, 
              itemBuilder: (context, i) {
                if (i == state.posts.length) {
                  return state.hasMore
                      ? const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : const SizedBox.shrink();
                }

                final post = state.posts[i];

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
    );
  }
}
