import 'package:equatable/equatable.dart';
import '../../../data/models/owner_booking_model.dart';

enum OwnerBookingStatus { initial, loading, loaded, acting, error }

class OwnerBookingState extends Equatable {
  final OwnerBookingStatus status;
  final List<OwnerBooking> bookings;
  final String filter;
  final String? error;

  const OwnerBookingState({
    this.status = OwnerBookingStatus.initial,
    this.bookings = const [],
    this.filter = 'upcoming',
    this.error,
  });

  OwnerBookingState copyWith({
    OwnerBookingStatus? status,
    List<OwnerBooking>? bookings,
    String? filter,
    String? error,
  }) {
    return OwnerBookingState(
      status: status ?? this.status,
      bookings: bookings ?? this.bookings,
      filter: filter ?? this.filter,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, bookings, filter, error];
}
