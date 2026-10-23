import 'package:equatable/equatable.dart';

import '../services/localization_service.dart';

class Service extends Equatable {
  final String id;
  final String name;
  final String category;
  final int duration;
  final double price;
  final String icon;

  const Service({
    required this.id,
    required this.name,
    required this.category,
    required this.duration,
    required this.price,
    required this.icon,
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      duration: json['duration'] as int,
      price: (json['price'] as num).toDouble(),
      icon: json['icon'] as String,
    );
  }

  String get durationText => '$duration min';
  String get priceText => formatPrice(price);

  @override
  List<Object?> get props => [id];
}
