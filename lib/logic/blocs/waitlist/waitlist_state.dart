import 'package:equatable/equatable.dart';
import '../../../data/models/waitlist_model.dart';

enum WaitlistStatus { initial, loading, loaded, error }

class WaitlistState extends Equatable {
  final WaitlistStatus status;
  final List<WaitlistEntry> entries;
  final String? error;

  const WaitlistState({
    this.status = WaitlistStatus.initial,
    this.entries = const [],
    this.error,
  });

  WaitlistState copyWith({
    WaitlistStatus? status,
    List<WaitlistEntry>? entries,
    String? error,
  }) {
    return WaitlistState(
      status: status ?? this.status,
      entries: entries ?? this.entries,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, entries, error];
}
