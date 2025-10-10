import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/notification_service.dart';
import '../../data/models/summary_model.dart';
import 'web_download_stub.dart' if (dart.library.js_interop) 'web_download_web.dart' as web_download;

class SummaryExportService {
  static Future<Uint8List> generatePdf(SummaryModel summary) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('HH:mm');

    // Use system fonts that support Unicode
    final baseFont = await PdfGoogleFonts.notoSansRegular();
    final boldFont = await PdfGoogleFonts.notoSansBold();

    // Build PDF content
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        theme: pw.ThemeData.withFont(
          base: baseFont,
          bold: boldFont,
        ),
        build: (pw.Context context) {
          return [
            // Header
            pw.Container(
              padding: const pw.EdgeInsets.only(bottom: 20),
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(width: 2, color: PdfColors.grey300),
                ),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Type badge
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.purple100,
                      borderRadius: pw.BorderRadius.circular(12),
                    ),
                    child: pw.Text(
                      _getSummaryTypeLabel(summary.summaryType).toUpperCase(),
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.purple800,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 16),

                  // Title
                  pw.Text(
                    summary.subject,
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 8),

                  // Metadata
                  pw.Row(
                    children: [
                      pw.Text(
                        '${dateFormat.format(summary.createdAt)} at ${timeFormat.format(summary.createdAt)}',
                        style: const pw.TextStyle(
                          fontSize: 12,
                          color: PdfColors.grey700,
                        ),
                      ),
                      if (summary.createdBy != null) ...[
                        pw.Text(' • ', style: const pw.TextStyle(color: PdfColors.grey700)),
                        pw.Text(
                          summary.createdBy!,
                          style: const pw.TextStyle(
                            fontSize: 12,
                            color: PdfColors.grey700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Overview
            _buildSection('OVERVIEW', summary.body),

            // Key Points
            if (summary.keyPoints?.isNotEmpty ?? false) ...[
              pw.SizedBox(height: 20),
              _buildSection('KEY POINTS', null),
              ...summary.keyPoints!.map((point) => _buildBulletPoint(point)),
            ],

            // Risks & Blockers
            if ((summary.risks?.isNotEmpty ?? false) || (summary.blockers?.isNotEmpty ?? false)) ...[
              pw.SizedBox(height: 20),
              _buildSection('RISKS & BLOCKERS', null),
              ..._buildRisksAndBlockers(summary.risks, summary.blockers),
            ],

            // Action Items
            if (summary.actionItems?.isNotEmpty ?? false) ...[
              pw.SizedBox(height: 20),
              _buildSection('ACTION ITEMS', null),
              ...summary.actionItems!.map((item) => _buildActionItem(item)),
            ],

            // Decisions
            if (summary.decisions?.isNotEmpty ?? false) ...[
              pw.SizedBox(height: 20),
              _buildSection('DECISIONS', null),
              ...summary.decisions!.map((decision) => _buildDecision(decision)),
            ],

            // Next Meeting Agenda
            if (summary.nextMeetingAgenda?.isNotEmpty ?? false) ...[
              pw.SizedBox(height: 20),
              _buildSection('NEXT MEETING AGENDA', null),
              ...summary.nextMeetingAgenda!.map((item) => _buildAgendaItem(item)),
            ],

            // Lessons Learned
            if (summary.lessonsLearned?.isNotEmpty ?? false) ...[
              pw.SizedBox(height: 20),
              _buildSection('LESSONS LEARNED', null),
              ...summary.lessonsLearned!.map((lesson) => _buildLessonLearned(lesson)),
            ],

            // Open Questions
            if (summary.communicationInsights?.unansweredQuestions.isNotEmpty ?? false) ...[
              pw.SizedBox(height: 20),
              _buildSection('OPEN QUESTIONS', null),
              ...summary.communicationInsights!.unansweredQuestions.map((question) => _buildOpenQuestion(question)),
            ],
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildSection(String title, String? content) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey800,
          ),
        ),
        if (content != null) ...[
          pw.SizedBox(height: 8),
          pw.Text(
            content,
            style: const pw.TextStyle(
              fontSize: 11,
              height: 1.5,
            ),
          ),
        ],
      ],
    );
  }

  static pw.Widget _buildBulletPoint(String text) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('- ', style: const pw.TextStyle(fontSize: 11)),
          pw.Expanded(
            child: pw.Text(
              text,
              style: const pw.TextStyle(fontSize: 11, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildActionItem(ActionItem item) {
    final buffer = StringBuffer();
    buffer.write(item.description);

    if (item.assignee != null || item.dueDate != null) {
      buffer.write(' (');
      if (item.assignee != null) {
        buffer.write(item.assignee);
      }
      if (item.assignee != null && item.dueDate != null) {
        buffer.write(' - ');
      }
      if (item.dueDate != null) {
        buffer.write('Due: ${item.dueDate}');
      }
      buffer.write(')');
    }

    return _buildBulletPoint(buffer.toString());
  }

  static pw.Widget _buildDecision(Decision decision) {
    final buffer = StringBuffer();
    buffer.write(decision.description);

    if (decision.rationale != null && decision.rationale!.isNotEmpty) {
      buffer.write('\n   - Rationale: ${decision.rationale}');
    }

    return _buildBulletPoint(buffer.toString());
  }

  static pw.Widget _buildAgendaItem(AgendaItem item) {
    final buffer = StringBuffer();
    buffer.write('${item.title}: ${item.description}');

    if (item.presenter != null) {
      buffer.write(' (${item.presenter})');
    }

    return _buildBulletPoint(buffer.toString());
  }

  static List<pw.Widget> _buildRisksAndBlockers(List<Map<String, dynamic>>? risks, List<Map<String, dynamic>>? blockers) {
    final widgets = <pw.Widget>[];
    final risksData = risks ?? [];
    final blockersData = blockers ?? [];

    for (final risk in risksData) {
      final description = risk['description'] ?? risk['title'] ?? 'Unknown risk';
      widgets.add(_buildBulletPoint('[RISK] $description'));
    }

    for (final blocker in blockersData) {
      final description = blocker['description'] ?? blocker['title'] ?? 'Unknown blocker';
      widgets.add(_buildBulletPoint('[BLOCKER] $description'));
    }

    return widgets;
  }

  static pw.Widget _buildLessonLearned(LessonLearned lesson) {
    final buffer = StringBuffer();
    buffer.write(lesson.title);

    if (lesson.description.isNotEmpty) {
      buffer.write('\n   - ${lesson.description}');
    }

    if (lesson.impact.isNotEmpty) {
      buffer.write('\n   - Impact: ${lesson.impact}');
    }

    if (lesson.recommendation != null && lesson.recommendation!.isNotEmpty) {
      buffer.write('\n   - Recommendation: ${lesson.recommendation}');
    }

    return _buildBulletPoint(buffer.toString());
  }

  static pw.Widget _buildOpenQuestion(UnansweredQuestion question) {
    final buffer = StringBuffer();
    buffer.write(question.question);

    if (question.context.isNotEmpty) {
      buffer.write('\n   - Context: ${question.context}');
    }

    if (question.raisedBy != null && question.raisedBy!.isNotEmpty) {
      buffer.write(' (Raised by: ${question.raisedBy})');
    }

    if (question.urgency.isNotEmpty) {
      buffer.write(' [${question.urgency.toUpperCase()}]');
    }

    return _buildBulletPoint(buffer.toString());
  }

  static String _getSummaryTypeLabel(SummaryType type) {
    switch (type) {
      case SummaryType.meeting:
        return 'Meeting';
      case SummaryType.project:
        return 'Project';
      case SummaryType.program:
        return 'Program';
      case SummaryType.portfolio:
        return 'Portfolio';
    }
  }

  // Export to DOCX file
  static Future<void> exportToDocx(BuildContext context, SummaryModel summary, WidgetRef ref) async {
    try {
      // Generate HTML content that can be opened in Word
      final htmlContent = _generateHtmlForDocx(summary);
      final bytes = utf8.encode(htmlContent);

      final dateFormat = DateFormat('yyyy-MM-dd');
      final fileName = '${summary.subject.replaceAll(' ', '_')}_${dateFormat.format(summary.createdAt)}.html';

      if (kIsWeb) {
        // For web, trigger download
        await _downloadFileWeb(bytes, fileName, 'text/html');
      } else {
        // For desktop/mobile, save to file
        final result = await FilePicker.platform.saveFile(
          dialogTitle: 'Save summary as Word document',
          fileName: fileName,
          type: FileType.custom,
          allowedExtensions: ['html'],
        );

        if (result != null) {
          final file = File(result);
          await file.writeAsBytes(bytes);

          if (context.mounted) {
            ref.read(notificationServiceProvider.notifier).showSuccess(
              'Document saved successfully',
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ref.read(notificationServiceProvider.notifier).showError(
          'Failed to export document: ${e.toString()}',
        );
      }
    }
  }

  // Export to JSON file
  static Future<void> exportToJson(BuildContext context, SummaryModel summary, WidgetRef ref) async {
    try {
      final jsonData = summary.toJson();
      final prettyJson = const JsonEncoder.withIndent('  ').convert(jsonData);
      final bytes = utf8.encode(prettyJson);

      final dateFormat = DateFormat('yyyy-MM-dd');
      final fileName = '${summary.subject.replaceAll(' ', '_')}_${dateFormat.format(summary.createdAt)}.json';

      if (kIsWeb) {
        // For web, trigger download
        await _downloadFileWeb(bytes, fileName, 'application/json');
      } else {
        // For desktop/mobile, save to file
        final result = await FilePicker.platform.saveFile(
          dialogTitle: 'Save summary as JSON',
          fileName: fileName,
          type: FileType.custom,
          allowedExtensions: ['json'],
        );

        if (result != null) {
          final file = File(result);
          await file.writeAsBytes(bytes);

          if (context.mounted) {
            ref.read(notificationServiceProvider.notifier).showSuccess(
              'JSON file saved successfully',
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ref.read(notificationServiceProvider.notifier).showError(
          'Failed to export JSON: ${e.toString()}',
        );
      }
    }
  }

  // Export to Markdown file
  static Future<void> exportToMarkdown(BuildContext context, SummaryModel summary, WidgetRef ref) async {
    try {
      final markdownContent = _generateMarkdown(summary);
      final bytes = utf8.encode(markdownContent);

      final dateFormat = DateFormat('yyyy-MM-dd');
      final fileName = '${summary.subject.replaceAll(' ', '_')}_${dateFormat.format(summary.createdAt)}.md';

      if (kIsWeb) {
        // For web, trigger download
        await _downloadFileWeb(bytes, fileName, 'text/markdown');
      } else {
        // For desktop/mobile, save to file
        final result = await FilePicker.platform.saveFile(
          dialogTitle: 'Save summary as Markdown',
          fileName: fileName,
          type: FileType.custom,
          allowedExtensions: ['md'],
        );

        if (result != null) {
          final file = File(result);
          await file.writeAsBytes(bytes);

          if (context.mounted) {
            ref.read(notificationServiceProvider.notifier).showSuccess(
              'Markdown file saved successfully',
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ref.read(notificationServiceProvider.notifier).showError(
          'Failed to export Markdown: ${e.toString()}',
        );
      }
    }
  }

  // Export to PDF file
  static Future<void> exportToPdf(BuildContext context, SummaryModel summary, WidgetRef ref) async {
    try {
      final pdfBytes = await generatePdf(summary);
      final dateFormat = DateFormat('yyyy-MM-dd');
      final fileName = '${summary.subject.replaceAll(' ', '_')}_${dateFormat.format(summary.createdAt)}.pdf';

      if (kIsWeb) {
        // For web, trigger direct download
        await _downloadFileWeb(pdfBytes, fileName, 'application/pdf');
      } else {
        // For desktop/mobile, save to file
        final result = await FilePicker.platform.saveFile(
          dialogTitle: 'Save summary as PDF',
          fileName: fileName,
          type: FileType.custom,
          allowedExtensions: ['pdf'],
        );

        if (result != null) {
          final file = File(result);
          await file.writeAsBytes(pdfBytes);

          if (context.mounted) {
            ref.read(notificationServiceProvider.notifier).showSuccess(
              'PDF saved successfully',
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ref.read(notificationServiceProvider.notifier).showError(
          'Failed to export PDF: ${e.toString()}',
        );
      }
    }
  }

  // Share functionality
  static Future<void> shareSummary(BuildContext context, SummaryModel summary, WidgetRef ref) async {
    try{
      // Generate a text version for sharing
      final buffer = StringBuffer();
      final dateFormat = DateFormat('MMM dd, yyyy');

      buffer.writeln(summary.subject);
      buffer.writeln('Date: ${dateFormat.format(summary.createdAt)}');
      buffer.writeln();
      buffer.writeln('SUMMARY:');
      buffer.writeln(summary.body);
      buffer.writeln();

      if (summary.keyPoints?.isNotEmpty ?? false) {
        buffer.writeln('KEY POINTS:');
        for (final point in summary.keyPoints!) {
          buffer.writeln('- $point');
        }
        buffer.writeln();
      }

      if (summary.actionItems?.isNotEmpty ?? false) {
        buffer.writeln('ACTION ITEMS:');
        for (final item in summary.actionItems!) {
          buffer.write('- ${item.description}');
          if (item.assignee != null) {
            buffer.write(' (${item.assignee})');
          }
          buffer.writeln();
        }
        buffer.writeln();
      }

      if (summary.decisions?.isNotEmpty ?? false) {
        buffer.writeln('DECISIONS:');
        for (final decision in summary.decisions!) {
          buffer.writeln('- ${decision.description}');
        }
      }

      // Handle sharing based on platform
      if (kIsWeb) {
        // For web, share text directly
        await Share.share(
          buffer.toString(),
          subject: summary.subject,
        );
      } else {
        // For mobile and desktop platforms, try to share PDF if possible
        try {
          final pdfData = await generatePdf(summary);
          final tempDir = await getTemporaryDirectory();
          final file = File('${tempDir.path}/summary_${DateTime.now().millisecondsSinceEpoch}.pdf');
          await file.writeAsBytes(pdfData);

          await Share.shareXFiles(
            [XFile(file.path)],
            text: 'Summary: ${summary.subject}',
            subject: summary.subject,
          );
        } catch (_) {
          // Fallback to text sharing if PDF generation fails
          await Share.share(
            buffer.toString(),
            subject: summary.subject,
          );
        }
      }

      if (context.mounted) {
        ref.read(notificationServiceProvider.notifier).showSuccess(
          'Summary shared successfully',
        );
      }
    } catch (e) {
      if (context.mounted) {
        ref.read(notificationServiceProvider.notifier).showError(
          'Failed to share summary: $e',
        );
      }
    }
  }

  // Helper method to generate HTML for DOCX export
  static String _generateHtmlForDocx(SummaryModel summary) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('HH:mm');

    final buffer = StringBuffer();
    buffer.writeln('<!DOCTYPE html>');
    buffer.writeln('<html>');
    buffer.writeln('<head>');
    buffer.writeln('<meta charset="UTF-8">');
    buffer.writeln('<title>${summary.subject}</title>');
    buffer.writeln('<style>');
    buffer.writeln('body { font-family: Arial, sans-serif; line-height: 1.6; margin: 40px; }');
    buffer.writeln('h1 { color: #333; border-bottom: 2px solid #ddd; padding-bottom: 10px; }');
    buffer.writeln('h2 { color: #555; margin-top: 30px; }');
    buffer.writeln('.metadata { color: #666; font-size: 14px; margin-bottom: 20px; }');
    buffer.writeln('.type-badge { background: #e3f2fd; color: #1976d2; padding: 4px 12px; border-radius: 12px; display: inline-block; font-size: 12px; font-weight: bold; }');
    buffer.writeln('ul { margin-left: 20px; }');
    buffer.writeln('li { margin: 8px 0; }');
    buffer.writeln('.risk { color: #d32f2f; font-weight: bold; }');
    buffer.writeln('.blocker { color: #f57c00; font-weight: bold; }');
    buffer.writeln('</style>');
    buffer.writeln('</head>');
    buffer.writeln('<body>');

    // Header
    buffer.writeln('<div class="type-badge">${_getSummaryTypeLabel(summary.summaryType).toUpperCase()}</div>');
    buffer.writeln('<h1>${summary.subject}</h1>');
    buffer.writeln('<div class="metadata">');
    buffer.writeln('Date: ${dateFormat.format(summary.createdAt)} at ${timeFormat.format(summary.createdAt)}');
    if (summary.createdBy != null) {
      buffer.writeln(' • Created by: ${summary.createdBy}');
    }
    buffer.writeln('</div>');

    // Overview
    buffer.writeln('<h2>Overview</h2>');
    buffer.writeln('<p>${summary.body.replaceAll('\n', '<br>')}</p>');

    // Key Points
    if (summary.keyPoints?.isNotEmpty ?? false) {
      buffer.writeln('<h2>Key Points</h2>');
      buffer.writeln('<ul>');
      for (final point in summary.keyPoints!) {
        buffer.writeln('<li>$point</li>');
      }
      buffer.writeln('</ul>');
    }

    // Risks & Blockers
    if ((summary.risks?.isNotEmpty ?? false) || (summary.blockers?.isNotEmpty ?? false)) {
      buffer.writeln('<h2>Risks & Blockers</h2>');
      buffer.writeln('<ul>');
      for (final risk in summary.risks ?? []) {
        final description = risk['description'] ?? risk['title'] ?? 'Unknown risk';
        buffer.writeln('<li><span class="risk">[RISK]</span> $description</li>');
      }
      for (final blocker in summary.blockers ?? []) {
        final description = blocker['description'] ?? blocker['title'] ?? 'Unknown blocker';
        buffer.writeln('<li><span class="blocker">[BLOCKER]</span> $description</li>');
      }
      buffer.writeln('</ul>');
    }

    // Action Items
    if (summary.actionItems?.isNotEmpty ?? false) {
      buffer.writeln('<h2>Action Items</h2>');
      buffer.writeln('<ul>');
      for (final item in summary.actionItems!) {
        buffer.write('<li>${item.description}');
        if (item.assignee != null || item.dueDate != null) {
          buffer.write(' (');
          if (item.assignee != null) buffer.write(item.assignee);
          if (item.assignee != null && item.dueDate != null) buffer.write(' - ');
          if (item.dueDate != null) buffer.write('Due: ${item.dueDate}');
          buffer.write(')');
        }
        buffer.writeln('</li>');
      }
      buffer.writeln('</ul>');
    }

    // Decisions
    if (summary.decisions?.isNotEmpty ?? false) {
      buffer.writeln('<h2>Decisions</h2>');
      buffer.writeln('<ul>');
      for (final decision in summary.decisions!) {
        buffer.writeln('<li>${decision.description}');
        if (decision.rationale != null && decision.rationale!.isNotEmpty) {
          buffer.writeln('<br><em>Rationale: ${decision.rationale}</em>');
        }
        buffer.writeln('</li>');
      }
      buffer.writeln('</ul>');
    }

    // Next Meeting Agenda
    if (summary.nextMeetingAgenda?.isNotEmpty ?? false) {
      buffer.writeln('<h2>Next Meeting Agenda</h2>');
      buffer.writeln('<ul>');
      for (final item in summary.nextMeetingAgenda!) {
        buffer.write('<li><strong>${item.title}:</strong> ${item.description}');
        if (item.presenter != null) {
          buffer.write(' (Presenter: ${item.presenter})');
        }
        buffer.writeln('</li>');
      }
      buffer.writeln('</ul>');
    }

    // Lessons Learned
    if (summary.lessonsLearned?.isNotEmpty ?? false) {
      buffer.writeln('<h2>Lessons Learned</h2>');
      buffer.writeln('<ul>');
      for (final lesson in summary.lessonsLearned!) {
        buffer.writeln('<li><strong>${lesson.title}</strong>');
        if (lesson.description.isNotEmpty) {
          buffer.writeln('<br>${lesson.description}');
        }
        if (lesson.impact.isNotEmpty) {
          buffer.writeln('<br><em>Impact: ${lesson.impact}</em>');
        }
        if (lesson.recommendation != null && lesson.recommendation!.isNotEmpty) {
          buffer.writeln('<br><em>Recommendation: ${lesson.recommendation}</em>');
        }
        buffer.writeln('</li>');
      }
      buffer.writeln('</ul>');
    }

    // Open Questions
    if (summary.communicationInsights?.unansweredQuestions.isNotEmpty ?? false) {
      buffer.writeln('<h2>Open Questions</h2>');
      buffer.writeln('<ul>');
      for (final question in summary.communicationInsights!.unansweredQuestions) {
        buffer.write('<li>${question.question}');
        if (question.context.isNotEmpty) {
          buffer.write('<br><em>Context: ${question.context}</em>');
        }
        if (question.raisedBy != null && question.raisedBy!.isNotEmpty) {
          buffer.write(' (Raised by: ${question.raisedBy})');
        }
        if (question.urgency.isNotEmpty) {
          buffer.write(' <strong>[${question.urgency.toUpperCase()}]</strong>');
        }
        buffer.writeln('</li>');
      }
      buffer.writeln('</ul>');
    }

    buffer.writeln('</body>');
    buffer.writeln('</html>');

    return buffer.toString();
  }

  // Helper method to generate Markdown content
  static String _generateMarkdown(SummaryModel summary) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('HH:mm');

    final buffer = StringBuffer();

    // Header
    buffer.writeln('# ${summary.subject}');
    buffer.writeln();
    buffer.writeln('**Type:** ${_getSummaryTypeLabel(summary.summaryType)}');
    buffer.writeln('**Date:** ${dateFormat.format(summary.createdAt)} at ${timeFormat.format(summary.createdAt)}');
    if (summary.createdBy != null) {
      buffer.writeln('**Created by:** ${summary.createdBy}');
    }
    buffer.writeln();
    buffer.writeln('---');
    buffer.writeln();

    // Overview
    buffer.writeln('## Overview');
    buffer.writeln();
    buffer.writeln(summary.body);
    buffer.writeln();

    // Key Points
    if (summary.keyPoints?.isNotEmpty ?? false) {
      buffer.writeln('## Key Points');
      buffer.writeln();
      for (final point in summary.keyPoints!) {
        buffer.writeln('- $point');
      }
      buffer.writeln();
    }

    // Risks & Blockers
    if ((summary.risks?.isNotEmpty ?? false) || (summary.blockers?.isNotEmpty ?? false)) {
      buffer.writeln('## Risks & Blockers');
      buffer.writeln();
      for (final risk in summary.risks ?? []) {
        final description = risk['description'] ?? risk['title'] ?? 'Unknown risk';
        buffer.writeln('- **[RISK]** $description');
      }
      for (final blocker in summary.blockers ?? []) {
        final description = blocker['description'] ?? blocker['title'] ?? 'Unknown blocker';
        buffer.writeln('- **[BLOCKER]** $description');
      }
      buffer.writeln();
    }

    // Action Items
    if (summary.actionItems?.isNotEmpty ?? false) {
      buffer.writeln('## Action Items');
      buffer.writeln();
      for (final item in summary.actionItems!) {
        buffer.write('- [ ] ${item.description}');
        if (item.assignee != null || item.dueDate != null) {
          buffer.write(' (');
          if (item.assignee != null) buffer.write(item.assignee);
          if (item.assignee != null && item.dueDate != null) buffer.write(' - ');
          if (item.dueDate != null) buffer.write('Due: ${item.dueDate}');
          buffer.write(')');
        }
        buffer.writeln();
      }
      buffer.writeln();
    }

    // Decisions
    if (summary.decisions?.isNotEmpty ?? false) {
      buffer.writeln('## Decisions');
      buffer.writeln();
      for (final decision in summary.decisions!) {
        buffer.writeln('- ${decision.description}');
        if (decision.rationale != null && decision.rationale!.isNotEmpty) {
          buffer.writeln('  - *Rationale: ${decision.rationale}*');
        }
      }
      buffer.writeln();
    }

    // Next Meeting Agenda
    if (summary.nextMeetingAgenda?.isNotEmpty ?? false) {
      buffer.writeln('## Next Meeting Agenda');
      buffer.writeln();
      for (final item in summary.nextMeetingAgenda!) {
        buffer.write('- **${item.title}:** ${item.description}');
        if (item.presenter != null) {
          buffer.write(' (Presenter: ${item.presenter})');
        }
        buffer.writeln();
      }
      buffer.writeln();
    }

    // Lessons Learned
    if (summary.lessonsLearned?.isNotEmpty ?? false) {
      buffer.writeln('## Lessons Learned');
      buffer.writeln();
      for (final lesson in summary.lessonsLearned!) {
        buffer.writeln('- **${lesson.title}**');
        if (lesson.description.isNotEmpty) {
          buffer.writeln('  - ${lesson.description}');
        }
        if (lesson.impact.isNotEmpty) {
          buffer.writeln('  - *Impact:* ${lesson.impact}');
        }
        if (lesson.recommendation != null && lesson.recommendation!.isNotEmpty) {
          buffer.writeln('  - *Recommendation:* ${lesson.recommendation}');
        }
      }
      buffer.writeln();
    }

    // Open Questions
    if (summary.communicationInsights?.unansweredQuestions.isNotEmpty ?? false) {
      buffer.writeln('## Open Questions');
      buffer.writeln();
      for (final question in summary.communicationInsights!.unansweredQuestions) {
        buffer.write('- ${question.question}');
        if (question.raisedBy != null && question.raisedBy!.isNotEmpty) {
          buffer.write(' *(Raised by: ${question.raisedBy})*');
        }
        if (question.urgency.isNotEmpty) {
          buffer.write(' **[${question.urgency.toUpperCase()}]**');
        }
        buffer.writeln();
        if (question.context.isNotEmpty) {
          buffer.writeln('  - *Context:* ${question.context}');
        }
      }
      buffer.writeln();
    }

    buffer.writeln('---');
    buffer.writeln();
    buffer.writeln('*Generated on ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}*');

    return buffer.toString();
  }

  // Helper method for web file downloads
  static Future<void> _downloadFileWeb(Uint8List bytes, String fileName, String mimeType) async {
    if (kIsWeb) {
      await web_download.downloadFileWeb(bytes, fileName, mimeType);
    }
  }
}