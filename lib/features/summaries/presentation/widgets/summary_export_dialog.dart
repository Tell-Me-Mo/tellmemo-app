import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/notification_service.dart';
import '../../data/models/summary_model.dart';
import '../../domain/services/summary_export_service.dart';

enum ExportFormat { pdf, docx, json, markdown }

class SummaryExportDialog extends ConsumerStatefulWidget {
  final SummaryModel summary;

  const SummaryExportDialog({
    super.key,
    required this.summary,
  });

  @override
  ConsumerState<SummaryExportDialog> createState() => _SummaryExportDialogState();
}

class _SummaryExportDialogState extends ConsumerState<SummaryExportDialog> {
  ExportFormat _selectedFormat = ExportFormat.pdf;
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.download_outlined,
                  size: 28,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Export Summary',
                  style: theme.textTheme.headlineSmall,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Choose export format:',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            _buildFormatOption(
              context,
              format: ExportFormat.pdf,
              icon: Icons.picture_as_pdf,
              title: 'PDF Document',
              subtitle: 'Formatted document with all sections',
              color: Colors.red,
            ),
            const SizedBox(height: 8),
            _buildFormatOption(
              context,
              format: ExportFormat.docx,
              icon: Icons.description,
              title: 'Word Document (DOCX)',
              subtitle: 'Editable document for Microsoft Word',
              color: Colors.blue,
            ),
            const SizedBox(height: 8),
            _buildFormatOption(
              context,
              format: ExportFormat.json,
              icon: Icons.code,
              title: 'JSON',
              subtitle: 'Structured data for developers',
              color: Colors.orange,
            ),
            const SizedBox(height: 8),
            _buildFormatOption(
              context,
              format: ExportFormat.markdown,
              icon: Icons.text_snippet,
              title: 'Markdown',
              subtitle: 'Plain text with formatting',
              color: Colors.green,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isExporting
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: _isExporting ? null : _handleExport,
                  icon: _isExporting
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colorScheme.onPrimary,
                          ),
                        )
                      : const Icon(Icons.download, size: 16),
                  label: Text(_isExporting ? 'Exporting...' : 'Export'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormatOption(
    BuildContext context, {
    required ExportFormat format,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final isSelected = _selectedFormat == format;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isExporting
            ? null
            : () {
                setState(() {
                  _selectedFormat = format;
                });
              },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline.withOpacity(0.3),
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
            color: isSelected
                ? theme.colorScheme.primary.withOpacity(0.05)
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Radio<ExportFormat>(
                value: format,
                groupValue: _selectedFormat,
                onChanged: _isExporting
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() {
                            _selectedFormat = value;
                          });
                        }
                      },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleExport() async {
    setState(() {
      _isExporting = true;
    });

    try {
      switch (_selectedFormat) {
        case ExportFormat.pdf:
          await SummaryExportService.exportToPdf(context, widget.summary, ref);
          break;
        case ExportFormat.docx:
          await SummaryExportService.exportToDocx(context, widget.summary, ref);
          break;
        case ExportFormat.json:
          await SummaryExportService.exportToJson(context, widget.summary, ref);
          break;
        case ExportFormat.markdown:
          await SummaryExportService.exportToMarkdown(context, widget.summary, ref);
          break;
      }

      if (mounted) {
        Navigator.of(context).pop();
        ref.read(notificationServiceProvider.notifier).showSuccess(
          'Summary exported as ${_getFormatName(_selectedFormat)} successfully',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
        ref.read(notificationServiceProvider.notifier).showError(
          'Export failed: ${e.toString()}',
        );
      }
    }
  }

  String _getFormatName(ExportFormat format) {
    switch (format) {
      case ExportFormat.pdf:
        return 'PDF';
      case ExportFormat.docx:
        return 'Word Document';
      case ExportFormat.json:
        return 'JSON';
      case ExportFormat.markdown:
        return 'Markdown';
    }
  }
}