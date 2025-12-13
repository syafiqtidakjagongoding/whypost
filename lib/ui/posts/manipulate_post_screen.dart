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

enum PostMode { create, reply, edit }

class AddPostWidget extends ConsumerStatefulWidget {
  final PostMode mode;
  final String? replyToId;
  final String? replyToMention;
  final String? editPostId;

  const AddPostWidget({
    super.key,
    this.mode = PostMode.create,
    this.replyToId,
    this.replyToMention,
    this.editPostId,
  });

  const AddPostWidget.create({super.key})
    : mode = PostMode.create,
      replyToId = null,
      replyToMention = null,
      editPostId = null;

  const AddPostWidget.reply({
    super.key,
    required this.replyToId,
    required this.replyToMention,
  }) : mode = PostMode.reply,
       editPostId = null;

  const AddPostWidget.edit({super.key, required this.editPostId})
    : mode = PostMode.edit,
      replyToId = null,
      replyToMention = null;

  @override
  ConsumerState<AddPostWidget> createState() => _AddPostWidgetState();
}

class _AddPostWidgetState extends ConsumerState<AddPostWidget> {
  final TextEditingController _contentController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final List<XFile> _images = [];

  List<CustomEmoji>? _customEmojiList;
  Map<String, dynamic>? _originalPost;
  List<Map<String, dynamic>> _existingMedia = [];
  bool _isLoading = true;
  String _visibility = 'public';

