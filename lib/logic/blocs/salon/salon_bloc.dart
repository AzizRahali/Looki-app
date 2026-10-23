import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/loomea_repository.dart';
import 'salon_event.dart';
import 'salon_state.dart';

class SalonBloc extends Bloc<SalonEvent, SalonState> {
  final LoomeeaRepository repository;

  SalonBloc({required this.repository}) : super(const SalonState()) {
    on<LoadSalons>(_onLoadSalons);
    on<LoadSalonByName>(_onLoadSalonByName);
    on<FilterByCategory>(_onFilterByCategory);
    on<ToggleService>(_onToggleService);
    on<SelectCategory>(_onSelectCategory);
  }

  Future<void> _onLoadSalons(
    LoadSalons event,
    Emitter<SalonState> emit,
  ) async {
    emit(state.copyWith(status: SalonStatus.loading));
    try {
      final salons = await repository.getSalons();
      emit(state.copyWith(status: SalonStatus.loaded, salons: salons));
    } catch (e) {
      emit(state.copyWith(status: SalonStatus.error, error: e.toString()));
    }
  }

  Future<void> _onLoadSalonByName(
    LoadSalonByName event,
    Emitter<SalonState> emit,
  ) async {
    emit(state.copyWith(status: SalonStatus.loading));
    try {
      final salon = await repository.getSalonByName(event.name);
      final category =
          salon != null && salon.categories.isNotEmpty
              ? salon.categories.first
              : '';
      emit(state.copyWith(
        status: SalonStatus.loaded,
        selectedSalon: salon,
        selectedServiceIds: [],
        selectedCategory: category,
      ));
    } catch (e) {
      emit(state.copyWith(status: SalonStatus.error, error: e.toString()));
    }
  }

  void _onFilterByCategory(
    FilterByCategory event,
    Emitter<SalonState> emit,
  ) async {
    emit(state.copyWith(status: SalonStatus.loading));
    try {
      final salons = await repository.getSalonsByCategory(event.category);
      emit(state.copyWith(status: SalonStatus.loaded, salons: salons));
    } catch (e) {
      emit(state.copyWith(status: SalonStatus.error, error: e.toString()));
    }
  }

  void _onToggleService(
    ToggleService event,
    Emitter<SalonState> emit,
  ) {
    final current = List<String>.from(state.selectedServiceIds);
    if (current.contains(event.serviceId)) {
      current.remove(event.serviceId);
    } else {
      current.add(event.serviceId);
    }
    emit(state.copyWith(selectedServiceIds: current));
  }

  void _onSelectCategory(
    SelectCategory event,
    Emitter<SalonState> emit,
  ) {
    emit(state.copyWith(selectedCategory: event.category));
  }
}
