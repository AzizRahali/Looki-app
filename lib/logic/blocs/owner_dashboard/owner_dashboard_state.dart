import 'package:equatable/equatable.dart';
import '../../../data/models/owner_dashboard_model.dart';
import '../../../data/models/owner_insights_model.dart';

enum OwnerDashboardStatus { initial, loading, loaded, error }

enum InsightsStatus { initial, loading, loaded, error }

class OwnerDashboardState extends Equatable {
  final OwnerDashboardStatus status;
  final Dashboard? dashboard;
  final String? error;
  final InsightsStatus insightsStatus;
  final OwnerInsights? insights;

  const OwnerDashboardState({
    this.status = OwnerDashboardStatus.initial,
    this.dashboard,
    this.error,
    this.insightsStatus = InsightsStatus.initial,
    this.insights,
  });

  OwnerDashboardState copyWith({
    OwnerDashboardStatus? status,
    Dashboard? dashboard,
    String? error,
    InsightsStatus? insightsStatus,
    OwnerInsights? insights,
  }) {
    return OwnerDashboardState(
      status: status ?? this.status,
      dashboard: dashboard ?? this.dashboard,
      error: error,
      insightsStatus: insightsStatus ?? this.insightsStatus,
      insights: insights ?? this.insights,
    );
  }

  @override
  List<Object?> get props => [status, dashboard, error, insightsStatus, insights];
}
