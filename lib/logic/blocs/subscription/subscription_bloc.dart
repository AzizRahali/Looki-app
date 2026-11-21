import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/loomea_repository.dart';
import 'subscription_event.dart';
import 'subscription_state.dart';

class SubscriptionBloc extends Bloc<SubscriptionEvent, SubscriptionState> {
  final LoomeeaRepository repository;

  SubscriptionBloc({required this.repository})
      : super(const SubscriptionState()) {
    on<LoadSubscription>(_onLoad);
  }

  Future<void> _onLoad(
    LoadSubscription event,
    Emitter<SubscriptionState> emit,
  ) async {
    emit(state.copyWith(status: SubscriptionLoadStatus.loading));
    try {
      final (subscription, plans) = await (
        repository.getSubscription(),
        repository.getSubscriptionPlans(),
      ).wait;
      // Built directly (not copyWith) so a lapsed subscription clears to null.
      emit(SubscriptionState(
        status: SubscriptionLoadStatus.loaded,
        subscription: subscription,
        plans: plans,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: SubscriptionLoadStatus.error,
        error: e.toString(),
      ));
    }
  }
}
