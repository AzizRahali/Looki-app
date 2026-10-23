import 'package:equatable/equatable.dart';

import '../../../data/models/salon_model.dart';

enum SalonStatus { initial, loading, loaded, error }

class SalonState extends Equatable {
  final SalonStatus status;
  final List<Salon> salons;
  final Salon? selectedSalon;
  final List<String> selectedServiceIds;
  final String selectedCategory;
  final String error;

  const SalonState({
    this.status = SalonStatus.initial,
    this.salons = const [],
    this.selectedSalon,
    this.selectedServiceIds = const [],
    this.selectedCategory = '',
    this.error = '',
  });

  double get selectedServicesTotal {
    if (selectedSalon == null) return 0;
    return selectedSalon!.services
        .where((s) => selectedServiceIds.contains(s.id))
        .fold(0.0, (sum, s) => sum + s.price);
  }

  int get selectedServicesCount => selectedServiceIds.length;

  String get selectedServicesNames {
    if (selectedSalon == null) return '';
    return selectedSalon!.services
        .where((s) => selectedServiceIds.contains(s.id))
        .map((s) => s.name)
        .join(', ');
  }

  SalonState copyWith({
    SalonStatus? status,
    List<Salon>? salons,
    Salon? selectedSalon,
    List<String>? selectedServiceIds,
    String? selectedCategory,
    String? error,
  }) {
    return SalonState(
      status: status ?? this.status,
      salons: salons ?? this.salons,
      selectedSalon: selectedSalon ?? this.selectedSalon,
      selectedServiceIds: selectedServiceIds ?? this.selectedServiceIds,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [
        status,
        salons,
        selectedSalon,
        selectedServiceIds,
        selectedCategory,
        error,
      ];
}
