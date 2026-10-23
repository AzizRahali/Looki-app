import 'package:equatable/equatable.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

class LoadProfile extends ProfileEvent {}

class UpdateProfile extends ProfileEvent {
  final String? fullName;
  final String? phone;
  final String? avatarUrl;

  const UpdateProfile({this.fullName, this.phone, this.avatarUrl});

  @override
  List<Object?> get props => [fullName, phone, avatarUrl];
}

class ToggleSavedSalon extends ProfileEvent {
  final String salonId;
  const ToggleSavedSalon(this.salonId);

  @override
  List<Object?> get props => [salonId];
}

class UploadAvatar extends ProfileEvent {
  final String base64Image;
  const UploadAvatar(this.base64Image);
  @override
  List<Object?> get props => [base64Image];
}

class ClearProfile extends ProfileEvent {}

class DeleteAccount extends ProfileEvent {}

class CancelDeletion extends ProfileEvent {}

