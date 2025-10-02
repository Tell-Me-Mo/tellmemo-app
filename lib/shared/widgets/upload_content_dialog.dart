import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show Uint8List;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../features/projects/domain/entities/project.dart';
import '../../features/meetings/presentation/providers/upload_provider.dart';
import '../../features/projects/presentation/providers/projects_provider.dart';
import '../../features/meetings/presentation/providers/meetings_provider.dart';
import '../../features/content/presentation/providers/processing_jobs_provider.dart';
import '../../features/meetings/domain/models/multi_file_upload_state.dart';
import 'multi_file_upload_list.dart';

enum ProjectSelectionMode { automatic, manual, specific }

// Constants for commonly used values
class _DialogConstants {
  static const double borderRadius = 12.0;
  static const double largeBorderRadius = 20.0;
  static const double padding = 20.0;
  static const double smallPadding = 16.0;
  static const double tinyPadding = 12.0;
  static const double spacing = 16.0;
  static const double smallSpacing = 8.0;
  static const double tinySpacing = 4.0;

  // Opacity values
  static const double highOpacity = 0.3;
  static const double mediumOpacity = 0.2;
  static const double lowOpacity = 0.1;
  static const double minimalOpacity = 0.05;

  // Supported file extensions
  static const List<String> textExtensions = ['txt', 'pdf', 'doc', 'docx', 'json'];
  static const List<String> audioExtensions = ['mp3', 'wav', 'm4a', 'aac', 'ogg', 'wma', 'flac'];
  static List<String> get allExtensions => [...textExtensions, ...audioExtensions];
}

class UploadContentDialog extends ConsumerStatefulWidget {
  final Project? project;
  final VoidCallback onUploadComplete;

  const UploadContentDialog({
    super.key,
    this.project,
    required this.onUploadComplete,
  });

  @override
  ConsumerState<UploadContentDialog> createState() => _UploadContentDialogState();
}

class _UploadContentDialogState extends ConsumerState<UploadContentDialog> {
  String? _selectedFilePath;
  String? _selectedFileName;
  Uint8List? _selectedFileBytes;
  // Default to meeting content type (most common use case)
  final String _contentType = 'meeting';
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String _uploadStatus = '';
  bool _isTextInput = false;
  bool _isMultiFileMode = false;

  // Project selection
  ProjectSelectionMode _projectMode = ProjectSelectionMode.automatic;
  String? _selectedProjectId;

