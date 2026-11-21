import 'package:equatable/equatable.dart';

abstract class SearchEvent extends Equatable {
  const SearchEvent();

  @override
  List<Object?> get props => [];
}

class SearchSalons extends SearchEvent {
  final String query;
  const SearchSalons(this.query);

  @override
  List<Object?> get props => [query];
}

/// Natural-language search interpreted by AI on the backend.
class SmartSearch extends SearchEvent {
  final String query;
  const SmartSearch(this.query);

  @override
  List<Object?> get props => [query];
}

class SearchAvailability extends SearchEvent {
  final String date;
  final String time;
  final int durationMinutes;
  const SearchAvailability({required this.date, required this.time, this.durationMinutes = 60});
  @override
  List<Object?> get props => [date, time, durationMinutes];
}

class ClearSearch extends SearchEvent {}
