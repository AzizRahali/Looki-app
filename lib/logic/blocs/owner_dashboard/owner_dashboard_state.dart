import 'package:equatable/equatable.dart';
import '../../../data/models/owner_dashboard_model.dart';

enum OwnerDashboardStatus { initial, loading, loaded, error }

class OwnerDashboardState extends Equatable {
  final OwnerDashboardStatus status;
  final Dashboard? dashboard;
  final String? error;

  const OwnerDashboardState({
    this.status = OwnerDashboardStatus.initial,
    this.dashboard,
    this.error,
  });

  OwnerDashboardState copyWith({
    OwnerDashboardStatus? status,
    Dashboard? dashboard,
    String? error,
  }) {
    return OwnerDashboardState(
      status: status ?? this.status,
      dashboard: dashboard ?? this.dashboard,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, dashboard, error];
}
