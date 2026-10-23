import 'package:equatable/equatable.dart';

abstract class BookingEvent extends Equatable {
  const BookingEvent();

  @override
  List<Object?> get props => [];
}

class LoadAppointments extends BookingEvent {}

class SelectDate extends BookingEvent {
  final int day;
  final int month;
  final int year;
  const SelectDate(this.day, this.month, this.year);

  @override
  List<Object?> get props => [day, month, year];
}

class SelectTimeSlot extends BookingEvent {
  final String time;
  const SelectTimeSlot(this.time);

  @override
  List<Object?> get props => [time];
}

class ConfirmBooking extends BookingEvent {
  final String salonId;
  final String date;
  final String startTime;
  final List<String> serviceIds;
  final String? paymentMethod;
  final String? notes;

  const ConfirmBooking({
    required this.salonId,
    required this.date,
    required this.startTime,
    required this.serviceIds,
    this.paymentMethod,
    this.notes,
  });

  @override
  List<Object?> get props =>
      [salonId, date, startTime, serviceIds, paymentMethod, notes];
}

class RescheduleBooking extends BookingEvent {
  final String bookingId;
  final String date;
  final String startTime;

  const RescheduleBooking({
    required this.bookingId,
    required this.date,
    required this.startTime,
  });

  @override
  List<Object?> get props => [bookingId, date, startTime];
}

class CancelBooking extends BookingEvent {
  final String bookingId;

  const CancelBooking(this.bookingId);

  @override
  List<Object?> get props => [bookingId];
}

/// Load available time slots for a given salon + date.
class LoadTimeSlots extends BookingEvent {
  final String salonId;
  final String date; // yyyy-MM-dd
  final int durationMinutes;
  const LoadTimeSlots({
    required this.salonId,
    required this.date,
    this.durationMinutes = 60,
  });

  @override
  List<Object?> get props => [salonId, date, durationMinutes];
}

/// Refresh slots (called by polling timer).
class RefreshSlots extends BookingEvent {
  const RefreshSlots();
}

/// Silently refresh appointments (polling).
class RefreshAppointments extends BookingEvent {
  const RefreshAppointments();
}

/// Confirm attendance for a risky-tier appointment.
class ConfirmAttendance extends BookingEvent {
  final String bookingId;
  const ConfirmAttendance(this.bookingId);

  @override
  List<Object?> get props => [bookingId];
}
