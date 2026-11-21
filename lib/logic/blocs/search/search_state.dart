import 'package:equatable/equatable.dart';

import '../../../data/models/salon_model.dart';
import '../../../data/models/smart_search_model.dart';

enum SearchStatus { initial, loading, loaded, error }

class SearchState extends Equatable {
  final SearchStatus status;
  final List<Salon> results;
  final String query;
  final String error;
  final bool isAvailabilityMode;
  final String? availabilityDate;
  final String? availabilityTime;

  /// True while showing results of a natural-language (smart) search.
  final bool isSmartMode;

  /// Whether the last smart search was interpreted by AI (vs. keyword fallback).
  final bool aiUsed;
  final SmartSearchFilters? smartFilters;

  const SearchState({
    this.status = SearchStatus.initial,
    this.results = const [],
    this.query = '',
    this.error = '',
    this.isAvailabilityMode = false,
    this.availabilityDate,
    this.availabilityTime,
    this.isSmartMode = false,
    this.aiUsed = false,
    this.smartFilters,
  });

  SearchState copyWith({
    SearchStatus? status,
    List<Salon>? results,
    String? query,
    String? error,
    bool? isAvailabilityMode,
    String? availabilityDate,
    String? availabilityTime,
    bool? isSmartMode,
    bool? aiUsed,
    SmartSearchFilters? smartFilters,
    bool clearSmartFilters = false,
  }) {
    return SearchState(
      status: status ?? this.status,
      results: results ?? this.results,
      query: query ?? this.query,
      error: error ?? this.error,
      isAvailabilityMode: isAvailabilityMode ?? this.isAvailabilityMode,
      availabilityDate: availabilityDate ?? this.availabilityDate,
      availabilityTime: availabilityTime ?? this.availabilityTime,
      isSmartMode: isSmartMode ?? this.isSmartMode,
      aiUsed: aiUsed ?? this.aiUsed,
      smartFilters:
          clearSmartFilters ? null : (smartFilters ?? this.smartFilters),
    );
  }

  @override
  List<Object?> get props => [
        status,
        results,
        query,
        error,
        isAvailabilityMode,
        availabilityDate,
        availabilityTime,
        isSmartMode,
        aiUsed,
        smartFilters,
      ];
}
