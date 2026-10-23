import 'package:equatable/equatable.dart';

class WaitlistEntry extends Equatable {
  final String id;
  final String salonId;
  final String salonName;
  final String date;
  final String status; // WAITING, NOTIFIED, EXPIRED
  final String createdAt;

  const WaitlistEntry({
    required this.id,
    required this.salonId,
    required this.salonName,
    required this.date,
    required this.status,
    required this.createdAt,
  });

  factory WaitlistEntry.fromJson(Map<String, dynamic> json) {
    return WaitlistEntry(
      id: json['id'] as String,
      salonId: json['salonId'] as String,
      salonName: json['salonName'] as String,
      date: json['date'] as String,
      status: json['status'] as String,
      createdAt: json['createdAt'] as String? ?? '',
    );
  }

  bool get isWaiting => status == 'WAITING';
  bool get isNotified => status == 'NOTIFIED';

  @override
  List<Object?> get props => [id, status];
}
