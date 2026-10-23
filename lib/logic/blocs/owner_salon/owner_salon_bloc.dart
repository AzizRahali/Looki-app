import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/portfolio_model.dart';
import '../../../data/models/review_model.dart';
import '../../../data/models/working_hours_model.dart';
import '../../../data/repositories/loomea_repository.dart';
import 'owner_salon_event.dart';
import 'owner_salon_state.dart';

class OwnerSalonBloc extends Bloc<OwnerSalonEvent, OwnerSalonState> {
  final LoomeeaRepository repository;

  OwnerSalonBloc({required this.repository}) : super(const OwnerSalonState()) {
    on<LoadMySalons>(_onLoadMySalons);
    on<CreateSalon>(_onCreateSalon);
    on<UpdateSalon>(_onUpdateSalon);
    on<DeleteSalon>(_onDeleteSalon);
    on<AddService>(_onAddService);
    on<UpdateService>(_onUpdateService);
    on<DeleteService>(_onDeleteService);
    on<LoadPortfolio>(_onLoadPortfolio);
    on<AddPortfolioPost>(_onAddPortfolioPost);
    on<UpdatePortfolioPost>(_onUpdatePortfolioPost);
    on<DeletePortfolioPost>(_onDeletePortfolioPost);
    on<UploadSalonImage>(_onUploadSalonImage);
    on<LoadReviews>(_onLoadReviews);
    on<LoadWorkingHours>(_onLoadWorkingHours);
    on<SaveWorkingHours>(_onSaveWorkingHours);
  }

  Future<void> _onLoadMySalons(
      LoadMySalons event, Emitter<OwnerSalonState> emit) async {
    emit(state.copyWith(status: OwnerSalonStatus.loading));
    try {
      final salons = await repository.getOwnerSalons();
      final salon = salons.isNotEmpty ? salons.first : null;
      List<PortfolioPost> posts = [];
      List<Review> reviews = [];
      List<WorkingHoursModel> workingHours = [];
      if (salon != null) {
        posts = await repository.getOwnerPortfolioPosts(salon.id);
        try { reviews = await repository.getReviews(salon.id); } catch (_) {}
        try { workingHours = await repository.getWorkingHours(salon.id); } catch (_) {}
      }
      emit(state.copyWith(
        status: OwnerSalonStatus.loaded,
        salon: salon,
        portfolioPosts: posts,
        reviews: reviews,
        workingHours: workingHours,
      ));
    } catch (e) {
      emit(state.copyWith(
          status: OwnerSalonStatus.error, error: e.toString()));
    }
  }

  Future<void> _onCreateSalon(
      CreateSalon event, Emitter<OwnerSalonState> emit) async {
    emit(state.copyWith(status: OwnerSalonStatus.saving));
    try {
      final salon = await repository.createSalon(event.data);
      emit(state.copyWith(status: OwnerSalonStatus.loaded, salon: salon));
    } catch (e) {
      emit(state.copyWith(
          status: OwnerSalonStatus.error, error: e.toString()));
    }
  }

  Future<void> _onUpdateSalon(
      UpdateSalon event, Emitter<OwnerSalonState> emit) async {
    emit(state.copyWith(status: OwnerSalonStatus.saving));
    try {
      final salon =
          await repository.updateOwnerSalon(event.salonId, event.data);
      emit(state.copyWith(status: OwnerSalonStatus.loaded, salon: salon));
    } catch (e) {
      emit(state.copyWith(
          status: OwnerSalonStatus.error, error: e.toString()));
    }
  }

  Future<void> _onDeleteSalon(
      DeleteSalon event, Emitter<OwnerSalonState> emit) async {
    emit(state.copyWith(status: OwnerSalonStatus.saving));
    try {
      await repository.deleteSalon(event.salonId);
      emit(const OwnerSalonState(status: OwnerSalonStatus.loaded));
    } catch (e) {
      emit(state.copyWith(
          status: OwnerSalonStatus.error, error: e.toString()));
    }
  }

  Future<void> _onAddService(
      AddService event, Emitter<OwnerSalonState> emit) async {
    emit(state.copyWith(status: OwnerSalonStatus.saving));
    try {
      final salon = await repository.addService(event.salonId, event.data);
      emit(state.copyWith(status: OwnerSalonStatus.loaded, salon: salon));
    } catch (e) {
      emit(state.copyWith(
          status: OwnerSalonStatus.error, error: e.toString()));
    }
  }

