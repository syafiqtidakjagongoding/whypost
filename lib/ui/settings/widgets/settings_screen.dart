import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:whypost/routing/routes.dart';
import 'package:whypost/state/theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: Column(
        children: [
           // Dark Mode Setting
          // Consumer(
          //   builder: (context, ref, child) {
          //    final themeMode = ref.watch(themeProvider);
          //     final platformBrightness = MediaQuery.of(
          //       context,
          //     ).platformBrightness;

          //     final isDark =
          //         themeMode == ThemeMode.dark ||
          //         (themeMode == ThemeMode.system &&
          //             platformBrightness == Brightness.dark);


          //     return SwitchListTile(
          //       secondary: const Icon(Icons.dark_mode_outlined),
          //       title: const Text("Theme Mode"),
          //       value: isDark,
          //       onChanged: (value) {
          //         ref
          //             .read(themeProvider.notifier)
          //             .setTheme(value ? ThemeMode.dark : ThemeMode.light);
          //       },
          //     );
          //   },
          // ),
          
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text("About App"),
            onTap: () {
              context.push(Routes.aboutApp);
            },
          ),
          const Divider(height: 0),
        ],
      ),
    );
  }
}
