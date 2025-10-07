import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:pm_master_v2/features/support_tickets/models/support_ticket.dart';
import 'package:pm_master_v2/features/support_tickets/services/support_ticket_service.dart';
import 'package:pm_master_v2/features/support_tickets/providers/support_ticket_provider.dart';

import 'support_ticket_provider_test.mocks.dart';

@GenerateMocks([SupportTicketService])
void main() {
  group('Support Ticket Provider Tests', () {
    late MockSupportTicketService mockService;
    late ProviderContainer container;

    // Sample test data
    final testTicket1 = SupportTicket(
      id: 'ticket-1',
      title: 'Bug in dashboard',
      description: 'The dashboard widget is not loading',
      type: TicketType.bugReport,
      priority: TicketPriority.high,
      status: TicketStatus.open,
      createdBy: 'user-1',
      creatorName: 'John Doe',
      creatorEmail: 'john@example.com',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
      commentCount: 0,
      attachmentCount: 0,
    );

    final testTicket2 = SupportTicket(
      id: 'ticket-2',
      title: 'Feature request: Dark mode',
      description: 'Add dark mode support to the app',
      type: TicketType.featureRequest,
      priority: TicketPriority.medium,
      status: TicketStatus.inProgress,
      createdBy: 'user-2',
      creatorName: 'Jane Smith',
      creatorEmail: 'jane@example.com',
      assignedTo: 'admin-1',
      assigneeName: 'Admin User',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 3)),
      commentCount: 2,
      attachmentCount: 1,
    );

    setUp(() {
      mockService = MockSupportTicketService();
    });

    tearDown(() {
      container.dispose();
    });

    group('TicketsNotifier initialization', () {
      test('loads tickets on initialization', () async {
        // Arrange
        when(mockService.getTickets(
          status: anyNamed('status'),
          priority: anyNamed('priority'),
          type: anyNamed('type'),
          assignedToMe: anyNamed('assignedToMe'),
          createdByMe: anyNamed('createdByMe'),
        )).thenAnswer((_) async => [testTicket1, testTicket2]);

        container = ProviderContainer(
          overrides: [
            supportTicketServiceProvider.overrideWithValue(mockService),
          ],
        );

        // Act - Listen for state changes
        AsyncValue<List<SupportTicket>>? finalState;
        final subscription = container.listen(
          ticketsProvider,
          (previous, next) {
            finalState = next;
          },
        );

        // Trigger the provider
        container.read(ticketsProvider);

        // Wait for async operation to complete
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(finalState?.hasValue, true);
        final tickets = finalState?.value;
        expect(tickets?.length, 2);
        expect(tickets?.first.id, testTicket1.id);
        verify(mockService.getTickets(
          status: anyNamed('status'),
          priority: anyNamed('priority'),
          type: anyNamed('type'),
          assignedToMe: anyNamed('assignedToMe'),
          createdByMe: anyNamed('createdByMe'),
        )).called(1);

        subscription.close();
      });

      test('sets error state when loading fails', () async {
        // Arrange
        when(mockService.getTickets(
          status: anyNamed('status'),
          priority: anyNamed('priority'),
          type: anyNamed('type'),
          assignedToMe: anyNamed('assignedToMe'),
          createdByMe: anyNamed('createdByMe'),
        )).thenThrow(Exception('Network error'));

        container = ProviderContainer(
          overrides: [
            supportTicketServiceProvider.overrideWithValue(mockService),
          ],
        );

        // Act
        final listener = container.listen(ticketsProvider, (prev, next) {});

        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(listener.read().hasError, true);
      });
    });

    group('loadTickets', () {
      test('loads tickets with filters', () async {
        // Arrange
        when(mockService.getTickets(
          status: TicketStatus.open,
          priority: TicketPriority.high,
          type: anyNamed('type'),
          assignedToMe: anyNamed('assignedToMe'),
          createdByMe: anyNamed('createdByMe'),
        )).thenAnswer((_) async => [testTicket1]);

        container = ProviderContainer(
          overrides: [
            supportTicketServiceProvider.overrideWithValue(mockService),
          ],
        );

        // Act
        final notifier = container.read(ticketsProvider.notifier);
        await notifier.loadTickets(
          status: TicketStatus.open,
          priority: TicketPriority.high,
        );

        // Assert
        final state = container.read(ticketsProvider);
        expect(state.hasValue, true);
        expect(state.value?.length, 1);
        expect(state.value?.first.id, testTicket1.id);
      });

      test('loads tickets assigned to me', () async {
        // Arrange
        when(mockService.getTickets(
          status: anyNamed('status'),
          priority: anyNamed('priority'),
          type: anyNamed('type'),
          assignedToMe: true,
          createdByMe: anyNamed('createdByMe'),
        )).thenAnswer((_) async => [testTicket2]);

        container = ProviderContainer(
          overrides: [
            supportTicketServiceProvider.overrideWithValue(mockService),
          ],
        );

        // Act
        final notifier = container.read(ticketsProvider.notifier);
        await notifier.loadTickets(assignedToMe: true);

        // Assert
        final state = container.read(ticketsProvider);
        expect(state.value?.length, 1);
        expect(state.value?.first.id, testTicket2.id);
      });
    });

    group('refresh', () {
      test('reloads tickets', () async {
        // Arrange
        when(mockService.getTickets(
          status: anyNamed('status'),
          priority: anyNamed('priority'),
          type: anyNamed('type'),
          assignedToMe: anyNamed('assignedToMe'),
          createdByMe: anyNamed('createdByMe'),
        )).thenAnswer((_) async => [testTicket1, testTicket2]);

        container = ProviderContainer(
          overrides: [
            supportTicketServiceProvider.overrideWithValue(mockService),
          ],
        );

        final notifier = container.read(ticketsProvider.notifier);

        // Wait for initial load
        await Future.delayed(const Duration(milliseconds: 100));

        // Act
        await notifier.refresh();

        // Assert
        verify(mockService.getTickets(
          status: anyNamed('status'),
          priority: anyNamed('priority'),
          type: anyNamed('type'),
          assignedToMe: anyNamed('assignedToMe'),
          createdByMe: anyNamed('createdByMe'),
        )).called(greaterThanOrEqualTo(2)); // Initial load + refresh
      });
    });

    group('addTicket', () {
      test('adds ticket to state', () async {
        // Arrange
        when(mockService.getTickets(
          status: anyNamed('status'),
          priority: anyNamed('priority'),
          type: anyNamed('type'),
          assignedToMe: anyNamed('assignedToMe'),
          createdByMe: anyNamed('createdByMe'),
        )).thenAnswer((_) async => [testTicket1]);

        container = ProviderContainer(
          overrides: [
            supportTicketServiceProvider.overrideWithValue(mockService),
          ],
        );

        final notifier = container.read(ticketsProvider.notifier);
        await Future.delayed(const Duration(milliseconds: 100));

        // Act
        notifier.addTicket(testTicket2);

        // Assert
        final state = container.read(ticketsProvider);
        expect(state.value?.length, 2);
        expect(state.value?.first.id, testTicket2.id); // New ticket is first
        expect(state.value?[1].id, testTicket1.id);
      });
    });

    group('updateTicket', () {
      test('updates existing ticket in state', () async {
        // Arrange
        when(mockService.getTickets(
          status: anyNamed('status'),
          priority: anyNamed('priority'),
          type: anyNamed('type'),
          assignedToMe: anyNamed('assignedToMe'),
          createdByMe: anyNamed('createdByMe'),
        )).thenAnswer((_) async => [testTicket1, testTicket2]);

        container = ProviderContainer(
          overrides: [
            supportTicketServiceProvider.overrideWithValue(mockService),
          ],
        );

        final notifier = container.read(ticketsProvider.notifier);
        await Future.delayed(const Duration(milliseconds: 100));

        // Act
        final updatedTicket = SupportTicket(
          id: testTicket1.id,
          title: 'Bug fixed in dashboard',
          description: testTicket1.description,
          type: testTicket1.type,
          priority: testTicket1.priority,
          status: TicketStatus.resolved,
          createdBy: testTicket1.createdBy,
          creatorName: testTicket1.creatorName,
          creatorEmail: testTicket1.creatorEmail,
          createdAt: testTicket1.createdAt,
          updatedAt: DateTime.now(),
          commentCount: testTicket1.commentCount,
          attachmentCount: testTicket1.attachmentCount,
        );
        notifier.updateTicket(updatedTicket);

        // Assert
        final state = container.read(ticketsProvider);
        expect(state.value?.length, 2);
        final updated = state.value?.firstWhere((t) => t.id == testTicket1.id);
        expect(updated?.status, TicketStatus.resolved);
        expect(updated?.title, 'Bug fixed in dashboard');
      });

      test('does not modify state if ticket not found', () async {
        // Arrange
        when(mockService.getTickets(
          status: anyNamed('status'),
          priority: anyNamed('priority'),
          type: anyNamed('type'),
          assignedToMe: anyNamed('assignedToMe'),
          createdByMe: anyNamed('createdByMe'),
        )).thenAnswer((_) async => [testTicket1]);

        container = ProviderContainer(
          overrides: [
            supportTicketServiceProvider.overrideWithValue(mockService),
          ],
        );

        final notifier = container.read(ticketsProvider.notifier);
        await Future.delayed(const Duration(milliseconds: 100));

        final originalState = container.read(ticketsProvider).value;

        // Act
        final nonExistentTicket = SupportTicket(
          id: 'non-existent',
          title: testTicket2.title,
          description: testTicket2.description,
          type: testTicket2.type,
          priority: testTicket2.priority,
          status: testTicket2.status,
          createdBy: testTicket2.createdBy,
          creatorName: testTicket2.creatorName,
          creatorEmail: testTicket2.creatorEmail,
          createdAt: testTicket2.createdAt,
          updatedAt: testTicket2.updatedAt,
          commentCount: testTicket2.commentCount,
          attachmentCount: testTicket2.attachmentCount,
        );
        notifier.updateTicket(nonExistentTicket);

        // Assert
        final state = container.read(ticketsProvider);
        expect(state.value?.length, originalState?.length);
      });
    });

    group('removeTicket', () {
      test('removes ticket from state', () async {
        // Arrange
        when(mockService.getTickets(
          status: anyNamed('status'),
          priority: anyNamed('priority'),
          type: anyNamed('type'),
          assignedToMe: anyNamed('assignedToMe'),
          createdByMe: anyNamed('createdByMe'),
        )).thenAnswer((_) async => [testTicket1, testTicket2]);

        container = ProviderContainer(
          overrides: [
            supportTicketServiceProvider.overrideWithValue(mockService),
          ],
        );

        final notifier = container.read(ticketsProvider.notifier);
        await Future.delayed(const Duration(milliseconds: 100));

        // Act
        notifier.removeTicket(testTicket1.id);

        // Assert
        final state = container.read(ticketsProvider);
        expect(state.value?.length, 1);
        expect(state.value?.first.id, testTicket2.id);
      });

      test('does nothing if ticket not found', () async {
        // Arrange
        when(mockService.getTickets(
          status: anyNamed('status'),
          priority: anyNamed('priority'),
          type: anyNamed('type'),
          assignedToMe: anyNamed('assignedToMe'),
          createdByMe: anyNamed('createdByMe'),
        )).thenAnswer((_) async => [testTicket1]);

        container = ProviderContainer(
          overrides: [
            supportTicketServiceProvider.overrideWithValue(mockService),
          ],
        );

        final notifier = container.read(ticketsProvider.notifier);
        await Future.delayed(const Duration(milliseconds: 100));

        // Act
        notifier.removeTicket('non-existent');

        // Assert
        final state = container.read(ticketsProvider);
        expect(state.value?.length, 1);
        expect(state.value?.first.id, testTicket1.id);
      });
    });

    group('selectedTicketProvider', () {
      test('starts with null', () {
        container = ProviderContainer();
        final selected = container.read(selectedTicketProvider);
        expect(selected, null);
      });

      test('can be set to a ticket', () {
        container = ProviderContainer();
        container.read(selectedTicketProvider.notifier).state = testTicket1;

        final selected = container.read(selectedTicketProvider);
        expect(selected, testTicket1);
      });
    });

    group('ticketCommentsProvider', () {
      test('loads comments for a ticket', () async {
        // Arrange
        final comments = [
          TicketComment(
            id: 'comment-1',
            ticketId: 'ticket-1',
            userId: 'user-1',
            userName: 'John Doe',
            userEmail: 'john@example.com',
            comment: 'This is a comment',
            isInternal: false,
            isSystemMessage: false,
            createdAt: DateTime.now(),
            attachments: const [],
          ),
        ];

        when(mockService.getComments('ticket-1')).thenAnswer((_) async => comments);

        container = ProviderContainer(
          overrides: [
            supportTicketServiceProvider.overrideWithValue(mockService),
          ],
        );

        // Act
        final commentsFuture = container.read(ticketCommentsProvider('ticket-1').future);
        final loadedComments = await commentsFuture;

        // Assert
        expect(loadedComments.length, 1);
        expect(loadedComments.first.comment, 'This is a comment');
      });
    });

    group('ticketDetailProvider', () {
      test('loads ticket detail', () async {
        // Arrange
        when(mockService.getTicket('ticket-1')).thenAnswer((_) async => testTicket1);

        container = ProviderContainer(
          overrides: [
            supportTicketServiceProvider.overrideWithValue(mockService),
          ],
        );

        // Act
        final ticketFuture = container.read(ticketDetailProvider('ticket-1').future);
        final loadedTicket = await ticketFuture;

        // Assert
        expect(loadedTicket.id, testTicket1.id);
        expect(loadedTicket.title, testTicket1.title);
      });
    });
  });
}
