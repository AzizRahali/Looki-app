import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/payment_model.dart';
import '../../../data/repositories/loomea_repository.dart';
import 'payment_event.dart';
import 'payment_state.dart';

/// Drives one Stripe Checkout payment: create the session, let the UI open
/// it, then poll the backend until Stripe reports a final result.
class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
  final LoomeeaRepository repository;
  final Duration pollInterval;
  Timer? _pollTimer;

  PaymentBloc({
    required this.repository,
    this.pollInterval = const Duration(seconds: 3),
  }) : super(const PaymentState()) {
    on<StartPayment>(_onStart);
    on<CheckoutClosed>(_onCheckoutClosed);
    on<CancelPayment>(_onCancel);
    on<PaymentPollTick>(_onPoll);
  }

  Future<void> _onStart(StartPayment event, Emitter<PaymentState> emit) async {
    _stopPolling();
    emit(PaymentState(
        status: PaymentFlowStatus.creating, request: event.request));
    try {
      final request = event.request;
      final checkout = switch (request) {
        BookingPaymentRequest() => await repository.startBookingPayment(
            salonId: request.salonId,
            date: request.date,
            startTime: request.startTime,
            serviceIds: request.serviceIds,
            notes: request.notes,
          ),
        SubscriptionPaymentRequest() =>
          await repository.startSubscriptionPayment(request.plan),
      };
      emit(state.copyWith(
        status: PaymentFlowStatus.awaitingCheckout,
        checkout: checkout,
      ));
      // Covers checkouts opened in an external browser, which can't tell us
      // when they're done.
      _pollTimer =
          Timer.periodic(pollInterval, (_) => add(const PaymentPollTick()));
    } catch (e) {
      emit(state.copyWith(
          status: PaymentFlowStatus.failed, error: e.toString()));
    }
  }

  Future<void> _onCheckoutClosed(
    CheckoutClosed event,
    Emitter<PaymentState> emit,
  ) async {
    if (state.isFinished || state.checkout == null) return;

    if (event.result == CheckoutResult.success) {
      emit(state.copyWith(status: PaymentFlowStatus.verifying));
      await _checkStatus(emit);
    } else {
      // Also covers "paid, then closed before the redirect": the backend
      // reports COMPLETED instead of cancelling in that case.
      await _cancel(emit);
    }
  }

  Future<void> _onCancel(CancelPayment event, Emitter<PaymentState> emit) async {
    if (state.isFinished || state.checkout == null) return;
    await _cancel(emit);
  }

  Future<void> _onPoll(PaymentPollTick event, Emitter<PaymentState> emit) async {
    if (state.isFinished || state.checkout == null) {
      _stopPolling();
      return;
    }
    await _checkStatus(emit);
  }

  Future<void> _cancel(Emitter<PaymentState> emit) async {
    try {
      final info = await repository.cancelPayment(state.checkout!.paymentRef);
      _emitForStatus(info, emit, pendingStatus: PaymentFlowStatus.cancelled);
    } catch (e) {
      emit(state.copyWith(
          status: PaymentFlowStatus.failed, error: e.toString()));
      _stopPolling();
    }
  }

  Future<void> _checkStatus(Emitter<PaymentState> emit) async {
    try {
      final info =
          await repository.getPaymentStatus(state.checkout!.paymentRef);
      _emitForStatus(info, emit);
    } catch (_) {
      // Transient network error — the next tick tries again.
    }
  }

  void _emitForStatus(
    PaymentStatusInfo info,
    Emitter<PaymentState> emit, {
    PaymentFlowStatus? pendingStatus,
  }) {
    final next = switch (info.status) {
      'COMPLETED' => PaymentFlowStatus.succeeded,
      'CANCELLED' => PaymentFlowStatus.cancelled,
      'REFUNDED' => PaymentFlowStatus.refunded,
      'FAILED' => PaymentFlowStatus.failed,
      _ => pendingStatus ?? state.status,
    };
    emit(state.copyWith(status: next, info: info));
    if (state.isFinished) _stopPolling();
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  @override
  Future<void> close() {
    _stopPolling();
    return super.close();
  }
}
