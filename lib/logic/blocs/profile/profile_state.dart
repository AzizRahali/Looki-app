import 'package:equatable/equatable.dart';

import '../../../data/models/profile_model.dart';
import '../../../data/models/salon_model.dart';

enum ProfileStatus { initial, loading, loaded, updating, deleting, deleted, error }

class ProfileState extends Equatable {
  final ProfileStatus status;
  final Profile? profile;
  final List<Salon> savedSalons;
  final String error;

  const ProfileState({
    this.status = ProfileStatus.initial,
    this.profile,
    this.savedSalons = const [],
    this.error = '',
  });

  bool isSalonSaved(String salonId) {
    return profile?.savedSalonIds.contains(salonId) ?? false;
  }

  ProfileState copyWith({
    ProfileStatus? status,
    Profile? profile,
    List<Salon>? savedSalons,
    String? error,
  }) {
    return ProfileState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      savedSalons: savedSalons ?? this.savedSalons,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [status, profile, savedSalons, error];
}
