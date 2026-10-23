import 'package:equatable/equatable.dart';

class CatalogService extends Equatable {
  final String name;
  final String icon;

  const CatalogService({required this.name, required this.icon});

  factory CatalogService.fromJson(Map<String, dynamic> json) => CatalogService(
        name: json['name'] as String,
        icon: json['icon'] as String? ?? 'miscellaneous_services',
      );

  @override
  List<Object?> get props => [name, icon];
}

class CatalogCategory extends Equatable {
  final String category;
  final String icon;
  final List<CatalogService> services;

  const CatalogCategory({
    required this.category,
    required this.icon,
    required this.services,
  });

  factory CatalogCategory.fromJson(Map<String, dynamic> json) =>
      CatalogCategory(
        category: json['category'] as String,
        icon: json['icon'] as String? ?? 'miscellaneous_services',
        services: (json['services'] as List)
            .map((s) => CatalogService.fromJson(s as Map<String, dynamic>))
            .toList(),
      );

  @override
  List<Object?> get props => [category, icon];
}
