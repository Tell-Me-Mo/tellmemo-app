import 'package:firebase_analytics/firebase_analytics.dart';
import '../utils/logger.dart';

/// Service for managing Firebase Analytics events and tracking
class FirebaseAnalyticsService {
  static final FirebaseAnalyticsService _instance =
      FirebaseAnalyticsService._internal();
  factory FirebaseAnalyticsService() => _instance;
  FirebaseAnalyticsService._internal();

  FirebaseAnalytics? _analytics;
  FirebaseAnalyticsObserver? _observer;
  bool _isInitialized = false;

  FirebaseAnalytics? get analytics => _analytics;
  FirebaseAnalyticsObserver? get observer => _observer;
  bool get isInitialized => _isInitialized;

  /// Initialize Firebase Analytics
  Future<void> initialize() async {
    try {
      _analytics = FirebaseAnalytics.instance;
      _observer = FirebaseAnalyticsObserver(
        analytics: _analytics!,
        // Allow all routes to be tracked (fixes issue with GoRouter)
        routeFilter: (route) => true,
        nameExtractor: (settings) {
          // Extract screen name from route settings
          // GoRouter passes the route name in settings.name
          if (settings.name != null && settings.name!.isNotEmpty) {
            // Convert route name to screen class name
            // e.g., "dashboard" -> "DashboardScreen"
            final screenName = _formatScreenName(settings.name!);
            Logger.debug('Screen tracked: $screenName (route: ${settings.name})');
            return screenName;
          }
          return settings.name ?? 'UnknownScreen';
        },
      );

      // Enable analytics collection
      await _analytics!.setAnalyticsCollectionEnabled(true);
      _isInitialized = true;

      Logger.info('Firebase Analytics initialized successfully');
    } catch (e) {
      Logger.error('Failed to initialize Firebase Analytics: $e', e);
      _isInitialized = false;
    }
  }

  /// Format route name to screen name
  String _formatScreenName(String routeName) {
    // Handle special cases
    final nameMap = {
      'landing': 'LandingScreen',
      'signin': 'SignInScreen',
      'signup': 'SignUpScreen',
      'forgot-password': 'ForgotPasswordScreen',
      'reset-password': 'PasswordResetScreen',
      'dashboard': 'DashboardScreen',
      'hierarchy': 'HierarchyScreen',
      'portfolio-detail': 'PortfolioDetailScreen',
      'program-detail': 'ProgramDetailScreen',
      'project-detail': 'ProjectDetailScreen',
      'documents': 'DocumentsScreen',
      'summaries': 'SummariesScreen',
      'summary-detail': 'SummaryDetailScreen',
      'risks': 'RisksScreen',
      'tasks': 'TasksScreen',
      'lessons': 'LessonsLearnedScreen',
      'support-tickets': 'SupportTicketsScreen',
      'integrations': 'IntegrationsScreen',
      'profile': 'UserProfileScreen',
      'organization-create': 'OrganizationWizardScreen',
      'organization-settings': 'OrganizationSettingsScreen',
      'organization-members': 'MemberManagementScreen',
    };

    return nameMap[routeName] ?? routeName;
  }

