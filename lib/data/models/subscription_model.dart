import 'package:equatable/equatable.dart';

class SubscriptionModel extends Equatable {
  final String id;
  final String plan; // MONTHLY | YEARLY
  final String planLabel; // "Monthly" | "Yearly"
  final double price;
  final String status; // ACTIVE | EXPIRED | CANCELLED
  final String startDate;
  final String endDate;
  final String paymentReference;

  const SubscriptionModel({
    required this.id,
    required this.plan,
    required this.planLabel,
    required this.price,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.paymentReference,
  });

  bool get isActive => status == 'ACTIVE';
  bool get isExpired => status == 'EXPIRED';
  bool get isCancelled => status == 'CANCELLED';

  DateTime? get endDateTime => DateTime.tryParse(endDate)?.toLocal();

  /// Whole days left in the current period (0 once it has ended).
  int get daysRemaining {
    final end = endDateTime;
    if (end == null) return 0;
    final days = end.difference(DateTime.now()).inHours / 24;
    return days <= 0 ? 0 : days.ceil();
  }

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionModel(
      id: json['id'] as String? ?? '',
      plan: json['plan'] as String? ?? '',
      planLabel: json['planLabel'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? '',
      startDate: json['startDate'] as String? ?? '',
      endDate: json['endDate'] as String? ?? '',
      paymentReference: json['paymentReference'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [
        id,
        plan,
        planLabel,
        price,
        status,
        startDate,
        endDate,
        paymentReference,
      ];
}

class SubscriptionPlanModel extends Equatable {
  final String plan; // MONTHLY | YEARLY
  final String label;
  final double price;
  final int durationDays;

  const SubscriptionPlanModel({
    required this.plan,
    required this.label,
    required this.price,
    required this.durationDays,
  });

  bool get isYearly => plan == 'YEARLY';

  factory SubscriptionPlanModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlanModel(
      plan: json['plan'] as String? ?? '',
      label: json['label'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      durationDays: (json['durationDays'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props => [plan, label, price, durationDays];
}
