import 'package:equatable/equatable.dart';

abstract class PasswordResetEvent extends Equatable {
  const PasswordResetEvent();
  @override
  List<Object?> get props => [];
}

/// User submitted their email to receive a reset link.
class SendRecoveryEmail extends PasswordResetEvent {
  final String email;
  const SendRecoveryEmail(this.email);
  @override
  List<Object?> get props => [email];
}

/// Deep-link token from email arrived in the app.
class ValidateEmailToken extends PasswordResetEvent {
  final String token;
  const ValidateEmailToken(this.token);
  @override
  List<Object?> get props => [token];
}

/// User submitted the new password.
class SubmitNewPassword extends PasswordResetEvent {
  final String password;
  const SubmitNewPassword(this.password);
  @override
  List<Object?> get props => [password];
}

/// Completely reset the BLoC to initial (e.g. navigating back to sign-in).
class ResetPasswordResetBloc extends PasswordResetEvent {
  const ResetPasswordResetBloc();
}
