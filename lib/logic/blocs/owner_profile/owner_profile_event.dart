import 'package:equatable/equatable.dart';

abstract class OwnerProfileEvent extends Equatable {
  const OwnerProfileEvent();
  @override
  List<Object?> get props => [];
}

class LoadOwnerProfile extends OwnerProfileEvent {
  const LoadOwnerProfile();
}

class UpdateOwnerProfile extends OwnerProfileEvent {
  final String? fullName;
  final String? phone;
  const UpdateOwnerProfile({this.fullName, this.phone});
  @override
  List<Object?> get props => [fullName, phone];
}

class UploadOwnerAvatar extends OwnerProfileEvent {
  final String base64Image;
  const UploadOwnerAvatar(this.base64Image);
  @override
  List<Object?> get props => [base64Image];
}