  Future<void> _onUpdateService(
      UpdateService event, Emitter<OwnerSalonState> emit) async {
    emit(state.copyWith(status: OwnerSalonStatus.saving));
    try {
      final salon = await repository.updateService(
          event.salonId, event.serviceId, event.data);
      emit(state.copyWith(status: OwnerSalonStatus.loaded, salon: salon));
    } catch (e) {
      emit(state.copyWith(
          status: OwnerSalonStatus.error, error: e.toString()));
    }
  }

  Future<void> _onDeleteService(
      DeleteService event, Emitter<OwnerSalonState> emit) async {
    emit(state.copyWith(status: OwnerSalonStatus.saving));
    try {
      final salon =
          await repository.deleteService(event.salonId, event.serviceId);
      emit(state.copyWith(status: OwnerSalonStatus.loaded, salon: salon));
    } catch (e) {
      emit(state.copyWith(
          status: OwnerSalonStatus.error, error: e.toString()));
    }
  }

  Future<void> _onLoadPortfolio(
      LoadPortfolio event, Emitter<OwnerSalonState> emit) async {
    try {
      final posts = await repository.getOwnerPortfolioPosts(event.salonId);
      emit(state.copyWith(portfolioPosts: posts));
    } catch (e) {
      emit(state.copyWith(
          status: OwnerSalonStatus.error, error: e.toString()));
    }
  }

  Future<void> _onAddPortfolioPost(
      AddPortfolioPost event, Emitter<OwnerSalonState> emit) async {
    emit(state.copyWith(status: OwnerSalonStatus.saving));
    try {
      await repository.addPortfolioPost(event.salonId, event.data);
      final posts = await repository.getOwnerPortfolioPosts(event.salonId);
      emit(state.copyWith(
          status: OwnerSalonStatus.loaded, portfolioPosts: posts));
    } catch (e) {
      emit(state.copyWith(
          status: OwnerSalonStatus.error, error: e.toString()));
    }
  }

  Future<void> _onUpdatePortfolioPost(
      UpdatePortfolioPost event, Emitter<OwnerSalonState> emit) async {
    emit(state.copyWith(status: OwnerSalonStatus.saving));
    try {
      await repository.updateOwnerPortfolioPost(event.salonId, event.postId, event.data);
      final posts = await repository.getOwnerPortfolioPosts(event.salonId);
      emit(state.copyWith(status: OwnerSalonStatus.loaded, portfolioPosts: posts));
    } catch (e) {
      emit(state.copyWith(status: OwnerSalonStatus.error, error: e.toString()));
    }
  }

  Future<void> _onDeletePortfolioPost(
      DeletePortfolioPost event, Emitter<OwnerSalonState> emit) async {
    emit(state.copyWith(status: OwnerSalonStatus.saving));
    try {
      await repository.deletePortfolioPost(event.salonId, event.postId);
      final posts = await repository.getOwnerPortfolioPosts(event.salonId);
      emit(state.copyWith(
          status: OwnerSalonStatus.loaded, portfolioPosts: posts));
    } catch (e) {
      emit(state.copyWith(
          status: OwnerSalonStatus.error, error: e.toString()));
    }
  }

  Future<void> _onUploadSalonImage(
      UploadSalonImage event, Emitter<OwnerSalonState> emit) async {
    emit(state.copyWith(status: OwnerSalonStatus.saving));
    try {
      final salon = await repository.uploadSalonImage(event.salonId, event.base64Image);
      emit(state.copyWith(status: OwnerSalonStatus.loaded, salon: salon));
    } catch (e) {
      emit(state.copyWith(status: OwnerSalonStatus.error, error: e.toString()));
    }
  }

  Future<void> _onLoadReviews(
      LoadReviews event, Emitter<OwnerSalonState> emit) async {
    try {
      final reviews = await repository.getReviews(event.salonId);
      emit(state.copyWith(reviews: reviews));
    } catch (e) {
      emit(state.copyWith(status: OwnerSalonStatus.error, error: e.toString()));
    }
  }

  Future<void> _onLoadWorkingHours(
      LoadWorkingHours event, Emitter<OwnerSalonState> emit) async {
    try {
      final hours = await repository.getWorkingHours(event.salonId);
      emit(state.copyWith(workingHours: hours));
    } catch (_) {}
  }

  Future<void> _onSaveWorkingHours(
      SaveWorkingHours event, Emitter<OwnerSalonState> emit) async {
    emit(state.copyWith(status: OwnerSalonStatus.saving));
    try {
      final hours = await repository.saveWorkingHours(event.salonId, event.hours);
      emit(state.copyWith(status: OwnerSalonStatus.loaded, workingHours: hours));
    } catch (e) {
      emit(state.copyWith(status: OwnerSalonStatus.error, error: e.toString()));
    }
  }
}
