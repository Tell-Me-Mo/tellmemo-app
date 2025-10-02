import 'package:flutter/material.dart';
import '../../../../core/widgets/breadcrumb_navigation.dart';
import '../../data/models/summary_model.dart';
import 'summary_detail_viewer.dart';
import 'executive_summary_viewer.dart';
import 'technical_summary_viewer.dart';
import 'stakeholder_summary_viewer.dart';

class FormatAwareSummaryViewer extends StatelessWidget {
  final SummaryModel summary;
  final VoidCallback? onExport;
  final VoidCallback? onCopy;
  final VoidCallback? onBack;
  final String format;
  final List<BreadcrumbItem>? breadcrumbs;

  const FormatAwareSummaryViewer({
    super.key,
    required this.summary,
    required this.format,
    this.onExport,
    this.onCopy,
    this.onBack,
    this.breadcrumbs,
  });

  @override
  Widget build(BuildContext context) {
    // Select the appropriate viewer based on format
    switch (format.toLowerCase()) {
      case 'executive':
        return ExecutiveSummaryViewer(
          summary: summary,
          onExport: onExport,
          onCopy: onCopy,
          onBack: onBack,
          breadcrumbs: breadcrumbs,
        );
      case 'technical':
        return TechnicalSummaryViewer(
          summary: summary,
          onExport: onExport,
          onCopy: onCopy,
          onBack: onBack,
          breadcrumbs: breadcrumbs,
        );
      case 'stakeholder':
        return StakeholderSummaryViewer(
          summary: summary,
          onExport: onExport,
          onCopy: onCopy,
          onBack: onBack,
          breadcrumbs: breadcrumbs,
        );
      case 'general':
      default:
        // Use the existing detailed viewer for general format
        return SummaryDetailViewer(
          summary: summary,
          onExport: onExport,
          onCopy: onCopy,
          onBack: onBack,
          breadcrumbs: breadcrumbs,
        );
    }
  }
}