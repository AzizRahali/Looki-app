import 'package:equatable/equatable.dart';

import '../services/localization_service.dart';

class SalonServiceItem extends Equatable {
  final String id;
  final String name;
  final String description;
  final String category;
  final double price;
  final int durationMinutes;
  final String icon;

  const SalonServiceItem({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.price,
    required this.durationMinutes,
    required this.icon,
  });

  factory SalonServiceItem.fromJson(Map<String, dynamic> json) {
    return SalonServiceItem(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      durationMinutes: json['durationMinutes'] as int? ?? 0,
      icon: json['icon'] as String? ?? 'content_cut',
    );
  }

  String get priceText => formatPrice(price);
  String get durationText => '${durationMinutes}min';

  @override
  List<Object?> get props => [id];
}
