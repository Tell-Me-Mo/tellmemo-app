import 'package:flutter_test/flutter_test.dart';
import 'package:pm_master_v2/features/hierarchy/data/models/hierarchy_model.dart';
import 'package:pm_master_v2/features/hierarchy/domain/entities/hierarchy_item.dart';

void main() {
  group('HierarchyNodeModel', () {
    group('fromJson', () {
      test('creates valid HierarchyNodeModel from complete JSON', () {
        // Arrange
        final json = {
          'id': 'node-123',
          'name': 'Test Node',
          'description': 'A test node',
          'type': 'portfolio',
          'portfolio_id': 'port-456',
          'program_id': 'prog-789',
          'created_at': '2024-01-15T10:30:00',
          'updated_at': '2024-01-20T15:45:00',
          'status': 'active',
          'member_count': 5,
          'children': [],
          'programs': [],
          'direct_projects': [],
          'projects': [],
        };

        // Act
        final model = HierarchyNodeModel.fromJson(json);

        // Assert
        expect(model.id, 'node-123');
        expect(model.name, 'Test Node');
        expect(model.description, 'A test node');
        expect(model.type, 'portfolio');
        expect(model.portfolioId, 'port-456');
        expect(model.programId, 'prog-789');
        expect(model.createdAt, '2024-01-15T10:30:00');
        expect(model.updatedAt, '2024-01-20T15:45:00');
        expect(model.status, 'active');
        expect(model.memberCount, 5);
        expect(model.children, isEmpty);
        expect(model.programs, isEmpty);
        expect(model.directProjects, isEmpty);
        expect(model.projects, isEmpty);
      });

      test('creates HierarchyNodeModel with minimal required fields', () {
        // Arrange
        final json = {
          'id': 'node-123',
          'name': 'Minimal Node',
          'type': 'project',
        };

        // Act
        final model = HierarchyNodeModel.fromJson(json);

        // Assert
        expect(model.id, 'node-123');
        expect(model.name, 'Minimal Node');
        expect(model.type, 'project');
        expect(model.description, isNull);
        expect(model.portfolioId, isNull);
        expect(model.programId, isNull);
        expect(model.createdAt, isNull);
        expect(model.updatedAt, isNull);
        expect(model.status, isNull);
        expect(model.memberCount, isNull);
        expect(model.children, isEmpty);
      });

      test('creates HierarchyNodeModel for all node types', () {
        final types = ['portfolio', 'program', 'project', 'virtual'];

        for (final type in types) {
          final json = {
            'id': 'node-123',
            'name': 'Node',
            'type': type,
          };

          final model = HierarchyNodeModel.fromJson(json);
          expect(model.type, type);
        }
      });
    });

    group('toJson', () {
      test('serializes complete HierarchyNodeModel to JSON', () {
        // Arrange
        final model = HierarchyNodeModel(
          id: 'node-123',
          name: 'Test Node',
          description: 'A test node',
          type: 'portfolio',
          portfolioId: 'port-456',
          programId: 'prog-789',
          createdAt: '2024-01-15T10:30:00',
          updatedAt: '2024-01-20T15:45:00',
          status: 'active',
          memberCount: 5,
          children: [],
          programs: [],
          directProjects: [],
          projects: [],
        );

        // Act
        final json = model.toJson();

        // Assert
        expect(json['id'], 'node-123');
        expect(json['name'], 'Test Node');
        expect(json['description'], 'A test node');
        expect(json['type'], 'portfolio');
        expect(json['portfolio_id'], 'port-456');
        expect(json['program_id'], 'prog-789');
        expect(json['created_at'], '2024-01-15T10:30:00');
        expect(json['updated_at'], '2024-01-20T15:45:00');
        expect(json['status'], 'active');
        expect(json['member_count'], 5);
      });

      test('serializes HierarchyNodeModel with null optional fields', () {
        // Arrange
        final model = HierarchyNodeModel(
          id: 'node-123',
          name: 'Minimal Node',
          type: 'project',
        );

        // Act
        final json = model.toJson();

        // Assert
        expect(json['description'], isNull);
        expect(json['portfolio_id'], isNull);
        expect(json['program_id'], isNull);
        expect(json['created_at'], isNull);
        expect(json['updated_at'], isNull);
        expect(json['status'], isNull);
        expect(json['member_count'], isNull);
      });
    });

    group('toEntity', () {
      test('converts portfolio node to HierarchyItem', () {
        // Arrange
        final model = HierarchyNodeModel(
          id: 'port-123',
          name: 'Test Portfolio',
          description: 'A test portfolio',
          type: 'portfolio',
          createdAt: '2024-01-15T10:30:00',
          updatedAt: '2024-01-20T15:45:00',
          children: [],
        );

        // Act
        final entity = model.toEntity();

        // Assert
        expect(entity.id, 'port-123');
        expect(entity.name, 'Test Portfolio');
        expect(entity.description, 'A test portfolio');
        expect(entity.type, HierarchyItemType.portfolio);
        expect(entity.createdAt, isA<DateTime>());
        expect(entity.updatedAt, isA<DateTime>());
        expect(entity.children, isEmpty);
      });

      test('converts program node to HierarchyItem', () {
        final model = HierarchyNodeModel(
          id: 'prog-123',
          name: 'Test Program',
          type: 'program',
          portfolioId: 'port-456',
          createdAt: '2024-01-15T10:30:00',
          updatedAt: '2024-01-20T15:45:00',
        );

        final entity = model.toEntity();
        expect(entity.type, HierarchyItemType.program);
        expect(entity.portfolioId, 'port-456');
      });

      test('converts project node to HierarchyItem', () {
        final model = HierarchyNodeModel(
          id: 'proj-123',
          name: 'Test Project',
          type: 'project',
          portfolioId: 'port-456',
          programId: 'prog-789',
          status: 'active',
          memberCount: 5,
          createdAt: '2024-01-15T10:30:00',
          updatedAt: '2024-01-20T15:45:00',
        );

        final entity = model.toEntity();
        expect(entity.type, HierarchyItemType.project);
        expect(entity.portfolioId, 'port-456');
        expect(entity.programId, 'prog-789');
        expect(entity.metadata?['status'], 'active');
        expect(entity.metadata?['memberCount'], 5);
      });

      test('handles unknown type - defaults to portfolio', () {
        final model = HierarchyNodeModel(
          id: 'node-123',
          name: 'Unknown Node',
          type: 'unknown',
          createdAt: '2024-01-15T10:30:00',
          updatedAt: '2024-01-20T15:45:00',
        );

        final entity = model.toEntity();
        expect(entity.type, HierarchyItemType.portfolio); // Default for unknown
      });

      test('converts nested children from children field', () {
        final model = HierarchyNodeModel(
          id: 'port-123',
          name: 'Portfolio',
          type: 'portfolio',
          createdAt: '2024-01-15T10:30:00',
          updatedAt: '2024-01-20T15:45:00',
          children: [
            HierarchyNodeModel(
              id: 'prog-123',
              name: 'Program 1',
              type: 'program',
              createdAt: '2024-01-15T10:30:00',
              updatedAt: '2024-01-20T15:45:00',
            ),
          ],
        );

        final entity = model.toEntity();
        expect(entity.children.length, 1);
        expect(entity.children.first.id, 'prog-123');
        expect(entity.children.first.type, HierarchyItemType.program);
      });

      test('converts nested children from programs/directProjects fields', () {
        final model = HierarchyNodeModel(
          id: 'port-123',
          name: 'Portfolio',
          type: 'portfolio',
          createdAt: '2024-01-15T10:30:00',
          updatedAt: '2024-01-20T15:45:00',
          programs: [
            HierarchyNodeModel(
              id: 'prog-123',
              name: 'Program 1',
              type: 'program',
              createdAt: '2024-01-15T10:30:00',
              updatedAt: '2024-01-20T15:45:00',
            ),
          ],
          directProjects: [
            HierarchyNodeModel(
              id: 'proj-123',
              name: 'Project 1',
              type: 'project',
              createdAt: '2024-01-15T10:30:00',
              updatedAt: '2024-01-20T15:45:00',
            ),
          ],
        );

        final entity = model.toEntity();
        expect(entity.children.length, 2); // 1 program + 1 direct project
      });

      test('includes metadata in entity', () {
        final model = HierarchyNodeModel(
          id: 'proj-123',
          name: 'Project',
          type: 'project',
          status: 'archived',
          memberCount: 10,
          createdAt: '2024-01-15T10:30:00',
          updatedAt: '2024-01-20T15:45:00',
        );

        final entity = model.toEntity();
        expect(entity.metadata?['status'], 'archived');
        expect(entity.metadata?['memberCount'], 10);
        expect(entity.metadata?['childCount'], 0);
        expect(entity.metadata?['type'], 'project');
      });

      test('handles null timestamps - uses current time', () {
        final model = HierarchyNodeModel(
          id: 'node-123',
          name: 'Node',
          type: 'portfolio',
        );

        final entity = model.toEntity();
        expect(entity.createdAt, isA<DateTime>());
        expect(entity.updatedAt, isA<DateTime>());
      });
    });

    group('Helper methods', () {
      test('isContainer returns true for portfolio', () {
        final model = HierarchyNodeModel(
          id: 'port-123',
          name: 'Portfolio',
          type: 'portfolio',
        );

        expect(model.isContainer, isTrue);
      });

      test('isContainer returns true for program', () {
        final model = HierarchyNodeModel(
          id: 'prog-123',
          name: 'Program',
          type: 'program',
        );

        expect(model.isContainer, isTrue);
      });

      test('isContainer returns false for project', () {
        final model = HierarchyNodeModel(
          id: 'proj-123',
          name: 'Project',
          type: 'project',
        );

        expect(model.isContainer, isFalse);
      });

      test('totalChildCount counts all child arrays', () {
        final model = HierarchyNodeModel(
          id: 'port-123',
          name: 'Portfolio',
          type: 'portfolio',
          children: [
            HierarchyNodeModel(id: '1', name: 'Child 1', type: 'project'),
          ],
          programs: [
            HierarchyNodeModel(id: '2', name: 'Program 1', type: 'program'),
          ],
          directProjects: [
            HierarchyNodeModel(id: '3', name: 'Project 1', type: 'project'),
          ],
          projects: [
            HierarchyNodeModel(id: '4', name: 'Project 2', type: 'project'),
          ],
        );

        expect(model.totalChildCount, 4); // 1 + 1 + 1 + 1
      });

      test('totalChildCount returns 0 when no children', () {
        final model = HierarchyNodeModel(
          id: 'proj-123',
          name: 'Project',
          type: 'project',
        );

        expect(model.totalChildCount, 0);
      });

      test('hasChildren returns true when node has children', () {
        final model = HierarchyNodeModel(
          id: 'port-123',
          name: 'Portfolio',
          type: 'portfolio',
          children: [
            HierarchyNodeModel(id: '1', name: 'Child', type: 'program'),
          ],
        );

        expect(model.hasChildren, isTrue);
      });

      test('hasChildren returns false when node has no children', () {
        final model = HierarchyNodeModel(
          id: 'proj-123',
          name: 'Project',
          type: 'project',
        );

        expect(model.hasChildren, isFalse);
      });
    });

    group('Edge cases', () {
      test('handles empty strings', () {
        final json = {
          'id': '',
          'name': '',
          'description': '',
          'type': '',
        };

        final model = HierarchyNodeModel.fromJson(json);
        expect(model.id, '');
        expect(model.name, '');
        expect(model.description, '');
        expect(model.type, '');
      });

      test('handles very long strings', () {
        final longString = 'A' * 10000;
        final json = {
          'id': longString,
          'name': longString,
          'description': longString,
          'type': 'portfolio',
        };

        final model = HierarchyNodeModel.fromJson(json);
        expect(model.id.length, 10000);
        expect(model.name.length, 10000);
        expect(model.description?.length, 10000);
      });

      test('handles special characters in strings', () {
        final json = {
          'id': 'node-123',
          'name': 'Node <>&"\'',
          'description': 'Test\nwith\ttabs',
          'type': 'portfolio',
        };

        final model = HierarchyNodeModel.fromJson(json);
        expect(model.name, 'Node <>&"\'');
        expect(model.description, 'Test\nwith\ttabs');
      });
    });
  });

  group('HierarchyResponse', () {
    test('creates valid HierarchyResponse from JSON', () {
      final json = {
        'hierarchy': [],
        'include_archived': true,
        'total_portfolios': 5,
        'has_orphaned_items': false,
      };

      final response = HierarchyResponse.fromJson(json);

      expect(response.hierarchy, isEmpty);
      expect(response.includeArchived, isTrue);
      expect(response.totalPortfolios, 5);
      expect(response.hasOrphanedItems, isFalse);
    });

    test('creates HierarchyResponse with default values', () {
      final json = {
        'hierarchy': [],
      };

      final response = HierarchyResponse.fromJson(json);

      expect(response.includeArchived, isFalse);
      expect(response.totalPortfolios, 0);
      expect(response.hasOrphanedItems, isFalse);
    });
  });

  group('MoveItemRequest', () {
    test('creates valid MoveItemRequest from JSON', () {
      final json = {
        'item_id': 'item-123',
        'item_type': 'project',
        'target_parent_id': 'port-456',
        'target_parent_type': 'portfolio',
      };

      final request = MoveItemRequest.fromJson(json);

      expect(request.itemId, 'item-123');
      expect(request.itemType, 'project');
      expect(request.targetParentId, 'port-456');
      expect(request.targetParentType, 'portfolio');
    });

    test('serializes MoveItemRequest to JSON', () {
      final request = MoveItemRequest(
        itemId: 'item-123',
        itemType: 'project',
        targetParentId: 'port-456',
        targetParentType: 'portfolio',
      );

      final json = request.toJson();

      expect(json['item_id'], 'item-123');
      expect(json['item_type'], 'project');
      expect(json['target_parent_id'], 'port-456');
      expect(json['target_parent_type'], 'portfolio');
    });
  });

  group('BulkDeleteRequest', () {
    test('creates valid BulkDeleteRequest from JSON', () {
      final json = {
        'items': [
          {'id': 'item-1', 'type': 'project'},
          {'id': 'item-2', 'type': 'program'},
        ],
        'delete_children': true,
        'reassign_to_id': 'port-456',
        'reassign_to_type': 'portfolio',
      };

      final request = BulkDeleteRequest.fromJson(json);

      expect(request.items.length, 2);
      expect(request.deleteChildren, isTrue);
      expect(request.reassignToId, 'port-456');
      expect(request.reassignToType, 'portfolio');
    });

    test('serializes BulkDeleteRequest to JSON', () {
      final request = BulkDeleteRequest(
        items: [
          MoveItemData(id: 'item-1', type: 'project'),
          MoveItemData(id: 'item-2', type: 'program'),
        ],
        deleteChildren: false,
        reassignToId: 'port-456',
        reassignToType: 'portfolio',
      );

      final json = request.toJson();

      expect(json['items'], hasLength(2));
      expect(json['delete_children'], isFalse);
      expect(json['reassign_to_id'], 'port-456');
      expect(json['reassign_to_type'], 'portfolio');
    });
  });
}
