/// Email Digest Preferences Model
///
/// Represents user preferences for email digest delivery.
/// Maps to backend API: GET/PUT /api/v1/email-preferences/digest

class EmailDigestPreferences {
  /// Whether email digests are enabled
  final bool enabled;

  /// Digest frequency: 'daily', 'weekly', 'monthly', 'never'
  final String frequency;

  /// Types of content to include in digest
  final List<String> contentTypes;

  /// Whether to include portfolio-level rollup
  final bool includePortfolioRollup;

  /// Last time digest was sent (ISO 8601)
  final String? lastSentAt;

  const EmailDigestPreferences({
    required this.enabled,
    required this.frequency,
    required this.contentTypes,
    this.includePortfolioRollup = true,
    this.lastSentAt,
  });

  /// Create from JSON response
  factory EmailDigestPreferences.fromJson(Map<String, dynamic> json) {
    return EmailDigestPreferences(
      enabled: json['enabled'] as bool? ?? false,
      frequency: json['frequency'] as String? ?? 'weekly',
      contentTypes: (json['content_types'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
      includePortfolioRollup: json['include_portfolio_rollup'] as bool? ?? true,
      lastSentAt: json['last_sent_at'] as String?,
    );
  }

  /// Convert to JSON for API request
  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'frequency': frequency,
      'content_types': contentTypes,
      'include_portfolio_rollup': includePortfolioRollup,
    };
  }

  /// Create copy with updated fields
  EmailDigestPreferences copyWith({
    bool? enabled,
    String? frequency,
    List<String>? contentTypes,
    bool? includePortfolioRollup,
    String? lastSentAt,
  }) {
    return EmailDigestPreferences(
      enabled: enabled ?? this.enabled,
      frequency: frequency ?? this.frequency,
      contentTypes: contentTypes ?? this.contentTypes,
      includePortfolioRollup: includePortfolioRollup ?? this.includePortfolioRollup,
      lastSentAt: lastSentAt ?? this.lastSentAt,
    );
  }

  /// Default preferences for new users
  factory EmailDigestPreferences.defaults() {
    return const EmailDigestPreferences(
      enabled: false,
      frequency: 'weekly',
      contentTypes: ['blockers', 'tasks_assigned', 'risks_critical'],
      includePortfolioRollup: true,
    );
  }

  @override
  String toString() {
    return 'EmailDigestPreferences(enabled: $enabled, frequency: $frequency, contentTypes: $contentTypes)';
  }
}

/// Available digest frequencies
class DigestFrequency {
  static const String daily = 'daily';
  static const String weekly = 'weekly';
  static const String monthly = 'monthly';
  static const String never = 'never';

  static const List<String> all = [daily, weekly, monthly, never];

  static String displayName(String frequency) {
    switch (frequency) {
      case daily:
        return 'Daily';
      case weekly:
        return 'Weekly';
      case monthly:
        return 'Monthly';
      case never:
        return 'Never';
      default:
        return frequency;
    }
  }

  static String description(String frequency) {
    switch (frequency) {
      case daily:
        return 'Receive digest every day at 8 AM UTC';
      case weekly:
        return 'Receive digest every Monday at 8 AM UTC';
      case monthly:
        return 'Receive digest on the 1st of each month at 8 AM UTC';
      case never:
        return 'Do not send digest emails';
      default:
        return '';
    }
  }
}

/// Available content types for digest
class DigestContentType {
  static const String blockers = 'blockers';
  static const String tasksAssigned = 'tasks_assigned';
  static const String risksCritical = 'risks_critical';
  static const String activities = 'activities';
  static const String decisions = 'decisions';

  static const List<String> all = [
    blockers,
    tasksAssigned,
    risksCritical,
    activities,
    decisions,
  ];

  static String displayName(String type) {
    switch (type) {
      case blockers:
        return 'Active Blockers';
      case tasksAssigned:
        return 'Tasks Assigned to Me';
      case risksCritical:
        return 'Critical Risks';
      case activities:
        return 'Project Activities';
      case decisions:
        return 'Key Decisions';
      default:
        return type;
    }
  }

  static String description(String type) {
    switch (type) {
      case blockers:
        return 'Include active and escalated project blockers';
      case tasksAssigned:
        return 'Include tasks that are assigned to you';
      case risksCritical:
        return 'Include high and critical severity risks';
      case activities:
        return 'Include recent project activities';
      case decisions:
        return 'Include important decisions made';
      default:
        return '';
    }
  }
}
