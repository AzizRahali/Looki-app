import 'package:equatable/equatable.dart';

class InsightSlot extends Equatable {
  /// 1 = Monday … 7 = Sunday.
  final int dayOfWeek;

  /// "morning", "afternoon" or "evening".
  final String partOfDay;
  final double bookingsPerWeek;

  const InsightSlot({
    required this.dayOfWeek,
    required this.partOfDay,
    required this.bookingsPerWeek,
  });

  static InsightSlot? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    return InsightSlot(
      dayOfWeek: (json['dayOfWeek'] as num?)?.toInt() ?? 1,
      partOfDay: json['partOfDay'] as String? ?? 'morning',
      bookingsPerWeek: (json['bookingsPerWeek'] as num?)?.toDouble() ?? 0,
    );
  }

  @override
  List<Object?> get props => [dayOfWeek, partOfDay, bookingsPerWeek];
}

class InsightService extends Equatable {
  final String name;
  final int bookings;

  const InsightService({required this.name, required this.bookings});

  @override
  List<Object?> get props => [name, bookings];
}

/// Owner business insights for the last [periodDays] days.
class OwnerInsights extends Equatable {
  final bool enoughData;
  final int periodDays;
  final int bookings;
  final int? bookingsChangePercent;
  final int revenue;
  final int? revenueChangePercent;
  final int? cancellationRate;
  final int? noShowRate;
  final int? returningClientRate;
  final List<InsightService> topServices;
  final InsightSlot? busiestSlot;
  final InsightSlot? quietestSlot;

  /// True when [summary] or [suggestions] were written by AI.
  final bool aiUsed;
  final String? summary;
  final List<String> suggestions;

  const OwnerInsights({
    required this.enoughData,
    required this.periodDays,
    required this.bookings,
    this.bookingsChangePercent,
    required this.revenue,
    this.revenueChangePercent,
    this.cancellationRate,
    this.noShowRate,
    this.returningClientRate,
    this.topServices = const [],
    this.busiestSlot,
    this.quietestSlot,
    this.aiUsed = false,
    this.summary,
    this.suggestions = const [],
  });

  factory OwnerInsights.fromJson(Map<String, dynamic> json) {
    final m = json['metrics'] as Map<String, dynamic>? ?? const {};
    int? optInt(String key) => (m[key] as num?)?.toInt();
    return OwnerInsights(
      enoughData: m['enoughData'] as bool? ?? false,
      periodDays: optInt('periodDays') ?? 28,
      bookings: optInt('bookings') ?? 0,
      bookingsChangePercent: optInt('bookingsChangePercent'),
      revenue: optInt('revenue') ?? 0,
      revenueChangePercent: optInt('revenueChangePercent'),
      cancellationRate: optInt('cancellationRate'),
      noShowRate: optInt('noShowRate'),
      returningClientRate: optInt('returningClientRate'),
      topServices: (m['topServices'] as List? ?? const [])
          .map((s) => s as Map<String, dynamic>)
          .map((s) => InsightService(
                name: s['name'] as String? ?? '',
                bookings: (s['bookings'] as num?)?.toInt() ?? 0,
              ))
          .toList(),
      busiestSlot:
          InsightSlot.fromJson(m['busiestSlot'] as Map<String, dynamic>?),
      quietestSlot:
          InsightSlot.fromJson(m['quietestSlot'] as Map<String, dynamic>?),
      aiUsed: json['aiUsed'] as bool? ?? false,
      summary: json['summary'] as String?,
      suggestions:
          (json['suggestions'] as List? ?? const []).cast<String>().toList(),
    );
  }

  @override
  List<Object?> get props => [
        enoughData,
        periodDays,
        bookings,
        bookingsChangePercent,
        revenue,
        revenueChangePercent,
        cancellationRate,
        noShowRate,
        returningClientRate,
        topServices,
        busiestSlot,
        quietestSlot,
        aiUsed,
        summary,
        suggestions,
      ];
}
