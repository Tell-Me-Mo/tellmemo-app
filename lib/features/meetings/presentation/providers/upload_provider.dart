import 'dart:io';
import 'dart:typed_data';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:dio/dio.dart';
import '../../../../shared/providers/api_client_provider.dart';
import '../../../../core/services/firebase_analytics_service.dart';
import '../../domain/models/multi_file_upload_state.dart';

part 'upload_provider.g.dart';

class UploadState {
  final bool isUploading;
  final double progress;
  final String? error;
  final String? successMessage;
  final String? jobId;

  const UploadState({
    this.isUploading = false,
    this.progress = 0.0,
    this.error,
    this.successMessage,
    this.jobId,
  });

  UploadState copyWith({
    bool? isUploading,
    double? progress,
    String? error,
    String? successMessage,
    String? jobId,
  }) {
    return UploadState(
      isUploading: isUploading ?? this.isUploading,
      progress: progress ?? this.progress,
      error: error ?? this.error,
      successMessage: successMessage ?? this.successMessage,
      jobId: jobId ?? this.jobId,
    );
  }
}

@riverpod
class UploadContent extends _$UploadContent {
  @override
  UploadState build() => const UploadState();

  // New method for uploading text content with optional AI matching
  Future<Map<String, dynamic>?> uploadTextContent({
    required String projectId,
    required String contentType,
    required String title,
    required String content,
    required String date,
    bool useAiMatching = false,
  }) async {
    state = state.copyWith(isUploading: true, progress: 0.0, error: null);

    // Log upload started
    final startTime = DateTime.now();
    await FirebaseAnalyticsService().logContentUploadStarted(
      contentType: contentType,
      projectId: projectId,
      fileSize: content.length,
    );

    try {
      final apiClient = ref.read(apiClientProvider);

      // Non-blocking progress simulation
      Future.microtask(() async {
        for (int i = 10; i <= 90; i += 20) {
          if (!state.isUploading) break;
          await Future.delayed(const Duration(milliseconds: 200));
          if (state.isUploading) {
            state = state.copyWith(progress: i / 100);
          }
        }
      });

      // Call the upload endpoint with AI matching parameter
      final response = await apiClient.uploadTextContent(
        projectId,
        contentType,
        title,
        content,
        date,
        useAiMatching: useAiMatching,
      );

      final jobId = response['job_id'] as String?;
      final returnedProjectId = response['project_id'] as String?;
      final contentId = response['content_id'] as String?;

      // Log upload completed
      final processingTime = DateTime.now().difference(startTime).inMilliseconds;
      await FirebaseAnalyticsService().logContentUploadCompleted(
        contentType: contentType,
        projectId: returnedProjectId ?? projectId,
        contentId: contentId,
        fileSize: content.length,
        processingTime: processingTime,
      );

      state = state.copyWith(
        isUploading: false,
        progress: 1.0,
        successMessage: response['message'] ?? 'Content uploaded successfully!',
        jobId: jobId,
      );

      return {
        ...response,
        'project_id': returnedProjectId ?? projectId,
      };
    } catch (e) {
      // Log upload failed
      await FirebaseAnalyticsService().logContentUploadFailed(
        contentType: contentType,
        errorReason: e.toString(),
        fileSize: content.length,
      );

      state = state.copyWith(
        isUploading: false,
        progress: 0.0,
        error: e.toString(),
      );
      rethrow;
    }
  }

