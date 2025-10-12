import 'package:flutter_test/flutter_test.dart';
import 'package:pm_master_v2/app/router/routes.dart';

void main() {
  group('AppRoutes', () {
    group('Route Paths', () {
      test('has correct landing path', () {
        expect(AppRoutes.landing, '/');
      });

      test('has correct dashboard path', () {
        expect(AppRoutes.dashboard, '/dashboard');
      });

      test('has correct projects path redirecting to hierarchy', () {
        expect(AppRoutes.projects, '/hierarchy');
      });

      test('has correct documents path', () {
        expect(AppRoutes.documents, '/documents');
      });

      test('has correct summaries path', () {
        expect(AppRoutes.summaries, '/summaries');
      });

      test('has correct integrations path', () {
        expect(AppRoutes.integrations, '/integrations');
      });

      test('has correct profile path', () {
        expect(AppRoutes.profile, '/profile');
      });
    });

    group('Route Names', () {
      test('has correct landing name', () {
        expect(AppRoutes.landingName, 'landing');
      });

      test('has correct dashboard name', () {
        expect(AppRoutes.dashboardName, 'dashboard');
      });

      test('has correct projects name', () {
        expect(AppRoutes.projectsName, 'projects');
      });

      test('has correct documents name', () {
        expect(AppRoutes.documentsName, 'documents');
      });

      test('has correct summaries name', () {
        expect(AppRoutes.summariesName, 'summaries');
      });
    });

    group('Helper Methods for Parameterized Routes', () {
      test('projectDetailPath generates correct path', () {
        expect(
          AppRoutes.projectDetailPath('project-123'),
          '/hierarchy/project/project-123',
        );
      });

      test('editProjectPath generates correct path', () {
        expect(
          AppRoutes.editProjectPath('project-456'),
          '/hierarchy/project/project-456/edit',
        );
      });

      test('uploadContentPath generates correct path', () {
        expect(
          AppRoutes.uploadContentPath('project-789'),
          '/hierarchy/project/project-789/upload',
        );
      });

      test('projectSummariesPath generates correct path', () {
        expect(
          AppRoutes.projectSummariesPath('project-abc'),
          '/hierarchy/project/project-abc/summaries',
        );
      });

      test('documentDetailPath generates correct path', () {
        expect(
          AppRoutes.documentDetailPath('doc-123'),
          '/documents/doc-123',
        );
      });

      test('summaryDetailPath generates correct path', () {
        expect(
          AppRoutes.summaryDetailPath('summary-xyz'),
          '/summaries/summary-xyz',
        );
      });

      test('integrationDetailPath generates correct path', () {
        expect(
          AppRoutes.integrationDetailPath('integration-001'),
          '/integrations/integration-001',
        );
      });
    });

    group('Authentication Helper Methods', () {
      test('signInWithRedirect encodes redirect path', () {
        final result = AppRoutes.signInWithRedirect('/dashboard');
        expect(result, '/auth/signin?redirect=%2Fdashboard');
      });

      test('signInWithRedirect handles complex paths', () {
        final result = AppRoutes.signInWithRedirect('/hierarchy/project/123');
        expect(result, contains('/auth/signin?redirect='));
        expect(result, contains('%2Fhierarchy%2Fproject%2F123'));
      });

      test('organizationSettingsPath returns correct path', () {
        expect(AppRoutes.organizationSettingsPath(), '/organization/settings');
      });

      test('organizationMembersPath returns correct path', () {
        expect(AppRoutes.organizationMembersPath(), '/organization/members');
      });

      test('organizationCreatePath returns correct path', () {
        expect(AppRoutes.organizationCreatePath(), '/organization/create');
      });
    });

    group('Deep Link Preservation', () {
      test('preserveDeepLink combines query parameters', () {
        final result = AppRoutes.preserveDeepLink(
          '/dashboard',
          {'project': 'proj-123'},
        );
        expect(result, '/dashboard?project=proj-123');
      });

      test('preserveDeepLink merges existing and new query parameters', () {
        final result = AppRoutes.preserveDeepLink(
          '/dashboard?filter=active',
          {'project': 'proj-123'},
        );
        expect(result, contains('filter=active'));
        expect(result, contains('project=proj-123'));
        expect(result, contains('?'));
      });

      test('preserveDeepLink handles path without query parameters', () {
        final result = AppRoutes.preserveDeepLink(
          '/hierarchy',
          {},
        );
        expect(result, '/hierarchy');
      });

      test('preserveDeepLink handles empty parameters map', () {
        final result = AppRoutes.preserveDeepLink(
          '/summaries?view=list',
          {},
        );
        expect(result, contains('view=list'));
      });

      test('preserveDeepLink overwrites duplicate parameters', () {
        final result = AppRoutes.preserveDeepLink(
          '/dashboard?project=old-id',
          {'project': 'new-id'},
        );
        expect(result, '/dashboard?project=new-id');
        expect(result, isNot(contains('old-id')));
      });

      test('preserveDeepLink handles special characters in path', () {
        final result = AppRoutes.preserveDeepLink(
          '/hierarchy/project/proj-123',
          {'tab': 'risks&tasks'},
        );
        expect(result, contains('/hierarchy/project/proj-123'));
        expect(result, contains('tab='));
      });
    });

    group('Edge Cases', () {
      test('projectDetailPath handles IDs with special characters', () {
        final result = AppRoutes.projectDetailPath('project-with-dashes-123');
        expect(result, '/hierarchy/project/project-with-dashes-123');
      });

      test('documentDetailPath handles UUIDs', () {
        final result = AppRoutes.documentDetailPath(
          '550e8400-e29b-41d4-a716-446655440000',
        );
        expect(
          result,
          '/documents/550e8400-e29b-41d4-a716-446655440000',
        );
      });

      test('signInWithRedirect handles paths with query parameters', () {
        final result = AppRoutes.signInWithRedirect(
          '/dashboard?view=cards&filter=active',
        );
        expect(result, contains('/auth/signin?redirect='));
        // The entire path with query params should be encoded
        expect(result, contains('%3F')); // Encoded '?'
        expect(result, contains('%26')); // Encoded '&'
      });
    });
  });
}
