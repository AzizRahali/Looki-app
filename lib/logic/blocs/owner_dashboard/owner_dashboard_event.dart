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
