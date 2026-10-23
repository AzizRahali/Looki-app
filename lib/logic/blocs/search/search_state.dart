import 'package:equatable/equatable.dart';

import '../../../data/models/salon_model.dart';

enum SearchStatus { initial, loading, loaded, error }

class SearchState extends Equatable {
  final SearchStatus status;
  final List<Salon> results;
  final String query;
  final String error;
  final bool isAvailabilityMode;
  final String? availabilityDate;
  final String? availabilityTime;

  const SearchState({
    this.status = SearchStatus.initial,
    this.results = const [],
    this.query = '',
    this.error = '',
    this.isAvailabilityMode = false,
    this.availabilityDate,
    this.availabilityTime,
  });

  SearchState copyWith({
    SearchStatus? status,
    List<Salon>? results,
    String? query,
    String? error,
    bool? isAvailabilityMode,
    String? availabilityDate,
    String? availabilityTime,
  }) {
    return SearchState(
      status: status ?? this.status,
      results: results ?? this.results,
      query: query ?? this.query,
      error: error ?? this.error,
      isAvailabilityMode: isAvailabilityMode ?? this.isAvailabilityMode,
      availabilityDate: availabilityDate ?? this.availabilityDate,
      availabilityTime: availabilityTime ?? this.availabilityTime,
    );
  }

  @override
  List<Object?> get props => [status, results, query, error, isAvailabilityMode, availabilityDate, availabilityTime];
}
