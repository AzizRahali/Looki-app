import 'package:equatable/equatable.dart';

abstract class SubscriptionEvent extends Equatable {
  const SubscriptionEvent();

  @override
  List<Object?> get props => [];
}

/// Load the owner's current subscription and the available plans.
class LoadSubscription extends SubscriptionEvent {
  const LoadSubscription();
}
