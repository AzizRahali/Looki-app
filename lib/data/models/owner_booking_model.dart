import 'package:equatable/equatable.dart';

import '../services/localization_service.dart';

class BookingServiceItem extends Equatable {
  final String serviceName;
  final double price;
  final int durationMinutes;

  const BookingServiceItem({
    required this.serviceName,
    required this.price,
    required this.durationMinutes,
  });

  factory BookingServiceItem.fromJson(Map<String, dynamic> json) {
    return BookingServiceItem(
      serviceName: json['serviceName'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      durationMinutes: json['durationMinutes'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [serviceName, price, durationMinutes];
}

class OwnerBooking extends Equatable {
  final String id;
  final String salonId;
  final String salonName;
  final String salonAddress;
  final String clientName;
  final String date;
  final String startTime;
  final String endTime;
  final String status;
  final String paymentMethod;
  /// AWAITING_PAYMENT | PAID | REFUNDED for card bookings, null otherwise.
  final String? paymentStatus;
  final String notes;
  final double totalPrice;
  final List<BookingServiceItem> services;
  final int reliabilityScore;
  final String reliabilityTier;
  final String clientPhone;
  final String clientAvatarUrl;

  const OwnerBooking({
    required this.id,
    required this.salonId,
    required this.salonName,
    required this.salonAddress,
    required this.clientName,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.paymentMethod,
    this.paymentStatus,
    required this.notes,
    required this.totalPrice,
    required this.services,
    this.reliabilityScore = 100,
    this.reliabilityTier = 'TRUSTED',
    this.clientPhone = '',
    this.clientAvatarUrl = '',
  });

  factory OwnerBooking.fromJson(Map<String, dynamic> json) {
    return OwnerBooking(
      id: json['id'] as String? ?? '',
      salonId: json['salonId'] as String? ?? '',
      salonName: json['salonName'] as String? ?? '',
      salonAddress: json['salonAddress'] as String? ?? '',
      clientName: json['clientName'] as String? ?? '',
      date: json['date'] as String? ?? '',
      startTime: json['startTime'] as String? ?? '',
      endTime: json['endTime'] as String? ?? '',
      status: json['status'] as String? ?? '',
      paymentMethod: json['paymentMethod'] as String? ?? '',
      paymentStatus: json['paymentStatus'] as String?,
      notes: json['notes'] as String? ?? '',
      totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? 0,
      services: (json['services'] as List?)
              ?.map((s) =>
                  BookingServiceItem.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
      reliabilityScore: json['clientReliabilityScore'] as int? ?? 100,
      reliabilityTier: json['clientReliabilityTier'] as String? ?? 'TRUSTED',
      clientPhone: json['clientPhone'] as String? ?? '',
      clientAvatarUrl: json['clientAvatarUrl'] as String? ?? '',
    );
  }

  bool get isPending => status == 'PENDING';
  bool get isConfirmed => status == 'CONFIRMED';
  bool get isCompleted => status == 'COMPLETED';
  bool get isCancelled => status == 'CANCELLED';
  bool get isAwaitingPayment => paymentStatus == 'AWAITING_PAYMENT';
  bool get isPaidOnline => paymentStatus == 'PAID';
  String get priceText => formatPrice(totalPrice);
  String get servicesText => services.map((s) => s.serviceName).join(', ');
  String get timeRange {
    if (startTime.length < 5 || endTime.length < 5) return 'Time TBA';
    return '${startTime.substring(0, 5)} – ${endTime.substring(0, 5)}';
  }

  @override
  List<Object?> get props => [id, status, paymentStatus, date, startTime, endTime, clientName, reliabilityScore, reliabilityTier, clientPhone, clientAvatarUrl];
}
