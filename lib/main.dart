import 'dart:async';

// ignore: depend_on_referenced_packages
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whypost/api/auth_api.dart';
import 'package:whypost/api/user_api.dart';
import 'package:whypost/app_theme.dart';
import 'package:whypost/routing/routes.dart';
import 'package:whypost/sharedpreferences/credentials.dart';
import 'package:whypost/state/account.dart';
import 'package:whypost/state/explore.dart';
import 'package:whypost/state/instance.dart';
import 'package:whypost/state/notifications.dart';
import 'package:whypost/state/theme.dart';
import 'package:whypost/state/timeline.dart';
import 'package:whypost/state/trends.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'routing/router.dart';
import 'package:app_links/app_links.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  await SharedPreferences.getInstance();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  StreamSubscription? _sub;
  Timer? _resetTimer;
  static const _keyToken = "access_token";
  static const _instanceurl = "instance_url";
  static const _clientId = "client_id";
  static const _clientSecret = "client_secret";

  @override
  void initState() {
    super.initState();
    initDeepLinks();
  }

  Future<void> initDeepLinks() async {
    _sub = AppLinks().uriLinkStream.listen((uri) async {

      final code = uri.queryParameters['code'];
      if (code != null) {
        if (mounted) {
          final prefs = await SharedPreferences.getInstance();

          final instanceUrl = prefs.getString(_instanceurl);
          final clientId = prefs.getString(_clientId);
          final clientSecret = prefs.getString(_clientSecret);

          if (instanceUrl == null || clientId == null || clientSecret == null) {
            debugPrint("❌ Oauth credentials missing");
            return;
          }

          final accToken = await getAccessToken(
            instanceBaseUrl: instanceUrl,
            clientId: clientId,
            clientSecret: clientSecret,
            code: code,
          );

          if (accToken == null || accToken.trim().isEmpty) {
            debugPrint("❌ Failed to retrieve token.");
            return;
          }

          await prefs.setString(_keyToken, accToken);
          final user = await fetchCurrentUser(instanceUrl, accToken);
          await CredentialsRepository.setCurrentUserId(user!['id']);

          Future.microtask(() {
            ref.invalidate(homeTimelineProvider);
            ref.invalidate(currentUserProvider);
            ref.invalidate(favouritedTimelineProvider);
            ref.invalidate(bookmarkedTimelineProvider);
            ref.invalidate(trendingLinksProvider);
            ref.invalidate(trendingTagsProvider);
            ref.invalidate(suggestedPeopleProvider);
            ref.invalidate(publicFederatedProvider);
            ref.invalidate(publicLocalProvider);
            ref.invalidate(trendProvider);
            ref.invalidate(instanceProvider);
            ref.invalidate(notificationsProvider);
            ref.invalidate(notificationsProviderByType("mention"));
            ref.invalidate(notificationsProviderByType("favourite"));
          });

          router.go(Routes.home);
        }
      } else {
        router.go(Routes.instance);
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _resetTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    return MaterialApp.router(
      title: "WhyPost",
      routerConfig: router,
      darkTheme: AppTheme.light,
      themeMode: themeMode,
      theme: AppTheme.light,
    );
  }
}