  static const List<Map<String, dynamic>> _visibilityOptions = [
    {'value': 'public', 'icon': Icons.public, 'label': 'Public'},
    {'value': 'unlisted', 'icon': Icons.lock_open, 'label': 'Unlisted'},
    {'value': 'private', 'icon': Icons.lock, 'label': 'Followers only'},
    {'value': 'direct', 'icon': Icons.mail, 'label': 'Direct'},
  ];

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    try {
      final cred = await CredentialsRepository.loadCredentials();

      if (cred.instanceUrl == null || cred.accToken == null) {
        router.go(Routes.instance);
        return;
      }

      // Load emojis and post data in parallel
      final results = await Future.wait([
        fetchCustomEmojis(cred.instanceUrl!, cred.accToken!),
        if (widget.mode == PostMode.edit && widget.editPostId != null)
          fetchStatusDetail(
            cred.instanceUrl!,
            cred.accToken!,
            widget.editPostId!,
          )
        else
          Future.value(null),
      ]);

      final emojis = results[0] as List<CustomEmoji>;
      final post = results.length > 1
          ? results[1] as Map<String, dynamic>?
          : null;

      if (!mounted) return;

      setState(() {
        _customEmojiList = emojis;
        _originalPost = post;
        _isLoading = false;
      });

      _initializeContent();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _showError('Failed to initialize: $e');

      if (widget.mode == PostMode.edit) {
        Navigator.of(context).pop();
      }
    }
  }

  void _initializeContent() {
    switch (widget.mode) {
      case PostMode.reply:
        if (widget.replyToMention != null) {
          _contentController.text = '${widget.replyToMention} ';
        }
        break;

      case PostMode.edit:
        if (_originalPost != null) {
          // Try to get plain text first (Mastodon 3.0+)
          final plainText = _originalPost!['text'] as String?;
          final htmlContent = _originalPost!['content'] as String?;

          _contentController.text =
              plainText ?? _parseHtmlContent(htmlContent ?? '');
          _visibility = _originalPost!['visibility'] ?? 'public';

          // Load existing media attachments
          final mediaAttachments = _originalPost!['media_attachments'];
          if (mediaAttachments != null && mediaAttachments is List) {
            _existingMedia = List<Map<String, dynamic>>.from(
              mediaAttachments.map((m) => Map<String, dynamic>.from(m)),
            );
          }
        }
        break;

      case PostMode.create:
        // Default empty state
        break;
    }
  }

  String _parseHtmlContent(String html) {
    if (html.isEmpty) return '';

    String text = html;

    // Extract hashtags
    text = text.replaceAllMapped(
      RegExp(
        r'<a[^>]*class="[^"]*hashtag[^"]*"[^>]*>([^<]+)</a>',
        caseSensitive: false,
      ),
      (match) {
        final tagText = match.group(1) ?? '';
        final cleanTag = tagText.replaceAll(RegExp(r'<[^>]*>'), '');
        return cleanTag.startsWith('#') ? cleanTag : '#$cleanTag';
      },
    );

    // Extract mentions
    text = text.replaceAllMapped(
      RegExp(
        r'<a[^>]*class="[^"]*mention[^"]*"[^>]*>([^<]+)</a>',
        caseSensitive: false,
      ),
      (match) => match.group(1) ?? '',
    );

    // Handle line breaks
    text = text.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
    text = text.replaceAll(RegExp(r'</p>', caseSensitive: false), '\n\n');

    // Remove remaining HTML tags
    text = text.replaceAll(RegExp(r'<[^>]*>'), '');

    // Decode HTML entities
    text = text
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&nbsp;', ' ');

    // Clean up whitespace
    return text.replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
  }

  Future<void> _pickImages() async {
    try {
      final picked = await _picker.pickMultiImage(imageQuality: 80);
      if (picked.isNotEmpty && mounted) {
        setState(() {
          _images.addAll(picked);
        });
      }
    } catch (e) {
      _showError('Failed to pick images: $e');
    }
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

  void _removeExistingMedia(int index) {
    setState(() {
      _existingMedia.removeAt(index);
    });
  }

  void _showVisibilityMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _buildVisibilityMenu(),
    );
  }

  Widget _buildVisibilityMenu() {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
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
                color: isSelected ? Colors.blue : null,
              ),
              title: Text(
                option['label'],
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? Colors.blue : null,
                ),
              ),
              trailing: isSelected
                  ? const Icon(Icons.check, color: Colors.blue)
                  : null,
              onTap: () {
                setState(() {
                  _visibility = option['value'] as String;
                });
                context.pop();
              },
            );
          }),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showEmojiPicker() {
    if (_customEmojiList == null) return;

    showDialog(context: context, builder: (context) => _buildEmojiPicker());
  }

  Widget _buildEmojiPicker() {
    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(16),
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Pick a custom emoji',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  childAspectRatio: 1,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _customEmojiList!.length,
                itemBuilder: (context, index) {
                  final emoji = _customEmojiList![index];
                  return InkWell(
                    onTap: () {
                      _contentController.text += ' :${emoji.shortcode}:';
                      Navigator.pop(context);
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
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.broken_image),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitPost() async {
    final content = _contentController.text.trim();

    if (content.isEmpty && _images.isEmpty && _existingMedia.isEmpty) {
      _showError('Write something or add an image');
      return;
    }

    final files = _images.map((x) => File(x.path)).toList();

    try {
      final credential = await CredentialsRepository.loadAllCredentials();

      switch (widget.mode) {
        case PostMode.create:
          await createFediversePost(
            content: content,
            visibility: _visibility,
            instanceUrl: credential.instanceUrl!,
            accessToken: credential.accToken!,
            images: files,
          );
          break;

        case PostMode.reply:
          await createFediversePost(
            content: content,
            visibility: _visibility,
            instanceUrl: credential.instanceUrl!,
            accessToken: credential.accToken!,
            images: files,
            inReplyToId: widget.replyToId,
          );
          break;

        case PostMode.edit:
          // Get IDs of existing media to keep
          final existingMediaIds = _existingMedia
              .map((m) => m['id'] as String)
              .toList();

          await editFediversePost(
            postId: widget.editPostId!,
            content: content,
            visibility: _visibility,
            instanceUrl: credential.instanceUrl!,
            accessToken: credential.accToken!,
            images: files,
            existingMediaIds: existingMediaIds,
          );
          break;
      }

      if (!mounted) return;

      // Invalidate timeline to refresh
      ref.invalidate(statusesTimelineProvider(credential.currentUserId!));

      _showSuccess(_getSuccessMessage());
      router.pop();
    } catch (e) {
      if (!mounted) return;
      _showError('Failed to submit post');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _getSuccessMessage() {
    return switch (widget.mode) {
      PostMode.create => 'Post created successfully!',
      PostMode.reply => 'Reply posted!',
      PostMode.edit => 'Post updated successfully!',
    };
  }

  String _getPageTitle() {
    return switch (widget.mode) {
      PostMode.create => 'Create Post',
      PostMode.reply => 'Reply',
      PostMode.edit => 'Edit Post',
    };
  }

  String _getButtonLabel() {
    return switch (widget.mode) {
      PostMode.create => 'Post',
      PostMode.reply => 'Reply',
      PostMode.edit => 'Save',
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(_getPageTitle())),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final currentVisibility = _visibilityOptions.firstWhere(
      (opt) => opt['value'] == _visibility,
    );

    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTextField(),
                  const SizedBox(height: 16),
                  if (_shouldShowExistingMedia()) _buildExistingMedia(),
                  if (_images.isNotEmpty) _buildNewImages(),
                ],
              ),
            ),
          ),
          _buildBottomToolbar(currentVisibility),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(_getPageTitle()),
      actions: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: ElevatedButton(
            onPressed: _submitPost,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 2,
            ),
            child: Text(
              _getButtonLabel(),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.black
                    : Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField() {
    return TextField(
      controller: _contentController,
      maxLines: null,
      autofocus: true,
      style: const TextStyle(fontSize: 16),
      decoration: InputDecoration(
        fillColor: Theme.of(context).colorScheme.surface,
        hintText: "What's on your mind?",
        border: InputBorder.none,
      ),
      onChanged: (_) => setState(() {}),
    );
  }

  bool _shouldShowExistingMedia() {
    return widget.mode == PostMode.edit && _existingMedia.isNotEmpty;
  }

  Widget _buildExistingMedia() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Existing media (${_existingMedia.length}):',
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(_existingMedia.length, (index) {
            final media = _existingMedia[index];
            final url = media['preview_url'] ?? media['url'] ?? '';

            return Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    url,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey[300],
                      child: const Icon(Icons.broken_image),
                    ),
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () => _removeExistingMedia(index),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(4),
                      child: const Icon(
                        Icons.close,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildNewImages() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.mode == PostMode.edit)
          Text(
            'New media to add:',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        const SizedBox(height: 8),
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
          itemBuilder: (context, index) => _buildImagePreview(index),
        ),
      ],
    );
  }

  Widget _buildImagePreview(int index) {
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
              child: const Icon(Icons.close, size: 18, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomToolbar(Map<String, dynamic> currentVisibility) {
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: _pickImages,
            icon: const Icon(Icons.image_outlined),
            tooltip: 'Add image',
          ),
          IconButton(
            onPressed: _showEmojiPicker,
            icon: const Icon(Icons.emoji_emotions_outlined),
            tooltip: 'Add emoji',
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: _showVisibilityMenu,
            icon: Icon(currentVisibility['icon'], size: 18),
            label: Text(
              currentVisibility['label'],
              style: const TextStyle(fontSize: 13),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }
}
