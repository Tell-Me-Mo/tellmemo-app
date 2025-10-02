import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../projects/domain/entities/risk.dart';
import 'aggregated_risks_provider.dart';
import '../../../projects/presentation/providers/projects_provider.dart';

// Provider for enhanced risk statistics with trends
final enhancedRiskStatisticsProvider = Provider<Map<String, int>>((ref) {
  final risksAsync = ref.watch(aggregatedRisksProvider);
  print('[STATISTICS_DEBUG] enhancedRiskStatisticsProvider - risksAsync state: ${risksAsync.isLoading ? "loading" : risksAsync.hasError ? "error" : "has data with ${risksAsync.value?.length ?? 0} risks"}');

  return risksAsync.when(
    data: (risks) {
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));
      final monthAgo = now.subtract(const Duration(days: 30));

      // Basic counts
      final total = risks.length;
      final critical = risks.where((r) => r.risk.severity == RiskSeverity.critical).length;
      final high = risks.where((r) => r.risk.severity == RiskSeverity.high).length;
      final medium = risks.where((r) => r.risk.severity == RiskSeverity.medium).length;
      final low = risks.where((r) => r.risk.severity == RiskSeverity.low).length;

      final active = risks.where((r) => r.risk.isActive).length;
      final resolved = risks.where((r) => r.risk.status == RiskStatus.resolved).length;
      final mitigating = risks.where((r) => r.risk.status == RiskStatus.mitigating).length;
      final escalated = risks.where((r) => r.risk.status == RiskStatus.escalated).length;

      // AI statistics
      final aiGenerated = risks.where((r) => r.risk.aiGenerated).length;

      // Calculate weekly changes
      final newThisWeek = risks.where((r) {
        final date = r.risk.identifiedDate;
        return date != null && date.isAfter(weekAgo);
      }).length;

      final resolvedThisWeek = risks.where((r) {
        final date = r.risk.resolvedDate;
        return date != null && date.isAfter(weekAgo);
      }).length;

      // Calculate average resolution time
      final resolvedRisks = risks.where((r) =>
        r.risk.status == RiskStatus.resolved &&
        r.risk.identifiedDate != null &&
        r.risk.resolvedDate != null
      ).toList();

      int avgResolutionDays = 0;
      if (resolvedRisks.isNotEmpty) {
        final totalDays = resolvedRisks.fold(0, (sum, r) {
          final duration = r.risk.resolvedDate!.difference(r.risk.identifiedDate!);
          return sum + duration.inDays;
        });
        avgResolutionDays = (totalDays / resolvedRisks.length).round();
      }

      // Trends (positive means increase)
      final weeklyChange = newThisWeek - resolvedThisWeek;
      final criticalChange = risks.where((r) {
        final date = r.risk.identifiedDate;
        return r.risk.severity == RiskSeverity.critical &&
            date != null && date.isAfter(weekAgo);
      }).length;

      final activeChange = newThisWeek - resolvedThisWeek;

      return {
        'total': total,
        'critical': critical,
        'high': high,
        'medium': medium,
        'low': low,
        'active': active,
        'resolved': resolved,
        'mitigating': mitigating,
        'escalated': escalated,
        'aiGenerated': aiGenerated,
        'weeklyChange': weeklyChange,
        'criticalChange': criticalChange,
        'activeChange': activeChange,
        'resolvedChange': resolvedThisWeek,
        'avgResolutionDays': avgResolutionDays,
        'newThisWeek': newThisWeek,
        'resolvedThisWeek': resolvedThisWeek,
      };
    },
    loading: () => <String, int>{},
    error: (_, __) => <String, int>{},
  );
});

// Provider for unique assignees across all risks
final uniqueAssigneesProvider = Provider<List<String>>((ref) {
  final risksAsync = ref.watch(aggregatedRisksProvider);

  return risksAsync.when(
    data: (risks) {
      final assignees = <String>{};
      for (final risk in risks) {
        if (risk.risk.assignedTo != null) {
          assignees.add(risk.risk.assignedTo!);
        }
      }
      return assignees.toList()..sort();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

// Provider for risk trends over time (for charts)
final riskTrendsProvider = Provider<RiskTrends>((ref) {
  final risksAsync = ref.watch(aggregatedRisksProvider);

  return risksAsync.when(
    data: (risks) {
      final now = DateTime.now();
      final trends = <DateTime, Map<String, int>>{};

      // Generate data points for last 30 days
      for (int i = 29; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final dayStart = DateTime(date.year, date.month, date.day);
        final dayEnd = dayStart.add(const Duration(days: 1));

        // Count risks active on this date
        final activeOnDate = risks.where((r) {
          final identifiedDate = r.risk.identifiedDate;
          final resolvedDate = r.risk.resolvedDate;

          if (identifiedDate == null) return false;

          // Risk was active if identified before day end and not resolved before day start
          return identifiedDate.isBefore(dayEnd) &&
              (resolvedDate == null || resolvedDate.isAfter(dayStart));
        }).toList();

        trends[dayStart] = {
          'total': activeOnDate.length,
          'critical': activeOnDate.where((r) => r.risk.severity == RiskSeverity.critical).length,
          'high': activeOnDate.where((r) => r.risk.severity == RiskSeverity.high).length,
          'medium': activeOnDate.where((r) => r.risk.severity == RiskSeverity.medium).length,
          'low': activeOnDate.where((r) => r.risk.severity == RiskSeverity.low).length,
        };
      }

      return RiskTrends(data: trends);
    },
    loading: () => RiskTrends(data: {}),
    error: (_, __) => RiskTrends(data: {}),
  );
});

// Provider for real-time WebSocket connection
final riskWebSocketProvider = StateNotifierProvider<RiskWebSocketNotifier, WebSocketState>((ref) {
  return RiskWebSocketNotifier(ref);
});

// WebSocket state management
class WebSocketState {
  final bool isConnected;
  final String? error;

  WebSocketState({
    this.isConnected = false,
    this.error,
  });
}

class RiskWebSocketNotifier extends StateNotifier<WebSocketState> {
  final Ref ref;

  RiskWebSocketNotifier(this.ref) : super(WebSocketState());

  Future<void> connect() async {
    // TODO: Implement WebSocket connection for real-time updates
    // This would connect to your backend WebSocket endpoint
    state = WebSocketState(isConnected: true);
  }

  void disconnect() {
    state = WebSocketState(isConnected: false);
  }

  void handleMessage(dynamic message) {
    // Handle incoming WebSocket messages
    // Update risks in real-time
    ref.invalidate(aggregatedRisksProvider);
  }
}

// Risk trends data model
class RiskTrends {
  final Map<DateTime, Map<String, int>> data;

  RiskTrends({required this.data});

  List<DateTime> get dates => data.keys.toList()..sort();

  List<int> getTrendForSeverity(String severity) {
    return dates.map((date) => data[date]?[severity] ?? 0).toList();
  }

  int getMaxValue() {
    int max = 0;
    for (final dayData in data.values) {
      final total = dayData['total'] ?? 0;
      if (total > max) max = total;
    }
    return max;
  }
}