import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/loomea_repository.dart';
import 'search_event.dart';
import 'search_state.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final LoomeeaRepository repository;

  SearchBloc({required this.repository}) : super(const SearchState()) {
    on<SearchSalons>(_onSearchSalons);
    on<SearchAvailability>(_onSearchAvailability);
    on<ClearSearch>(_onClearSearch);
  }

  Future<void> _onSearchSalons(
    SearchSalons event,
    Emitter<SearchState> emit,
  ) async {
    emit(state.copyWith(
      status: SearchStatus.loading,
      query: event.query,
      isAvailabilityMode: false,
    ));
    try {
      final results = await repository.searchSalons(event.query);
      emit(state.copyWith(status: SearchStatus.loaded, results: results));
    } catch (e) {
      emit(state.copyWith(status: SearchStatus.error, error: e.toString()));
    }
  }

  Future<void> _onSearchAvailability(
    SearchAvailability event,
    Emitter<SearchState> emit,
  ) async {
    emit(state.copyWith(
      status: SearchStatus.loading,
      isAvailabilityMode: true,
      availabilityDate: event.date,
      availabilityTime: event.time,
    ));
    try {
      final results = await repository.searchAvailable(
        date: event.date,
        time: event.time,
        durationMinutes: event.durationMinutes,
      );
      emit(state.copyWith(status: SearchStatus.loaded, results: results));
    } catch (e) {
      emit(state.copyWith(status: SearchStatus.error, error: e.toString()));
    }
  }

  void _onClearSearch(ClearSearch event, Emitter<SearchState> emit) {
    emit(const SearchState());
  }
}
