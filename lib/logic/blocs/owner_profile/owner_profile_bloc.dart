import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/loomea_repository.dart';
import 'owner_profile_event.dart';
import 'owner_profile_state.dart';

class OwnerProfileBloc extends Bloc<OwnerProfileEvent, OwnerProfileState> {
  final LoomeeaRepository repository;

  OwnerProfileBloc({required this.repository})
      : super(const OwnerProfileState()) {
    on<LoadOwnerProfile>(_onLoadProfile);
    on<UpdateOwnerProfile>(_onUpdateProfile);
    on<UploadOwnerAvatar>(_onUploadAvatar);
  }

  Future<void> _onLoadProfile(
      LoadOwnerProfile event, Emitter<OwnerProfileState> emit) async {
    emit(state.copyWith(status: OwnerProfileStatus.loading));
    try {
      final profile = await repository.getProfile();
      emit(state.copyWith(
          status: OwnerProfileStatus.loaded, profile: profile));
    } catch (e) {
      emit(state.copyWith(
          status: OwnerProfileStatus.error, error: e.toString()));
    }
  }

  Future<void> _onUploadAvatar(
      UploadOwnerAvatar event, Emitter<OwnerProfileState> emit) async {
    if (state.profile == null) return;
    emit(state.copyWith(status: OwnerProfileStatus.updating));
    try {
      final updated = await repository.uploadAvatar(event.base64Image);
      emit(state.copyWith(status: OwnerProfileStatus.loaded, profile: updated));
    } catch (e) {
      emit(state.copyWith(
          status: OwnerProfileStatus.error,
          error: e.toString(),
          profile: state.profile));
    }
  }

  Future<void> _onUpdateProfile(
      UpdateOwnerProfile event, Emitter<OwnerProfileState> emit) async {
    if (state.profile == null) return;
    emit(state.copyWith(status: OwnerProfileStatus.updating));
    try {
      final updated = await repository.updateProfile(
          fullName: event.fullName, phone: event.phone);
      emit(state.copyWith(
          status: OwnerProfileStatus.loaded, profile: updated));
    } catch (e) {
      emit(state.copyWith(
          status: OwnerProfileStatus.error,
          error: e.toString(),
          profile: state.profile));
    }
  }
}
