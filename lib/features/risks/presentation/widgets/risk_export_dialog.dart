import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RiskExportDialog extends ConsumerStatefulWidget {
  final String format;
  final VoidCallback onExport;

  const RiskExportDialog({
    super.key,
    required this.format,
    required this.onExport,
  });

  @override
  ConsumerState<RiskExportDialog> createState() => _RiskExportDialogState();
}

class _RiskExportDialogState extends ConsumerState<RiskExportDialog> {
  bool _includeResolved = true;
  bool _includeDetails = true;
  bool _includeCharts = false;
  String _dateRange = 'all';
  String _groupBy = 'none';
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    String title;
    IconData icon;
    switch (widget.format) {
      case 'pdf':
        title = 'Export to PDF';
        icon = Icons.picture_as_pdf;
        break;
      case 'report':
        title = 'Generate Report';
        icon = Icons.description;
        break;
      default:
        title = 'Export Data';
        icon = Icons.download;
    }

    return AlertDialog(
      title: Row(
        children: [
          Icon(icon, size: 24),
          const SizedBox(width: 8),
          Text(title),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Export Options Section
            Text(
              'Export Options',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),

            // Include Resolved Risks
            CheckboxListTile(
              title: const Text('Include Resolved Risks'),
              subtitle: const Text('Export risks with resolved status'),
              value: _includeResolved,
              onChanged: (value) {
                setState(() {
                  _includeResolved = value ?? true;
                });
              },
              contentPadding: EdgeInsets.zero,
            ),

            // Include Detailed Information
            CheckboxListTile(
              title: const Text('Include Detailed Information'),
              subtitle: const Text('Export mitigation plans, impact analysis, etc.'),
              value: _includeDetails,
              onChanged: (value) {
                setState(() {
                  _includeDetails = value ?? true;
                });
              },
              contentPadding: EdgeInsets.zero,
            ),

            // Include Charts (PDF only)
            if (widget.format == 'pdf' || widget.format == 'report') ...[
              CheckboxListTile(
                title: const Text('Include Charts & Analytics'),
                subtitle: const Text('Add visual representations of risk data'),
                value: _includeCharts,
                onChanged: (value) {
                  setState(() {
                    _includeCharts = value ?? false;
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),
            ],

            const Divider(height: 24),

            // Date Range Section
            Text(
              'Date Range',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              value: _dateRange,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.date_range),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('All Time')),
                DropdownMenuItem(value: 'week', child: Text('Last Week')),
                DropdownMenuItem(value: 'month', child: Text('Last Month')),
                DropdownMenuItem(value: 'quarter', child: Text('Last Quarter')),
                DropdownMenuItem(value: 'year', child: Text('Last Year')),
              ],
              onChanged: (value) {
                setState(() {
                  _dateRange = value ?? 'all';
                });
              },
            ),

            const SizedBox(height: 16),

            // Group By Section
            Text(
              'Group By',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              value: _groupBy,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.view_module),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              items: const [
                DropdownMenuItem(value: 'none', child: Text('No Grouping')),
                DropdownMenuItem(value: 'project', child: Text('Project')),
                DropdownMenuItem(value: 'severity', child: Text('Severity')),
                DropdownMenuItem(value: 'status', child: Text('Status')),
                DropdownMenuItem(value: 'assigned', child: Text('Assignee')),
              ],
              onChanged: (value) {
                setState(() {
                  _groupBy = value ?? 'none';
                });
              },
            ),

            const SizedBox(height: 16),

            // File Format Info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getFormatDescription(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isExporting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _isExporting ? null : _performExport,
          icon: _isExporting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
              : const Icon(Icons.download, size: 18),
          label: Text(_isExporting ? 'Exporting...' : 'Export'),
        ),
      ],
    );
  }

  String _getFormatDescription() {
    switch (widget.format) {
      case 'pdf':
        return 'Export risks as a formatted PDF document with optional charts and analytics.';
      case 'report':
        return 'Generate a comprehensive risk assessment report including trends and recommendations.';
      default:
        return 'Export risk data in the selected format.';
    }
  }

  Future<void> _performExport() async {
    setState(() {
      _isExporting = true;
    });

    // Simulate export process
    await Future.delayed(const Duration(seconds: 2));

    widget.onExport();

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export completed successfully'),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'Open',
            textColor: Colors.white,
            onPressed: () {
              // Open exported file
            },
          ),
        ),
      );
    }
  }
}