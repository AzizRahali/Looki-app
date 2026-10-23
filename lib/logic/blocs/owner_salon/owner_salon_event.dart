import 'package:equatable/equatable.dart';
import '../../../data/models/working_hours_model.dart';

abstract class OwnerSalonEvent extends Equatable {
  const OwnerSalonEvent();
  @override
  List<Object?> get props => [];
}

class LoadMySalons extends OwnerSalonEvent {
  const LoadMySalons();
}

class CreateSalon extends OwnerSalonEvent {
  final Map<String, dynamic> data;
  const CreateSalon(this.data);
  @override
  List<Object?> get props => [data];
}

class UpdateSalon extends OwnerSalonEvent {
  final String salonId;
  final Map<String, dynamic> data;
  const UpdateSalon(this.salonId, this.data);
  @override
  List<Object?> get props => [salonId, data];
}

class DeleteSalon extends OwnerSalonEvent {
  final String salonId;
  const DeleteSalon(this.salonId);
  @override
  List<Object?> get props => [salonId];
}

class AddService extends OwnerSalonEvent {
  final String salonId;
  final Map<String, dynamic> data;
  const AddService(this.salonId, this.data);
  @override
  List<Object?> get props => [salonId, data];
}

class UpdateService extends OwnerSalonEvent {
  final String salonId;
  final String serviceId;
  final Map<String, dynamic> data;
  const UpdateService(this.salonId, this.serviceId, this.data);
  @override
  List<Object?> get props => [salonId, serviceId, data];
}

class DeleteService extends OwnerSalonEvent {
  final String salonId;
  final String serviceId;
  const DeleteService(this.salonId, this.serviceId);
  @override
  List<Object?> get props => [salonId, serviceId];
}

class LoadPortfolio extends OwnerSalonEvent {
  final String salonId;
  const LoadPortfolio(this.salonId);
  @override
  List<Object?> get props => [salonId];
}

class AddPortfolioPost extends OwnerSalonEvent {
  final String salonId;
  final Map<String, dynamic> data;
  const AddPortfolioPost(this.salonId, this.data);
  @override
  List<Object?> get props => [salonId, data];
}

class UpdatePortfolioPost extends OwnerSalonEvent {
  final String salonId;
  final String postId;
  final Map<String, dynamic> data;
  const UpdatePortfolioPost(this.salonId, this.postId, this.data);
  @override
  List<Object?> get props => [salonId, postId, data];
}

class DeletePortfolioPost extends OwnerSalonEvent {
  final String salonId;
  final String postId;
  const DeletePortfolioPost(this.salonId, this.postId);
  @override
  List<Object?> get props => [salonId, postId];
}

class UploadSalonImage extends OwnerSalonEvent {
  final String salonId;
  final String base64Image;
  const UploadSalonImage(this.salonId, this.base64Image);
  @override
  List<Object?> get props => [salonId];
}

class LoadReviews extends OwnerSalonEvent {
  final String salonId;
  const LoadReviews(this.salonId);
  @override
  List<Object?> get props => [salonId];
}

class LoadWorkingHours extends OwnerSalonEvent {
  final String salonId;
  const LoadWorkingHours(this.salonId);
  @override
  List<Object?> get props => [salonId];
}

class SaveWorkingHours extends OwnerSalonEvent {
  final String salonId;
  final List<WorkingHoursModel> hours;
  const SaveWorkingHours(this.salonId, this.hours);
  @override
  List<Object?> get props => [salonId, hours];
}

