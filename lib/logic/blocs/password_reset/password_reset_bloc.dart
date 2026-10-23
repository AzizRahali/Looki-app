import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/loomea_repository.dart';
import 'password_reset_event.dart';
import 'password_reset_state.dart';

class PasswordResetBloc extends Bloc<PasswordResetEvent, PasswordResetState> {
  final LoomeeaRepository repository;

  PasswordResetBloc({required this.repository})
      : super(const PasswordResetState()) {
    on<SendRecoveryEmail>(_onSendEmail);
    on<ValidateEmailToken>(_onValidateEmailToken);
    on<SubmitNewPassword>(_onSubmitNewPassword);
    on<ResetPasswordResetBloc>(_onReset);
  }

  Future<void> _onSendEmail(
    SendRecoveryEmail event,
    Emitter<PasswordResetState> emit,
  ) async {
    emit(state.copyWith(
      status: PasswordResetStatus.loading,
      email:  event.email,
    ));
    try {
      final result = await repository.forgotPassword(email: event.email);
      emit(state.copyWith(
        status: PasswordResetStatus.emailSent,
        hint:   result.hint,
      ));
    } catch (e) {
      emit(state.copyWith(
        status:       PasswordResetStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onValidateEmailToken(
    ValidateEmailToken event,
    Emitter<PasswordResetState> emit,
  ) async {
    emit(state.copyWith(status: PasswordResetStatus.loading));
    try {
      final valid = await repository.validateResetToken(event.token);
      if (valid) {
        emit(state.copyWith(
          status:     PasswordResetStatus.tokenReady,
          resetToken: event.token,
        ));
      } else {
        emit(state.copyWith(
          status:       PasswordResetStatus.error,
          errorMessage: 'token_expired',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status:       PasswordResetStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onSubmitNewPassword(
    SubmitNewPassword event,
    Emitter<PasswordResetState> emit,
  ) async {
    emit(state.copyWith(status: PasswordResetStatus.saving));
    try {
      final accessToken = await repository.resetPassword(
        resetToken:  state.resetToken,
        newPassword: event.password,
      );
      emit(state.copyWith(
        status:      PasswordResetStatus.success,
        accessToken: accessToken,
      ));
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('same_password')) {
        emit(state.copyWith(
          status:       PasswordResetStatus.tokenReady,
          errorMessage: 'same_password',
        ));
      } else if (msg.contains('token_expired')) {
        emit(state.copyWith(
          status:       PasswordResetStatus.error,
          errorMessage: 'token_expired',
        ));
      } else {
        emit(state.copyWith(
          status:       PasswordResetStatus.tokenReady,
          errorMessage: msg,
        ));
      }
    }
  }

  void _onReset(ResetPasswordResetBloc event, Emitter<PasswordResetState> emit) {
    emit(const PasswordResetState());
  }
}
