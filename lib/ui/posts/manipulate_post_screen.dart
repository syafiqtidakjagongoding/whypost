import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:whypost/api/custom_emoji.dart';
import 'package:whypost/api/statuses_api.dart';
import 'package:whypost/routing/router.dart';
import 'package:whypost/routing/routes.dart';
import 'dart:io';
import 'package:whypost/sharedpreferences/credentials.dart';
import 'package:whypost/state/timeline.dart';

class AddPostWidget extends ConsumerStatefulWidget {
  final Map<String, dynamic>? replyContext;

  const AddPostWidget({
    Key? key,
    this.replyContext,
    required replyTo,
    required mention,
    required isReply,
  }) : super(key: key);

  @override
  ConsumerState<AddPostWidget> createState() => _AddPostWidgetState();
}

class _AddPostWidgetState extends ConsumerState<AddPostWidget> {
  final TextEditingController _contentController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final List<XFile> _images = [];
  List<CustomEmoji>? customEmojiList;

  // Visibility options
  String _visibility = 'public';
  final List<Map<String, dynamic>> _visibilityOptions = [
    {'value': 'public', 'icon': Icons.public, 'label': 'Public'},
    {'value': 'unlisted', 'icon': Icons.lock_open, 'label': 'Unlisted'},
    {'value': 'private', 'icon': Icons.lock, 'label': 'Followers only'},
    {'value': 'direct', 'icon': Icons.mail, 'label': 'Direct'},
  ];

  @override
  void initState() {
    super.initState();
    // If replying, pre-fill with mention
    if (widget.replyContext != null &&
        widget.replyContext!['mention'] != null) {
      _contentController.text = '${widget.replyContext!['mention']} ';
    }
    load();
  }

  Future<void> load() async {
    final cred = await CredentialsRepository.loadCredentials();
    if (cred.instanceUrl == null || cred.accToken == null) {
      router.go(Routes.instance);
    }
    final emojis = await fetchCustomEmojis(cred.instanceUrl!, cred.accToken!);
    setState(() {
      customEmojiList = emojis;
    });
  }

  Future<void> _pickImages() async {
    final picked = await _picker.pickMultiImage(imageQuality: 80);
    if (picked.isNotEmpty) {
      setState(() {
        _images.addAll(picked);
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

  void _showVisibilityMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Post visibility',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              ..._visibilityOptions.map((option) {
                final isSelected = _visibility == option['value'];
                return ListTile(
                  leading: Icon(
                    option['icon'],
                    color: isSelected
                        ? Colors.blue
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                  title: Text(
                    option['label'],
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: isSelected
                          ? Colors.blue
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check, color: Colors.blue)
                      : null,
                  onTap: () {
                    setState(() {
                      _visibility = option['value'];
                    });
                    context.pop();
                  },
                );
              }),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showEmojiPicker() async {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Pick an custom emoji',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                SizedBox(
                  width: 300,
                  height: 300,
                  child: GridView.count(
                    crossAxisCount: 5,
                    childAspectRatio: 1,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    children: customEmojiList == null
                        ? []
                        : customEmojiList!.map((emoji) {
                            return InkWell(
                              onTap: () {
                                _contentController.text +=
                                    ":${emoji.shortcode}:";
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Image.network(
                                  emoji.url,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            );
                          }).toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _submitPost(WidgetRef ref) async {
    final content = _contentController.text.trim();

    if (content.isEmpty && _images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Write something or add an image')),
      );
      return;
    }

    final List<File> files = _images.map((x) => File(x.path)).toList();
    final isReply = widget.replyContext?['isReply'] == true;
    final replyToId = widget.replyContext?['replyTo'];

    try {
      final credential = await CredentialsRepository.loadAllCredentials();
      await createFediversePost(
        content: content,
        visibility: _visibility,
        instanceUrl: credential.instanceUrl!,
        accessToken: credential.accToken!,
        images: files,
        inReplyToId: isReply ? replyToId : null,
      );

      setState(() {
        _contentController.clear();
        _images.clear();
        _visibility = 'public';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isReply ? 'Reply posted!' : 'Post created successfully!',
          ),
        ),
      );
      ref.invalidate(statusesTimelineProvider(credential.currentUserId!));
      router.pop();
    } catch (e) {
      ScaffoldMessenger.of(
        // ignore: use_build_context_synchronously
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to create post: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (customEmojiList == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final currentVisibility = _visibilityOptions.firstWhere(
      (opt) => opt['value'] == _visibility,
    );

    final isReply = widget.replyContext?['isReply'] == true;
    final pageTitle = isReply ? 'Reply' : 'Create Post';

    return Scaffold(
      appBar: AppBar(
        title: Text(pageTitle),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: ElevatedButton(
              onPressed: () => _submitPost(ref),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 2,
              ),
              child: Text(
                isReply ? 'Reply' : 'Post',
                style: Theme.of(context).textTheme.labelMedium!.copyWith(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.black
                      : Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _contentController,
                    maxLines: null,
                    autofocus: true,

                    style: const TextStyle(fontSize: 16),
                    decoration: InputDecoration(
                      fillColor: Theme.of(context).colorScheme.surface,
                      hintText: "What's on your mind?",
                      border: InputBorder.none,
                    ),
                    onChanged: (v) {
                      setState(() {});
                    },
                  ),

                  const SizedBox(height: 16),

                  // Image preview
                  if (_images.isNotEmpty)
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: _images.length == 1 ? 1 : 2,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 1,
                      ),
                      itemCount: _images.length,
                      itemBuilder: (context, index) {
                        final file = File(_images[index].path);
                        return Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                file,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: () => _removeImage(index),
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.black87,
                                    shape: BoxShape.circle,
                                  ),
                                  padding: const EdgeInsets.all(6),
                                  child: const Icon(
                                    Icons.close,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                ],
              ),
            ),
          ),

          // Bottom toolbar
          Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey[200]!)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                // Image button
                IconButton(
                  onPressed: _pickImages,
                  icon: Icon(Icons.image_outlined),
                  color: Theme.of(context).colorScheme.onSurface,
                  tooltip: 'Add image',
                ),

                // Emoji button
                IconButton(
                  onPressed: () {
                    _showEmojiPicker();
                  },
                  icon: Icon(Icons.emoji_emotions_outlined),
                  color: Theme.of(context).colorScheme.onSurface,
                  tooltip: 'Add emoji',
                ),

                // Poll button (optional)
                // IconButton(
                //   onPressed: () {
                //     ScaffoldMessenger.of(context).showSnackBar(
                //       const SnackBar(content: Text('Poll feature coming soon')),
                //     );
                //   },
                //   icon: const Icon(Icons.poll_outlined),
                //   color: Colors.grey[600],
                //   tooltip: 'Create poll',
                // ),
                const Spacer(),

                // Visibility selector
                TextButton.icon(
                  onPressed: _showVisibilityMenu,
                  icon: Icon(
                    currentVisibility['icon'],
                    size: 18,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  label: Text(
                    currentVisibility['label'],
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 13,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
