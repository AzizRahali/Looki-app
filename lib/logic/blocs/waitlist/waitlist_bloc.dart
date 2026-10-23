import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/loomea_repository.dart';
import '../../../data/services/notification_service.dart';
import 'waitlist_event.dart';
import 'waitlist_state.dart';

class WaitlistBloc extends Bloc<WaitlistEvent, WaitlistState> {
  final LoomeeaRepository repository;

  WaitlistBloc({required this.repository}) : super(const WaitlistState()) {
    on<LoadWaitlist>(_onLoad);
    on<RefreshWaitlist>(_onRefresh);
    on<JoinWaitlist>(_onJoin);
    on<LeaveWaitlist>(_onLeave);
  }

  Future<void> _onLoad(LoadWaitlist event, Emitter<WaitlistState> emit) async {
    emit(state.copyWith(status: WaitlistStatus.loading));
    try {
      final entries = await repository.getMyWaitlist();
      emit(state.copyWith(status: WaitlistStatus.loaded, entries: entries));
    } catch (e) {
      emit(state.copyWith(status: WaitlistStatus.error, error: e.toString()));
    }
  }

  Future<void> _onRefresh(RefreshWaitlist event, Emitter<WaitlistState> emit) async {
    if (state.status == WaitlistStatus.initial) return;
    try {
      final entries = await repository.getMyWaitlist();
      // Detect newly NOTIFIED entries and fire a local notification
      final prevIds = {for (final e in state.entries) e.id: e.status};
      for (final e in entries) {
        if (e.isNotified && prevIds[e.id] == 'WAITING') {
          NotificationService.instance.showWaitlistAvailable(e.salonName, e.date);
        }
      }
      emit(state.copyWith(status: WaitlistStatus.loaded, entries: entries));
    } catch (_) {}
  }

  Future<void> _onJoin(JoinWaitlist event, Emitter<WaitlistState> emit) async {
    try {
      final entry = await repository.joinWaitlist(
          salonId: event.salonId, date: event.date);
      emit(state.copyWith(entries: [...state.entries, entry]));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onLeave(LeaveWaitlist event, Emitter<WaitlistState> emit) async {
    try {
      await repository.leaveWaitlist(event.entryId);
      final updated = state.entries.where((e) => e.id != event.entryId).toList();
      emit(state.copyWith(entries: updated));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }
}
