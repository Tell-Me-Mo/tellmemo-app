import 'package:flutter/foundation.dart' show Uint8List;
import 'package:file_picker/file_picker.dart';

/// Status of individual file upload
enum FileUploadStatus {
  queued,
  uploading,
  processing,
  completed,
  failed,
  cancelled,
}

/// Represents a single file in a multi-file upload batch
class FileUploadItem {
  final String id; // Unique identifier for this upload item
  final PlatformFile platformFile;
  final FileUploadStatus status;
  final double progress; // 0.0 to 1.0
  final String? error;
  final String? jobId; // Job ID from backend once uploaded
  final String? contentId; // Content ID from backend once uploaded
  final DateTime addedAt;

  FileUploadItem({
    required this.id,
    required this.platformFile,
    this.status = FileUploadStatus.queued,
    this.progress = 0.0,
    this.error,
    this.jobId,
    this.contentId,
    DateTime? addedAt,
  }) : addedAt = addedAt ?? DateTime.now();

  String get fileName => platformFile.name;
  int? get fileSize => platformFile.size;
  String? get filePath => platformFile.path;
  Uint8List? get fileBytes => platformFile.bytes;

  // Helper to determine if file is audio
  bool get isAudioFile {
    final extension = fileName.split('.').last.toLowerCase();
    return ['mp3', 'wav', 'm4a', 'aac', 'ogg', 'wma', 'flac']
        .contains(extension);
  }

  // Helper to determine file type category
  String get fileType {
    final extension = fileName.split('.').last.toLowerCase();
    if (['mp3', 'wav', 'm4a', 'aac', 'ogg', 'wma', 'flac'].contains(extension)) {
      return 'audio';
    } else if (['pdf'].contains(extension)) {
      return 'pdf';
    } else if (['doc', 'docx'].contains(extension)) {
      return 'document';
    } else if (['txt'].contains(extension)) {
      return 'text';
    } else if (['json'].contains(extension)) {
      return 'json';
    }
    return 'file';
  }

  FileUploadItem copyWith({
    FileUploadStatus? status,
    double? progress,
    String? error,
    String? jobId,
    String? contentId,
  }) {
    return FileUploadItem(
      id: id,
      platformFile: platformFile,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      error: error,
      jobId: jobId ?? this.jobId,
      contentId: contentId ?? this.contentId,
      addedAt: addedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FileUploadItem &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// State for multi-file upload batch
class MultiFileUploadState {
  final List<FileUploadItem> files;
  final bool isUploading;
  final String? currentUploadingFileId;
  final String? globalError;

  const MultiFileUploadState({
    this.files = const [],
    this.isUploading = false,
    this.currentUploadingFileId,
    this.globalError,
  });

  // Aggregate statistics
  int get totalFiles => files.length;
  int get completedCount =>
      files.where((f) => f.status == FileUploadStatus.completed).length;
  int get failedCount =>
      files.where((f) => f.status == FileUploadStatus.failed).length;
  int get queuedCount =>
      files.where((f) => f.status == FileUploadStatus.queued).length;
  int get uploadingCount =>
      files.where((f) => f.status == FileUploadStatus.uploading).length;
  int get processingCount =>
      files.where((f) => f.status == FileUploadStatus.processing).length;

  double get overallProgress {
    if (files.isEmpty) return 0.0;
    final totalProgress = files.fold<double>(0.0, (sum, file) {
      if (file.status == FileUploadStatus.completed) return sum + 1.0;
      if (file.status == FileUploadStatus.uploading) return sum + file.progress;
      return sum;
    });
    return totalProgress / files.length;
  }

  bool get hasErrors => files.any((f) => f.status == FileUploadStatus.failed);
  bool get allCompleted =>
      files.isNotEmpty &&
      files.every((f) => f.status == FileUploadStatus.completed);
  bool get hasQueuedFiles =>
      files.any((f) => f.status == FileUploadStatus.queued);

  FileUploadItem? getFileById(String id) {
    try {
      return files.firstWhere((f) => f.id == id);
    } catch (e) {
      return null;
    }
  }

  MultiFileUploadState copyWith({
    List<FileUploadItem>? files,
    bool? isUploading,
    String? currentUploadingFileId,
    String? globalError,
  }) {
    return MultiFileUploadState(
      files: files ?? this.files,
      isUploading: isUploading ?? this.isUploading,
      currentUploadingFileId: currentUploadingFileId,
      globalError: globalError,
    );
  }

  /// Update a specific file in the list
  MultiFileUploadState updateFile(String fileId, FileUploadItem updatedFile) {
    return copyWith(
      files: files.map((f) => f.id == fileId ? updatedFile : f).toList(),
    );
  }

  /// Remove a file from the list
  MultiFileUploadState removeFile(String fileId) {
    return copyWith(
      files: files.where((f) => f.id != fileId).toList(),
    );
  }

  /// Add files to the list
  MultiFileUploadState addFiles(List<FileUploadItem> newFiles) {
    return copyWith(
      files: [...files, ...newFiles],
    );
  }

  /// Clear all files
  MultiFileUploadState clearFiles() {
    return copyWith(files: []);
  }
}
