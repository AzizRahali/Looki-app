import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/appointment_model.dart';
import '../../../data/repositories/loomea_repository.dart';
import '../../../data/services/notification_service.dart';
import 'booking_event.dart';
import 'booking_state.dart';

class BookingBloc extends Bloc<BookingEvent, BookingState> {
  final LoomeeaRepository repository;

  /// Tracks the last slot query params for polling refresh.
  String? _lastSlotSalonId;
  String? _lastSlotDate;
  int _lastSlotDuration = 60;

  /// IDs of appointments for which a 1h reminder has already been shown.
  final Set<String> _reminderSent = {};

  BookingBloc({required this.repository}) : super(const BookingState()) {
    on<LoadAppointments>(_onLoadAppointments);
    on<SelectDate>(_onSelectDate);
    on<SelectTimeSlot>(_onSelectTimeSlot);
    on<ConfirmBooking>(_onConfirmBooking);
    on<RescheduleBooking>(_onRescheduleBooking);
    on<CancelBooking>(_onCancelBooking);
    on<LoadTimeSlots>(_onLoadTimeSlots);
    on<RefreshSlots>(_onRefreshSlots);
    on<RefreshAppointments>(_onRefreshAppointments);
    on<ConfirmAttendance>(_onConfirmAttendance);
  }

  Future<void> _onLoadAppointments(
    LoadAppointments event,
    Emitter<BookingState> emit,
  ) async {
    // Clearing the badge: user opened the Bookings tab.
    emit(state.copyWith(status: BookingStatus.loading, hasStatusUpdate: false));
    try {
      final upcoming = await repository.getUpcomingAppointments();
      final past = await repository.getPastAppointments();
      _checkReminders(upcoming);
      emit(state.copyWith(
        status: BookingStatus.loaded,
        upcoming: upcoming,
        past: past,
        hasStatusUpdate: false,
      ));
    } catch (e) {
      emit(state.copyWith(status: BookingStatus.error, error: e.toString()));
    }
  }

  void _onSelectDate(SelectDate event, Emitter<BookingState> emit) {
    emit(state.copyWith(
      selectedDay: event.day,
      selectedMonth: event.month,
      selectedYear: event.year,
      selectedTime: '',
    ));
  }

  void _onSelectTimeSlot(SelectTimeSlot event, Emitter<BookingState> emit) {
    emit(state.copyWith(selectedTime: event.time));
  }

  Future<void> _onConfirmBooking(
    ConfirmBooking event,
    Emitter<BookingState> emit,
  ) async {
    emit(state.copyWith(status: BookingStatus.loading));
    try {
      await repository.createBooking(
        salonId: event.salonId,
        date: event.date,
        startTime: event.startTime,
        serviceIds: event.serviceIds,
        paymentMethod: event.paymentMethod,
        notes: event.notes,
      );
      // Reload appointments after booking
      final upcoming = await repository.getUpcomingAppointments();
      final past = await repository.getPastAppointments();
      emit(state.copyWith(
        status: BookingStatus.loaded,
        upcoming: upcoming,
        past: past,
      ));
    } catch (e) {
      emit(state.copyWith(status: BookingStatus.error, error: e.toString()));
    }
  }

  Future<void> _onRescheduleBooking(
    RescheduleBooking event,
    Emitter<BookingState> emit,
  ) async {
    emit(state.copyWith(status: BookingStatus.loading));
    try {
      await repository.rescheduleBooking(
        bookingId: event.bookingId,
        date: event.date,
        startTime: event.startTime,
      );
      final upcoming = await repository.getUpcomingAppointments();
      final past = await repository.getPastAppointments();
      emit(state.copyWith(
        status: BookingStatus.loaded,
        upcoming: upcoming,
        past: past,
      ));
    } catch (e) {
      emit(state.copyWith(status: BookingStatus.error, error: e.toString()));
    }
  }

  Future<void> _onCancelBooking(
    CancelBooking event,
    Emitter<BookingState> emit,
  ) async {
    emit(state.copyWith(status: BookingStatus.loading));
    try {
      await repository.cancelBooking(event.bookingId);
      final upcoming = await repository.getUpcomingAppointments();
      final past = await repository.getPastAppointments();
      emit(state.copyWith(
        status: BookingStatus.loaded,
        upcoming: upcoming,
        past: past,
      ));
    } catch (e) {
      emit(state.copyWith(status: BookingStatus.error, error: e.toString()));
    }
  }

