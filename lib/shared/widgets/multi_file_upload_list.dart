import 'package:flutter/material.dart';
import '../../features/meetings/domain/models/multi_file_upload_state.dart';

/// Widget to display a list of files in a multi-file upload batch
class MultiFileUploadList extends StatelessWidget {
  final List<FileUploadItem> files;
  final bool isUploading;
  final Function(String fileId)? onRemoveFile;
  final bool showRemoveButtons;

  const MultiFileUploadList({
    super.key,
    required this.files,
    this.isUploading = false,
    this.onRemoveFile,
    this.showRemoveButtons = true,
  });

  @override
  Widget build(BuildContext context) {
    if (files.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        _buildHeader(context),
        const SizedBox(height: 12),
        // File list
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: files.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
            ),
            itemBuilder: (context, index) {
              return _FileUploadItem(
                file: files[index],
                onRemove: (showRemoveButtons &&
                        onRemoveFile != null &&
                        !isUploading &&
                        files[index].status != FileUploadStatus.uploading &&
                        files[index].status != FileUploadStatus.processing)
                    ? () => onRemoveFile!(files[index].id)
                    : null,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final completedCount =
        files.where((f) => f.status == FileUploadStatus.completed).length;
    final failedCount =
        files.where((f) => f.status == FileUploadStatus.failed).length;

    return Row(
      children: [
        Icon(
          Icons.file_copy_outlined,
          size: 18,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Text(
          '${files.length} file${files.length != 1 ? 's' : ''} selected',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        if (isUploading) ...[
          const SizedBox(width: 12),
          Text(
            '($completedCount completed${failedCount > 0 ? ', $failedCount failed' : ''})',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

/// Individual file item in the upload list
class _FileUploadItem extends StatelessWidget {
  final FileUploadItem file;
  final VoidCallback? onRemove;

  const _FileUploadItem({
    required this.file,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          // File type icon
          _buildFileIcon(context),
          const SizedBox(width: 12),
          // File info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        file.fileName,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (file.fileSize != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        _formatFileSize(file.fileSize!),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                // Status or progress
                _buildStatus(context),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Status icon or remove button
          _buildActionWidget(context),
        ],
      ),
    );
  }

  Widget _buildFileIcon(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    IconData icon;
    Color color;

    switch (file.fileType) {
      case 'audio':
        icon = Icons.audio_file;
        color = Colors.purple;
        break;
      case 'pdf':
        icon = Icons.picture_as_pdf;
        color = Colors.red;
        break;
      case 'document':
        icon = Icons.description;
        color = Colors.blue;
        break;
      case 'text':
        icon = Icons.text_snippet;
        color = Colors.green;
        break;
      case 'json':
        icon = Icons.data_object;
        color = Colors.orange;
        break;
      default:
        icon = Icons.insert_drive_file;
        color = colorScheme.onSurfaceVariant;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        icon,
        size: 20,
        color: color,
      ),
    );
  }

  Widget _buildStatus(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    switch (file.status) {
      case FileUploadStatus.queued:
        return Row(
          children: [
            Icon(
              Icons.schedule,
              size: 14,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 4),
            Text(
              'Queued',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
          ],
        );

      case FileUploadStatus.uploading:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    value: file.progress,
                    valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Uploading... ${(file.progress * 100).toInt()}%',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: file.progress,
              minHeight: 3,
              backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              borderRadius: BorderRadius.circular(2),
            ),
          ],
        );

      case FileUploadStatus.processing:
        return Row(
          children: [
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'Processing...',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.orange,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );

      case FileUploadStatus.completed:
        return Row(
          children: [
            Icon(
              Icons.check_circle,
              size: 14,
              color: Colors.green,
            ),
            const SizedBox(width: 4),
            Text(
              'Completed',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.green,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );

      case FileUploadStatus.failed:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.error_outline,
                  size: 14,
                  color: Colors.red,
                ),
                const SizedBox(width: 4),
                Text(
                  'Failed',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            if (file.error != null) ...[
              const SizedBox(height: 2),
              Text(
                file.error!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.red.withValues(alpha: 0.7),
                  fontSize: 11,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        );

      case FileUploadStatus.cancelled:
        return Row(
          children: [
            Icon(
              Icons.cancel_outlined,
              size: 14,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 4),
            Text(
              'Cancelled',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
          ],
        );
    }
  }

  Widget _buildActionWidget(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Show status icon for completed/failed
    if (file.status == FileUploadStatus.completed) {
      return Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.check,
          size: 16,
          color: Colors.green,
        ),
      );
    }

    if (file.status == FileUploadStatus.failed) {
      return Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.error_outline,
          size: 16,
          color: Colors.red,
        ),
      );
    }

    // Show remove button for queued/cancelled files
    if (onRemove != null) {
      return IconButton(
        icon: Icon(
          Icons.close,
          size: 18,
        ),
        onPressed: onRemove,
        tooltip: 'Remove file',
        visualDensity: VisualDensity.compact,
        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
      );
    }

    return const SizedBox(width: 32); // Placeholder for alignment
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// Overall progress indicator for multi-file upload
class MultiFileUploadProgress extends StatelessWidget {
  final MultiFileUploadState state;
  final VoidCallback? onCancel;

  const MultiFileUploadProgress({
    super.key,
    required this.state,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    if (!state.isUploading && state.completedCount == 0) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Progress bar
          LinearProgressIndicator(
            value: state.overallProgress,
            minHeight: 8,
            backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 12),
          // Status text
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.isUploading
                          ? 'Uploading files...'
                          : state.allCompleted
                              ? 'All files uploaded!'
                              : 'Upload incomplete',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${state.completedCount} of ${state.totalFiles} completed'
                      '${state.failedCount > 0 ? ' • ${state.failedCount} failed' : ''}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (state.isUploading && state.hasQueuedFiles && onCancel != null)
                TextButton(
                  onPressed: onCancel,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                  child: const Text('Cancel Remaining'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
