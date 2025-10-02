import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb, compute;
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class TranscriptionResult {
  final String text;
  final String? sessionId;
  final DateTime timestamp;
  final Duration audioDuration;
  final Map<String, dynamic>? metadata;
  final String? jobId;
  final String? contentId;

  TranscriptionResult({
    required this.text,
    this.sessionId,
    required this.timestamp,
    required this.audioDuration,
    this.metadata,
    this.jobId,
    this.contentId,
  });

  factory TranscriptionResult.fromJson(Map<String, dynamic> json) {
    final metadata = json['metadata'] as Map<String, dynamic>?;
    return TranscriptionResult(
      text: json['text'] ?? '',
      sessionId: json['session_id'],
      timestamp: DateTime.parse('${json['timestamp']}Z').toLocal(),
      audioDuration: Duration(seconds: json['audio_duration'] ?? 0),
      metadata: metadata,
      jobId: json['job_id'],
      contentId: metadata?['content_id'] as String?,
    );
  }
}

class TranscriptionService {
  late final Dio _dio;
  final String baseUrl;

  TranscriptionService({String? customBaseUrl})
      : baseUrl = customBaseUrl ?? dotenv.env['FLUTTER_API_BASE_URL'] ?? 'http://localhost:8000' {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(minutes: 5), // Longer timeout for processing
      headers: {
        'Content-Type': 'multipart/form-data',
      },
    ));
  }

  // Transcribe audio file or blob URL
  Future<TranscriptionResult> transcribeAudioFile({
    required String audioFilePath,
    String? projectId,
    String? meetingTitle,
    String? language,
    Map<String, dynamic>? additionalMetadata,
  }) async {
    try {
      print('[TranscriptionService] Starting transcription for: $audioFilePath');
      print('[TranscriptionService] Platform is web: $kIsWeb');
      
      MultipartFile audioMultipart;
      
      if (kIsWeb) {
        // For web, handle blob URL or base64 data
        if (audioFilePath.startsWith('blob:') || audioFilePath.startsWith('data:')) {
          print('[TranscriptionService] Processing web audio data (blob/data URL)');
          
          // Fetch blob data without blocking UI
          Uint8List bytes;
          try {
            bytes = await _fetchAudioBlobAsync(audioFilePath);
          } catch (e) {
            throw Exception('Failed to fetch audio blob: $e');
          }
          
          print('[TranscriptionService] Web audio data size: ${bytes.length} bytes');
          
          // Create multipart file from bytes
          audioMultipart = MultipartFile.fromBytes(
            bytes,
            filename: 'recording.webm', // Web recordings are typically WebM
          );
        } else {
          throw Exception('Invalid web audio data format');
        }
      } else {
        // For native platforms, validate file in background
        final isValid = await _validateAudioFileAsync(audioFilePath);
        if (!isValid) {
          throw Exception('Invalid audio file: $audioFilePath');
        }
        
        final audioFile = File(audioFilePath);
        final fileSize = await audioFile.length();
        print('[TranscriptionService] Native audio file size: $fileSize bytes');

        // Create multipart file from file
        audioMultipart = await MultipartFile.fromFile(
          audioFilePath,
          filename: audioFilePath.split('/').last,
        );
      }

      // Prepare multipart form data
      final formData = FormData.fromMap({
        'audio_file': audioMultipart,
        if (projectId != null) 'project_id': projectId,
        if (meetingTitle != null) 'meeting_title': meetingTitle,
        if (language != null) 'language': language,
        if (additionalMetadata != null) ...additionalMetadata,
        'timestamp': DateTime.now().toIso8601String(),
      });

      // Send request to transcription endpoint
      final response = await _dio.post(
        '/api/transcribe',
        data: formData,
        onSendProgress: (sent, total) {
          // Progress callback for large files
          // final progress = (sent / total * 100).toStringAsFixed(0);
          // Logger: Upload progress: $progress%
        },
      );

      if (response.statusCode == 200) {
        print('[TranscriptionService] Transcription successful, response: ${response.data}');
        final result = TranscriptionResult.fromJson(response.data);
        print('[TranscriptionService] Parsed transcription text: ${result.text}');
        return result;
      } else {
        throw Exception('Transcription failed: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout) {
        throw Exception('Connection timeout - server may be unavailable');
      } else if (e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Transcription is taking too long - try a shorter recording');
      } else if (e.response != null) {
        throw Exception('Server error: ${e.response?.data['error'] ?? e.message}');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Transcription error: $e');
    }
  }

  // Check transcription service health
  Future<bool> checkServiceHealth() async {
    try {
      final response = await _dio.get('/health');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Get supported languages
  Future<List<String>> getSupportedLanguages() async {
    try {
      final response = await _dio.get('/api/languages');
      if (response.statusCode == 200) {
        return List<String>.from(response.data['languages'] ?? ['en']);
      }
    } catch (e) {
      // Default to English if endpoint unavailable
    }
    return ['en'];
  }

  // Cancel ongoing transcription (if backend supports it)
  Future<void> cancelTranscription(String sessionId) async {
    try {
      await _dio.post('/api/transcribe/cancel', data: {
        'session_id': sessionId,
      });
    } catch (e) {
      // Ignore cancellation errors
    }
  }

  // Dispose resources
  // Async helper to fetch blob data without blocking UI
  Future<Uint8List> _fetchAudioBlobAsync(String audioPath) async {
    if (kIsWeb) {
      // For web, we can't use isolates, but we can use async properly
      final response = await http.get(Uri.parse(audioPath));
      if (response.statusCode != 200) {
        throw Exception('Failed to fetch audio blob: ${response.statusCode}');
      }
      return response.bodyBytes;
    } else {
      // For native platforms, use compute for heavy operations
      return await compute(_fetchAudioBlobInIsolate, audioPath);
    }
  }
  
  // Isolate function for fetching blob data (native platforms)
  static Future<Uint8List> _fetchAudioBlobInIsolate(String audioPath) async {
    final response = await http.get(Uri.parse(audioPath));
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch audio blob: ${response.statusCode}');
    }
    return response.bodyBytes;
  }
  
  // Async helper to validate audio file without blocking UI
  Future<bool> _validateAudioFileAsync(String filePath) async {
    if (kIsWeb) {
      return true; // Skip validation on web
    }
    return await compute(_validateAudioFileInIsolate, filePath);
  }
  
  // Isolate function for file validation (native platforms)
  static bool _validateAudioFileInIsolate(String filePath) {
    final file = File(filePath);
    if (!file.existsSync()) {
      return false;
    }
    final fileSize = file.lengthSync();
    return fileSize > 0;
  }

  void dispose() {
    _dio.close();
  }
}