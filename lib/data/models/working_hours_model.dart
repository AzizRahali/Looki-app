import 'package:equatable/equatable.dart';

class WorkingHoursModel extends Equatable {
  final int dayOfWeek; // 0 = Monday … 6 = Sunday
  final String openTime;  // "HH:mm"
  final String closeTime; // "HH:mm"
  final bool closed;

  const WorkingHoursModel({
    required this.dayOfWeek,
    required this.openTime,
    required this.closeTime,
    required this.closed,
  });

  static const _days = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];

  String get dayName => _days[dayOfWeek];

  factory WorkingHoursModel.fromJson(Map<String, dynamic> json) {
    return WorkingHoursModel(
      dayOfWeek: (json['dayOfWeek'] as num?)?.toInt() ?? 0,
      openTime: json['openTime'] as String? ?? '09:00',
      closeTime: json['closeTime'] as String? ?? '20:00',
      closed: json['closed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'dayOfWeek': dayOfWeek,
    'openTime': closed ? null : openTime,
    'closeTime': closed ? null : closeTime,
    'closed': closed,
  };

  WorkingHoursModel copyWith({
    String? openTime,
    String? closeTime,
    bool? closed,
  }) {
    return WorkingHoursModel(
      dayOfWeek: dayOfWeek,
      openTime: openTime ?? this.openTime,
      closeTime: closeTime ?? this.closeTime,
      closed: closed ?? this.closed,
    );
  }

  static List<WorkingHoursModel> defaultSchedule() => List.generate(7, (i) {
    return WorkingHoursModel(
      dayOfWeek: i,
      openTime: '09:00',
      closeTime: '20:00',
      closed: false,
    );
  });

  @override
  List<Object?> get props => [dayOfWeek, openTime, closeTime, closed];
}