  @override
  void initState() {
    super.initState();
    if (widget.project != null) {
      _projectMode = ProjectSelectionMode.specific;
      _selectedProjectId = widget.project!.id;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: _DialogConstants.allExtensions,
        allowMultiple: true, // Enable multi-file selection
      );

      if (result != null) {
        setState(() {
          _isTextInput = false;

          if (result.files.length == 1) {
            // Single file mode
            _isMultiFileMode = false;
            final file = result.files.single;

            if (file.bytes != null) {
              _selectedFileBytes = file.bytes;
              _selectedFilePath = null;
            } else {
              _selectedFilePath = file.path;
              _selectedFileBytes = null;
            }
            _selectedFileName = file.name;

            if (_titleController.text.isEmpty) {
              _titleController.text = file.name.replaceAll(RegExp(r'\.[^.]+$'), '');
            }
          } else {
            // Multiple files mode
            _isMultiFileMode = true;
            _selectedFilePath = null;
            _selectedFileBytes = null;
            _selectedFileName = null;

            // Add files to multi-file upload provider
            final multiFileUpload = ref.read(multiFileUploadProvider.notifier);
            final fileItems = result.files.map((platformFile) {
              final fileId = '${DateTime.now().microsecondsSinceEpoch}_${platformFile.name}';
              return FileUploadItem(
                id: fileId,
                platformFile: platformFile,
              );
            }).toList();

            multiFileUpload.addFiles(fileItems);

            if (_titleController.text.isEmpty) {
              _titleController.text = '${result.files.length} files';
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  bool _isAudioFile(String? fileName) {
    if (fileName == null) return false;
    final fileExtension = fileName.split('.').last.toLowerCase();
    return _DialogConstants.audioExtensions.contains(fileExtension);
  }

  Future<void> _uploadContent() async {
    // Check if multi-file mode
    if (_isMultiFileMode) {
      await _uploadMultipleFiles();
      return;
    }

    bool hasContent = _isTextInput ?
      _contentController.text.isNotEmpty :
      (_selectedFilePath != null || _selectedFileBytes != null);

    if (!hasContent || _titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide content and enter a title'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
      _uploadStatus = 'Preparing upload...';
    });

    try {
      final dateStr = DateTime.now().toIso8601String().split('T')[0];
      Map<String, dynamic>? response;
      final uploadProvider = ref.read(uploadContentProvider.notifier);

      // Simulate progress updates
      setState(() {
        _uploadProgress = 0.2;
        _uploadStatus = 'Uploading file...';
      });

      if (_isAudioFile(_selectedFileName) && !_isTextInput) {
        response = await uploadProvider.uploadAudioFile(
          projectId: _projectMode == ProjectSelectionMode.automatic ? 'auto' :
                   (_selectedProjectId ?? widget.project?.id ?? ''),
          filePath: _selectedFilePath,
          fileBytes: _selectedFileBytes,
          fileName: _selectedFileName!,
          title: _titleController.text,
          contentType: _contentType,
          date: dateStr,
          useAiMatching: _projectMode == ProjectSelectionMode.automatic,
        );
      } else {
        String contentToUpload;

        if (_isTextInput) {
          contentToUpload = _contentController.text;
        } else if (_selectedFileBytes != null) {
          contentToUpload = String.fromCharCodes(_selectedFileBytes!);
        } else if (_selectedFilePath != null) {
          final file = File(_selectedFilePath!);
          contentToUpload = await file.readAsString();
        } else {
          throw Exception('No content to upload');
        }

        response = await uploadProvider.uploadContent(
          projectId: _projectMode == ProjectSelectionMode.automatic ? 'auto' :
                   (_selectedProjectId ?? widget.project?.id ?? ''),
          contentType: _contentType,
          title: _titleController.text,
          content: contentToUpload,
          date: dateStr,
          filePath: _selectedFilePath,
          useAIMatching: _projectMode == ProjectSelectionMode.automatic,
        );
      }

      setState(() {
        _uploadProgress = 0.6;
        _uploadStatus = 'Processing content...';
      });

      if (response != null) {
        final jobId = response['job_id'] as String?;
        final contentId = response['id'] as String?;
        final returnedProjectId = response['project_id'] as String?;

        if (_projectMode == ProjectSelectionMode.automatic && returnedProjectId != null) {
          ref.invalidate(projectsListProvider);
          await ref.read(projectsListProvider.future);
        }

        if (jobId != null) {
          final projectIdToUse = returnedProjectId ?? _selectedProjectId ?? widget.project?.id ?? '';
          await ref.read(processingJobsProvider.notifier).addJob(
            jobId: jobId,
            contentId: contentId,
            projectId: projectIdToUse,
          );
        }

        setState(() {
          _uploadProgress = 1.0;
          _uploadStatus = 'Upload complete!';
        });

        ref.invalidate(meetingsListProvider);

        // Brief delay to show completion
        await Future.delayed(const Duration(milliseconds: 500));
        widget.onUploadComplete();
      }
    } catch (e) {
      if (mounted) {
        // More specific error messages
        String errorMessage = 'Upload failed';
        if (e.toString().contains('network')) {
          errorMessage = 'Network error: Please check your connection';
        } else if (e.toString().contains('size')) {
          errorMessage = 'File too large: Maximum size is 50MB';
        } else if (e.toString().contains('format')) {
          errorMessage = 'Unsupported file format';
        } else {
          errorMessage = 'Upload failed: ${e.toString().replaceAll('Exception:', '').trim()}';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text(errorMessage)),
              ],
            ),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _uploadContent,
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  Future<void> _uploadMultipleFiles() async {
    final multiFileUpload = ref.read(multiFileUploadProvider.notifier);
    final multiFileState = ref.read(multiFileUploadProvider);

    if (multiFileState.files.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select files to upload'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final dateStr = DateTime.now().toIso8601String().split('T')[0];
      final projectId = _projectMode == ProjectSelectionMode.automatic
          ? 'auto'
          : (_selectedProjectId ?? widget.project?.id ?? '');

      // Start multi-file upload
      await multiFileUpload.uploadFiles(
        projectId: projectId,
        contentType: _contentType,
        dateStr: dateStr,
        useAiMatching: _projectMode == ProjectSelectionMode.automatic,
        onFileUploaded: (jobId, contentId, returnedProjectId) {
          // Register each job with the processing jobs provider
          ref.read(processingJobsProvider.notifier).addJob(
            jobId: jobId,
            contentId: contentId,
            projectId: returnedProjectId,
          );
        },
      );

      // Check if AI matching was used and refresh projects if needed
      if (_projectMode == ProjectSelectionMode.automatic) {
        ref.invalidate(projectsListProvider);
        await ref.read(projectsListProvider.future);
      }

      // Refresh meetings list
      ref.invalidate(meetingsListProvider);

      // Show success message
      final finalState = ref.read(multiFileUploadProvider);
      if (finalState.completedCount > 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${finalState.completedCount} of ${finalState.totalFiles} files uploaded successfully'
                '${finalState.failedCount > 0 ? ' (${finalState.failedCount} failed)' : ''}',
              ),
              backgroundColor: finalState.hasErrors ? Colors.orange : Colors.green,
            ),
          );
        }
      }

      // Brief delay before closing
      await Future.delayed(const Duration(milliseconds: 500));

      // Clear multi-file state
      multiFileUpload.reset();

      // Close dialog
      if (mounted) {
        widget.onUploadComplete();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Upload failed: ${e.toString()}')),
              ],
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Detect mobile screen
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final horizontalPadding = isMobile ? 16.0 : _DialogConstants.padding;
    final verticalPadding = isMobile ? 16.0 : _DialogConstants.padding;

    // Use IntrinsicHeight for better dialog sizing when project is provided
    final Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _DialogHeader(
          project: widget.project,
          colorScheme: colorScheme,
          textTheme: textTheme,
        ),
        Flexible(
          fit: widget.project != null ? FlexFit.loose : FlexFit.tight,
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.project == null) ...[
                  _ProjectSelectionSection(
                    projectMode: _projectMode,
                    selectedProjectId: _selectedProjectId,
                    onModeChanged: (mode) => setState(() {
                      _projectMode = mode;
                      if (mode == ProjectSelectionMode.automatic) {
                        _selectedProjectId = null;
                      }
                    }),
                    onProjectSelected: (projectId) => setState(() {
                      _selectedProjectId = projectId;
                    }),
                    colorScheme: colorScheme,
                    textTheme: textTheme,
                  ),
                  const SizedBox(height: _DialogConstants.padding),
                ],
                // Show multi-file list if in multi-file mode
                if (_isMultiFileMode) ...[
                  Consumer(
                    builder: (context, ref, child) {
                      final multiFileState = ref.watch(multiFileUploadProvider);
                      return MultiFileUploadList(
                        files: multiFileState.files,
                        isUploading: multiFileState.isUploading,
                        onRemoveFile: (fileId) {
                          ref.read(multiFileUploadProvider.notifier).removeFile(fileId);
                          // Switch back to single file mode if no files left
                          if (multiFileState.files.length == 1) {
                            setState(() {
                              _isMultiFileMode = false;
                            });
                          }
                        },
                        showRemoveButtons: !multiFileState.isUploading,
                      );
                    },
                  ),
                  const SizedBox(height: _DialogConstants.smallPadding),
                  // Show progress if uploading
                  Consumer(
                    builder: (context, ref, child) {
                      final multiFileState = ref.watch(multiFileUploadProvider);
                      if (multiFileState.isUploading || multiFileState.completedCount > 0) {
                        return Column(
                          children: [
                            MultiFileUploadProgress(
                              state: multiFileState,
                              onCancel: () {
                                ref.read(multiFileUploadProvider.notifier).cancelRemaining();
                              },
                            ),
                            const SizedBox(height: _DialogConstants.smallPadding),
                          ],
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ] else ...[
                  // Content Input with integrated paste option
                  _ContentInputSection(
                    isTextInput: _isTextInput,
                    selectedFileName: _selectedFileName,
                    selectedFilePath: _selectedFilePath,
                    selectedFileBytes: _selectedFileBytes,
                    contentController: _contentController,
                    onInputTypeChanged: (isText) => setState(() => _isTextInput = isText),
                    onPickFile: _pickFile,
                    colorScheme: colorScheme,
                    textTheme: textTheme,
                  ),
                  SizedBox(height: isMobile ? 12 : _DialogConstants.smallPadding),
                  // Title field with consistent styling (only for single file)
                  _TitleField(
                    controller: _titleController,
                    colorScheme: colorScheme,
                  ),
                ],
              ],
            ),
          ),
        ),
        Consumer(
          builder: (context, ref, child) {
            final multiFileState = ref.watch(multiFileUploadProvider);
            final fileCount = _isMultiFileMode ? multiFileState.files.length : 1;

            return _DialogActions(
              isUploading: _isUploading,
              uploadProgress: _uploadProgress,
              uploadStatus: _uploadStatus,
              onUpload: _uploadContent,
              colorScheme: colorScheme,
              fileCount: fileCount,
              isMultiFile: _isMultiFileMode,
            );
          },
        ),
      ],
    );

    // Use IntrinsicHeight when project is provided for compact dialog
    // But NOT when in multi-file mode (contains ListView which can't be intrinsic)
    return (widget.project != null && !_isMultiFileMode)
        ? IntrinsicHeight(child: content)
        : content;
  }
}

// Extracted Header Widget
class _DialogHeader extends StatelessWidget {
  final Project? project;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  const _DialogHeader({
    required this.project,
    required this.colorScheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    // Detect mobile screen
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Container(
      padding: EdgeInsets.all(isMobile ? 16.0 : _DialogConstants.padding),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: _DialogConstants.lowOpacity),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(_DialogConstants.largeBorderRadius),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isMobile ? 8 : 10),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: _DialogConstants.lowOpacity),
              borderRadius: BorderRadius.circular(_DialogConstants.borderRadius),
            ),
            child: Icon(
              Icons.upload_file_outlined,
              color: Colors.blue,
              size: isMobile ? 20 : 24,
            ),
          ),
          SizedBox(width: isMobile ? 12 : _DialogConstants.spacing),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Upload Meeting Transcript',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: isMobile ? 18 : null,
                  ),
                ),
                if (!isMobile || project != null)
                  Text(
                    project != null ?
                      'Add meeting transcript to ${project!.name}' :
                      'Add meeting transcript to project',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: isMobile ? 11 : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.close, size: isMobile ? 20 : 24),
            style: IconButton.styleFrom(
              backgroundColor: colorScheme.surfaceContainerHighest.withValues(
                alpha: _DialogConstants.highOpacity,
              ),
              padding: isMobile ? const EdgeInsets.all(8) : null,
            ),
          ),
        ],
      ),
    );
  }
}