  /// Fetch available time slots for the selected date.
  Future<void> _onLoadTimeSlots(
    LoadTimeSlots event,
    Emitter<BookingState> emit,
  ) async {
    // Store params for polling refresh
    _lastSlotSalonId = event.salonId;
    _lastSlotDate = event.date;
    _lastSlotDuration = event.durationMinutes;

    emit(state.copyWith(slotsLoading: true, slots: const [], selectedTime: ''));
    try {
      final slots = await repository.getAvailableSlots(
        salonId: event.salonId,
        date: event.date,
        durationMinutes: event.durationMinutes,
      );
      emit(state.copyWith(slotsLoading: false, slots: slots));
    } catch (e) {
      emit(state.copyWith(slotsLoading: false));
    }
  }

  /// Silent slot refresh for polling — no loading indicator.
  Future<void> _onRefreshSlots(
    RefreshSlots event,
    Emitter<BookingState> emit,
  ) async {
    if (_lastSlotSalonId == null || _lastSlotDate == null) return;
    try {
      final slots = await repository.getAvailableSlots(
        salonId: _lastSlotSalonId!,
        date: _lastSlotDate!,
        durationMinutes: _lastSlotDuration,
      );

      // If user's selected slot got booked, deselect it
      String selectedTime = state.selectedTime;
      if (selectedTime.isNotEmpty) {
        final stillAvailable = slots.any(
            (s) => s.time == selectedTime && s.status.toUpperCase() != 'BOOKED');
        if (!stillAvailable) {
          selectedTime = '';
        }
      }

      emit(state.copyWith(slots: slots, selectedTime: selectedTime));
    } catch (_) {
      // Silent refresh — don't show error
    }
  }

  /// Silent appointment refresh for polling — only emits when status changes.
  Future<void> _onRefreshAppointments(
    RefreshAppointments event,
    Emitter<BookingState> emit,
  ) async {
    try {
      final upcoming = await repository.getUpcomingAppointments();
      final past = await repository.getPastAppointments();

      _checkReminders(upcoming);

      final changed = _appointmentsChanged(state.upcoming, upcoming) ||
          _appointmentsChanged(state.past, past);
      if (changed) {
        // Detect status changes and fire notifications
        final prevMap = {for (final a in [...state.upcoming, ...state.past]) a.id: a.status};
        for (final a in [...upcoming, ...past]) {
          final prevStatus = prevMap[a.id];
          if (prevStatus != null && prevStatus != a.status) {
            NotificationService.instance.showBookingStatusChange(a.salonName, a.status);
          }
        }
        emit(state.copyWith(
          status: BookingStatus.loaded,
          upcoming: upcoming,
          past: past,
          hasStatusUpdate: true,
        ));
      }
    } catch (_) {
      // Silent refresh — don't show error
    }
  }

  /// Confirm attendance for a risky-tier appointment.
  Future<void> _onConfirmAttendance(
    ConfirmAttendance event,
    Emitter<BookingState> emit,
  ) async {
    emit(state.copyWith(status: BookingStatus.loading));
    try {
      await repository.confirmAttendance(event.bookingId);
      final upcoming = await repository.getUpcomingAppointments();
      final past = await repository.getPastAppointments();
      emit(state.copyWith(
        status: BookingStatus.loaded,
        upcoming: upcoming,
        past: past,
      ));
    } catch (e) {
      emit(state.copyWith(status: BookingStatus.error, error: e.toString()));
    }
  }

  void _checkReminders(List<Appointment> upcoming) {
    final now = DateTime.now();
    for (final a in upcoming) {
      if (!a.isConfirmed) continue;
      if (_reminderSent.contains(a.id)) continue;
      final apptTime = _parseDateTime(a.date, a.time);
      if (apptTime == null) continue;
      final diff = apptTime.difference(now).inMinutes;
      if (diff >= 45 && diff <= 75) {
        _reminderSent.add(a.id);
        NotificationService.instance.showBookingReminder(a.salonName, a.time);
      }
    }
  }

  DateTime? _parseDateTime(String date, String time) {
    try {
      final d = date.split('-');
      final t = time.split(':');
      return DateTime(int.parse(d[0]), int.parse(d[1]), int.parse(d[2]),
          int.parse(t[0]), int.parse(t[1]));
    } catch (_) {
      return null;
    }
  }

  /// Returns true when lists differ in length, IDs, status, date or time.
  bool _appointmentsChanged(
      List<Appointment> current, List<Appointment> incoming) {
    if (current.length != incoming.length) return true;
    final currentMap = {
      for (final a in current) a.id: '${a.status}|${a.date}|${a.time}'
    };
    for (final a in incoming) {
      if (currentMap[a.id] != '${a.status}|${a.date}|${a.time}') return true;
    }
    return false;
  }
}
