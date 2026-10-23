import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/owner_booking_model.dart';
import '../../../data/repositories/loomea_repository.dart';
import '../../../data/services/notification_service.dart';
import 'owner_booking_event.dart';
import 'owner_booking_state.dart';

class OwnerBookingBloc extends Bloc<OwnerBookingEvent, OwnerBookingState> {
  final LoomeeaRepository repository;
  String? _currentSalonId;

  OwnerBookingBloc({required this.repository})
      : super(const OwnerBookingState()) {
    on<LoadOwnerBookings>(_onLoadBookings);
    on<ConfirmBooking>(_onConfirmBooking);
    on<CompleteBooking>(_onCompleteBooking);
    on<RejectBooking>(_onRejectBooking);
    on<SilentRefreshBookings>(_onSilentRefresh);
  }

  Future<void> _onLoadBookings(
      LoadOwnerBookings event, Emitter<OwnerBookingState> emit) async {
    _currentSalonId = event.salonId;
    emit(state.copyWith(
        status: OwnerBookingStatus.loading, filter: event.filter));
    try {
      List<OwnerBooking> bookings;
      switch (event.filter) {
        case 'past':
          bookings = await repository.getOwnerPastBookings(event.salonId);
          break;
        case 'all':
          bookings = await repository.getOwnerBookings(event.salonId);
          break;
        default:
          bookings = await repository.getOwnerUpcomingBookings(event.salonId);
      }
      emit(state.copyWith(
          status: OwnerBookingStatus.loaded, bookings: bookings));
    } catch (e) {
      emit(state.copyWith(
          status: OwnerBookingStatus.error, error: e.toString()));
    }
  }

  Future<void> _onConfirmBooking(
      ConfirmBooking event, Emitter<OwnerBookingState> emit) async {
    emit(state.copyWith(status: OwnerBookingStatus.acting));
    try {
      await repository.confirmBooking(event.bookingId);
      if (_currentSalonId != null) {
        add(LoadOwnerBookings(_currentSalonId!, filter: state.filter));
      } else {
        emit(state.copyWith(status: OwnerBookingStatus.loaded));
      }
    } catch (e) {
      emit(state.copyWith(
          status: OwnerBookingStatus.error, error: e.toString()));
    }
  }

  Future<void> _onCompleteBooking(
      CompleteBooking event, Emitter<OwnerBookingState> emit) async {
    emit(state.copyWith(status: OwnerBookingStatus.acting));
    try {
      await repository.completeBooking(event.bookingId);
      if (_currentSalonId != null) {
        add(LoadOwnerBookings(_currentSalonId!, filter: state.filter));
      } else {
        emit(state.copyWith(status: OwnerBookingStatus.loaded));
      }
    } catch (e) {
      emit(state.copyWith(
          status: OwnerBookingStatus.error, error: e.toString()));
    }
  }

  Future<void> _onRejectBooking(
      RejectBooking event, Emitter<OwnerBookingState> emit) async {
    emit(state.copyWith(status: OwnerBookingStatus.acting));
    try {
      await repository.rejectBooking(event.bookingId, reason: event.reason);
      if (_currentSalonId != null) {
        add(LoadOwnerBookings(_currentSalonId!, filter: state.filter));
      } else {
        emit(state.copyWith(status: OwnerBookingStatus.loaded));
      }
    } catch (e) {
      emit(state.copyWith(
          status: OwnerBookingStatus.error, error: e.toString()));
    }
  }

  Future<void> _onSilentRefresh(
      SilentRefreshBookings event, Emitter<OwnerBookingState> emit) async {
    try {
      List<OwnerBooking> fresh;
      switch (state.filter) {
        case 'past':
          fresh = await repository.getOwnerPastBookings(event.salonId);
          break;
        case 'all':
          fresh = await repository.getOwnerBookings(event.salonId);
          break;
        default:
          fresh = await repository.getOwnerUpcomingBookings(event.salonId);
      }
      // Notify owner for new PENDING bookings (new bookings or reschedules)
      final prevIds = {for (final b in state.bookings) b.id: b.status};
      for (final b in fresh) {
        final prevStatus = prevIds[b.id];
        if (b.status == 'PENDING') {
          if (prevStatus == null) {
            // Brand new booking
            NotificationService.instance.showNewBooking(b);
          } else if (prevStatus != 'PENDING') {
            // Rescheduled back to pending
            NotificationService.instance.showRescheduledByClient(
              b.clientName.isNotEmpty ? b.clientName : 'A client',
              b.timeRange,
            );
          }
        }
      }
      emit(state.copyWith(status: OwnerBookingStatus.loaded, bookings: fresh));
    } catch (_) {}
  }
}
