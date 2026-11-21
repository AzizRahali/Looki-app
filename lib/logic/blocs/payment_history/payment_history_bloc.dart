import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/payment_model.dart';
import '../../../data/repositories/loomea_repository.dart';

// ─── Events ──────────────────────────────────────────────────────────────────

abstract class PaymentHistoryEvent extends Equatable {
  const PaymentHistoryEvent();

  @override
  List<Object?> get props => [];
}

class LoadPaymentHistory extends PaymentHistoryEvent {
  const LoadPaymentHistory();
}

// ─── State ───────────────────────────────────────────────────────────────────

enum PaymentHistoryStatus { initial, loading, loaded, error }

class PaymentHistoryState extends Equatable {
  final PaymentHistoryStatus status;
  final List<PaymentHistoryItem> items;
  final String error;

  const PaymentHistoryState({
    this.status = PaymentHistoryStatus.initial,
    this.items = const [],
    this.error = '',
  });

  PaymentHistoryState copyWith({
    PaymentHistoryStatus? status,
    List<PaymentHistoryItem>? items,
    String? error,
  }) {
    return PaymentHistoryState(
      status: status ?? this.status,
      items: items ?? this.items,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [status, items, error];
}

// ─── Bloc ────────────────────────────────────────────────────────────────────

class PaymentHistoryBloc extends Bloc<PaymentHistoryEvent, PaymentHistoryState> {
  final LoomeeaRepository repository;

  PaymentHistoryBloc({required this.repository})
      : super(const PaymentHistoryState()) {
    on<LoadPaymentHistory>(_onLoad);
  }

  Future<void> _onLoad(
    LoadPaymentHistory event,
    Emitter<PaymentHistoryState> emit,
  ) async {
    emit(state.copyWith(status: PaymentHistoryStatus.loading));
    try {
      final items = await repository.getPaymentHistory();
      emit(state.copyWith(status: PaymentHistoryStatus.loaded, items: items));
    } catch (e) {
      emit(state.copyWith(
          status: PaymentHistoryStatus.error, error: e.toString()));
    }
  }
}
