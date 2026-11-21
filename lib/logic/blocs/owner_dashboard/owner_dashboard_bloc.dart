import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/loomea_repository.dart';
import '../../../data/services/localization_service.dart';
import 'owner_dashboard_event.dart';
import 'owner_dashboard_state.dart';

class OwnerDashboardBloc
    extends Bloc<OwnerDashboardEvent, OwnerDashboardState> {
  final LoomeeaRepository repository;

  // Only the most recent insights request may update the state.
  int _latestInsightsRequest = 0;

  OwnerDashboardBloc({required this.repository})
      : super(const OwnerDashboardState()) {
    on<LoadDashboard>(_onLoadDashboard);
    on<RefreshDashboard>(_onRefreshDashboard);
    on<LoadInsights>(_onLoadInsights);
  }

  Future<void> _onLoadDashboard(
      LoadDashboard event, Emitter<OwnerDashboardState> emit) async {
    emit(state.copyWith(status: OwnerDashboardStatus.loading));
    try {
      final dashboard = await repository.getOwnerDashboard(event.salonId);
      emit(state.copyWith(
          status: OwnerDashboardStatus.loaded, dashboard: dashboard));
      add(LoadInsights(event.salonId, AppLocalizations.instance.locale));
    } catch (e) {
      emit(state.copyWith(
          status: OwnerDashboardStatus.error, error: e.toString()));
    }
  }

  Future<void> _onLoadInsights(
      LoadInsights event, Emitter<OwnerDashboardState> emit) async {
    final request = ++_latestInsightsRequest;
    emit(state.copyWith(insightsStatus: InsightsStatus.loading));
    try {
      final insights =
          await repository.getOwnerInsights(event.salonId, event.language);
      if (request != _latestInsightsRequest) return;
      emit(state.copyWith(
          insightsStatus: InsightsStatus.loaded, insights: insights));
    } catch (_) {
      if (request != _latestInsightsRequest) return;
      emit(state.copyWith(insightsStatus: InsightsStatus.error));
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
