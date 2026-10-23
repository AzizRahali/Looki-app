import 'package:equatable/equatable.dart';

import '../../../data/models/profile_model.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  pendingVerification, // registered but phone not yet verified
  error,
}

class AuthState extends Equatable {
  final AuthStatus status;
  final Profile? user;
  final String error;
  final String pendingEmail;
  final String pendingRole;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.error = '',
    this.pendingEmail = '',
    this.pendingRole = '',
  });

  AuthState copyWith({
    AuthStatus? status,
    Profile? user,
    String? error,
    String? pendingEmail,
    String? pendingRole,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      error: error ?? this.error,
      pendingEmail: pendingEmail ?? this.pendingEmail,
      pendingRole: pendingRole ?? this.pendingRole,
    );
  }

  @override
  List<Object?> get props =>
      [status, user, error, pendingEmail, pendingRole];
}
