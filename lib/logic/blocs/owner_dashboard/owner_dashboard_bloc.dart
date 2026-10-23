import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/loomea_repository.dart';
import 'owner_dashboard_event.dart';
import 'owner_dashboard_state.dart';

class OwnerDashboardBloc
    extends Bloc<OwnerDashboardEvent, OwnerDashboardState> {
  final LoomeeaRepository repository;

  OwnerDashboardBloc({required this.repository})
      : super(const OwnerDashboardState()) {
    on<LoadDashboard>(_onLoadDashboard);
    on<RefreshDashboard>(_onRefreshDashboard);
  }

  Future<void> _onLoadDashboard(
      LoadDashboard event, Emitter<OwnerDashboardState> emit) async {
    emit(state.copyWith(status: OwnerDashboardStatus.loading));
    try {
      final dashboard = await repository.getOwnerDashboard(event.salonId);
      emit(state.copyWith(
          status: OwnerDashboardStatus.loaded, dashboard: dashboard));
    } catch (e) {
      emit(state.copyWith(
          status: OwnerDashboardStatus.error, error: e.toString()));
    }
  }

  Future<void> _onRefreshDashboard(
      RefreshDashboard event, Emitter<OwnerDashboardState> emit) async {
    try {
      final dashboard = await repository.getOwnerDashboard(event.salonId);
      emit(state.copyWith(
          status: OwnerDashboardStatus.loaded, dashboard: dashboard));
    } catch (_) {
      // Silent refresh
    }
  }
}
