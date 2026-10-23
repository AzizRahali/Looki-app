import 'package:equatable/equatable.dart';

import 'service_model.dart';
import 'review_model.dart';

class Salon extends Equatable {
  final String id;
  final String name;
  final String address;
  final String fullAddress;
  final String phone;
  final String website;
  final double rating;
  final int reviewCount;
  final double distance;
  final bool isVerified;
  final String openTime;
  final String closeTime;
  final List<String> tags;
  final List<String> categories;
  final String imageUrl;
  final List<Service> services;
  final List<Review> reviews;
  final double latitude;
  final double longitude;

  const Salon({
    required this.id,
    required this.name,
    required this.address,
    required this.fullAddress,
    this.phone = '',
    this.website = '',
    required this.rating,
    required this.reviewCount,
    required this.distance,
    required this.isVerified,
    required this.openTime,
    required this.closeTime,
    required this.tags,
    required this.categories,
    this.imageUrl = '',
    required this.services,
    required this.reviews,
    this.latitude = 0.0,
    this.longitude = 0.0,
  });

  factory Salon.fromJson(Map<String, dynamic> json) {
    return Salon(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      address: json['address'] as String? ?? '',
      fullAddress: json['fullAddress'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      website: json['website'] as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      distance: (json['distance'] as num?)?.toDouble() ?? 0.0,
      isVerified: json['isVerified'] as bool? ?? false,
      openTime: json['openTime'] as String? ?? '',
      closeTime: json['closeTime'] as String? ?? '',
      tags: json['tags'] != null
          ? List<String>.from(json['tags'] as List)
          : const [],
      categories: json['categories'] != null
          ? List<String>.from(json['categories'] as List)
          : const [],
      imageUrl: json['imageUrl'] as String? ?? '',
      services: json['services'] != null
          ? (json['services'] as List)
              .map((s) => Service.fromJson(s as Map<String, dynamic>))
              .toList()
          : const [],
      reviews: json['reviews'] != null
          ? (json['reviews'] as List)
              .map((r) => Review.fromJson(r as Map<String, dynamic>))
              .toList()
          : const [],
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
    );
  }

  String get openUntil => 'Open until ${closeTime.replaceAll(':00', '')}';
  String get distanceText => '$distance mi';

  @override
  List<Object?> get props => [id];
}
