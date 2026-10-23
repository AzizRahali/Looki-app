import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class LoginRequested extends AuthEvent {
  final String email;
  final String password;
  final bool rememberMe;

  const LoginRequested({
    required this.email,
    required this.password,
    this.rememberMe = true,
  });

  @override
  List<Object?> get props => [email, password, rememberMe];
}

class RegisterRequested extends AuthEvent {
  final String fullName;
  final String email;
  final String password;
  final String? phone;
  final String role; // 'CLIENT' or 'SALON_OWNER'

  const RegisterRequested({
    required this.fullName,
    required this.email,
    required this.password,
    this.phone,
    this.role = 'CLIENT',
  });

  @override
  List<Object?> get props => [fullName, email, password, phone, role];
}

class SendOtpRequested extends AuthEvent {
  final String email;

  const SendOtpRequested({required this.email});

  @override
  List<Object?> get props => [email];
}

class VerifyOtpRequested extends AuthEvent {
  final String email;
  final String otp;

  const VerifyOtpRequested({required this.email, required this.otp});

  @override
  List<Object?> get props => [email, otp];
}

class LogoutRequested extends AuthEvent {}

class CheckAuthStatus extends AuthEvent {}
