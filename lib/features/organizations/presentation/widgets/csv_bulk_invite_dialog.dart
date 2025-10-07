import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pm_master_v2/core/constants/validation_constants.dart';
import 'package:pm_master_v2/features/organizations/presentation/providers/organization_provider.dart';
import 'dart:io';

class CsvBulkInviteDialog extends ConsumerStatefulWidget {
  final String organizationId;

  const CsvBulkInviteDialog({
    super.key,
    required this.organizationId,
  });

  @override
  ConsumerState<CsvBulkInviteDialog> createState() => _CsvBulkInviteDialogState();
}

class _CsvBulkInviteDialogState extends ConsumerState<CsvBulkInviteDialog> {
  final List<BulkInviteEntry> _entries = [];
  bool _isLoading = false;
  bool _isProcessing = false;
  String? _errorMessage;
  String _defaultRole = 'member';
  int _successCount = 0;
  int _failureCount = 0;
  final Map<String, String> _failureReasons = {};

  Future<void> _pickCsvFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'txt'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _isLoading = true;
          _errorMessage = null;
        });

        final file = File(result.files.single.path!);
        final contents = await file.readAsString();
        _parseCsvContent(contents);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to read file: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _parseCsvContent(String content) {
    try {
      _entries.clear();
      final lines = content.split('\n').where((line) => line.trim().isNotEmpty).toList();

      if (lines.isEmpty) {
        setState(() {
          _errorMessage = 'CSV file is empty';
          _isLoading = false;
        });
        return;
      }

      // Check if first line is header
      final firstLine = lines[0].toLowerCase();
      final hasHeader = firstLine.contains('email') || firstLine.contains('role') || firstLine.contains('name');
      final startIndex = hasHeader ? 1 : 0;

      for (int i = startIndex; i < lines.length; i++) {
        final parts = _parseCsvLine(lines[i]);
        if (parts.isEmpty) continue;

        String email = parts[0].trim();
        String? name = parts.length > 1 ? parts[1].trim() : null;
        String role = parts.length > 2 ? parts[2].trim().toLowerCase() : _defaultRole;

        // Validate email
        if (email.isNotEmpty && FormValidators.validateEmail(email) == null) {
          // Validate role
          if (!['admin', 'member', 'viewer'].contains(role)) {
            role = _defaultRole;
          }

          // Check for duplicates
          if (!_entries.any((e) => e.email == email)) {
            _entries.add(BulkInviteEntry(
              email: email,
              name: name?.isNotEmpty == true ? name : null,
              role: role,
            ));
          }
        }
      }

      setState(() {
        _isLoading = false;
        if (_entries.isEmpty) {
          _errorMessage = 'No valid email addresses found in the CSV file';
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to parse CSV: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  List<String> _parseCsvLine(String line) {
    final List<String> result = [];
    bool inQuotes = false;
    StringBuffer current = StringBuffer();

    for (int i = 0; i < line.length; i++) {
      final char = line[i];

      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == ',' && !inQuotes) {
        result.add(current.toString());
        current.clear();
      } else {
        current.write(char);
      }
    }

    if (current.isNotEmpty) {
      result.add(current.toString());
    }

    return result;
  }

  Future<void> _sendBulkInvitations() async {
    if (_entries.isEmpty) return;

    setState(() {
      _isProcessing = true;
      _successCount = 0;
      _failureCount = 0;
      _failureReasons.clear();
    });

    final apiService = ref.read(organizationApiServiceProvider);

    for (final entry in _entries) {
      try {
        await apiService.inviteToOrganization(
          widget.organizationId,
          {
            'email': entry.email,
            'role': entry.role,
            'name': entry.name,
          },
        );
        setState(() {
          _successCount++;
        });
      } catch (e) {
        setState(() {
          _failureCount++;
          _failureReasons[entry.email] = e.toString();
        });
      }
    }

    if (mounted) {
      setState(() {
        _isProcessing = false;
      });

      if (_successCount > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully sent $_successCount invitation${_successCount == 1 ? '' : 's'}'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      if (_failureCount == 0) {
        Navigator.of(context).pop();
      }
    }
  }

  void _downloadTemplate() {
    const template = 'email,name,role\nexample@company.com,John Doe,member\nmanager@company.com,Jane Smith,admin\nviewer@company.com,Bob Johnson,viewer';
    Clipboard.setData(const ClipboardData(text: template));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('CSV template copied to clipboard'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.upload_file,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Bulk Invite via CSV',
                    style: theme.textTheme.headlineSmall,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Instructions
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'CSV Format',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Upload a CSV file with columns: email, name (optional), role (optional)\n'
                      'Roles can be: admin, member, or viewer (default: member)',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: _downloadTemplate,
                      icon: const Icon(Icons.download, size: 16),
                      label: const Text('Copy Template to Clipboard'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // File picker or entries list
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 300, minHeight: 200),
                child: _entries.isEmpty && !_isLoading
                    ? _buildUploadArea(theme)
                    : _isLoading
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        : _buildEntriesList(theme),
              ),

              // Error message
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: theme.colorScheme.onErrorContainer,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: theme.colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Progress indicator
              if (_isProcessing) ...[
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: _entries.isEmpty
                      ? 0
                      : (_successCount + _failureCount) / _entries.length,
                ),
                const SizedBox(height: 8),
                Text(
                  'Sending invitations... ($_successCount/${_entries.length})',
                  style: theme.textTheme.bodySmall,
                ),
              ],

              const SizedBox(height: 16),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isProcessing ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _entries.isNotEmpty && !_isProcessing
                        ? _sendBulkInvitations
                        : null,
                    icon: _isProcessing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                    label: Text(
                      _isProcessing
                          ? 'Sending...'
                          : 'Send ${_entries.length} Invitation${_entries.length == 1 ? '' : 's'}',
                    ),
                  ),
                ],
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUploadArea(ThemeData theme) {
    return InkWell(
      onTap: _pickCsvFile,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          border: Border.all(
            color: theme.colorScheme.outline,
            width: 2,
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_upload,
              size: 48,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Click to upload CSV file',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'or drag and drop',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEntriesList(ThemeData theme) {
    return Column(
      children: [
        // Default role selector
        Row(
          children: [
            Text(
              'Default Role:',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(width: 16),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'admin',
                  label: Text('Admin'),
                ),
                ButtonSegment(
                  value: 'member',
                  label: Text('Member'),
                ),
                ButtonSegment(
                  value: 'viewer',
                  label: Text('Viewer'),
                ),
              ],
              selected: {_defaultRole},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() {
                  _defaultRole = newSelection.first;
                  // Update entries without explicit role
                  for (var entry in _entries) {
                    if (entry.role == 'member') {
                      entry.role = _defaultRole;
                    }
                  }
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Entries list
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: theme.dividerColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainer,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
                  ),
                  child: Row(
                    children: [
                      Text(
                        '${_entries.length} invitation${_entries.length == 1 ? '' : 's'} to send',
                        style: theme.textTheme.titleSmall,
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _entries.clear();
                          });
                        },
                        child: const Text('Clear All'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _entries.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final entry = _entries[index];
                      final hasError = _failureReasons.containsKey(entry.email);

                      return ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor: hasError
                              ? Colors.red.withValues(alpha: 0.1)
                              : theme.colorScheme.primaryContainer,
                          child: Text(
                            entry.email[0].toUpperCase(),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: hasError
                                  ? Colors.red
                                  : theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                        title: Text(
                          entry.email,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: hasError ? Colors.red : null,
                          ),
                        ),
                        subtitle: hasError
                            ? Text(
                                _failureReasons[entry.email] ?? 'Failed',
                                style: TextStyle(
                                  color: Colors.red.shade700,
                                  fontSize: 12,
                                ),
                              )
                            : entry.name != null
                                ? Text(
                                    entry.name!,
                                    style: theme.textTheme.bodySmall,
                                  )
                                : null,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Chip(
                              label: Text(
                                entry.role.toUpperCase(),
                                style: const TextStyle(fontSize: 11),
                              ),
                              visualDensity: VisualDensity.compact,
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () {
                                setState(() {
                                  _entries.removeAt(index);
                                });
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class BulkInviteEntry {
  String email;
  String? name;
  String role;

  BulkInviteEntry({
    required this.email,
    this.name,
    required this.role,
  });
}
