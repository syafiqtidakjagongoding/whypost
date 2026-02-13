import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:whypost/routing/routes.dart';
import 'package:whypost/sharedpreferences/credentials.dart';
import 'package:whypost/ui/posts/manipulate_post_screen.dart';
import 'package:whypost/ui/home/widgets/home_screen.dart';
import 'package:whypost/ui/notifications/widgets/notifications_screen.dart';
import 'package:whypost/ui/profile/widgets/edit_profile.dart';
import 'package:whypost/ui/profile/widgets/follow_screen.dart';
import 'package:whypost/ui/profile/widgets/profile_screen.dart';
import 'package:whypost/ui/instance/widgets/choosing_instance.dart';
import 'package:whypost/ui/instance/widgets/instance_auth_page.dart';
import 'package:whypost/ui/search/widgets/search_screen.dart';
import 'package:whypost/ui/settings/widgets/about.dart';
import 'package:whypost/ui/settings/widgets/instance_info.dart';
import 'package:whypost/ui/settings/widgets/settings_screen.dart';
import 'package:whypost/ui/splash/splash_screen.dart';
import 'package:whypost/ui/tags/tag_posts_screen.dart';
import 'package:whypost/ui/utils/full_screen_video_player.dart';
import 'package:whypost/ui/utils/full_screen_image_viewer.dart';
import 'package:whypost/ui/posts/viewpost_screen.dart';

final router = GoRouter(
  initialLocation: Routes.splash,
  routes: [
    GoRoute(path: Routes.splash, builder: (context, state) => SplashScreen()),
    GoRoute(
      path: Routes.instance,
      builder: (context, state) => const ChooseInstancePage(),
    ),

    GoRoute(
      path: Routes.instanceAuthPage,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;

        final instanceData = extra["instanceData"] as Map<String, dynamic>;
        return InstanceAuthPage(instanceData: instanceData);
      },
    ),
    GoRoute(
      path: Routes.viewVideo,
      builder: (context, state) {
        final extra = state.extra as String;

        return FullscreenVideoPlayer(url: extra.toString());
      },
    ),
    GoRoute(
      path: Routes.settings,
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: Routes.instanceInfo,
      builder: (context, state) => const InstanceInfo(),
    ),
    GoRoute(
      path: Routes.aboutApp,
      builder: (context, state) => const AboutApp(),
    ),
    GoRoute(
      path: Routes.viewImages,
      builder: (context, state) {
        final extra = state.extra as String;

        return FullScreenImageViewer(url: extra.toString());
      },
    ),
    GoRoute(
      path: Routes.viewPost,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;

        final postId = extra["postId"] as String;
        return ViewpostScreen(postId: postId);
      },
    ),
  // Create post route
    GoRoute(
      path: Routes.addPost,
      builder: (context, state) => AddPostWidget.create(),
    ),

    // Reply route with parameters
    GoRoute(
      path: '/reply/:postId',
      builder: (context, state) {
        final postId = state.pathParameters['postId']!;
        final mention = state.uri.queryParameters['mention'] ?? '';

        return AddPostWidget.reply(replyToId: postId, replyToMention: mention);
      },
    ),

    // Edit route with parameters
    GoRoute(
      path: '/edit-post/:postId',
      builder: (context, state) {
        final postId = state.pathParameters['postId']!;

        return AddPostWidget.edit(
          editPostId: postId,
        );
      },
    ),
    GoRoute(
      path: Routes.tagPosts,
      builder: (context, state) {
        final name = state.pathParameters['name']!;
        return TagpostsScreen(tag: name);
      },
    ),
    GoRoute(
      path: Routes.userProfile,
      builder: (context, state) {
        final userId = state.pathParameters['userId']!;
        return ProfileScreen(identifier: userId);
      },
    ),
    GoRoute(
      path: Routes.detailNotifications,
      builder: (context, state) {
        final userId = state.pathParameters['id']!;
        return ProfileScreen(identifier: userId);
      },
    ),
    GoRoute(
      path: Routes.followers,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;

        final type = extra["type"] as String;
        final accountId = extra["accountId"] as String;
        return FollowScreen(type: type, accountId: accountId);
      },
    ),
    GoRoute(
      path: Routes.following,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;

        final type = extra["type"] as String;
        final accountId = extra["accountId"] as String;
        return FollowScreen(type: type, accountId: accountId);
      },
    ),
    GoRoute(
      path: Routes.editProfile,
      builder: (context, state) {
        return EditProfile();
      },
    ),

    ShellRoute(
      builder: (context, state, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final navbarColor = isDark
            ? Colors.black87
            : Theme.of(context).colorScheme.primary;
        return Scaffold(
          body: child,
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _calculateIndex(state.uri.toString()),
            onTap: (index) async {
              switch (index) {
                case 0:
                  context.go(Routes.home);
                  break;
                case 1:
                  context.go(Routes.search);
                  break;
                case 2:
                  context.go(Routes.notifications);
                  break;
                case 3:
                  final userId = await CredentialsRepository.getCurrentUserId();
                  if (!context.mounted) return;
                  context.go(Routes.profile, extra: userId);
                  break;
              }
            },
            showSelectedLabels: false,
            showUnselectedLabels: false,
            selectedItemColor: const Color.fromARGB(255, 245, 237, 237),
            unselectedItemColor: Colors.white,
            backgroundColor: navbarColor,
            type: BottomNavigationBarType.fixed,
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: "Home",
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.search),
                label: "Search",
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.notifications),
                label: "Notifications",
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: "Profile",
              ),
            ],
          ),
        );
      },
      routes: [
        GoRoute(
          path: Routes.home,
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: Routes.search,
          builder: (context, state) => const SearchScreen(),
        ),
        GoRoute(
          path: Routes.notifications,
          builder: (context, state) => const NotificationsScreen(),
        ),
        GoRoute(
          path: Routes.profile,
          builder: (context, state) {
            final id = state.extra as String?;

            return ProfileScreen(identifier: id);
          },
        ),
      ],
    ),
  ],
);

int _calculateIndex(String location) {
  if (location.startsWith(Routes.home)) return 0;
  if (location.startsWith(Routes.search)) return 1;
  if (location.startsWith(Routes.notifications)) return 2;
  if (location.startsWith(Routes.profile)) return 3;
  return 0;
}
