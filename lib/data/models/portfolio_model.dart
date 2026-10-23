import 'package:equatable/equatable.dart';

class PortfolioPost extends Equatable {
  final String id;
  final String salonId;
  final String caption;
  final String imageUrl;
  final String createdAt;

  const PortfolioPost({
    required this.id,
    required this.salonId,
    required this.caption,
    required this.imageUrl,
    required this.createdAt,
  });

  factory PortfolioPost.fromJson(Map<String, dynamic> json) {
    return PortfolioPost(
      id: json['id'] as String? ?? '',
      salonId: json['salonId'] as String? ?? '',
      caption: json['caption'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      createdAt: json['createdAt'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [id];
}
