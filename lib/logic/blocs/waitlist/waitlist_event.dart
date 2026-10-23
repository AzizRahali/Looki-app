import 'package:equatable/equatable.dart';

abstract class WaitlistEvent extends Equatable {
  const WaitlistEvent();
  @override
  List<Object?> get props => [];
}

class LoadWaitlist extends WaitlistEvent {}

class RefreshWaitlist extends WaitlistEvent {
  const RefreshWaitlist();
}

class JoinWaitlist extends WaitlistEvent {
  final String salonId;
  final String salonName;
  final String date;
  const JoinWaitlist({required this.salonId, required this.salonName, required this.date});
  @override
  List<Object?> get props => [salonId, date];
}

class LeaveWaitlist extends WaitlistEvent {
  final String entryId;
  const LeaveWaitlist(this.entryId);
  @override
  List<Object?> get props => [entryId];
}
