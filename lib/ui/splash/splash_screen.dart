import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:whypost/routing/routes.dart';
import 'package:whypost/state/account.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
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
        final user = await ref.read(currentUserProvider.future);
        if (!mounted) return;

        if (user != null) {
          _navigateOnce(Routes.home);
        }
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
          ],
        ),
      ),
    );
  }
}
