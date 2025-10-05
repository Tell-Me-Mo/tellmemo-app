import 'package:pm_master_v2/features/organizations/data/models/organization_model.dart';
import 'package:pm_master_v2/features/organizations/data/models/organization_member.dart';
import 'package:pm_master_v2/features/organizations/domain/entities/organization.dart';

/// Test fixtures for organization-related data
class OrganizationTestFixtures {
  /// Sample organization model
  static OrganizationModel get sampleOrganizationModel => OrganizationModel(
        id: 'org-1',
        name: 'Test Organization',
        slug: 'test-organization',
        description: 'A test organization for unit testing',
        logoUrl: null,
        settings: {
          'data_retention_days': 90,
          'email_notifications': true,
          'weekly_reports': false,
        },
        isActive: true,
        createdBy: 'user-1',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 15),
        memberCount: 3,
        currentUserRole: 'admin',
        currentUserId: 'user-1',
        projectCount: 5,
        documentCount: 12,
      );

  /// Sample organization entity
  static Organization get sampleOrganization => sampleOrganizationModel.toEntity();

  /// Sample organization with member role
  static OrganizationModel get sampleOrganizationAsMember =>
      sampleOrganizationModel.copyWith(
        currentUserRole: 'member',
      );

  /// Sample organization with viewer role
  static OrganizationModel get sampleOrganizationAsViewer =>
      sampleOrganizationModel.copyWith(
        currentUserRole: 'viewer',
      );

  /// List of sample organization members
  static List<OrganizationMember> get sampleMembers => [
        OrganizationMember(
          organizationId: 'org-1',
          userId: 'user-1',
          userEmail: 'admin@test.com',
          userName: 'Admin User',
          userAvatarUrl: null,
          role: 'admin',
          status: 'active',
          joinedAt: DateTime(2024, 1, 1),
          lastActiveAt: DateTime.now().subtract(const Duration(minutes: 5)),
        ),
        OrganizationMember(
          organizationId: 'org-1',
          userId: 'user-2',
          userEmail: 'member@test.com',
          userName: 'Member User',
          userAvatarUrl: null,
          role: 'member',
          status: 'active',
          joinedAt: DateTime(2024, 1, 5),
          lastActiveAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        OrganizationMember(
          organizationId: 'org-1',
          userId: 'user-3',
          userEmail: 'viewer@test.com',
          userName: 'Viewer User',
          userAvatarUrl: null,
          role: 'viewer',
          status: 'active',
          joinedAt: DateTime(2024, 1, 10),
          lastActiveAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
        OrganizationMember(
          organizationId: 'org-1',
          userId: 'user-4',
          userEmail: 'pending@test.com',
          userName: 'Pending User',
          userAvatarUrl: null,
          role: 'member',
          status: 'invited',
          invitedAt: DateTime(2024, 1, 14),
          invitedBy: 'user-1',
        ),
      ];

  /// Sample admin member
  static OrganizationMember get sampleAdminMember => sampleMembers[0];

  /// Sample regular member
  static OrganizationMember get sampleRegularMember => sampleMembers[1];

  /// Sample pending invitation
  static OrganizationMember get samplePendingInvitation => sampleMembers[3];

  /// Create a custom organization with specific properties
  static OrganizationModel createOrganization({
    String id = 'org-test',
    String name = 'Custom Organization',
    String? description,
    String currentUserRole = 'admin',
    int memberCount = 1,
    int projectCount = 0,
    int documentCount = 0,
  }) {
    return OrganizationModel(
      id: id,
      name: name,
      slug: name.toLowerCase().replaceAll(' ', '-'),
      description: description,
      settings: const {},
      isActive: true,
      createdBy: 'user-1',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      memberCount: memberCount,
      currentUserRole: currentUserRole,
      currentUserId: 'user-1',
      projectCount: projectCount,
      documentCount: documentCount,
    );
  }

  /// Create a custom organization member
  static OrganizationMember createMember({
    String organizationId = 'org-1',
    String userId = 'user-test',
    String email = 'test@example.com',
    String name = 'Test User',
    String role = 'member',
    String status = 'active',
  }) {
    return OrganizationMember(
      organizationId: organizationId,
      userId: userId,
      userEmail: email,
      userName: name,
      role: role,
      status: status,
      joinedAt: status == 'active' ? DateTime.now() : null,
      invitedAt: status == 'invited' ? DateTime.now() : null,
      lastActiveAt: status == 'active' ? DateTime.now() : null,
    );
  }

  /// Multiple organizations for listing
  static List<OrganizationModel> get multipleOrganizations => [
        sampleOrganizationModel,
        createOrganization(
          id: 'org-2',
          name: 'Second Organization',
          description: 'Another test organization',
          memberCount: 5,
          projectCount: 10,
        ),
        createOrganization(
          id: 'org-3',
          name: 'Third Organization',
          currentUserRole: 'member',
          memberCount: 2,
        ),
      ];
}
