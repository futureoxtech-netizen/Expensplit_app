import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/errors/error_messages.dart';
import '../../../shared/widgets/app_sheet.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/avatar.dart';
import '../../../shared/widgets/gradient_scaffold.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../auth/providers/auth_provider.dart';

/// Dedicated screen for editing the user's public profile: avatar, display
/// name and bio. Email is shown read-only (changing it would require a
/// re-verification flow we don't support yet). Saving only sends fields that
/// actually changed.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _bioCtrl;

  bool _saving = false;
  bool _uploadingAvatar = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    _nameCtrl = TextEditingController(text: user?.name ?? '');
    _bioCtrl = TextEditingController(text: user?.bio ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final source = await showAppFixedSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Photo library'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            if (!kIsWeb)
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded),
                title: const Text('Take photo'),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
          ],
        ),
      ),
    );
    if (source == null) return;

    final XFile? picked = await picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 800,
      maxHeight: 800,
    );
    if (picked == null || !mounted) return;

    setState(() => _uploadingAvatar = true);
    try {
      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        await ref
            .read(authProvider.notifier)
            .uploadAvatar(bytes: bytes, filename: picked.name);
      } else {
        await ref
            .read(authProvider.notifier)
            .uploadAvatar(file: File(picked.path));
      }
      if (mounted) showSuccessSnack(context, 'Profile photo updated');
    } catch (e) {
      if (mounted) showErrorSnack(context, e, fallback: 'Could not upload photo');
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final user = ref.read(authProvider).user;
    final newName = _nameCtrl.text.trim();
    final newBio = _bioCtrl.text.trim();

    // Only send fields that actually changed.
    final nameChanged = newName != (user?.name ?? '');
    final bioChanged = newBio != (user?.bio ?? '');

    if (!nameChanged && !bioChanged) {
      showSuccessSnack(context, 'No changes to save');
      context.pop();
      return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(authProvider.notifier).updateProfile(
            name: nameChanged ? newName : null,
            bio: bioChanged ? newBio : null,
          );
      if (mounted) {
        showSuccessSnack(context, 'Profile updated');
        context.pop();
      }
    } catch (e) {
      if (mounted) showErrorSnack(context, e, fallback: 'Could not update profile');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final cs = Theme.of(context).colorScheme;

    return GradientScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Edit profile'),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(0, 8, 0, 32),
          children: [
            Center(
              child: GestureDetector(
                onTap: _uploadingAvatar ? null : _pickAndUploadAvatar,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    _uploadingAvatar
                        ? const SizedBox(
                            width: 96,
                            height: 96,
                            child: Center(
                              child: CircularProgressIndicator(strokeWidth: 3),
                            ),
                          )
                        : Avatar(
                            name: user?.name ?? '?',
                            imageUrl: user?.avatarUrl,
                            size: 96,
                          ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          gradient: AppColors.brandGradient,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          size: 15,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: _uploadingAvatar ? null : _pickAndUploadAvatar,
                child: const Text('Change photo'),
              ),
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _nameCtrl,
              label: 'Display name',
              hint: 'Your name',
              prefixIcon: Icons.person_outline_rounded,
              textInputAction: TextInputAction.next,
              validator: (v) {
                final t = (v ?? '').trim();
                if (t.length < 2) return 'Name must be at least 2 characters';
                if (t.length > 80) return 'Name is too long';
                return null;
              },
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _bioCtrl,
              label: 'Bio',
              hint: 'A short line about you (optional)',
              prefixIcon: Icons.info_outline_rounded,
              maxLines: 3,
              minLines: 2,
              validator: (v) =>
                  (v != null && v.length > 280) ? 'Bio is too long (max 280)' : null,
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Email',
              initialValue: user?.email ?? '',
              prefixIcon: Icons.mail_outline_rounded,
              enabled: false,
            ),
            Padding(
              padding: const EdgeInsets.only(left: 4, top: 6),
              child: Text(
                'Email cannot be changed.',
                style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurface.withOpacity(0.55),
                ),
              ),
            ),
            const SizedBox(height: 28),
            PrimaryButton(
              label: 'Save changes',
              loading: _saving,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}
