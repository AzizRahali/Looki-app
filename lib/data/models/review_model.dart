import 'package:equatable/equatable.dart';

class Review extends Equatable {
  final String id;
  final String salonId;
  final String userId;
  final String userName;
  final String userAvatar;
  final int rating;
  final String comment;
  final String createdAt;

  const Review({
    required this.id,
    this.salonId = '',
    this.userId = '',
    required this.userName,
    this.userAvatar = '',
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] as String? ?? '',
      salonId: json['salonId'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      userName: json['userName'] as String? ?? '',
      userAvatar: json['userAvatar'] as String? ?? '',
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      comment: json['comment'] as String? ?? '',
      createdAt: json['createdAt'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [id, salonId, userId, userName, rating, comment, createdAt];
}
