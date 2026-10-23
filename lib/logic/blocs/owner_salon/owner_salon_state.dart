import 'package:equatable/equatable.dart';
import '../../../data/models/owner_salon_model.dart';
import '../../../data/models/portfolio_model.dart';
import '../../../data/models/review_model.dart';
import '../../../data/models/working_hours_model.dart';

enum OwnerSalonStatus { initial, loading, loaded, saving, error }

class OwnerSalonState extends Equatable {
  final OwnerSalonStatus status;
  final OwnerSalon? salon;
  final List<PortfolioPost> portfolioPosts;
  final List<Review> reviews;
  final List<WorkingHoursModel> workingHours;
  final String? error;

  const OwnerSalonState({
    this.status = OwnerSalonStatus.initial,
    this.salon,
    this.portfolioPosts = const [],
    this.reviews = const [],
    this.workingHours = const [],
    this.error,
  });

  OwnerSalonState copyWith({
    OwnerSalonStatus? status,
    OwnerSalon? salon,
    List<PortfolioPost>? portfolioPosts,
    List<Review>? reviews,
    List<WorkingHoursModel>? workingHours,
    String? error,
  }) {
    return OwnerSalonState(
      status: status ?? this.status,
      salon: salon ?? this.salon,
      portfolioPosts: portfolioPosts ?? this.portfolioPosts,
      reviews: reviews ?? this.reviews,
      workingHours: workingHours ?? this.workingHours,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, salon, portfolioPosts, reviews, workingHours, error];
}
