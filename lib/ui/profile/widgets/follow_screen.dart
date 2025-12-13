import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:whypost/state/account.dart';
import 'package:whypost/ui/utils/PeopleListTile.dart';

class FollowScreen extends ConsumerStatefulWidget {
  final String type; // followers / following
  final String accountId;

  const FollowScreen({super.key, required this.type, required this.accountId});

  @override
  ConsumerState<FollowScreen> createState() => _FollowScreenState();
}

class _FollowScreenState extends ConsumerState<FollowScreen> {

  bool loading = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

   @override
  Widget build(BuildContext context) {
    final asyncItems = widget.type == "followers"
        ? ref.watch(accountFollowersProvider(widget.accountId))
        : ref.watch(accountFollowingProvider(widget.accountId));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.type == "followers" ? "Followers" : "Following"),
        centerTitle: true,
      ),
      body: asyncItems.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(child: Text("Error when fetching your relationship")),
        data: (items) {
          return ListView.builder(
            itemCount: items.length + 1,
            itemBuilder: (_, i) {
              if (i == items.length) {
                if (loading) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                return const SizedBox.shrink();
              }
              return PeopleListTile(account: items[i]);
            },
          );
        },
      ),
    );
  }
}