  /// Log a custom event
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    if (!_isInitialized || _analytics == null) return;
    try {
      await _analytics!.logEvent(
        name: name,
        parameters: parameters,
      );
      Logger.debug('Analytics event logged: $name');
    } catch (e) {
      Logger.error('Failed to log analytics event: $e', e);
    }
  }

  /// Log screen view
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    if (!_isInitialized || _analytics == null) return;
    try {
      await _analytics!.logScreenView(
        screenName: screenName,
        screenClass: screenClass,
      );
      Logger.debug('Screen view logged: $screenName');
    } catch (e) {
      Logger.error('Failed to log screen view: $e', e);
    }
  }

  /// Log app open event
  Future<void> logAppOpen() async {
    if (!_isInitialized || _analytics == null) return;
    try {
      await _analytics!.logAppOpen();
      Logger.debug('App open event logged');
    } catch (e) {
      Logger.error('Failed to log app open: $e', e);
    }
  }

  /// Log login event
  Future<void> logLogin({String? method}) async {
    if (!_isInitialized || _analytics == null) return;
    try {
      await _analytics!.logLogin(loginMethod: method);
      Logger.debug('Login event logged');
    } catch (e) {
      Logger.error('Failed to log login: $e', e);
    }
  }

  /// Log sign up event
  Future<void> logSignUp({String? method}) async {
    if (!_isInitialized || _analytics == null) return;
    try {
      if (method != null) {
        await _analytics!.logSignUp(signUpMethod: method);
      } else {
        await _analytics!.logSignUp(signUpMethod: 'unknown');
      }
      Logger.debug('Sign up event logged');
    } catch (e) {
      Logger.error('Failed to log sign up: $e', e);
    }
  }

  /// Set user ID
  Future<void> setUserId(String? userId) async {
    if (!_isInitialized || _analytics == null) return;
    try {
      await _analytics!.setUserId(id: userId);
      Logger.debug('User ID set: $userId');
    } catch (e) {
      Logger.error('Failed to set user ID: $e', e);
    }
  }

  /// Set user property
  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {
    if (!_isInitialized || _analytics == null) return;
    try {
      await _analytics!.setUserProperty(name: name, value: value);
      Logger.debug('User property set: $name = $value');
    } catch (e) {
      Logger.error('Failed to log user property: $e', e);
    }
  }

  /// Log meeting created event
  Future<void> logMeetingCreated({
    String? meetingId,
    String? meetingType,
  }) async {
    await logEvent(
      name: 'meeting_created',
      parameters: {
        if (meetingId != null) 'meeting_id': meetingId,
        if (meetingType != null) 'meeting_type': meetingType,
      },
    );
  }

  /// Log transcript uploaded event
  Future<void> logTranscriptUploaded({
    String? meetingId,
    int? fileSize,
  }) async {
    await logEvent(
      name: 'transcript_uploaded',
      parameters: {
        if (meetingId != null) 'meeting_id': meetingId,
        if (fileSize != null) 'file_size': fileSize,
      },
    );
  }

  /// Log summary generated event
  Future<void> logSummaryGenerated({
    String? meetingId,
    String? summaryType,
  }) async {
    await logEvent(
      name: 'summary_generated',
      parameters: {
        if (meetingId != null) 'meeting_id': meetingId,
        if (summaryType != null) 'summary_type': summaryType,
      },
    );
  }

  /// Log project created event
  Future<void> logProjectCreated({
    required String projectId,
    required String projectName,
    String? parentId,
    String? parentType,
  }) async {
    await logEvent(
      name: 'project_created',
      parameters: {
        'project_id': projectId,
        'project_name': projectName,
        if (parentId != null) 'parent_id': parentId,
        if (parentType != null) 'parent_type': parentType,
      },
    );
  }

  /// Log project viewed
  Future<void> logProjectViewed({
    required String projectId,
    String? projectName,
    String? viewSource,
  }) async {
    await logEvent(
      name: 'project_viewed',
      parameters: {
        'project_id': projectId,
        if (projectName != null) 'project_name': projectName,
        if (viewSource != null) 'view_source': viewSource,
      },
    );
  }

  /// Log project updated
  Future<void> logProjectUpdated({
    required String projectId,
    required List<String> fieldsChanged,
  }) async {
    await logEvent(
      name: 'project_updated',
      parameters: {
        'project_id': projectId,
        'fields_changed': fieldsChanged.join(','),
        'fields_count': fieldsChanged.length,
      },
    );
  }

  /// Log project archived
  Future<void> logProjectArchived({
    required String projectId,
    String? archiveReason,
  }) async {
    await logEvent(
      name: 'project_archived',
      parameters: {
        'project_id': projectId,
        if (archiveReason != null) 'archive_reason': archiveReason,
      },
    );
  }

  /// Log project deleted
  Future<void> logProjectDeleted({
    required String projectId,
  }) async {
    await logEvent(
      name: 'project_deleted',
      parameters: {'project_id': projectId},
    );
  }

  // --- Hierarchy Events ---

  /// Log portfolio created
  Future<void> logPortfolioCreated({
    required String portfolioId,
    required String portfolioName,
  }) async {
    await logEvent(
      name: 'portfolio_created',
      parameters: {
        'portfolio_id': portfolioId,
        'portfolio_name': portfolioName,
      },
    );
  }

  /// Log program created
  Future<void> logProgramCreated({
    required String programId,
    required String programName,
    String? portfolioId,
  }) async {
    await logEvent(
      name: 'program_created',
      parameters: {
        'program_id': programId,
        'program_name': programName,
        if (portfolioId != null) 'portfolio_id': portfolioId,
      },
    );
  }

  /// Log hierarchy navigated
  Future<void> logHierarchyNavigated({
    required String level,
    required String entityId,
    String? navigationSource,
  }) async {
    await logEvent(
      name: 'hierarchy_navigated',
      parameters: {
        'level': level,
        'entity_id': entityId,
        if (navigationSource != null) 'navigation_source': navigationSource,
      },
    );
  }

  /// Log portfolio viewed
  Future<void> logPortfolioViewed({
    required String portfolioId,
    String? portfolioName,
  }) async {
    await logEvent(
      name: 'portfolio_viewed',
      parameters: {
        'portfolio_id': portfolioId,
        if (portfolioName != null) 'portfolio_name': portfolioName,
      },
    );
  }

  /// Log program viewed
  Future<void> logProgramViewed({
    required String programId,
    String? programName,
  }) async {
    await logEvent(
      name: 'program_viewed',
      parameters: {
        'program_id': programId,
        if (programName != null) 'program_name': programName,
      },
    );
  }

  /// Log search performed event
  Future<void> logSearchPerformed({
    String? query,
    String? searchType,
    int? resultCount,
  }) async {
    await logEvent(
      name: 'search_performed',
      parameters: {
        if (query != null) 'query': query,
        if (searchType != null) 'search_type': searchType,
        if (resultCount != null) 'result_count': resultCount,
      },
    );
  }

  /// Log export event
  Future<void> logExport({
    required String exportType,
    String? format,
  }) async {
    await logEvent(
      name: 'export_data',
      parameters: {
        'export_type': exportType,
        if (format != null) 'format': format,
      },
    );
  }

  // ========== AUTH & ORGANIZATION EVENTS ==========

  /// Log sign in attempt
  Future<void> logSignInAttempt({String method = 'email'}) async {
    await logEvent(
      name: 'signin_attempt',
      parameters: {'method': method},
    );
  }

  /// Log sign in success
  Future<void> logSignInSuccess({
    required String method,
    required bool hasOrganization,
  }) async {
    await logLogin(method: method);
    await logEvent(
      name: 'signin_success',
      parameters: {
        'method': method,
        'has_organization': hasOrganization ? 'true' : 'false',
      },
    );
  }

  /// Log sign in failed
  Future<void> logSignInFailed({required String errorType}) async {
    await logEvent(
      name: 'signin_failed',
      parameters: {'error_type': errorType},
    );
  }

  /// Log sign in forgot password clicked
  Future<void> logSignInForgotPasswordClicked() async {
    await logEvent(name: 'signin_forgot_password_clicked');
  }

  /// Log sign in signup clicked
  Future<void> logSignInSignUpClicked() async {
    await logEvent(name: 'signin_signup_clicked');
  }

  /// Log sign in remember me toggled
  Future<void> logSignInRememberMeToggled({required bool enabled}) async {
    await logEvent(
      name: 'signin_remember_me_toggled',
      parameters: {'enabled': enabled ? 'true' : 'false'},
    );
  }

  /// Log signup form started
  Future<void> logSignUpFormStarted({required bool hasPrefilledEmail}) async {
    await logEvent(
      name: 'signup_form_started',
      parameters: {'has_prefilled_email': hasPrefilledEmail ? 'true' : 'false'},
    );
  }

  /// Log signup attempt
  Future<void> logSignUpAttempt() async {
    await logEvent(name: 'signup_attempt');
  }

  /// Log signup success
  Future<void> logSignUpSuccess({
    required bool hasName,
    required bool willCreateOrg,
  }) async {
    await logSignUp(method: 'email');
    await logEvent(
      name: 'signup_success',
      parameters: {
        'has_name': hasName ? 'true' : 'false',
        'will_create_org': willCreateOrg ? 'true' : 'false',
      },
    );
  }

  /// Log signup failed
  Future<void> logSignUpFailed({required String errorType}) async {
    await logEvent(
      name: 'signup_failed',
      parameters: {'error_type': errorType},
    );
  }

  /// Log signup existing account clicked
  Future<void> logSignUpExistingAccountClicked() async {
    await logEvent(name: 'signup_existing_account_clicked');
  }

  /// Log password reset request sent
  Future<void> logPasswordResetRequested({required bool hasPrefilledEmail}) async {
    await logEvent(
      name: 'password_reset_request_sent',
      parameters: {'has_prefilled_email': hasPrefilledEmail ? 'true' : 'false'},
    );
  }

  /// Log password reset request success
  Future<void> logPasswordResetSuccess() async {
    await logEvent(name: 'password_reset_request_success');
  }

  /// Log password reset request failed
  Future<void> logPasswordResetFailed({required String errorType}) async {
    await logEvent(
      name: 'password_reset_request_failed',
      parameters: {'error_type': errorType},
    );
  }

  /// Log password reset try another email
  Future<void> logPasswordResetTryAnotherEmail() async {
    await logEvent(name: 'password_reset_try_another_email');
  }

  /// Log password reset back to signin
  Future<void> logPasswordResetBackToSignIn() async {
    await logEvent(name: 'password_reset_back_to_signin');
  }

  /// Log password update attempt
  Future<void> logPasswordUpdateAttempt() async {
    await logEvent(name: 'password_update_attempt');
  }

  /// Log password update success
  Future<void> logPasswordUpdateSuccess() async {
    await logEvent(name: 'password_update_success');
  }

  /// Log password update failed
  Future<void> logPasswordUpdateFailed({required String errorType}) async {
    await logEvent(
      name: 'password_update_failed',
      parameters: {'error_type': errorType},
    );
  }

  /// Log organization creation screen viewed
  Future<void> logOrgCreationScreenViewed({required String trigger}) async {
    await logScreenView(
      screenName: 'OrganizationWizard',
      screenClass: 'OrganizationWizardScreen',
    );
    await logEvent(
      name: 'org_creation_screen_viewed',
      parameters: {'trigger': trigger},
    );
  }

  /// Log organization creation started
  Future<void> logOrgCreationStarted() async {
    await logEvent(name: 'org_creation_started');
  }

  /// Log organization member invited
  Future<void> logOrgMemberInvited({required int emailCount}) async {
    await logEvent(
      name: 'org_member_invited',
      parameters: {'email_count': emailCount},
    );
  }

  /// Log organization member removed
  Future<void> logOrgMemberRemoved({required int remainingCount}) async {
    await logEvent(
      name: 'org_member_removed',
      parameters: {'remaining_count': remainingCount},
    );
  }

  /// Log organization creation attempt
  Future<void> logOrgCreationAttempt({
    required int memberCount,
    required bool hasDescription,
  }) async {
    await logEvent(
      name: 'org_creation_attempt',
      parameters: {
        'member_count': memberCount,
        'has_description': hasDescription ? 'true' : 'false',
      },
    );
  }

  /// Log organization creation success
  Future<void> logOrgCreationSuccess({
    required String orgId,
    required int memberCount,
    required bool hasDescription,
  }) async {
    await logEvent(
      name: 'org_creation_success',
      parameters: {
        'organization_id': orgId,
        'member_count': memberCount,
        'has_description': hasDescription ? 'true' : 'false',
      },
    );
    // Set user property
    await setUserProperty(name: 'has_organization', value: 'true');
    await setUserProperty(name: 'organization_id', value: orgId);
  }

  /// Log organization creation failed
  Future<void> logOrgCreationFailed({required String error}) async {
    await logEvent(
      name: 'org_creation_failed',
      parameters: {'error_message': error},
    );
  }

  /// Log organization creation cancelled
  Future<void> logOrgCreationCancelled({required bool hadProgress}) async {
    await logEvent(
      name: 'org_creation_cancelled',
      parameters: {'had_progress': hadProgress ? 'true' : 'false'},
    );
  }

  // ========== CORE MVP FEATURES ==========

  // --- Content Upload & Processing ---

  /// Log content upload started
  Future<void> logContentUploadStarted({
    required String contentType,
    required String projectId,
    int? fileSize,
  }) async {
    await logEvent(
      name: 'content_upload_started',
      parameters: {
        'content_type': contentType,
        'project_id': projectId,
        if (fileSize != null) 'file_size': fileSize,
      },
    );
  }

  /// Log content upload completed
  Future<void> logContentUploadCompleted({
    required String contentType,
    required String projectId,
    String? contentId,
    int? fileSize,
    int? processingTime,
  }) async {
    await logEvent(
      name: 'content_upload_completed',
      parameters: {
        'content_type': contentType,
        'project_id': projectId,
        if (contentId != null) 'content_id': contentId,
        if (fileSize != null) 'file_size': fileSize,
        if (processingTime != null) 'processing_time_ms': processingTime,
      },
    );
  }

  /// Log content upload failed
  Future<void> logContentUploadFailed({
    required String contentType,
    required String errorReason,
    int? fileSize,
  }) async {
    await logEvent(
      name: 'content_upload_failed',
      parameters: {
        'content_type': contentType,
        'error_reason': errorReason,
        if (fileSize != null) 'file_size': fileSize,
      },
    );
  }

  /// Log content processing started
  Future<void> logContentProcessingStarted({
    required String contentId,
    required String contentType,
  }) async {
    await logEvent(
      name: 'content_processing_started',
      parameters: {
        'content_id': contentId,
        'content_type': contentType,
      },
    );
  }

  /// Log content processing completed
  Future<void> logContentProcessingCompleted({
    required String contentId,
    required String contentType,
    int? chunkCount,
    int? processingTime,
  }) async {
    await logEvent(
      name: 'content_processing_completed',
      parameters: {
        'content_id': contentId,
        'content_type': contentType,
        if (chunkCount != null) 'chunk_count': chunkCount,
        if (processingTime != null) 'processing_time_ms': processingTime,
      },
    );
  }

  /// Log content processing failed
  Future<void> logContentProcessingFailed({
    required String contentId,
    required String errorReason,
  }) async {
    await logEvent(
      name: 'content_processing_failed',
      parameters: {
        'content_id': contentId,
        'error_reason': errorReason,
      },
    );
  }

  // --- RAG Query System ---

  /// Log query asked
  Future<void> logQueryAsked({
    required String projectId,
    required int queryLength,
    String? queryType,
  }) async {
    await logEvent(
      name: 'query_asked',
      parameters: {
        'project_id': projectId,
        'query_length': queryLength,
        if (queryType != null) 'query_type': queryType,
      },
    );
  }

  /// Log query completed
  Future<void> logQueryCompleted({
    required String projectId,
    required int responseTime,
    int? sourcesCount,
    int? responseLength,
  }) async {
    await logEvent(
      name: 'query_completed',
      parameters: {
        'project_id': projectId,
        'response_time_ms': responseTime,
        if (sourcesCount != null) 'sources_count': sourcesCount,
        if (responseLength != null) 'response_length': responseLength,
      },
    );
  }

  /// Log query failed
  Future<void> logQueryFailed({
    required String projectId,
    required String errorReason,
  }) async {
    await logEvent(
      name: 'query_failed',
      parameters: {
        'project_id': projectId,
        'error_reason': errorReason,
      },
    );
  }

  /// Log query feedback
  Future<void> logQueryFeedback({
    required String projectId,
    required bool isHelpful,
    String? feedbackText,
  }) async {
    await logEvent(
      name: 'query_feedback',
      parameters: {
        'project_id': projectId,
        'is_helpful': isHelpful ? 'true' : 'false',
        if (feedbackText != null) 'feedback_text': feedbackText,
      },
    );
  }

  /// Log query source clicked
  Future<void> logQuerySourceClicked({
    required String projectId,
    required String sourceId,
    String? sourceType,
  }) async {
    await logEvent(
      name: 'query_source_clicked',
      parameters: {
        'project_id': projectId,
        'source_id': sourceId,
        if (sourceType != null) 'source_type': sourceType,
      },
    );
  }

  // --- Summary Generation ---

  /// Log summary generation requested
  Future<void> logSummaryGenerationRequested({
    required String entityType,
    required String entityId,
    required String summaryType,
    String? format,
  }) async {
    await logEvent(
      name: 'summary_generation_requested',
      parameters: {
        'entity_type': entityType,
        'entity_id': entityId,
        'summary_type': summaryType,
        if (format != null) 'format': format,
      },
    );
  }

  /// Log summary generation completed
  Future<void> logSummaryGenerationCompleted({
    required String entityType,
    required String entityId,
    required String summaryType,
    String? summaryId,
    int? generationTime,
  }) async {
    await logEvent(
      name: 'summary_generation_completed',
      parameters: {
        'entity_type': entityType,
        'entity_id': entityId,
        'summary_type': summaryType,
        if (summaryId != null) 'summary_id': summaryId,
        if (generationTime != null) 'generation_time_ms': generationTime,
      },
    );
  }

  /// Log summary generation failed
  Future<void> logSummaryGenerationFailed({
    required String entityType,
    required String entityId,
    required String errorReason,
  }) async {
    await logEvent(
      name: 'summary_generation_failed',
      parameters: {
        'entity_type': entityType,
        'entity_id': entityId,
        'error_reason': errorReason,
      },
    );
  }

  /// Log summary viewed
  Future<void> logSummaryViewed({
    required String summaryId,
    required String summaryType,
    String? entityType,
  }) async {
    await logEvent(
      name: 'summary_viewed',
      parameters: {
        'summary_id': summaryId,
        'summary_type': summaryType,
        if (entityType != null) 'entity_type': entityType,
      },
    );
  }

  /// Log summary exported
  Future<void> logSummaryExported({
    required String summaryId,
    required String format,
    String? summaryType,
  }) async {
    await logEvent(
      name: 'summary_exported',
      parameters: {
        'summary_id': summaryId,
        'format': format,
        if (summaryType != null) 'summary_type': summaryType,
      },
    );
  }

  /// Log summary shared
  Future<void> logSummaryShared({
    required String summaryId,
    required String shareMethod,
    String? summaryType,
  }) async {
    await logEvent(
      name: 'summary_shared',
      parameters: {
        'summary_id': summaryId,
        'share_method': shareMethod,
        if (summaryType != null) 'summary_type': summaryType,
      },
    );
  }

  // ========== TASK MANAGEMENT ==========

  /// Log task created
  Future<void> logTaskCreated({
    required String taskId,
    required String projectId,
    String? priority,
    bool? hasDueDate,
    bool? hasAssignee,
  }) async {
    await logEvent(
      name: 'task_created',
      parameters: {
        'task_id': taskId,
        'project_id': projectId,
        if (priority != null) 'priority': priority,
        if (hasDueDate != null) 'has_due_date': hasDueDate ? 'true' : 'false',
        if (hasAssignee != null) 'has_assignee': hasAssignee ? 'true' : 'false',
      },
    );
  }

  /// Log task updated
  Future<void> logTaskUpdated({
    required String taskId,
    required String projectId,
    required List<String> fieldsChanged,
  }) async {
    await logEvent(
      name: 'task_updated',
      parameters: {
        'task_id': taskId,
        'project_id': projectId,
        'fields_changed': fieldsChanged.join(','),
        'fields_count': fieldsChanged.length,
      },
    );
  }

  /// Log task status changed
  Future<void> logTaskStatusChanged({
    required String taskId,
    required String projectId,
    required String fromStatus,
    required String toStatus,
  }) async {
    await logEvent(
      name: 'task_status_changed',
      parameters: {
        'task_id': taskId,
        'project_id': projectId,
        'from_status': fromStatus,
        'to_status': toStatus,
      },
    );
  }

  /// Log task deleted
  Future<void> logTaskDeleted({
    required String taskId,
    required String projectId,
  }) async {
    await logEvent(
      name: 'task_deleted',
      parameters: {
        'task_id': taskId,
        'project_id': projectId,
      },
    );
  }

  /// Log task viewed
  Future<void> logTaskViewed({
    required String taskId,
    required String projectId,
    String? viewSource,
  }) async {
    await logEvent(
      name: 'task_viewed',
      parameters: {
        'task_id': taskId,
        'project_id': projectId,
        if (viewSource != null) 'view_source': viewSource,
      },
    );
  }

  /// Log task bulk operation
  Future<void> logTaskBulkOperation({
    required String operationType,
    required int count,
    String? projectId,
  }) async {
    await logEvent(
      name: 'task_bulk_operation',
      parameters: {
        'operation_type': operationType,
        'count': count,
        if (projectId != null) 'project_id': projectId,
      },
    );
  }

  /// Log task filter applied
  Future<void> logTaskFilterApplied({
    required String filterType,
    required int activeCount,
    String? projectId,
  }) async {
    await logEvent(
      name: 'task_filter_applied',
      parameters: {
        'filter_type': filterType,
        'active_count': activeCount,
        if (projectId != null) 'project_id': projectId,
      },
    );
  }

  /// Log task sort applied
  Future<void> logTaskSortApplied({
    required String sortBy,
    required String sortOrder,
    String? projectId,
  }) async {
    await logEvent(
      name: 'task_sort_applied',
      parameters: {
        'sort_by': sortBy,
        'sort_order': sortOrder,
        if (projectId != null) 'project_id': projectId,
      },
    );
  }

  /// Log task view changed
  Future<void> logTaskViewChanged({
    required String fromView,
    required String toView,
    String? projectId,
  }) async {
    await logEvent(
      name: 'task_view_changed',
      parameters: {
        'from_view': fromView,
        'to_view': toView,
        if (projectId != null) 'project_id': projectId,
      },
    );
  }

  /// Log task export initiated
  Future<void> logTaskExportInitiated({
    required String format,
    required int count,
    String? projectId,
  }) async {
    await logEvent(
      name: 'task_export_initiated',
      parameters: {
        'format': format,
        'count': count,
        if (projectId != null) 'project_id': projectId,
      },
    );
  }

  /// Log task kanban drag
  Future<void> logTaskKanbanDrag({
    required String taskId,
    required String fromStatus,
    required String toStatus,
    String? projectId,
  }) async {
    await logEvent(
      name: 'task_kanban_drag',
      parameters: {
        'task_id': taskId,
        'from_status': fromStatus,
        'to_status': toStatus,
        if (projectId != null) 'project_id': projectId,
      },
    );
  }

  // ========== RISK MANAGEMENT ==========

  /// Log risk identified
  Future<void> logRiskIdentified({
    required String riskId,
    required String projectId,
    required String severity,
    bool? isAiGenerated,
    String? source,
  }) async {
    await logEvent(
      name: 'risk_identified',
      parameters: {
        'risk_id': riskId,
        'project_id': projectId,
        'severity': severity,
        if (isAiGenerated != null) 'is_ai_generated': isAiGenerated ? 'true' : 'false',
        if (source != null) 'source': source,
      },
    );
  }

  /// Log risk updated
  Future<void> logRiskUpdated({
    required String riskId,
    required String projectId,
    required List<String> fieldsChanged,
  }) async {
    await logEvent(
      name: 'risk_updated',
      parameters: {
        'risk_id': riskId,
        'project_id': projectId,
        'fields_changed': fieldsChanged.join(','),
        'fields_count': fieldsChanged.length,
      },
    );
  }

  /// Log risk status changed
  Future<void> logRiskStatusChanged({
    required String riskId,
    required String projectId,
    required String fromStatus,
    required String toStatus,
  }) async {
    await logEvent(
      name: 'risk_status_changed',
      parameters: {
        'risk_id': riskId,
        'project_id': projectId,
        'from_status': fromStatus,
        'to_status': toStatus,
      },
    );
  }

  /// Log risk severity changed
  Future<void> logRiskSeverityChanged({
    required String riskId,
    required String projectId,
    required String fromSeverity,
    required String toSeverity,
  }) async {
    await logEvent(
      name: 'risk_severity_changed',
      parameters: {
        'risk_id': riskId,
        'project_id': projectId,
        'from_severity': fromSeverity,
        'to_severity': toSeverity,
      },
    );
  }

  /// Log risk assigned
  Future<void> logRiskAssigned({
    required String riskId,
    required String projectId,
    bool? hasAssignee,
  }) async {
    await logEvent(
      name: 'risk_assigned',
      parameters: {
        'risk_id': riskId,
        'project_id': projectId,
        if (hasAssignee != null) 'has_assignee': hasAssignee ? 'true' : 'false',
      },
    );
  }

  /// Log risk viewed
  Future<void> logRiskViewed({
    required String riskId,
    required String projectId,
    String? viewSource,
  }) async {
    await logEvent(
      name: 'risk_viewed',
      parameters: {
        'risk_id': riskId,
        'project_id': projectId,
        if (viewSource != null) 'view_source': viewSource,
      },
    );
  }

  /// Log risk filter applied
  Future<void> logRiskFilterApplied({
    required String filterType,
    required int activeCount,
    String? projectId,
  }) async {
    await logEvent(
      name: 'risk_filter_applied',
      parameters: {
        'filter_type': filterType,
        'active_count': activeCount,
        if (projectId != null) 'project_id': projectId,
      },
    );
  }

  /// Log risk view changed
  Future<void> logRiskViewChanged({
    required String fromView,
    required String toView,
    String? projectId,
  }) async {
    await logEvent(
      name: 'risk_view_changed',
      parameters: {
        'from_view': fromView,
        'to_view': toView,
        if (projectId != null) 'project_id': projectId,
      },
    );
  }

  /// Log risk bulk operation
  Future<void> logRiskBulkOperation({
    required String operationType,
    required int count,
    String? projectId,
  }) async {
    await logEvent(
      name: 'risk_bulk_operation',
      parameters: {
        'operation_type': operationType,
        'count': count,
        if (projectId != null) 'project_id': projectId,
      },
    );
  }

  /// Log risk export initiated
  Future<void> logRiskExportInitiated({
    required String format,
    required int count,
    String? projectId,
  }) async {
    await logEvent(
      name: 'risk_export_initiated',
      parameters: {
        'format': format,
        'count': count,
        if (projectId != null) 'project_id': projectId,
      },
    );
  }

  // ========== AUDIO RECORDING & TRANSCRIPTION ==========

  /// Log recording started
  Future<void> logRecordingStarted({
    bool? hasProjectSelected,
    String? projectMode,
  }) async {
    await logEvent(
      name: 'recording_started',
      parameters: {
        if (hasProjectSelected != null)
          'has_project_selected': hasProjectSelected ? 'true' : 'false',
        if (projectMode != null) 'project_mode': projectMode,
      },
    );
  }

  /// Log recording paused
  Future<void> logRecordingPaused({
    int? durationSoFar,
  }) async {
    await logEvent(
      name: 'recording_paused',
      parameters: {
        if (durationSoFar != null) 'duration_so_far': durationSoFar,
      },
    );
  }

  /// Log recording resumed
  Future<void> logRecordingResumed() async {
    await logEvent(name: 'recording_resumed');
  }

  /// Log recording stopped
  Future<void> logRecordingStopped({
    required int totalDuration,
    int? fileSize,
  }) async {
    await logEvent(
      name: 'recording_stopped',
      parameters: {
        'total_duration': totalDuration,
        if (fileSize != null) 'file_size': fileSize,
      },
    );
  }

  /// Log recording cancelled
  Future<void> logRecordingCancelled({
    int? durationBeforeCancel,
  }) async {
    await logEvent(
      name: 'recording_cancelled',
      parameters: {
        if (durationBeforeCancel != null)
          'duration_before_cancel': durationBeforeCancel,
      },
    );
  }

  /// Log transcription started
  Future<void> logTranscriptionStarted({
    int? audioDuration,
  }) async {
    await logEvent(
      name: 'transcription_started',
      parameters: {
        if (audioDuration != null) 'audio_duration': audioDuration,
      },
    );
  }

  /// Log transcription completed
  Future<void> logTranscriptionCompleted({
    required int duration,
    int? wordCount,
    int? processingTime,
  }) async {
    await logEvent(
      name: 'transcription_completed',
      parameters: {
        'duration': duration,
        if (wordCount != null) 'word_count': wordCount,
        if (processingTime != null) 'processing_time': processingTime,
      },
    );
  }

  /// Log transcription failed
  Future<void> logTranscriptionFailed({
    required String errorReason,
    int? audioDuration,
  }) async {
    await logEvent(
      name: 'transcription_failed',
      parameters: {
        'error_reason': errorReason,
        if (audioDuration != null) 'audio_duration': audioDuration,
      },
    );
  }

  /// Log recording uploaded
  Future<void> logRecordingUploaded({
    required String projectId,
    required int fileSize,
    int? duration,
  }) async {
    await logEvent(
      name: 'recording_uploaded',
      parameters: {
        'project_id': projectId,
        'file_size': fileSize,
        if (duration != null) 'duration': duration,
      },
    );
  }

  /// Log recording discarded
  Future<void> logRecordingDiscarded({
    int? duration,
  }) async {
    await logEvent(
      name: 'recording_discarded',
      parameters: {
        if (duration != null) 'duration': duration,
      },
    );
  }

  // ========== DASHBOARD INTERACTIONS ==========

  /// Log dashboard viewed
  Future<void> logDashboardViewed({
    int? projectCount,
    int? recentActivityCount,
    bool? hasUnreadNotifications,
  }) async {
    await logEvent(
      name: 'dashboard_viewed',
      parameters: {
        if (projectCount != null) 'project_count': projectCount,
        if (recentActivityCount != null) 'recent_activity_count': recentActivityCount,
        if (hasUnreadNotifications != null)
          'has_unread_notifications': hasUnreadNotifications ? 'true' : 'false',
      },
    );
  }

  /// Log dashboard quick action clicked
  Future<void> logDashboardQuickActionClicked({
    required String action,
    String? projectId,
  }) async {
    await logEvent(
      name: 'dashboard_quick_action_clicked',
      parameters: {
        'action': action,
        if (projectId != null) 'project_id': projectId,
      },
    );
  }

  /// Log dashboard AI panel opened
  Future<void> logDashboardAiPanelOpened({
    String? source,
  }) async {
    await logEvent(
      name: 'dashboard_ai_panel_opened',
      parameters: {
        if (source != null) 'source': source,
      },
    );
  }

  /// Log dashboard project card clicked
  Future<void> logDashboardProjectCardClicked({
    required String projectId,
    String? projectName,
    int? position,
  }) async {
    await logEvent(
      name: 'dashboard_project_card_clicked',
      parameters: {
        'project_id': projectId,
        if (projectName != null) 'project_name': projectName,
        if (position != null) 'position': position,
      },
    );
  }

  /// Log dashboard summary card clicked
  Future<void> logDashboardSummaryCardClicked({
    required String summaryId,
    required String summaryType,
    String? entityId,
  }) async {
    await logEvent(
      name: 'dashboard_summary_card_clicked',
      parameters: {
        'summary_id': summaryId,
        'summary_type': summaryType,
        if (entityId != null) 'entity_id': entityId,
      },
    );
  }

  /// Log dashboard refreshed
  Future<void> logDashboardRefreshed({
    String? refreshMethod,
  }) async {
    await logEvent(
      name: 'dashboard_refreshed',
      parameters: {
        if (refreshMethod != null) 'refresh_method': refreshMethod,
      },
    );
  }

  /// Log dashboard activity clicked
  Future<void> logDashboardActivityClicked({
    required String activityType,
    String? activityId,
    String? relatedEntityId,
  }) async {
    await logEvent(
      name: 'dashboard_activity_clicked',
      parameters: {
        'activity_type': activityType,
        if (activityId != null) 'activity_id': activityId,
        if (relatedEntityId != null) 'related_entity_id': relatedEntityId,
      },
    );
  }
}
