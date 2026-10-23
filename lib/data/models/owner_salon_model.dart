import 'package:equatable/equatable.dart';
import 'owner_service_model.dart';

class OwnerSalon extends Equatable {
  final String id;
  final String name;
  final String description;
  final String address;
  final String phone;
  final String imageUrl;
  final double latitude;
  final double longitude;
  final double rating;
  final int reviewCount;
  final String openingHours;
  final List<String> tags;
  final List<SalonServiceItem> services;

  const OwnerSalon({
    required this.id,
    required this.name,
    required this.description,
    required this.address,
    required this.phone,
    required this.imageUrl,
    required this.latitude,
    required this.longitude,
    required this.rating,
    required this.reviewCount,
    required this.openingHours,
    required this.tags,
    required this.services,
  });

  factory OwnerSalon.fromJson(Map<String, dynamic> json) {
    return OwnerSalon(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      address: json['address'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: json['reviewCount'] as int? ?? 0,
      openingHours: json['openingHours'] as String? ?? '',
      tags: (json['tags'] as List?)?.map((t) => t.toString()).toList() ?? [],
      services: (json['services'] as List?)
              ?.map((s) =>
                  SalonServiceItem.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  @override
  List<Object?> get props => [id];
}