  // New method for uploading files with optional AI matching
  Future<Map<String, dynamic>?> uploadFile({
    required String projectId,
    String? filePath,
    Uint8List? fileBytes,
    required String fileName,
    required String contentType,
    required String title,
    required String date,
    bool useAiMatching = false,
  }) async {
    state = state.copyWith(isUploading: true, progress: 0.0, error: null);

    try {
      final apiClient = ref.read(apiClientProvider);

      // Non-blocking progress simulation
      Future.microtask(() async {
        for (int i = 10; i <= 90; i += 20) {
          if (!state.isUploading) break;
          await Future.delayed(const Duration(milliseconds: 200));
          if (state.isUploading) {
            state = state.copyWith(progress: i / 100);
          }
        }
      });

      // Create MultipartFile
      MultipartFile file;
      if (fileBytes != null) {
        file = MultipartFile.fromBytes(
          fileBytes,
          filename: fileName,
        );
      } else if (filePath != null) {
        file = await MultipartFile.fromFile(
          filePath,
          filename: fileName,
        );
      } else {
        throw Exception('No file to upload');
      }

      // Call the upload file endpoint with AI matching parameter
      final response = await apiClient.uploadFile(
        projectId: projectId,
        file: file,
        contentType: contentType,
        title: title,
        date: date,
        useAiMatching: useAiMatching,
      );

      final jobId = response['job_id'] as String?;
      final returnedProjectId = response['project_id'] as String?;

      state = state.copyWith(
        isUploading: false,
        progress: 1.0,
        successMessage: response['message'] ?? 'File uploaded successfully!',
        jobId: jobId,
      );

      return {
        ...response,
        'project_id': returnedProjectId ?? projectId,
      };
    } catch (e) {
      state = state.copyWith(
        isUploading: false,
        progress: 0.0,
        error: e.toString(),
      );
      rethrow;
    }
  }

