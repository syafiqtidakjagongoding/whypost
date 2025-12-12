import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:whypost/routing/routes.dart';
import 'package:whypost/state/notifications.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationCard extends StatelessWidget {
  final Map<String, dynamic> notification;

  const NotificationCard({super.key, required this.notification});

  @override
  Widget build(BuildContext context) {
    final account = notification['account'];
    return InkWell(
      onTap: () {
        context.push(
          Routes.viewPost,
          extra: {"postId": notification['status']['id']},
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade300, width: 0.5),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildNotificationIcon(),
            const SizedBox(width: 12),

            // Avatar
            GestureDetector(
              onTap: () {
                context.push("/user/${account['id']}");
              },
              child: CircleAvatar(
                radius: 20,
                backgroundImage: NetworkImage(account['avatar']),
              ),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // =============================
                  // HEADER — TAP → PROFILE
                  // =============================
                  InkWell(
                    onTap: () {
                      context.push("/user/${account['id']}");
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildNotificationHeader(context),
                        const SizedBox(height: 4),

                        Text(
                          timeago.format(
                            DateTime.parse(notification['created_at']),
                          ),
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ),

                  // =============================
                  // STATUS PREVIEW — TAP → VIEW POST
                  // =============================
                  if (notification['status'] != null) ...[
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () {
                        context.push(
                          Routes.viewPost,
                          extra: {"postId": notification['status']['id']},
                        );
                      },
                      child: _buildStatusPreview(context),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationIcon() {
    IconData icon;
    Color color;

    switch (notification['type']) {
      case 'favourite':
        icon = Icons.star;
        color = Colors.amber;
        break;
      case 'reblog':
        icon = Icons.repeat;
        color = Colors.green;
        break;
      case 'mention':
        icon = Icons.alternate_email;
        color = Colors.blue;
        break;
      case 'follow':
        icon = Icons.person_add;
        color = Colors.purple;
        break;
      case 'poll':
        icon = Icons.poll;
        color = Colors.teal;
        break;
      case 'status':
        icon = Icons.edit;
        color = Colors.orange;
        break;
      default:
        icon = Icons.notifications;
        color = Colors.grey;
    }

    return Icon(icon, color: color, size: 20);
  }

  Widget _buildNotificationHeader(BuildContext context) {
    String action;

    switch (notification['type']) {
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
        action = 'posted a new status';
        break;
      default:
        action = 'interacted with you';
    }

    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 14, color: Colors.black),
        children: [
          TextSpan(
            text: notification['account']['display_name'],
            style: Theme.of(context).textTheme.labelMedium,
          ),
          TextSpan(
            text: ' $action',
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPreview(BuildContext context) {
    final status = notification['status'];
    if (status == null) return const SizedBox.shrink();
    final media = status['media_attachments'] as List<dynamic>? ?? [];
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _stripHtml(status['content']),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
            ),
          ),

          if (media.isNotEmpty) ...[
            const SizedBox(width: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.network(
                media[0]['preview_url'] ?? media[0]['url'],
                width: 40,
                height: 40,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 40,
                    height: 40,
                    color: Colors.grey.shade300,
                    child: Icon(Icons.image, color: Colors.grey.shade600),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _stripHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .trim();
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
