class AppRoutes {
  // Private constructor
  AppRoutes._();

  // Route paths
  static const String landing = '/';
  static const String dashboard = '/dashboard';
  static const String projects = '/hierarchy';  // Redirects to hierarchy
  static const String projectDetail = '/hierarchy/project/:id';
  static const String createProject = '/hierarchy';  // Projects created from hierarchy
  static const String editProject = '/hierarchy/project/:id/edit';
  static const String uploadContent = '/hierarchy/project/:id/upload';
  static const String projectSummaries = '/hierarchy/project/:id/summaries';
  static const String documents = '/documents';
  static const String documentDetail = '/documents/:id';
  static const String summaries = '/summaries';
  static const String summaryDetail = '/summaries/:id';
  static const String integrations = '/integrations';
  static const String integrationDetail = '/integrations/:id';
  static const String settings = '/settings';
  static const String profile = '/profile';
  static const String changePassword = '/profile/change-password';

  // Route names
  static const String landingName = 'landing';
  static const String dashboardName = 'dashboard';
  static const String projectsName = 'projects';
  static const String projectDetailName = 'project-detail';
  static const String createProjectName = 'create-project';
  static const String editProjectName = 'edit-project';
  static const String uploadContentName = 'upload-content';
  static const String projectSummariesName = 'project-summaries';
  static const String documentsName = 'documents';
  static const String documentDetailName = 'document-detail';
  static const String summariesName = 'summaries';
  static const String summaryDetailName = 'summary-detail';
  static const String integrationsName = 'integrations';
  static const String integrationDetailName = 'integration-detail';
  static const String settingsName = 'settings';
  static const String profileName = 'profile';
  static const String changePasswordName = 'change-password';

  // Helper methods for parameterized routes
  static String projectDetailPath(String projectId) => '/hierarchy/project/$projectId';
  static String editProjectPath(String projectId) => '/hierarchy/project/$projectId/edit';
  static String uploadContentPath(String projectId) => '/hierarchy/project/$projectId/upload';
  static String projectSummariesPath(String projectId) => '/hierarchy/project/$projectId/summaries';
  static String documentDetailPath(String documentId) => '/documents/$documentId';
  static String summaryDetailPath(String summaryId) => '/summaries/$summaryId';
  static String integrationDetailPath(String integrationId) => '/integrations/$integrationId';

  // Authentication and organization helper methods
  static String signInWithRedirect(String redirectPath) =>
      '/auth/signin?redirect=${Uri.encodeComponent(redirectPath)}';

  static String organizationSettingsPath() => '/organization/settings';
  static String organizationMembersPath() => '/organization/members';
  static String organizationCreatePath() => '/organization/create';

  // Deep link preservation helpers
  static String preserveDeepLink(String currentPath, Map<String, String> queryParams) {
    final uri = Uri.parse(currentPath);
    final combinedParams = Map<String, String>.from(uri.queryParameters);
    combinedParams.addAll(queryParams);

    return Uri(
      path: uri.path,
      queryParameters: combinedParams.isNotEmpty ? combinedParams : null,
    ).toString();
  }
}