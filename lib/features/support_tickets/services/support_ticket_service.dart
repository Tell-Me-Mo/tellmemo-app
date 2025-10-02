import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:pm_master_v2/features/support_tickets/models/support_ticket.dart';
import 'package:pm_master_v2/features/auth/data/repositories/auth_repository.dart';
import 'package:pm_master_v2/core/config/api_config.dart';

class SupportTicketService {
  final AuthRepository _authRepository;

  SupportTicketService({required AuthRepository authRepository})
      : _authRepository = authRepository;

  Future<Map<String, String>> _getHeaders() async {
    final session = _authRepository.currentSession;
    final token = session?.accessToken ?? '';
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  Future<SupportTicket> createTicket({
    required String title,
    required String description,
    required TicketType type,
    required TicketPriority priority,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/support-tickets/'),
        headers: headers,
        body: jsonEncode({
          'title': title,
          'description': description,
          'type': type.value,
          'priority': priority.value,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return SupportTicket.fromJson(data);
      } else {
        throw Exception('Failed to create ticket: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error creating ticket: $e');
    }
  }

  Future<List<SupportTicket>> getTickets({
    TicketStatus? status,
    TicketPriority? priority,
    TicketType? type,
    bool assignedToMe = false,
    bool createdByMe = false,
    String sortBy = 'created_at',
    String sortOrder = 'desc',
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final headers = await _getHeaders();
      final queryParams = <String, String>{
        if (status != null) 'status': status.value,
        if (priority != null) 'priority': priority.value,
        if (type != null) 'type': type.value,
        'assigned_to_me': assignedToMe.toString(),
        'created_by_me': createdByMe.toString(),
        'sort_by': sortBy,
        'sort_order': sortOrder,
        'limit': limit.toString(),
        'offset': offset.toString(),
      };

      final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/support-tickets/')
          .replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => SupportTicket.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load tickets: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error loading tickets: $e');
    }
  }

  Future<SupportTicket> getTicket(String ticketId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/support-tickets/$ticketId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return SupportTicket.fromJson(data);
      } else {
        throw Exception('Failed to load ticket: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error loading ticket: $e');
    }
  }

  Future<SupportTicket> updateTicket(
    String ticketId, {
    String? title,
    String? description,
    TicketType? type,
    TicketPriority? priority,
    TicketStatus? status,
    String? assignedTo,
    String? resolutionNotes,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = <String, dynamic>{};

      if (title != null) body['title'] = title;
      if (description != null) body['description'] = description;
      if (type != null) body['type'] = type.value;
      if (priority != null) body['priority'] = priority.value;
      if (status != null) body['status'] = status.value;
      if (assignedTo != null) body['assigned_to'] = assignedTo;
      if (resolutionNotes != null) body['resolution_notes'] = resolutionNotes;

      final response = await http.patch(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/support-tickets/$ticketId'),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return SupportTicket.fromJson(data);
      } else {
        throw Exception('Failed to update ticket: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error updating ticket: $e');
    }
  }

  Future<TicketComment> addComment(
    String ticketId, {
    required String comment,
    bool isInternal = false,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse(
            '${ApiConfig.baseUrl}/api/v1/support-tickets/$ticketId/comments'),
        headers: headers,
        body: jsonEncode({
          'comment': comment,
          'is_internal': isInternal,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return TicketComment.fromJson(data);
      } else {
        throw Exception('Failed to add comment: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error adding comment: $e');
    }
  }

  Future<List<TicketComment>> getComments(
    String ticketId, {
    bool includeInternal = false,
  }) async {
    try {
      final headers = await _getHeaders();
      final queryParams = {
        'include_internal': includeInternal.toString(),
      };

      final uri = Uri.parse(
              '${ApiConfig.baseUrl}/api/v1/support-tickets/$ticketId/comments')
          .replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => TicketComment.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load comments: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error loading comments: $e');
    }
  }

  Future<void> deleteTicket(String ticketId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/support-tickets/$ticketId'),
        headers: headers,
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete ticket: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error deleting ticket: $e');
    }
  }

  Future<Map<String, dynamic>> uploadAttachment(
    String ticketId, {
    String? filePath,
    List<int>? fileBytes,
    required String fileName,
    String? commentId,
  }) async {
    try {
      List<int> bytes;

      if (fileBytes != null) {
        // Use provided bytes (for web)
        bytes = fileBytes;
      } else if (filePath != null) {
        // Read from file path (for native)
        final file = File(filePath);
        if (!await file.exists()) {
          throw Exception('File not found: $filePath');
        }
        bytes = await file.readAsBytes();
      } else {
        throw Exception('Either filePath or fileBytes must be provided');
      }

      final mimeType = _getMimeType(fileName);

      final session = _authRepository.currentSession;
      final token = session?.accessToken ?? '';

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/api/v1/support-tickets/$ticketId/attachments'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      if (commentId != null) {
        request.fields['comment_id'] = commentId;
      }

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: fileName,
          contentType: MediaType.parse(mimeType),
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to upload attachment: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error uploading attachment: $e');
    }
  }

  Future<void> downloadAttachment(
    String ticketId,
    String attachmentId,
    String savePath,
  ) async {
    try {
      final headers = await _getHeaders();
      // Remove Content-Type header for download
      headers.remove('Content-Type');

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/support-tickets/$ticketId/attachments/$attachmentId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final file = File(savePath);
        await file.writeAsBytes(response.bodyBytes);
      } else {
        throw Exception('Failed to download attachment: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error downloading attachment: $e');
    }
  }

  String _getMimeType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return 'application/pdf';
      case 'doc':
      case 'docx':
        return 'application/msword';
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'gif':
        return 'image/gif';
      case 'txt':
        return 'text/plain';
      case 'csv':
        return 'text/csv';
      case 'xlsx':
      case 'xls':
        return 'application/vnd.ms-excel';
      default:
        return 'application/octet-stream';
    }
  }
}