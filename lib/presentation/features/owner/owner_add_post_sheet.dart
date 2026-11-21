import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../data/services/localization_service.dart';

import '../../../data/api/api_client.dart';

import '../../../data/models/portfolio_model.dart';
import '../../core/utils/image_utils.dart';
import '../../../logic/blocs/owner_salon/owner_salon_bloc.dart';
import '../../../logic/blocs/owner_salon/owner_salon_event.dart';
import '../../../logic/blocs/owner_salon/owner_salon_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/loomea_tokens.dart';
import '../../core/widgets/loomea_ui.dart';

class OwnerAddPostSheet extends StatefulWidget {
  final String salonId;
  final PortfolioPost? post; // non-null → edit mode

  const OwnerAddPostSheet({super.key, required this.salonId, this.post});

  @override
  State<OwnerAddPostSheet> createState() => _OwnerAddPostSheetState();
}

class _OwnerAddPostSheetState extends State<OwnerAddPostSheet> {
  final _captionCtrl = TextEditingController();
  final _picker = ImagePicker();
  XFile? _pickedFile;
  Uint8List? _imageBytes;

  bool get _isEditing => widget.post != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _captionCtrl.text = widget.post!.caption;
    }
  }

  @override
  void dispose() {
    _captionCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final image = await _picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1080,
    );
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _pickedFile = image;
        _imageBytes = bytes;
      });
    }
  }

  void _showSourcePicker() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take a Photo'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    final caption = _captionCtrl.text.trim();
    if (caption.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please enter a caption'),
        backgroundColor: AppColors.error,
      ));
      return;
    }

    // Build request data.
    // imageData: raw base64 bytes (no data-URL prefix) — only included when a
    // new image was picked. Edit without a new pick keeps the existing image.
    final Map<String, dynamic> data = {'caption': caption};
    if (_imageBytes != null) {
      data['imageData'] = base64Encode(_imageBytes!);
    } else if (!_isEditing) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please select a photo'),
        backgroundColor: AppColors.error,
      ));
      return;
    }

    if (_isEditing) {
      context.read<OwnerSalonBloc>().add(
            UpdatePortfolioPost(widget.salonId, widget.post!.id, data),
          );
    } else {
      context.read<OwnerSalonBloc>().add(AddPortfolioPost(widget.salonId, data));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<OwnerSalonBloc, OwnerSalonState>(
      listenWhen: (prev, curr) =>
          prev.status == OwnerSalonStatus.saving &&
          curr.status == OwnerSalonStatus.loaded,
      listener: (_, __) => Navigator.pop(context),
      child: Padding(
        padding: const EdgeInsets.only(
          left: LoomeaTokens.screenPaddingH,
          right: LoomeaTokens.screenPaddingH,
          top: 20,
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 24),
          child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Icon(
                  _isEditing
                      ? Icons.edit_outlined
                      : Icons.add_photo_alternate_outlined,
                  color: AppColors.textPrimary,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  _isEditing ? 'Edit Portfolio Post' : 'Add Portfolio Post',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Photo picker / preview
            GestureDetector(
              onTap: _showSourcePicker,
              child: _buildImageArea(),
            ),
            const SizedBox(height: 16),

            // Caption
            LoomeaLabeledField(
              label: tr('post_caption'),
              child: TextField(
                controller: _captionCtrl,
                decoration: const InputDecoration(hintText: 'e.g. "Fresh fade cut"'),
                maxLength: 200,
              ),
            ),
            const SizedBox(height: 20),

            BlocBuilder<OwnerSalonBloc, OwnerSalonState>(
              builder: (context, state) {
                final saving = state.status == OwnerSalonStatus.saving;
                return SizedBox(
                  height: LoomeaTokens.buttonHeight,
                  child: ElevatedButton(
                    onPressed: saving ? null : _submit,
                    child: saving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppColors.onPrimary))
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_rounded, size: 18),
                              const SizedBox(width: 8),
                              Text(_isEditing ? tr('save') : tr('done')),
                            ],
                          ),
                  ),
                );
              },
            ),
          ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageArea() {
    // New image picked — show bytes preview
    if (_imageBytes != null) {
      return _imagePreview(Image.memory(_imageBytes!, fit: BoxFit.cover));
    }
    // Edit mode with existing image — show it
    if (_isEditing && widget.post!.imageUrl.isNotEmpty) {
      String? token;
      try { token = context.read<ApiClient>().token; } catch (_) {}
      return _imagePreview(buildPortfolioImage(widget.post!.imageUrl, BoxFit.cover, token: token));
    }
    // Empty state — tap to pick
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(LoomeaTokens.radiusCard),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_photo_alternate_outlined,
              size: 36, color: AppColors.textSecondary),
          SizedBox(height: 10),
          Text('Tap to select a photo',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
          SizedBox(height: 4),
          Text('Gallery or Camera',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _imagePreview(Widget image) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(LoomeaTokens.radiusCard),
          child: SizedBox(
            height: 200,
            width: double.infinity,
            child: image,
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.edit_outlined, size: 16, color: Colors.white),
          ),
        ),
      ],
    );
  }
}

/// Renders a portfolio image from a network URL.
/// Pass [token] to include the Authorization header for authenticated endpoints.
Widget buildPortfolioImage(String imageUrl, BoxFit fit, {String? token}) {
  if (imageUrl.isEmpty) return _brokenImage();
  final resolved = resolveImageUrl(imageUrl);
  return Image.network(
    resolved,
    fit: fit,
    gaplessPlayback: true,
    headers: token != null ? {'Authorization': 'Bearer $token'} : const {},
    errorBuilder: (_, __, ___) => _brokenImage(),
  );
}

Widget _brokenImage() => Container(
      color: AppColors.inputBackground,
      child: const Icon(Icons.broken_image_rounded, color: AppColors.textSecondary),
    );