  // Keep the original method for backward compatibility
  Future<Map<String, dynamic>?> uploadContent({
    String? projectId,
    required String contentType,
    required String title,
    required String content,
    required String date,
    String? filePath,
    bool useAIMatching = false,
  }) async {
    state = state.copyWith(isUploading: true, progress: 0.0, error: null);

    try {
      // Get the API client
      final apiClient = ref.read(apiClientProvider);

      // Non-blocking progress simulation
      Future.microtask(() async {
        for (int i = 10; i <= 90; i += 20) {
          if (!state.isUploading) break;
          await Future.delayed(const Duration(milliseconds: 200));
          if (state.isUploading) {
            state = state.copyWith(progress: i / 100);
          }
        }
      });

      // Determine which endpoint to use based on AI matching
      final Map<String, dynamic> response;
      if (useAIMatching) {
        // Call AI matching endpoint (to be implemented)
        response = await apiClient.uploadContentWithAIMatching(
          contentType,
          title,
          content,
          date,
        );
      } else if (projectId != null) {
        // For both file uploads and text uploads, use the text endpoint since
        // - Web: file content is already read into 'content' parameter
        // - Text: content is directly provided
        // This handles both cases uniformly
        response = await apiClient.uploadTextContent(
          projectId,
          contentType,
          title,
          content,
          date,
        );
      } else {
        throw Exception('Project ID is required when not using AI matching');
      }

      // Extract job ID from response if available
      final jobId = response['job_id'] as String?;
      
      state = state.copyWith(
        isUploading: false,
        progress: 1.0,
        successMessage: 'Content uploaded successfully!',
        jobId: jobId,
      );
      
      // Return the response which should contain the content ID and job ID
      return response;
    } catch (e) {
      state = state.copyWith(
        isUploading: false,
        progress: 0.0,
        error: e.toString(),
      );
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> uploadAudioFile({
    required String projectId,
    required String contentType,
    required String title,
    required String date,
    String? filePath,
    Uint8List? fileBytes,
    required String fileName,
    bool useAiMatching = false,
  }) async {
    state = state.copyWith(isUploading: true, progress: 0.0, error: null);

    try {
      // Get the API client
      final apiClient = ref.read(apiClientProvider);

      // Non-blocking progress simulation
      Future.microtask(() async {
        for (int i = 10; i <= 90; i += 20) {
          if (!state.isUploading) break;
          await Future.delayed(const Duration(milliseconds: 200));
          if (state.isUploading) {
            state = state.copyWith(progress: i / 100);
          }
        }
      });

      // Create MultipartFile
      MultipartFile audioFile;
      if (fileBytes != null) {
        // Web platform - use bytes
        audioFile = MultipartFile.fromBytes(
          fileBytes,
          filename: fileName,
        );
      } else if (filePath != null) {
        // Desktop/mobile - use file path
        audioFile = await MultipartFile.fromFile(
          filePath,
          filename: fileName,
        );
      } else {
        throw Exception('No audio file to upload');
      }

      // Call transcription endpoint with AI matching parameter
      final response = await apiClient.transcribeAudio(
        projectId: projectId,
        audioFile: audioFile,
        meetingTitle: title,
        language: 'en', // Default to English, can be made configurable
        useAiMatching: useAiMatching,
      );

      // Extract job ID from response
      final jobId = response['job_id'] as String?;

      state = state.copyWith(
        isUploading: false,
        progress: 1.0,
        successMessage: 'Audio file uploaded! Transcription in progress.',
        jobId: jobId,
      );

      // Return the response with job ID and project ID
      final returnedProjectId = response['metadata']?['project_id'] as String?;
      return {
        'job_id': jobId,
        'status': response['status'],
        'message': response['message'],
        'project_id': returnedProjectId ?? projectId,
        ...response['metadata'] ?? {},
      };
    } catch (e) {
      state = state.copyWith(
        isUploading: false,
        progress: 0.0,
        error: e.toString(),
      );
      rethrow;
    }
  }

  void resetState() {
    state = const UploadState();
  }
}

@riverpod
UploadState uploadState(UploadStateRef ref) {
  return ref.watch(uploadContentProvider);
}

// Multi-file upload provider
@riverpod
class MultiFileUpload extends _$MultiFileUpload {
  bool _isCancelled = false;

  @override
  MultiFileUploadState build() => const MultiFileUploadState();

  /// Add files to the upload queue
  void addFiles(List<FileUploadItem> files) {
    state = state.addFiles(files);
  }

  /// Remove a file from the queue (only if not uploading/processing)
  void removeFile(String fileId) {
    final file = state.getFileById(fileId);
    if (file != null &&
        file.status != FileUploadStatus.uploading &&
        file.status != FileUploadStatus.processing) {
      state = state.removeFile(fileId);
    }
  }

  /// Clear all files from the queue
  void clearAll() {
    state = state.clearFiles();
    _isCancelled = false;
  }

  /// Cancel remaining uploads
  void cancelRemaining() {
    _isCancelled = true;

    // Update queued files to cancelled status
    final updatedFiles = state.files.map((file) {
      if (file.status == FileUploadStatus.queued) {
        return file.copyWith(status: FileUploadStatus.cancelled);
      }
      return file;
    }).toList();

    state = state.copyWith(
      files: updatedFiles,
      isUploading: false,
      currentUploadingFileId: null,
    );
  }

  /// Upload multiple files sequentially
  Future<void> uploadFiles({
    required String projectId,
    required String contentType,
    required String dateStr,
    bool useAiMatching = false,
    Function(String jobId, String? contentId, String projectId)? onFileUploaded,
  }) async {
    if (state.files.isEmpty) return;

    _isCancelled = false;
    state = state.copyWith(isUploading: true, globalError: null);

    // Log batch upload started
    await FirebaseAnalyticsService().logEvent(
      name: 'multi_file_upload_started',
      parameters: {
        'file_count': state.totalFiles,
        'content_type': contentType,
        'use_ai_matching': useAiMatching,
      },
    );

    final startTime = DateTime.now();
    int successCount = 0;
    int failureCount = 0;

    try {
      final apiClient = ref.read(apiClientProvider);

      // Process each file sequentially
      for (final file in state.files) {
        // Check if cancelled
        if (_isCancelled) {
          break;
        }

        // Skip if already completed, failed, or cancelled
        if (file.status == FileUploadStatus.completed ||
            file.status == FileUploadStatus.failed ||
            file.status == FileUploadStatus.cancelled) {
          continue;
        }

        // Update file status to uploading
        state = state
            .updateFile(
              file.id,
              file.copyWith(status: FileUploadStatus.uploading, progress: 0.0),
            )
            .copyWith(currentUploadingFileId: file.id);

        try {
          // Simulate progress updates
          _simulateProgress(file.id);

          Map<String, dynamic> response;

          // Determine upload method based on file type
          if (file.isAudioFile) {
            // Upload audio file
            MultipartFile audioFile;
            if (file.fileBytes != null) {
              audioFile = MultipartFile.fromBytes(
                file.fileBytes!,
                filename: file.fileName,
              );
            } else if (file.filePath != null) {
              audioFile = await MultipartFile.fromFile(
                file.filePath!,
                filename: file.fileName,
              );
            } else {
              throw Exception('No file data available');
            }

            response = await apiClient.transcribeAudio(
              projectId: projectId,
              audioFile: audioFile,
              meetingTitle: file.fileName.replaceAll(RegExp(r'\.[^.]+$'), ''),
              language: 'en',
              useAiMatching: useAiMatching,
            );
          } else {
            // Upload text/document file
            String contentToUpload;
            if (file.fileBytes != null) {
              contentToUpload = String.fromCharCodes(file.fileBytes!);
            } else if (file.filePath != null) {
              final fileObj = File(file.filePath!);
              contentToUpload = await fileObj.readAsString();
            } else {
              throw Exception('No file data available');
            }

            response = await apiClient.uploadTextContent(
              projectId,
              contentType,
              file.fileName.replaceAll(RegExp(r'\.[^.]+$'), ''),
              contentToUpload,
              dateStr,
              useAiMatching: useAiMatching,
            );
          }

          // Extract response data
          final jobId = response['job_id'] as String?;
          final contentId = response['id'] as String?;
          final returnedProjectId = response['project_id'] as String?;

          // Update file status to processing/completed
          state = state.updateFile(
            file.id,
            file.copyWith(
              status: FileUploadStatus.processing,
              progress: 1.0,
              jobId: jobId,
              contentId: contentId,
            ),
          );

          successCount++;

          // Callback for job registration
          if (onFileUploaded != null && jobId != null) {
            onFileUploaded(jobId, contentId, returnedProjectId ?? projectId);
          }

          // Brief delay between uploads to avoid overwhelming the server
          await Future.delayed(const Duration(milliseconds: 300));
        } catch (e) {
          // Update file status to failed
          state = state.updateFile(
            file.id,
            file.copyWith(
              status: FileUploadStatus.failed,
              progress: 0.0,
              error: e.toString(),
            ),
          );
          failureCount++;

          // Log individual file failure
          await FirebaseAnalyticsService().logContentUploadFailed(
            contentType: contentType,
            errorReason: e.toString(),
            fileSize: file.fileSize ?? 0,
          );

          // Continue with next file (don't break the loop)
          continue;
        }
      }

      // Log batch upload completed
      final processingTime = DateTime.now().difference(startTime).inMilliseconds;
      await FirebaseAnalyticsService().logEvent(
        name: 'multi_file_upload_completed',
        parameters: {
          'total_files': state.totalFiles,
          'success_count': successCount,
          'failure_count': failureCount,
          'processing_time_ms': processingTime,
          'cancelled': _isCancelled,
        },
      );
    } catch (e) {
      // Global error
      state = state.copyWith(
        globalError: e.toString(),
        isUploading: false,
        currentUploadingFileId: null,
      );

      await FirebaseAnalyticsService().logEvent(
        name: 'multi_file_upload_failed',
        parameters: {
          'error': e.toString(),
          'files_processed': successCount + failureCount,
        },
      );
    } finally {
      state = state.copyWith(
        isUploading: false,
        currentUploadingFileId: null,
      );
    }
  }

  /// Simulate progress updates for a file
  void _simulateProgress(String fileId) {
    Future.microtask(() async {
      for (int i = 10; i <= 90; i += 15) {
        if (_isCancelled) break;

        final file = state.getFileById(fileId);
        if (file == null || file.status != FileUploadStatus.uploading) break;

        await Future.delayed(const Duration(milliseconds: 150));

        if (state.getFileById(fileId)?.status == FileUploadStatus.uploading) {
          state = state.updateFile(
            fileId,
            file.copyWith(progress: i / 100),
          );
        }
      }
    });
  }

  /// Reset state
  void reset() {
    state = const MultiFileUploadState();
    _isCancelled = false;
  }
}