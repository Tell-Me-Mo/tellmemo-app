import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class UserAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? name;
  final double size;
  final bool isEditable;
  final VoidCallback? onTap;

  const UserAvatar({
    super.key,
    this.imageUrl,
    this.name,
    this.size = 80,
    this.isEditable = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: isEditable ? onTap : null,
      child: Stack(
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(size * 0.15),
              color: theme.colorScheme.secondary.withValues(alpha: 0.1),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(size * 0.15),
              child: imageUrl != null && imageUrl!.isNotEmpty
                  ? Image.network(
                      imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _buildFallback(theme),
                    )
                  : _buildFallback(theme),
            ),
          ),
          if (isEditable)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: size * 0.3,
                height: size * 0.3,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(size * 0.15),
                  border: Border.all(
                    color: theme.colorScheme.surface,
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.camera_alt,
                  size: size * 0.15,
                  color: theme.colorScheme.onPrimary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFallback(ThemeData theme) {
    return Icon(
      Icons.person,
      size: size * 0.5,
      color: theme.colorScheme.secondary,
    );
  }
}

class AvatarPicker extends StatelessWidget {
  final String? currentImageUrl;
  final String? userName;
  final Function(String?) onImageSelected;

  const AvatarPicker({
    super.key,
    this.currentImageUrl,
    this.userName,
    required this.onImageSelected,
  });

  @override
  Widget build(BuildContext context) {
    return UserAvatar(
      imageUrl: currentImageUrl,
      name: userName,
      isEditable: true,
      onTap: () => _pickImage(context),
    );
  }

  Future<void> _pickImage(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        // In a real implementation, you would upload the file to storage
        // and get back a URL. For now, we'll use the local path.
        // You might want to integrate with Supabase Storage or another service.

        // For now, just simulate selecting an image
        onImageSelected(result.files.single.path);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile picture updated'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting image: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}