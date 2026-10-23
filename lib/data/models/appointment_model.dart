import 'package:equatable/equatable.dart';

import '../services/localization_service.dart';

class Appointment extends Equatable {
  final String id;
  final String bookingId;
  final String salonId;
  final String salonName;
  final String salonImageUrl;
  final List<String> serviceNames;
  final String date;
  final String time;
  final String endTime;
  final String address;
  final String status;
  final double totalPrice;
  final String paymentMethod;
  final bool requiresClientConfirmation;
  final String? clientConfirmedAt;

  const Appointment({
    required this.id,
    required this.bookingId,
    required this.salonId,
    required this.salonName,
    this.salonImageUrl = '',
    required this.serviceNames,
    required this.date,
    required this.time,
    required this.endTime,
    required this.address,
    required this.status,
    required this.totalPrice,
    required this.paymentMethod,
    this.requiresClientConfirmation = false,
    this.clientConfirmedAt,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'] as String,
      bookingId: json['bookingId'] as String? ?? json['id'] as String,
      salonId: json['salonId'] as String,
      salonName: json['salonName'] as String,
      salonImageUrl: json['salonImageUrl'] as String? ?? '',
      serviceNames: List<String>.from(json['serviceNames'] as List? ?? []),
      date: json['date'] as String,
      time: json['time'] as String? ?? json['startTime'] as String? ?? '',
      endTime: json['endTime'] as String? ?? '',
      address: json['address'] as String? ?? json['salonAddress'] as String? ?? '',
      status: json['status'] as String,
      totalPrice: (json['totalPrice'] as num? ?? 0).toDouble(),
      paymentMethod: json['paymentMethod'] as String? ?? 'PAY_AT_SALON',
      requiresClientConfirmation:
          json['requiresClientConfirmation'] as bool? ?? false,
      clientConfirmedAt: json['clientConfirmedAt'] as String?,
    );
  }

  bool get isPending => status == 'PENDING' || status == 'pending';
  bool get isConfirmed => status == 'CONFIRMED' || status == 'confirmed';
  bool get isUpcoming => isConfirmed || isPending;
  bool get isCompleted => status == 'COMPLETED' || status == 'completed';
  bool get isCancelled => status == 'CANCELLED' || status == 'cancelled';
  bool get isNoShow => status == 'NO_SHOW';
  bool get needsAttendanceConfirmation =>
      requiresClientConfirmation && clientConfirmedAt == null && isConfirmed;

  String get servicesText => serviceNames.join(', ');
  String get statusLabel => status.toUpperCase();
  String get priceText => formatPrice(totalPrice);

  @override
  List<Object?> get props =>
      [id, status, date, time, endTime, requiresClientConfirmation, clientConfirmedAt];
}
