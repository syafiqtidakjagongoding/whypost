// People List Tile
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:whypost/sharedpreferences/credentials.dart';
import 'package:whypost/state/account.dart';
import 'package:whypost/state/action.dart';

class PeopleListTile extends ConsumerStatefulWidget {
  final Map<String, dynamic> account;

  const PeopleListTile({super.key, required this.account});
  @override
  ConsumerState<PeopleListTile> createState() => _PeopleListTileState();
}

class _PeopleListTileState extends ConsumerState<PeopleListTile> {
  Map<String, dynamic>? account;
  String? currentUserId;

  @override
  void initState() {
    super.initState();
    account = widget.account;
    load();
  }

  Future<void> load() async {
    final result = await CredentialsRepository.getCurrentUserId();

    setState(() {
      currentUserId = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    final avatar = account!["avatar_static"] ?? "";
    final displayName = account!["display_name"] ?? "Unknown";
    final username = account!["acct"] ?? "";
    final followers = account!["followers_count"] ?? 0;
    final id = account!['id'];
    final follow = ref.watch(followProvider);
    final requested = ref.watch(requestedFollowProvider);
    final relationshipAsync = ref.watch(relationshipProvider(id));

    return relationshipAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (rel) {
        final isRequested = requested[id] ?? false;
        final isFollowed = follow[id] ?? false;
        final requestedValue = rel?['requested'];
        final followingValue = rel?['following'];

        if (!follow.containsKey(id) && followingValue != null) {
          Future.microtask(() {
            ref
                .read(followProvider.notifier)
                .update((state) => {...state, id: followingValue});
          });
        }

        if (!requested.containsKey(id) && requestedValue != null) {
          Future.microtask(() {
            ref
                .read(requestedFollowProvider.notifier)
                .update((state) => {...state, id: requestedValue});
          });
        }

        return Material(
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              ref.invalidate(selectedUserProvider(id));
              context.push('/user/$id');
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundImage: avatar.isNotEmpty
                        ? NetworkImage(avatar)
                        : null,
                    child: avatar.isEmpty ? const Icon(Icons.person) : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                displayName,
                                style: const TextStyle(fontSize: 17),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                "@$username",
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "$followers followers",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (account!['id'] != currentUserId)
                    SizedBox(
                      height: 32,
                      child: OutlinedButton(
                        onPressed: () async {
                          try {
                            if (isFollowed == true) {
                              final res = await ref.read(
                                unfollowUserProvider(id).future,
                              );
                              ref.read(followProvider.notifier).update((state) {
                                return {...state, id: res!['following']};
                              });
                            } else {
                              final res = await ref.read(
                                followUserProvider(id).future,
                              );
                              if (res!['requested']) {
                                ref
                                    .read(requestedFollowProvider.notifier)
                                    .update((state) {
                                      return {...state, id: res['requested']};
                                    });
                              } else {
                                ref.read(followProvider.notifier).update((
                                  state,
                                ) {
                                  return {...state, id: res['following']};
                                });
                              }
                            }
                            ref.invalidate(relationshipProvider(id));
                          } catch (e) {
                            final messenger = ScaffoldMessenger.of(context);
                              messenger.showSnackBar(
                              const SnackBar(
                                content: Text("Something went wrong."),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          backgroundColor: isFollowed == true
                              ? Colors.white
                              : Colors.black,
                          foregroundColor: isFollowed == true
                              ? Colors.black
                              : Colors.white,
                          side: BorderSide(
                            color: isFollowed == true
                                ? Colors.grey[400]!
                                : Colors.black,
                            width: 1,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          isFollowed == true
                              ? "Following"
                              : isRequested == true
                              ? "Requested"
                              : "Follow",
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
