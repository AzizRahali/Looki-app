import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/loomea_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoomeeaRepository repository;

  AuthBloc({required this.repository}) : super(const AuthState()) {
    on<LoginRequested>(_onLogin);
    on<RegisterRequested>(_onRegister);
    on<SendOtpRequested>(_onSendOtp);
    on<VerifyOtpRequested>(_onVerifyOtp);
    on<LogoutRequested>(_onLogout);
    on<CheckAuthStatus>(_onCheckAuth);
  }

  Future<void> _onLogin(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));
    try {
      final result = await repository.login(
        email: event.email,
        password: event.password,
        rememberMe: event.rememberMe,
      );
      emit(state.copyWith(
        status: AuthStatus.authenticated,
        user: result.user,
      ));
    } on EmailNotVerifiedException catch (e) {
      emit(state.copyWith(
        status: AuthStatus.pendingVerification,
        pendingEmail: e.email,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onRegister(
    RegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));
    try {
      final pending = await repository.registerPending(
        fullName: event.fullName,
        email: event.email,
        password: event.password,
        phone: event.phone,
        role: event.role,
      );
      emit(state.copyWith(
        status: AuthStatus.pendingVerification,
        pendingEmail: pending.email,
        pendingRole: pending.role,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onSendOtp(
    SendOtpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));
    try {
      await repository.sendOtp(email: event.email);
      emit(state.copyWith(
        status: AuthStatus.pendingVerification,
        pendingEmail: event.email,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onVerifyOtp(
    VerifyOtpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));
    try {
      final result = await repository.verifyEmail(
        email: event.email,
        otp: event.otp,
      );
      emit(state.copyWith(
        status: AuthStatus.authenticated,
        user: result.user,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onLogout(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await repository.logout();
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }

  void _onCheckAuth(
    CheckAuthStatus event,
    Emitter<AuthState> emit,
  ) {
    if (repository.isLoggedIn) {
      emit(state.copyWith(status: AuthStatus.authenticated));
    } else {
      emit(const AuthState(status: AuthStatus.unauthenticated));
    }
  }
}
