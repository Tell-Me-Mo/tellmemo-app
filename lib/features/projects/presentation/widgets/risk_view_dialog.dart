import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/risk.dart';
import '../../domain/entities/project.dart';
import '../providers/risks_tasks_provider.dart';
import '../../../risks/presentation/screens/risks_aggregation_screen_v2.dart';
import '../../../queries/presentation/widgets/ask_ai_panel.dart';
import '../../../queries/presentation/providers/query_provider.dart';
import '../../../../core/services/notification_service.dart';

class RiskViewDialog extends ConsumerStatefulWidget {
  final String projectId;
  final Risk risk;
  final Project? project;

  const RiskViewDialog({
    super.key,
    required this.projectId,
    required this.risk,
    this.project,
  });

  @override
  ConsumerState<RiskViewDialog> createState() => _RiskViewDialogState();
}

class _RiskViewDialogState extends ConsumerState<RiskViewDialog> {
  late Risk _risk;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _risk = widget.risk;
  }

  DateTime _createTimezoneNaiveNow() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, now.hour, now.minute, now.second, now.millisecond);
  }

  Future<void> _markAsResolved() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final updatedRisk = _risk.copyWith(
        status: RiskStatus.resolved,
        lastUpdated: _createTimezoneNaiveNow(),
        updatedBy: 'current_user', // TODO: Get from auth
      );

      await ref.read(risksNotifierProvider(widget.projectId).notifier).updateRisk(updatedRisk);

      if (mounted) {
        setState(() {
          _risk = updatedRisk;
        });
        ref.read(notificationServiceProvider.notifier).showSuccess('Risk marked as resolved');
      }
    } catch (e) {
      if (mounted) {
        ref.read(notificationServiceProvider.notifier).showError('Failed to update risk: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _markAsMitigating() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final updatedRisk = _risk.copyWith(
        status: RiskStatus.mitigating,
        lastUpdated: _createTimezoneNaiveNow(),
        updatedBy: 'current_user', // TODO: Get from auth
      );

      await ref.read(risksNotifierProvider(widget.projectId).notifier).updateRisk(updatedRisk);

      if (mounted) {
        setState(() {
          _risk = updatedRisk;
        });
        ref.read(notificationServiceProvider.notifier).showSuccess('Risk marked as mitigating');
      }
    } catch (e) {
      if (mounted) {
        ref.read(notificationServiceProvider.notifier).showError('Failed to update risk: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _markAsIdentified() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final updatedRisk = _risk.copyWith(
        status: RiskStatus.identified,
        lastUpdated: _createTimezoneNaiveNow(),
        updatedBy: 'current_user', // TODO: Get from auth
      );

      await ref.read(risksNotifierProvider(widget.projectId).notifier).updateRisk(updatedRisk);

      if (mounted) {
        setState(() {
          _risk = updatedRisk;
        });
        ref.read(notificationServiceProvider.notifier).showSuccess('Risk marked as identified');
      }
    } catch (e) {
      if (mounted) {
        ref.read(notificationServiceProvider.notifier).showError('Failed to update risk: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _deleteRisk() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Risk'),
        content: const Text('Are you sure you want to delete this risk? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await ref.read(risksNotifierProvider(widget.projectId).notifier).deleteRisk(_risk.id);

      if (mounted) {
        Navigator.of(context).pop();
        ref.read(notificationServiceProvider.notifier).showSuccess('Risk deleted successfully');
      }
    } catch (e) {
      if (mounted) {
        ref.read(notificationServiceProvider.notifier).showError('Failed to delete risk: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _openEditDialog() {
    Navigator.of(context).pop(); // Close the view dialog first
    showDialog(
      context: context,
      builder: (context) => CreateRiskDialog(
        initialProjectId: widget.projectId,
        initialRisk: _risk,
        onCreated: () {
          // Refresh data after edit
        },
      ),
    );
  }

  String _buildRiskContext(Risk risk) {
    final buffer = StringBuffer();
    buffer.writeln('- Status: ${risk.statusLabel}');
    buffer.writeln('- Severity: ${risk.severityLabel}');
    buffer.writeln('- Description: ${risk.description}');
    if (risk.mitigation != null && risk.mitigation!.isNotEmpty) {
      buffer.writeln('- Mitigation: ${risk.mitigation}');
    }
    if (risk.impact != null && risk.impact!.isNotEmpty) {
      buffer.writeln('- Impact: ${risk.impact}');
    }
    if (risk.probability != null) {
      buffer.writeln('- Probability: ${(risk.probability! * 100).toStringAsFixed(0)}%');
    }
    if (risk.assignedTo != null && risk.assignedTo!.isNotEmpty) {
      buffer.writeln('- Assigned to: ${risk.assignedTo}');
    }
    return buffer.toString();
  }

  void _openAIDialog() {
    final riskContext = '''Context: Analyzing a risk in the project.
Risk Title: ${_risk.title}
${_buildRiskContext(_risk)}''';

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      transitionDuration: Duration.zero,
      pageBuilder: (context, animation, secondaryAnimation) {
        return AskAIPanel(
          projectId: widget.projectId,
          projectName: widget.project?.name ?? 'Project',
          contextInfo: riskContext,
          conversationId: 'risk_${_risk.id}',
          rightOffset: 0.0,
          onClose: () {
            Navigator.of(context).pop();
            ref.read(queryProvider.notifier).clearConversation();
          },
        );
      },
    );
  }

  Color _getStatusColor(RiskStatus status) {
    switch (status) {
      case RiskStatus.identified:
        return Colors.orange;
      case RiskStatus.mitigating:
        return Colors.blue;
      case RiskStatus.resolved:
        return Colors.green;
      case RiskStatus.accepted:
        return Colors.grey;
      case RiskStatus.escalated:
        return Colors.red;
    }
  }

  Color _getSeverityColor(RiskSeverity severity) {
    switch (severity) {
      case RiskSeverity.low:
        return Colors.green;
      case RiskSeverity.medium:
        return Colors.orange;
      case RiskSeverity.high:
        return Colors.red;
      case RiskSeverity.critical:
        return Colors.red.shade900;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Padding(
      padding: isMobile ? EdgeInsets.zero : const EdgeInsets.only(right: 100),
      child: Dialog(
        insetPadding: isMobile
            ? const EdgeInsets.symmetric(horizontal: 8, vertical: 24)
            : const EdgeInsets.symmetric(horizontal: 40.0, vertical: 24.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isMobile ? double.infinity : 600,
            maxHeight: MediaQuery.of(context).size.height * 0.9,
            minWidth: isMobile ? 0 : 400,
          ),
          child: IntrinsicHeight(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: EdgeInsets.all(isMobile ? 12 : 20),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning,
                        color: colorScheme.primary,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Risk Details',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (widget.project != null)
                              Text(
                                widget.project!.name,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                      ),
                      // Quick Status Buttons
                      if (_risk.status == RiskStatus.identified)
                        IconButton(
                          icon: const Icon(
                            Icons.engineering,
                            color: Colors.blue,
                          ),
                          onPressed: _isSaving ? null : _markAsMitigating,
                          tooltip: 'Start mitigating',
                        ),
                      if (_risk.status == RiskStatus.mitigating)
                        IconButton(
                          icon: const Icon(
                            Icons.check_circle_outline,
                            color: Colors.green,
                          ),
                          onPressed: _isSaving ? null : _markAsResolved,
                          tooltip: 'Mark as resolved',
                        ),
                      if (_risk.status == RiskStatus.resolved)
                        IconButton(
                          icon: const Icon(
                            Icons.refresh,
                            color: Colors.orange,
                          ),
                          onPressed: _isSaving ? null : _markAsIdentified,
                          tooltip: 'Reactivate risk',
                        ),

                      // More actions menu
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert),
                        tooltip: 'More actions',
                        offset: Offset(0, isMobile ? 40 : 45),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 8,
                        iconSize: isMobile ? 20 : 24,
                        onSelected: (value) {
                          switch (value) {
                            case 'edit':
                              _openEditDialog();
                              break;
                            case 'delete':
                              _deleteRisk();
                              break;
                          }
                        },
                        itemBuilder: (BuildContext context) => [
                          PopupMenuItem<String>(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit_outlined, size: 20, color: colorScheme.primary),
                                const SizedBox(width: 12),
                                const Text('Edit'),
                              ],
                            ),
                          ),
                          const PopupMenuDivider(),
                          const PopupMenuItem<String>(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                SizedBox(width: 12),
                                Text('Delete', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                      ),

                      if (!isMobile) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 1,
                          height: 24,
                          color: colorScheme.outline.withValues(alpha: 0.2),
                        ),
                        const SizedBox(width: 8),
                      ],

                      // AI Assistant button
                      IconButton(
                        onPressed: _openAIDialog,
                        icon: const Icon(Icons.auto_awesome),
                        tooltip: 'AI Assistant',
                        iconSize: isMobile ? 20 : 24,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.green.withValues(alpha: 0.1),
                          foregroundColor: Colors.green,
                        ),
                      ),

                      if (isMobile) const SizedBox(width: 8),

                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                        iconSize: isMobile ? 20 : 24,
                        padding: isMobile ? EdgeInsets.zero : null,
                        constraints: isMobile ? const BoxConstraints() : null,
                      ),
                    ],
                  ),
                ),

                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(isMobile ? 12 : 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          _risk.title,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        SizedBox(height: isMobile ? 16 : 20),

                        // Status and Severity Row
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Status',
                                    style: theme.textTheme.labelLarge,
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(_risk.status)
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: _getStatusColor(_risk.status),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 12,
                                          height: 12,
                                          decoration: BoxDecoration(
                                            color: _getStatusColor(_risk.status),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _risk.statusLabel,
                                          style: TextStyle(
                                            color: _getStatusColor(_risk.status),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: isMobile ? 12 : 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Severity',
                                    style: theme.textTheme.labelLarge,
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getSeverityColor(_risk.severity)
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.flag,
                                          size: 16,
                                          color: _getSeverityColor(_risk.severity),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _risk.severityLabel,
                                          style: TextStyle(
                                            color: _getSeverityColor(_risk.severity),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: isMobile ? 16 : 20),

                        // Description
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Description',
                              style: theme.textTheme.labelLarge,
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(_risk.description),
                            ),
                          ],
                        ),

                        // Mitigation
                        if (_risk.mitigation != null && _risk.mitigation!.isNotEmpty) ...[
                          SizedBox(height: isMobile ? 16 : 20),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Mitigation Strategy',
                                style: theme.textTheme.labelLarge,
                              ),
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(_risk.mitigation!),
                              ),
                            ],
                          ),
                        ],

                        // Impact
                        if (_risk.impact != null && _risk.impact!.isNotEmpty) ...[
                          SizedBox(height: isMobile ? 16 : 20),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Impact',
                                style: theme.textTheme.labelLarge,
                              ),
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(_risk.impact!),
                              ),
                            ],
                          ),
                        ],

                        // Probability
                        if (_risk.probability != null) ...[
                          SizedBox(height: isMobile ? 16 : 20),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Probability',
                                    style: theme.textTheme.labelLarge,
                                  ),
                                  Text(
                                    '${(_risk.probability! * 100).toStringAsFixed(0)}%',
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: _getSeverityColor(_risk.severity),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              LinearProgressIndicator(
                                value: _risk.probability!,
                                minHeight: 8,
                                borderRadius: BorderRadius.circular(4),
                                color: _getSeverityColor(_risk.severity),
                                backgroundColor: _getSeverityColor(_risk.severity).withValues(alpha: 0.2),
                              ),
                            ],
                          ),
                        ],

                        // Assignment
                        if (_risk.assignedTo != null || _risk.assignedToEmail != null) ...[
                          SizedBox(height: isMobile ? 16 : 20),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Assignment',
                                style: theme.textTheme.labelLarge,
                              ),
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (_risk.assignedTo != null) ...[
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.person,
                                            size: 16,
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(_risk.assignedTo!),
                                        ],
                                      ),
                                    ],
                                    if (_risk.assignedToEmail != null) ...[
                                      if (_risk.assignedTo != null)
                                        const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.email,
                                            size: 16,
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(_risk.assignedToEmail!),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],

                        // Metadata
                        SizedBox(height: isMobile ? 16 : 20),
                        const Divider(),
                        SizedBox(height: isMobile ? 16 : 20),

                        Text(
                          'Metadata',
                          style: theme.textTheme.labelLarge,
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 16,
                          runSpacing: 8,
                          children: [
                            if (_risk.identifiedDate != null)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.create,
                                    size: 14,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Identified: ${DateFormat('MMM d, y').format(_risk.identifiedDate!)}',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            if (_risk.lastUpdated != null)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.update,
                                    size: 14,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Updated: ${DateFormat('MMM d, y').format(_risk.lastUpdated!)}',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}