import 'package:equatable/equatable.dart';

enum PasswordResetStatus {
  initial,
  loading,
  emailSent,     // email link sent, user needs to check inbox
  tokenReady,    // email token validated -> can set new password
  saving,        // submitting new password
  success,       // password reset + auto-login complete
  error,         // generic unrecoverable error
}

class PasswordResetState extends Equatable {
  final PasswordResetStatus status;

  final String email;           // email the user typed (kept for display)
  final String hint;            // masked email for display
  final String resetToken;      // opaque token to present on /reset-password

  // Post-success
  final String accessToken;

  // Generic error message
  final String errorMessage;

  const PasswordResetState({
    this.status       = PasswordResetStatus.initial,
    this.email        = '',
    this.hint         = '',
    this.resetToken   = '',
    this.accessToken  = '',
    this.errorMessage = '',
  });

  PasswordResetState copyWith({
    PasswordResetStatus? status,
    String? email,
    String? hint,
    String? resetToken,
    String? accessToken,
    String? errorMessage,
  }) {
    return PasswordResetState(
      status:       status       ?? this.status,
      email:        email        ?? this.email,
      hint:         hint         ?? this.hint,
      resetToken:   resetToken   ?? this.resetToken,
      accessToken:  accessToken  ?? this.accessToken,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status, email, hint, resetToken, accessToken, errorMessage,
  ];
}
