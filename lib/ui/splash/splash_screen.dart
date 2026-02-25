import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:whypost/api/user_api.dart';
import 'package:whypost/routing/routes.dart';
import 'package:whypost/sharedpreferences/credentials.dart';


class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  String _statusText = "Loading...";

  @override
  void initState() {
    super.initState();
    _initGuest();
  }

  bool _navigated = false;

  void _navigateOnce(String route) {
    if (_navigated) return;
    _navigated = true;
    context.go(route);
  }

  void _initGuest() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final cred = await CredentialsRepository.loadCredentials();
        final user = await fetchCurrentUser(cred.instanceUrl!, cred.accToken!);
        if (!mounted) return;

        if (user != null) {
          _navigateOnce(Routes.home);
        } else {
          _navigateOnce(Routes.instance);
        }
      } on TimeoutException {
        if (!mounted) return;
        setState(() {
          _statusText = "Server Timeout";
        });
        await Future.delayed(const Duration(seconds: 2));
        SystemNavigator.pop();
      } catch (e) {
        _navigateOnce(Routes.instance);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(255, 117, 31, 1),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset("assets/images/icon_app.png", width: 200, height: 200),

            const SizedBox(height: 20),

            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 12),
            Text(_statusText, style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}
