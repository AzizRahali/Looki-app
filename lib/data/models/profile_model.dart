import 'package:equatable/equatable.dart';

class PaymentMethod extends Equatable {
  final String id;
  final String type;
  final String last4;
  final bool isDefault;

  const PaymentMethod({
    required this.id,
    required this.type,
    required this.last4,
    required this.isDefault,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id'] as String,
      type: json['type'] as String,
      last4: json['last4'] as String,
      isDefault: json['isDefault'] as bool,
    );
  }

  String get displayName =>
      '${type[0].toUpperCase()}${type.substring(1)} ending in $last4';

  @override
  List<Object?> get props => [id];
}

class Profile extends Equatable {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String avatarUrl;
  final String location;
  final String role; // 'CLIENT' or 'SALON_OWNER'
  final List<PaymentMethod> paymentMethods;
  final List<String> savedSalonIds;
  final int reliabilityScore;
  final String reliabilityTier; // TRUSTED | NORMAL | RISKY | RESTRICTED
  /// ISO-8601 timestamp of scheduled hard-deletion; null = active account.
  final String? scheduledDeletionAt;

  const Profile({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.avatarUrl,
    required this.location,
    this.role = 'CLIENT',
    required this.paymentMethods,
    required this.savedSalonIds,
    this.reliabilityScore = 100,
    this.reliabilityTier = 'TRUSTED',
    this.scheduledDeletionAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String? ?? '',
      location: json['location'] as String? ?? '',
      role: json['role'] as String? ?? 'CLIENT',
      paymentMethods: (json['paymentMethods'] as List?)
              ?.map((p) => PaymentMethod.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
      savedSalonIds: List<String>.from(json['savedSalonIds'] as List? ?? []),
      reliabilityScore: json['reliabilityScore'] as int? ?? 100,
      reliabilityTier: json['reliabilityTier'] as String? ?? 'TRUSTED',
      scheduledDeletionAt: json['scheduledDeletionAt'] as String?,
    );
  }

  bool get isOwner => role == 'SALON_OWNER';
  bool get isClient => role == 'CLIENT';
  bool get isPendingDeletion => scheduledDeletionAt != null;
  String get firstName => fullName.split(' ').first;

  /// Days remaining until permanent deletion (0 if overdue).
  int get daysUntilDeletion {
    if (scheduledDeletionAt == null) return 0;
    final deadline = DateTime.tryParse(scheduledDeletionAt!);
    if (deadline == null) return 0;
    final diff = deadline.difference(DateTime.now()).inDays;
    return diff.clamp(0, 30);
  }

  PaymentMethod? get defaultPayment =>
      paymentMethods.where((p) => p.isDefault).firstOrNull;

  /// Human-readable tier label.
  String get tierLabel => switch (reliabilityTier) {
        'TRUSTED'    => 'Trusted',
        'NORMAL'     => 'Normal',
        'RISKY'      => 'Risky',
        'RESTRICTED' => 'Restricted',
        _            => reliabilityTier,
      };

  Profile copyWith({
    String? fullName,
    String? email,
    String? phone,
    String? avatarUrl,
    String? location,
    String? role,
    List<PaymentMethod>? paymentMethods,
    List<String>? savedSalonIds,
    int? reliabilityScore,
    String? reliabilityTier,
    Object? scheduledDeletionAt = _sentinel,
  }) {
    return Profile(
      id: id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      location: location ?? this.location,
      role: role ?? this.role,
      paymentMethods: paymentMethods ?? this.paymentMethods,
      savedSalonIds: savedSalonIds ?? this.savedSalonIds,
      reliabilityScore: reliabilityScore ?? this.reliabilityScore,
      reliabilityTier: reliabilityTier ?? this.reliabilityTier,
      scheduledDeletionAt: scheduledDeletionAt == _sentinel
          ? this.scheduledDeletionAt
          : scheduledDeletionAt as String?,
    );
  }

  static const Object _sentinel = Object();

  @override
  List<Object?> get props => [id, savedSalonIds, role, reliabilityScore, reliabilityTier, scheduledDeletionAt];
}
