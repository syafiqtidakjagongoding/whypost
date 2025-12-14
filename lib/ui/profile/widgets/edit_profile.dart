import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:whypost/api/accounts_api.dart';
import 'package:whypost/service/htmlToText.dart';
import 'package:whypost/sharedpreferences/credentials.dart';
import 'package:whypost/state/account.dart';

class EditProfile extends ConsumerStatefulWidget {
  const EditProfile({super.key});

  @override
  ConsumerState<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends ConsumerState<EditProfile> {
  late TextEditingController _nameController = TextEditingController();
  late TextEditingController _bioController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  String? newHeaderPath;
  String? newAvatarPath;
  String? id;

  @override
  void initState() {
    super.initState();
    load();
  }

  

  Future<void> load() async {
    final user = await ref.read(currentUserProvider.future);

    if (!mounted) return;

    setState(() {
      _nameController.text = user?['display_name'] ?? "";
      _bioController.text = htmlToText(user?['note'] ?? "");
      id = user?['id'] ?? "";
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> pickHeader() async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );

    if (picked != null) {
      setState(() {
        newHeaderPath = picked.path;
      });

    } 
  }

  Future<void> pickAvatar() async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );

    if (picked != null) {
      setState(() {
        newAvatarPath = picked.path;
      });

    } 
  }

  Future<void> saveProfile() async {
    try {

      final cred = await CredentialsRepository.loadCredentials();
      await updateProfile(
        baseUrl: cred.instanceUrl!,
        token: cred.accToken!,
        displayName: _nameController.text,
        note: _bioController.text,
        avatar: newAvatarPath != null ? File(newAvatarPath!) : null,
        header: newHeaderPath != null ? File(newHeaderPath!) : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Profile edited")));
      }
      ref.invalidate(currentUserProvider);
      ref.invalidate(selectedUserProvider(id!));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't update profile")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit profile"),
        centerTitle: false,
        actions: [
          TextButton(
            onPressed: saveProfile,
            child: Text(
              "Save",
              style: Theme.of(
                context,
              ).textTheme.labelMedium!.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
      body: user.when(
        data: (userData) {
          return SingleChildScrollView(
            child: Column(
              children: [
                // HEADER
                Stack(
                  children: [
                    Container(
                      height: 120,
                      width: double.infinity,
                      color: Colors.grey[800],
                      child: newHeaderPath != null
                          ? Image.file(File(newHeaderPath!), fit: BoxFit.cover)
                          : Image.network(
                              userData!['header'],
                              fit: BoxFit.cover,
                            ),
                    ),

                    Positioned(
                      right: 12,
                      bottom: 12,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.photo_camera,
                            color: Colors.white,
                            size: 20,
                          ),
                          onPressed: pickHeader,
                        ),
                      ),
                    ),
                  ],
                ),

                // AVATAR
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundImage: newAvatarPath != null
                            ? FileImage(File(newAvatarPath!))
                            : (userData?['avatar'] != null
                                  ? NetworkImage(userData!['avatar'])
                                  : null),
                        child:
                            userData?['avatar'] == null && newAvatarPath == null
                            ? const Icon(Icons.person, size: 40)
                            : null,
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.photo_camera,
                              color: Colors.white,
                              size: 16,
                            ),
                            padding: const EdgeInsets.all(4),
                            constraints: const BoxConstraints(),
                            onPressed: pickAvatar,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // FORM
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel("Display name"),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _nameController,
                        hintText: "Your display name",
                      ),

                      const SizedBox(height: 24),

                      _buildLabel("Bio"),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _bioController,
                        hintText: "Tell the world a bit about yourself",
                        maxLines: 4,
                        maxLength: 500,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },

        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text("Error: $e")),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.grey,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    int maxLines = 1,
    int? maxLength,
  }) {
    final theme = Theme.of(context);

    return TextField(
      controller: controller,
      maxLines: maxLines,
      maxLength: maxLength,
      style: TextStyle(color: theme.colorScheme.onSurface),
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: theme.colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
    );
  }
}
