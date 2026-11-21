import 'package:equatable/equatable.dart';

import '../../../data/models/subscription_model.dart';

enum SubscriptionLoadStatus { initial, loading, loaded, error }

class SubscriptionState extends Equatable {
  final SubscriptionLoadStatus status;
  final SubscriptionModel? subscription;
  final List<SubscriptionPlanModel> plans;
  final String error;

  const SubscriptionState({
    this.status = SubscriptionLoadStatus.initial,
    this.subscription,
    this.plans = const [],
    this.error = '',
  });

  bool get hasActiveSubscription => subscription?.isActive == true;

  SubscriptionState copyWith({
    SubscriptionLoadStatus? status,
    SubscriptionModel? subscription,
    List<SubscriptionPlanModel>? plans,
    String? error,
  }) {
    return SubscriptionState(
      status: status ?? this.status,
      subscription: subscription ?? this.subscription,
      plans: plans ?? this.plans,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [status, subscription, plans, error];
}
