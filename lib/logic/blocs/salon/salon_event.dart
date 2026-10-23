import 'package:equatable/equatable.dart';

abstract class SalonEvent extends Equatable {
  const SalonEvent();

  @override
  List<Object?> get props => [];
}

class LoadSalons extends SalonEvent {}

class LoadSalonByName extends SalonEvent {
  final String name;
  const LoadSalonByName(this.name);

  @override
  List<Object?> get props => [name];
}

class FilterByCategory extends SalonEvent {
  final String category;
  const FilterByCategory(this.category);

  @override
  List<Object?> get props => [category];
}

class ToggleService extends SalonEvent {
  final String serviceId;
  const ToggleService(this.serviceId);

  @override
  List<Object?> get props => [serviceId];
}

class SelectCategory extends SalonEvent {
  final String category;
  const SelectCategory(this.category);

  @override
  List<Object?> get props => [category];
}