// Extracted Project Selection Section with Segmented Control
class _ProjectSelectionSection extends ConsumerWidget {
  final ProjectSelectionMode projectMode;
  final String? selectedProjectId;
  final Function(ProjectSelectionMode) onModeChanged;
  final Function(String?) onProjectSelected;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  const _ProjectSelectionSection({
    required this.projectMode,
    required this.selectedProjectId,
    required this.onModeChanged,
    required this.onProjectSelected,
    required this.colorScheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(projectsListProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Project Selection',
              style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 8),
            if (projectMode == ProjectSelectionMode.automatic)
              Tooltip(
                message: 'AI will analyze your content and automatically match it to an existing project or create a new one',
                child: Icon(
                  Icons.info_outline,
                  size: 16,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                ),
              ),
          ],
        ),
        const SizedBox(height: _DialogConstants.tinyPadding),
        // Segmented Control
        Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: _DialogConstants.lowOpacity),
            borderRadius: BorderRadius.circular(_DialogConstants.borderRadius),
          ),
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              Expanded(
                child: _SegmentedButton(
                  label: 'AI Auto-match',
                  icon: Icons.auto_awesome,
                  isSelected: projectMode == ProjectSelectionMode.automatic,
                  onTap: () => onModeChanged(ProjectSelectionMode.automatic),
                  colorScheme: colorScheme,
                  textTheme: textTheme,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _SegmentedButton(
                  label: 'Select Project',
                  icon: Icons.format_list_bulleted,
                  isSelected: projectMode == ProjectSelectionMode.manual,
                  onTap: () => onModeChanged(ProjectSelectionMode.manual),
                  colorScheme: colorScheme,
                  textTheme: textTheme,
                ),
              ),
            ],
          ),
        ),
        // Animated transition for dropdown
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: projectMode == ProjectSelectionMode.manual
              ? Column(
                  children: [
                    const SizedBox(height: _DialogConstants.spacing),
                    projectsAsync.when(
                    data: (projects) => _ProjectDropdown(
                      projects: projects,
                      selectedProjectId: selectedProjectId,
                      onChanged: onProjectSelected,
                      colorScheme: colorScheme,
                      textTheme: textTheme,
                    ),
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(_DialogConstants.smallSpacing),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    error: (error, _) => Padding(
                      padding: const EdgeInsets.all(_DialogConstants.smallSpacing),
                      child: Text(
                        'Error loading projects',
                        style: TextStyle(color: colorScheme.error),
                      ),
                    ),
                    ),
                  ],
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

// Segmented Button for Project Mode
class _SegmentedButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  const _SegmentedButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.colorScheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primary.withValues(alpha: _DialogConstants.lowOpacity)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isSelected
                ? Border.all(color: colorScheme.primary.withValues(alpha: 0.3))
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


// Project Dropdown Widget
class _ProjectDropdown extends StatelessWidget {
  final List<Project> projects;
  final String? selectedProjectId;
  final Function(String?) onChanged;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  const _ProjectDropdown({
    required this.projects,
    required this.selectedProjectId,
    required this.onChanged,
    required this.colorScheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_DialogConstants.smallSpacing),
            borderSide: BorderSide(
              color: colorScheme.outline.withValues(alpha: _DialogConstants.highOpacity),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_DialogConstants.smallSpacing),
            borderSide: BorderSide(
              color: colorScheme.outline.withValues(alpha: _DialogConstants.highOpacity),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_DialogConstants.smallSpacing),
            borderSide: BorderSide(color: colorScheme.primary, width: 2),
          ),
          filled: true,
          fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: _DialogConstants.highOpacity),
        ),
      ),
      child: DropdownButtonFormField<String>(
        initialValue: selectedProjectId,
        decoration: InputDecoration(
          hintText: 'Choose a project',
          hintStyle: TextStyle(
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
          ),
          prefixIcon: Icon(
            Icons.folder_outlined,
            color: selectedProjectId != null ?
              colorScheme.primary :
              colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            size: 20,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: _DialogConstants.tinyPadding,
            vertical: 14,
          ),
        ),
        dropdownColor: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(_DialogConstants.borderRadius),
        elevation: 4,
        style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
        icon: Icon(
          Icons.keyboard_arrow_down_rounded,
          color: colorScheme.onSurfaceVariant,
        ),
        selectedItemBuilder: (BuildContext context) {
          return projects.map<Widget>((project) {
            return Container(
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: _DialogConstants.tinyPadding),
                  Text(
                    project.name,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }).toList();
        },
        items: projects.map((project) {
          return DropdownMenuItem<String>(
            value: project.id,
            child: _ProjectDropdownItem(
              project: project,
              colorScheme: colorScheme,
              textTheme: textTheme,
            ),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}

// Project Dropdown Item
class _ProjectDropdownItem extends StatelessWidget {
  final Project project;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  const _ProjectDropdownItem({
    required this.project,
    required this.colorScheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: _DialogConstants.tinySpacing),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: _DialogConstants.highOpacity),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              Icons.work_outline,
              size: 16,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: _DialogConstants.tinyPadding),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  project.name,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface,
                  ),
                ),
                if (project.description != null && project.description!.isNotEmpty)
                  Text(
                    project.description!,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Content Input Section - Unified Design
class _ContentInputSection extends StatelessWidget {
  final bool isTextInput;
  final String? selectedFileName;
  final String? selectedFilePath;
  final Uint8List? selectedFileBytes;
  final TextEditingController contentController;
  final Function(bool) onInputTypeChanged;
  final VoidCallback onPickFile;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  const _ContentInputSection({
    required this.isTextInput,
    required this.selectedFileName,
    required this.selectedFilePath,
    required this.selectedFileBytes,
    required this.contentController,
    required this.onInputTypeChanged,
    required this.onPickFile,
    required this.colorScheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeInOut,
      switchOutCurve: Curves.easeInOut,
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: SizeTransition(
            sizeFactor: animation,
            child: child,
          ),
        );
      },
      child: !isTextInput
          ? _UnifiedUploadArea(
              selectedFileName: selectedFileName,
              hasFile: selectedFilePath != null || selectedFileBytes != null,
              onPickFile: onPickFile,
              onSwitchToPaste: () => onInputTypeChanged(true),
              colorScheme: colorScheme,
              textTheme: textTheme,
            )
          : _TextInputArea(
              controller: contentController,
              onSwitchToUpload: () => onInputTypeChanged(false),
              colorScheme: colorScheme,
              textTheme: textTheme,
            ),
    );
  }
}

// Unified Upload Area with integrated paste option
class _UnifiedUploadArea extends StatelessWidget {
  final String? selectedFileName;
  final bool hasFile;
  final VoidCallback onPickFile;
  final VoidCallback onSwitchToPaste;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  const _UnifiedUploadArea({
    required this.selectedFileName,
    required this.hasFile,
    required this.onPickFile,
    required this.onSwitchToPaste,
    required this.colorScheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    // Detect mobile screen
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    // Adjust sizes for mobile
    final iconSize = isMobile ? 40.0 : 48.0;
    final verticalPadding = isMobile ? 16.0 : 20.0;
    final containerPadding = isMobile ? 16.0 : _DialogConstants.padding;
    final dividerVerticalPadding = isMobile ? 12.0 : _DialogConstants.smallPadding;

    return Container(
      padding: EdgeInsets.all(containerPadding),
      decoration: BoxDecoration(
        border: Border.all(
          color: hasFile ?
            Colors.blue.withValues(alpha: _DialogConstants.highOpacity) :
            colorScheme.outline.withValues(alpha: _DialogConstants.mediumOpacity),
          width: hasFile ? 2 : 1.5,
          style: hasFile ? BorderStyle.solid : BorderStyle.solid,
        ),
        borderRadius: BorderRadius.circular(_DialogConstants.borderRadius),
        color: hasFile ?
          Colors.blue.withValues(alpha: _DialogConstants.minimalOpacity) :
          colorScheme.surfaceContainerHighest.withValues(alpha: 0.05),
      ),
      child: Column(
        children: [
          // File upload area
          InkWell(
            onTap: onPickFile,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: verticalPadding),
              child: Column(
                children: [
                  Icon(
                    hasFile ? Icons.insert_drive_file : Icons.cloud_upload_outlined,
                    size: iconSize,
                    color: hasFile ?
                      Colors.blue :
                      colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: _DialogConstants.tinyPadding),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: isMobile ? 8.0 : 0.0),
                    child: Text(
                      selectedFileName ?? 'Click to select meeting transcript',
                      style: textTheme.bodyLarge?.copyWith(
                        color: hasFile ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
                        fontWeight: hasFile ? FontWeight.w500 : FontWeight.normal,
                        fontSize: isMobile ? 15 : null,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: isMobile ? 2 : null,
                      overflow: isMobile ? TextOverflow.ellipsis : null,
                    ),
                  ),
                  SizedBox(height: isMobile ? 6 : _DialogConstants.tinySpacing),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: isMobile ? 12.0 : 0.0),
                    child: Text(
                      isMobile
                        ? 'Audio or text files: TXT, PDF, DOC, DOCX, JSON, MP3, WAV, M4A, AAC, OGG, WMA, FLAC'
                        : 'Audio or text files: ${_DialogConstants.allExtensions.map((e) => e.toUpperCase()).join(', ')}',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                        fontSize: isMobile ? 10 : 11,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: isMobile ? 2 : null,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Divider with "OR" text
          Padding(
            padding: EdgeInsets.symmetric(vertical: dividerVerticalPadding),
            child: Row(
              children: [
                Expanded(
                  child: Divider(
                    color: colorScheme.outline.withValues(alpha: _DialogConstants.mediumOpacity),
                    thickness: 1,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: _DialogConstants.smallPadding),
                  child: Text(
                    'OR',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(
                  child: Divider(
                    color: colorScheme.outline.withValues(alpha: _DialogConstants.mediumOpacity),
                    thickness: 1,
                  ),
                ),
              ],
            ),
          ),

          // Paste text button
          SizedBox(
            width: isMobile ? double.infinity : null,
            child: OutlinedButton.icon(
              onPressed: onSwitchToPaste,
              icon: Icon(
                Icons.text_fields,
                size: isMobile ? 18 : 20,
                color: colorScheme.primary,
              ),
              label: Text(
                'Paste Text',
                style: TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w500,
                  fontSize: isMobile ? 14 : null,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 20 : 24,
                  vertical: isMobile ? 10 : 12,
                ),
                side: BorderSide(
                  color: colorScheme.primary.withValues(alpha: 0.5),
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_DialogConstants.smallSpacing),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


// Text Input Area with back to upload option
class _TextInputArea extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSwitchToUpload;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  const _TextInputArea({
    required this.controller,
    required this.onSwitchToUpload,
    required this.colorScheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: _DialogConstants.mediumOpacity),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(_DialogConstants.borderRadius),
      ),
      child: Column(
        children: [
          TextField(
            controller: controller,
            maxLines: 8,
            decoration: InputDecoration(
              hintText: 'Paste or type your meeting transcript here...\n\nYou can paste meeting transcripts from Zoom, Teams, or any other source.',
              hintStyle: TextStyle(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(_DialogConstants.smallPadding),
            ),
          ),
          Divider(
            height: 1,
            color: colorScheme.outline.withValues(alpha: _DialogConstants.mediumOpacity),
          ),
          Padding(
            padding: const EdgeInsets.all(_DialogConstants.smallPadding),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton.icon(
                  onPressed: onSwitchToUpload,
                  icon: Icon(
                    Icons.upload_file,
                    size: 18,
                  ),
                  label: Text('Upload File Instead'),
                  style: TextButton.styleFrom(
                    foregroundColor: colorScheme.primary,
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

// Title Field with consistent visual alignment
class _TitleField extends StatelessWidget {
  final TextEditingController controller;
  final ColorScheme colorScheme;

  const _TitleField({
    required this.controller,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    // Detect mobile screen
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Meeting Title',
          style: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w500,
            fontSize: isMobile ? 13 : null,
          ),
        ),
        SizedBox(height: isMobile ? 8 : _DialogConstants.tinyPadding),
        TextField(
          controller: controller,
          style: TextStyle(fontSize: isMobile ? 14 : null),
          decoration: InputDecoration(
            hintText: isMobile
              ? 'e.g., Weekly Standup'
              : 'e.g., Weekly Standup, Sprint Planning, Client Review',
            hintStyle: TextStyle(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              fontSize: isMobile ? 13 : null,
            ),
            prefixIcon: Icon(
              Icons.title,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              size: isMobile ? 18 : 20,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(_DialogConstants.borderRadius),
              borderSide: BorderSide(
                color: colorScheme.outline.withValues(alpha: _DialogConstants.mediumOpacity),
                width: 1.5,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(_DialogConstants.borderRadius),
              borderSide: BorderSide(
                color: colorScheme.outline.withValues(alpha: _DialogConstants.mediumOpacity),
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(_DialogConstants.borderRadius),
              borderSide: BorderSide(
                color: colorScheme.primary,
                width: 2,
              ),
            ),
            filled: true,
            fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.05),
            contentPadding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : _DialogConstants.smallPadding,
              vertical: isMobile ? 12 : 14,
            ),
          ),
        ),
      ],
    );
  }
}

// Dialog Actions with Progress Indicator
class _DialogActions extends StatelessWidget {
  final bool isUploading;
  final double uploadProgress;
  final String uploadStatus;
  final VoidCallback onUpload;
  final ColorScheme colorScheme;
  final int fileCount;
  final bool isMultiFile;

  const _DialogActions({
    required this.isUploading,
    required this.uploadProgress,
    required this.uploadStatus,
    required this.onUpload,
    required this.colorScheme,
    this.fileCount = 1,
    this.isMultiFile = false,
  });

  @override
  Widget build(BuildContext context) {
    // Detect mobile screen
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Container(
      padding: EdgeInsets.all(isMobile ? 16.0 : _DialogConstants.padding),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: _DialogConstants.lowOpacity),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(_DialogConstants.largeBorderRadius),
        ),
      ),
      child: Column(
        children: [
          if (isUploading) ...[
            LinearProgressIndicator(
              value: uploadProgress,
              backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
            ),
            const SizedBox(height: 8),
            Text(
              uploadStatus,
              style: TextStyle(
                fontSize: isMobile ? 11 : 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: isUploading ? null : () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 12 : 16,
                    vertical: isMobile ? 8 : 12,
                  ),
                ),
                child: Text('Cancel', style: TextStyle(fontSize: isMobile ? 14 : null)),
              ),
              SizedBox(width: isMobile ? 8 : _DialogConstants.tinyPadding),
              FilledButton.icon(
                onPressed: isUploading ? null : onUpload,
                icon: isUploading ?
                  SizedBox(
                    width: isMobile ? 14 : 16,
                    height: isMobile ? 14 : 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      value: uploadProgress > 0 ? uploadProgress : null,
                    ),
                  ) :
                  Icon(Icons.upload, size: isMobile ? 18 : null),
                label: Text(
                  isUploading
                      ? '${(uploadProgress * 100).toInt()}%'
                      : isMultiFile
                          ? 'Upload $fileCount file${fileCount != 1 ? 's' : ''}'
                          : 'Upload',
                  style: TextStyle(fontSize: isMobile ? 14 : null),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 16 : 24,
                    vertical: isMobile ? 10 : _DialogConstants.tinyPadding,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}