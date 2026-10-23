import 'package:equatable/equatable.dart';

abstract class OwnerBookingEvent extends Equatable {
  const OwnerBookingEvent();
  @override
  List<Object?> get props => [];
}

class LoadOwnerBookings extends OwnerBookingEvent {
  final String salonId;
  final String filter;
  const LoadOwnerBookings(this.salonId, {this.filter = 'upcoming'});
  @override
  List<Object?> get props => [salonId, filter];
}

class ConfirmBooking extends OwnerBookingEvent {
  final String bookingId;
  const ConfirmBooking(this.bookingId);
  @override
  List<Object?> get props => [bookingId];
}

class CompleteBooking extends OwnerBookingEvent {
  final String bookingId;
  const CompleteBooking(this.bookingId);
  @override
  List<Object?> get props => [bookingId];
}

class RejectBooking extends OwnerBookingEvent {
  final String bookingId;
  final String reason;
  const RejectBooking(this.bookingId, {required this.reason});
  @override
  List<Object?> get props => [bookingId, reason];
}

/// Silent background refresh — no loading indicator, only emits on change.
class SilentRefreshBookings extends OwnerBookingEvent {
  final String salonId;
  const SilentRefreshBookings(this.salonId);
  @override
  List<Object?> get props => [salonId];
}

