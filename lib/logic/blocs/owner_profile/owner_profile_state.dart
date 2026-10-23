import 'package:equatable/equatable.dart';
import '../../../data/models/profile_model.dart';

enum OwnerProfileStatus { initial, loading, loaded, updating, error }

class OwnerProfileState extends Equatable {
  final OwnerProfileStatus status;
  final Profile? profile;
  final String? error;

  const OwnerProfileState({
    this.status = OwnerProfileStatus.initial,
    this.profile,
    this.error,
  });

  OwnerProfileState copyWith({
    OwnerProfileStatus? status,
    Profile? profile,
    String? error,
  }) {
    return OwnerProfileState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, profile, error];
}
