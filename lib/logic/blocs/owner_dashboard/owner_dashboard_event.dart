import 'package:equatable/equatable.dart';

abstract class OwnerDashboardEvent extends Equatable {
  const OwnerDashboardEvent();
  @override
  List<Object?> get props => [];
}

class LoadDashboard extends OwnerDashboardEvent {
  final String salonId;
  const LoadDashboard(this.salonId);
  @override
  List<Object?> get props => [salonId];
}

class RefreshDashboard extends OwnerDashboardEvent {
  final String salonId;
  const RefreshDashboard(this.salonId);
  @override
  List<Object?> get props => [salonId];
}

/// Loads business insights; may be slow when the AI model is starting up.
class LoadInsights extends OwnerDashboardEvent {
  final String salonId;
  final String language;
  const LoadInsights(this.salonId, this.language);
  @override
  List<Object?> get props => [salonId, language];
}
