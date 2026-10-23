import 'package:equatable/equatable.dart';

import '../../../data/models/appointment_model.dart';
import '../../../data/repositories/loomea_repository.dart';

enum BookingStatus { initial, loading, loaded, error }

class BookingState extends Equatable {
  final BookingStatus status;
  final List<Appointment> upcoming;
  final List<Appointment> past;
  final int selectedDay;
  final int selectedMonth;
  final int selectedYear;
  final String selectedTime;
  final String error;
  final List<TimeSlot> slots;
  final bool slotsLoading;
  /// True when a background poll detected a status change the user hasn't
  /// seen yet. Cleared as soon as the Bookings tab is opened.
  final bool hasStatusUpdate;

  const BookingState({
    this.status = BookingStatus.initial,
    this.upcoming = const [],
    this.past = const [],
    this.selectedDay = 0,
    this.selectedMonth = 0,
    this.selectedYear = 0,
    this.selectedTime = '',
    this.error = '',
    this.slots = const [],
    this.slotsLoading = false,
    this.hasStatusUpdate = false,
  });

  BookingState copyWith({
    BookingStatus? status,
    List<Appointment>? upcoming,
    List<Appointment>? past,
    int? selectedDay,
    int? selectedMonth,
    int? selectedYear,
    String? selectedTime,
    String? error,
    List<TimeSlot>? slots,
    bool? slotsLoading,
    bool? hasStatusUpdate,
  }) {
    return BookingState(
      status: status ?? this.status,
      upcoming: upcoming ?? this.upcoming,
      past: past ?? this.past,
      selectedDay: selectedDay ?? this.selectedDay,
      selectedMonth: selectedMonth ?? this.selectedMonth,
      selectedYear: selectedYear ?? this.selectedYear,
      selectedTime: selectedTime ?? this.selectedTime,
      error: error ?? this.error,
      slots: slots ?? this.slots,
      slotsLoading: slotsLoading ?? this.slotsLoading,
      hasStatusUpdate: hasStatusUpdate ?? this.hasStatusUpdate,
    );
  }

  @override
  List<Object?> get props => [
        status,
        upcoming,
        past,
        selectedDay,
        selectedMonth,
        selectedYear,
        selectedTime,
        error,
        slots,
        slotsLoading,
        hasStatusUpdate,
      ];
}
