import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../projects/domain/entities/risk.dart';
import '../../../projects/domain/entities/project.dart';
import '../../../projects/presentation/providers/projects_provider.dart';
import '../../../projects/presentation/providers/risks_tasks_provider.dart';

class AggregatedRisk {
  final Risk risk;
  final Project project;

  const AggregatedRisk({
    required this.risk,
    required this.project,
  });
}

final aggregatedRisksProvider = FutureProvider.autoDispose<List<AggregatedRisk>>((ref) async {
  print('[RISKS_PROVIDER_DEBUG] aggregatedRisksProvider - started at ${DateTime.now()}');

  // Check if projects provider is ready
  final projectsAsync = ref.watch(projectsListProvider);

  // If projects are still loading, wait for them
  if (!projectsAsync.hasValue) {
    print('[RISKS_PROVIDER_DEBUG] Projects not ready yet, waiting...');
    final projects = await ref.watch(projectsListProvider.future);
    print('[RISKS_PROVIDER_DEBUG] Projects loaded after wait: ${projects.length} projects');
    // Continue with the loaded projects
    return _fetchRisksForProjects(ref, projects);
  }

  // Projects are already loaded
  final projects = projectsAsync.value ?? [];
  print('[RISKS_PROVIDER_DEBUG] Using cached projects: ${projects.length} projects');
  return _fetchRisksForProjects(ref, projects);
});

Future<List<AggregatedRisk>> _fetchRisksForProjects(Ref ref, List<Project> projects) async {
  print('[RISKS_PROVIDER_DEBUG] _fetchRisksForProjects called with ${projects.length} projects');

  if (projects.isEmpty) {
    print('[RISKS_PROVIDER_DEBUG] No projects, returning empty risks');
    return [];
  }

  final aggregatedRisks = <AggregatedRisk>[];

  // Fetch risks from all projects in parallel
  print('[RISKS_PROVIDER_DEBUG] Starting to fetch risks from ${projects.length} projects');
  final riskFutures = projects.map((project) async {
    try {
      print('[RISKS_PROVIDER_DEBUG] Fetching risks for project: ${project.name} (${project.id})');
      final risks = await ref.read(projectRisksProvider(project.id).future);
      print('[RISKS_PROVIDER_DEBUG] Project ${project.name} has ${risks.length} risks');
      return risks.map((risk) => AggregatedRisk(
        risk: risk,
        project: project,
      )).toList();
    } catch (e) {
      print('[RISKS_PROVIDER_DEBUG] Error fetching risks for project ${project.name}: $e');
      // If a project fails, return empty list for that project
      return <AggregatedRisk>[];
    }
  }).toList();

  final riskResults = await Future.wait(riskFutures);
  print('[RISKS_PROVIDER_DEBUG] All risk futures completed');

  // Flatten the list of lists
  for (final risks in riskResults) {
    aggregatedRisks.addAll(risks);
  }
  print('[RISKS_PROVIDER_DEBUG] Total aggregated risks: ${aggregatedRisks.length}');

  // Sort by severity (critical first) and then by date
  aggregatedRisks.sort((a, b) {
    // Sort by severity first
    final severityOrder = {
      RiskSeverity.critical: 0,
      RiskSeverity.high: 1,
      RiskSeverity.medium: 2,
      RiskSeverity.low: 3,
    };

    final severityCompare = severityOrder[a.risk.severity]!
        .compareTo(severityOrder[b.risk.severity]!);

    if (severityCompare != 0) return severityCompare;

    // Then sort by identified date (newest first)
    if (a.risk.identifiedDate != null && b.risk.identifiedDate != null) {
      return b.risk.identifiedDate!.compareTo(a.risk.identifiedDate!);
    }

    return 0;
  });

  print('[RISKS_PROVIDER_DEBUG] Returning ${aggregatedRisks.length} sorted risks');
  return aggregatedRisks;
}

// Provider for filtering risks by severity
final filteredRisksBySeverityProvider = Provider.family<List<AggregatedRisk>, RiskSeverity?>((ref, severity) {
  final risksAsync = ref.watch(aggregatedRisksProvider);

  return risksAsync.when(
    data: (risks) {
      if (severity == null) return risks;
      return risks.where((r) => r.risk.severity == severity).toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

// Provider for filtering risks by status
final filteredRisksByStatusProvider = Provider.family<List<AggregatedRisk>, RiskStatus?>((ref, status) {
  final risksAsync = ref.watch(aggregatedRisksProvider);

  return risksAsync.when(
    data: (risks) {
      if (status == null) return risks;
      return risks.where((r) => r.risk.status == status).toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

// Provider for getting risk statistics
final riskStatisticsProvider = Provider((ref) {
  final risksAsync = ref.watch(aggregatedRisksProvider);

  return risksAsync.when(
    data: (risks) {
      final total = risks.length;
      final critical = risks.where((r) => r.risk.severity == RiskSeverity.critical).length;
      final high = risks.where((r) => r.risk.severity == RiskSeverity.high).length;
      final medium = risks.where((r) => r.risk.severity == RiskSeverity.medium).length;
      final low = risks.where((r) => r.risk.severity == RiskSeverity.low).length;

      final active = risks.where((r) => r.risk.isActive).length;
      final resolved = risks.where((r) => r.risk.status == RiskStatus.resolved).length;
      final mitigating = risks.where((r) => r.risk.status == RiskStatus.mitigating).length;

      final aiGenerated = risks.where((r) => r.risk.aiGenerated).length;

      return {
        'total': total,
        'critical': critical,
        'high': high,
        'medium': medium,
        'low': low,
        'active': active,
        'resolved': resolved,
        'mitigating': mitigating,
        'aiGenerated': aiGenerated,
      };
    },
    loading: () => <String, int>{},
    error: (_, __) => <String, int>{},
  );
});