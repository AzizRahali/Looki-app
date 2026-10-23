import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/loomea_repository.dart';
import 'profile_event.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final LoomeeaRepository repository;

  ProfileBloc({required this.repository}) : super(const ProfileState()) {
    on<LoadProfile>(_onLoadProfile);
    on<UpdateProfile>(_onUpdateProfile);
    on<UploadAvatar>(_onUploadAvatar);
    on<ToggleSavedSalon>(_onToggleSavedSalon);
    on<ClearProfile>(_onClearProfile);
    on<DeleteAccount>(_onDeleteAccount);
    on<CancelDeletion>(_onCancelDeletion);
  }

  Future<void> _onUpdateProfile(
    UpdateProfile event,
    Emitter<ProfileState> emit,
  ) async {
    if (state.profile == null) return;
    emit(state.copyWith(status: ProfileStatus.updating));
    try {
      final updated = await repository.updateProfile(
        fullName: event.fullName,
        phone: event.phone,
        avatarUrl: event.avatarUrl,
      );
      // Merge: keep locally tracked fields (savedSalonIds) from current state
      final merged = updated.copyWith(
        savedSalonIds: state.profile!.savedSalonIds,
      );
      emit(state.copyWith(status: ProfileStatus.loaded, profile: merged));
    } catch (e) {
      emit(state.copyWith(
        status: ProfileStatus.error,
        error: e.toString(),
        profile: state.profile, // keep existing profile on error
      ));
    }
  }

  Future<void> _onUploadAvatar(
    UploadAvatar event,
    Emitter<ProfileState> emit,
  ) async {
    emit(state.copyWith(status: ProfileStatus.updating));
    try {
      final updated = await repository.uploadAvatar(event.base64Image);
      emit(state.copyWith(status: ProfileStatus.loaded, profile: updated));
    } catch (e) {
      emit(state.copyWith(
          status: ProfileStatus.error, error: e.toString(), profile: state.profile));
    }
  }

  Future<void> _onLoadProfile(
    LoadProfile event,
    Emitter<ProfileState> emit,
  ) async {
    emit(state.copyWith(status: ProfileStatus.loading));
    try {
      final profile = await repository.getProfile();
      final savedSalons =
          await repository.getSavedSalons(profile.savedSalonIds);
      emit(state.copyWith(
        status: ProfileStatus.loaded,
        profile: profile,
        savedSalons: savedSalons,
      ));
    } catch (e) {
      emit(state.copyWith(status: ProfileStatus.error, error: e.toString()));
    }
  }

  void _onClearProfile(ClearProfile event, Emitter<ProfileState> emit) {
    emit(const ProfileState());
  }

  Future<void> _onDeleteAccount(
    DeleteAccount event,
    Emitter<ProfileState> emit,
  ) async {
    emit(state.copyWith(status: ProfileStatus.deleting));
    try {
      final updated = await repository.deleteAccount();
      emit(state.copyWith(status: ProfileStatus.loaded, profile: updated));
    } catch (e) {
      emit(state.copyWith(
          status: ProfileStatus.error, error: e.toString(), profile: state.profile));
    }
  }

  Future<void> _onCancelDeletion(
    CancelDeletion event,
    Emitter<ProfileState> emit,
  ) async {
    emit(state.copyWith(status: ProfileStatus.updating));
    try {
      final updated = await repository.cancelDeletion();
      emit(state.copyWith(status: ProfileStatus.loaded, profile: updated));
    } catch (e) {
      emit(state.copyWith(
          status: ProfileStatus.error, error: e.toString(), profile: state.profile));
    }
  }

  Future<void> _onToggleSavedSalon(
    ToggleSavedSalon event,
    Emitter<ProfileState> emit,
  ) async {
    if (state.profile == null) return;

    final wasSaved = state.profile!.savedSalonIds.contains(event.salonId);

    // Optimistic update — instant UI feedback before the API round-trip
    final optimisticIds = List<String>.from(state.profile!.savedSalonIds);
    if (wasSaved) {
      optimisticIds.remove(event.salonId);
    } else {
      optimisticIds.add(event.salonId);
    }
    final optimisticProfile = state.profile!.copyWith(savedSalonIds: optimisticIds);
    final optimisticSalons = await repository.getSavedSalons(optimisticIds);
    emit(state.copyWith(profile: optimisticProfile, savedSalons: optimisticSalons));

    // Persist to backend then sync with server truth
    try {
      if (wasSaved) {
        await repository.unsaveSalon(event.salonId);
      } else {
        await repository.saveSalon(event.salonId);
      }
      // Re-fetch profile so savedSalonIds stays in sync with the DB
      final freshProfile = await repository.getProfile();
      final freshSalons = await repository.getSavedSalons(freshProfile.savedSalonIds);
      emit(state.copyWith(profile: freshProfile, savedSalons: freshSalons));
    } catch (_) {
      // Revert to original state on failure
      final originalSalons = await repository.getSavedSalons(state.profile!.savedSalonIds);
      emit(state.copyWith(profile: state.profile, savedSalons: originalSalons));
    }
  }
}
