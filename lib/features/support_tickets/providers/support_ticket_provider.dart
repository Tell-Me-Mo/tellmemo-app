import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pm_master_v2/features/support_tickets/models/support_ticket.dart';
import 'package:pm_master_v2/features/support_tickets/services/support_ticket_service.dart';
import 'package:pm_master_v2/features/auth/presentation/providers/auth_provider.dart';

final supportTicketServiceProvider = Provider<SupportTicketService>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return SupportTicketService(authRepository: authRepository);
});

final ticketsProvider =
    StateNotifierProvider<TicketsNotifier, AsyncValue<List<SupportTicket>>>(
        (ref) {
  final service = ref.watch(supportTicketServiceProvider);
  return TicketsNotifier(service);
});

class TicketsNotifier extends StateNotifier<AsyncValue<List<SupportTicket>>> {
  final SupportTicketService _service;

  TicketsNotifier(this._service) : super(const AsyncValue.loading()) {
    loadTickets();
  }

  Future<void> loadTickets({
    TicketStatus? status,
    TicketPriority? priority,
    TicketType? type,
    bool assignedToMe = false,
    bool createdByMe = false,
  }) async {
    state = const AsyncValue.loading();
    try {
      final tickets = await _service.getTickets(
        status: status,
        priority: priority,
        type: type,
        assignedToMe: assignedToMe,
        createdByMe: createdByMe,
      );
      state = AsyncValue.data(tickets);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> refresh() async {
    await loadTickets();
  }

  void addTicket(SupportTicket ticket) {
    state.whenData((tickets) {
      state = AsyncValue.data([ticket, ...tickets]);
    });
  }

  void updateTicket(SupportTicket updatedTicket) {
    state.whenData((tickets) {
      final newTickets = tickets.map((ticket) {
        return ticket.id == updatedTicket.id ? updatedTicket : ticket;
      }).toList();
      state = AsyncValue.data(newTickets);
    });
  }

  void removeTicket(String ticketId) {
    state.whenData((tickets) {
      final newTickets = tickets.where((t) => t.id != ticketId).toList();
      state = AsyncValue.data(newTickets);
    });
  }
}

final selectedTicketProvider = StateProvider<SupportTicket?>((ref) => null);

final ticketCommentsProvider = FutureProvider.family<List<TicketComment>, String>(
  (ref, ticketId) async {
    final service = ref.watch(supportTicketServiceProvider);
    return service.getComments(ticketId);
  },
);

final ticketDetailProvider = FutureProvider.family<SupportTicket, String>(
  (ref, ticketId) async {
    final service = ref.watch(supportTicketServiceProvider);
    return service.getTicket(ticketId);
  },
);