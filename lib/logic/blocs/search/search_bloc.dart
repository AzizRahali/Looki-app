import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/loomea_repository.dart';
import 'search_event.dart';
import 'search_state.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final LoomeeaRepository repository;

  // Searches run concurrently; only the most recent one may update the state.
  int _latestRequest = 0;

  SearchBloc({required this.repository}) : super(const SearchState()) {
    on<SearchSalons>(_onSearchSalons);
    on<SmartSearch>(_onSmartSearch);
    on<SearchAvailability>(_onSearchAvailability);
    on<ClearSearch>(_onClearSearch);
  }

  Future<void> _onSearchSalons(
    SearchSalons event,
    Emitter<SearchState> emit,
  ) async {
    final request = ++_latestRequest;
    emit(state.copyWith(
      status: SearchStatus.loading,
      query: event.query,
      isAvailabilityMode: false,
      isSmartMode: false,
      clearSmartFilters: true,
    ));
    try {
      final results = await repository.searchSalons(event.query);
      if (request != _latestRequest) return;
      emit(state.copyWith(status: SearchStatus.loaded, results: results));
    } catch (e) {
      if (request != _latestRequest) return;
      emit(state.copyWith(status: SearchStatus.error, error: e.toString()));
    }
  }

  Future<void> _onSmartSearch(
    SmartSearch event,
    Emitter<SearchState> emit,
  ) async {
    final request = ++_latestRequest;
    emit(state.copyWith(
      status: SearchStatus.loading,
      query: event.query,
      isAvailabilityMode: false,
      isSmartMode: true,
      aiUsed: false,
      clearSmartFilters: true,
    ));
    try {
      final result = await repository.smartSearch(event.query);
      if (request != _latestRequest) return;
      emit(state.copyWith(
        status: SearchStatus.loaded,
        results: result.salons,
        aiUsed: result.aiUsed,
        smartFilters: result.filters,
      ));
    } catch (e) {
      if (request != _latestRequest) return;
      emit(state.copyWith(status: SearchStatus.error, error: e.toString()));
    }
  }

  Future<void> _onSearchAvailability(
    SearchAvailability event,
    Emitter<SearchState> emit,
  ) async {
    final request = ++_latestRequest;
    emit(state.copyWith(
      status: SearchStatus.loading,
      isAvailabilityMode: true,
      availabilityDate: event.date,
      availabilityTime: event.time,
      isSmartMode: false,
      clearSmartFilters: true,
    ));
    try {
      final results = await repository.searchAvailable(
        date: event.date,
        time: event.time,
        durationMinutes: event.durationMinutes,
      );
      if (request != _latestRequest) return;
      emit(state.copyWith(status: SearchStatus.loaded, results: results));
    } catch (e) {
      if (request != _latestRequest) return;
      emit(state.copyWith(status: SearchStatus.error, error: e.toString()));
    }
  }

  void _onClearSearch(ClearSearch event, Emitter<SearchState> emit) {
    _latestRequest++;
    emit(const SearchState());
  }
}
