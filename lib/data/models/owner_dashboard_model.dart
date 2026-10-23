import 'package:equatable/equatable.dart';
import 'owner_booking_model.dart';

class Dashboard extends Equatable {
  final String salonId;
  final String salonName;
  final int todayAppointments;
  final int upcomingAppointments;
  final int completedAppointments;
  final int cancelledAppointments;
  final double todayRevenue;
  final double totalRevenue;
  final List<OwnerBooking> todayBookings;

  const Dashboard({
    required this.salonId,
    required this.salonName,
    required this.todayAppointments,
    required this.upcomingAppointments,
    required this.completedAppointments,
    required this.cancelledAppointments,
    required this.todayRevenue,
    required this.totalRevenue,
    required this.todayBookings,
  });

  factory Dashboard.fromJson(Map<String, dynamic> json) {
    return Dashboard(
      salonId: json['salonId'] as String? ?? '',
      salonName: json['salonName'] as String? ?? '',
      todayAppointments: json['todayAppointments'] as int? ?? 0,
      upcomingAppointments: json['upcomingAppointments'] as int? ?? 0,
      completedAppointments: json['completedAppointments'] as int? ?? 0,
      cancelledAppointments: json['cancelledAppointments'] as int? ?? 0,
      todayRevenue: (json['todayRevenue'] as num?)?.toDouble() ?? 0,
      totalRevenue: (json['totalRevenue'] as num?)?.toDouble() ?? 0,
      todayBookings: (json['todayBookings'] as List?)
              ?.map(
                  (b) => OwnerBooking.fromJson(b as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  @override
  List<Object?> get props => [
        salonId,
        todayAppointments,
        upcomingAppointments,
        completedAppointments,
        cancelledAppointments,
        todayRevenue,
        totalRevenue,
        todayBookings,
      ];
}
