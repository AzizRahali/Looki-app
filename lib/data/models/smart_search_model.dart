import 'package:equatable/equatable.dart';

import 'salon_model.dart';

/// Filters the backend extracted from a natural-language query.
class SmartSearchFilters extends Equatable {
  final String? service;
  final String? category;
  final String? location;
  final double? maxPrice;
  final String? date;
  final String? timeFrom;
  final String? timeTo;

  const SmartSearchFilters({
    this.service,
    this.category,
    this.location,
    this.maxPrice,
    this.date,
    this.timeFrom,
    this.timeTo,
  });

  factory SmartSearchFilters.fromJson(Map<String, dynamic> json) {
    return SmartSearchFilters(
      service: json['service'] as String?,
      category: json['category'] as String?,
      location: json['location'] as String?,
      maxPrice: (json['maxPrice'] as num?)?.toDouble(),
      date: json['date'] as String?,
      timeFrom: json['timeFrom'] as String?,
      timeTo: json['timeTo'] as String?,
    );
  }

  bool get isEmpty =>
      service == null &&
      category == null &&
      location == null &&
      maxPrice == null &&
      date == null;

  @override
  List<Object?> get props =>
      [service, category, location, maxPrice, date, timeFrom, timeTo];
}

class SmartSearchResult {
  final List<Salon> salons;

  /// False when the backend fell back to keyword search.
  final bool aiUsed;
  final SmartSearchFilters? filters;

  const SmartSearchResult({
    required this.salons,
    required this.aiUsed,
    this.filters,
  });
}
