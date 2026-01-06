import 'package:hive/hive.dart';

part 'product_model.g.dart';

@HiveType(typeId: 0)
class Product {
  @HiveField(0)
  final int id;
  
  @HiveField(1)
  final String name;
  
  @HiveField(2)
  final String category;
  
  @HiveField(3)
  final int price;
  
  @HiveField(4)
  final String color;
  
  @HiveField(5)
  final String description;
  
  @HiveField(6)
  final String imagePath;
  
  @HiveField(7)
  final DateTime? createdAt;
  
  @HiveField(8)
  final DateTime? updatedAt;

  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.color,
    required this.description,
    required this.imagePath,
    this.createdAt,
    this.updatedAt,
  });

  // Constructor untuk create new product (tanpa ID)
  factory Product.create({
    required String name,
    required String category,
    required int price,
    required String color,
    required String description,
    required String imagePath,
  }) {
    return Product(
      id: 0, // ID akan di-generate oleh Supabase
      name: name,
      category: category,
      price: price,
      color: color,
      description: description,
      imagePath: imagePath,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  Product copyWith({
    int? id,
    String? name,
    String? category,
    int? price,
    String? color,
    String? description,
    String? imagePath,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      price: price ?? this.price,
      color: color ?? this.color,
      description: description ?? this.description,
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      price: json['price'] ?? 0,
      color: json['color'] ?? '',
      description: json['description'] ?? '',
      imagePath: json['image_path'] ?? '',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'price': price,
      'color': color,
      'description': description,
      'image_path': imagePath,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // Untuk create new product, kita exclude ID karena auto increment
  Map<String, dynamic> toJsonForCreate() {
    return {
      'name': name,
      'category': category,
      'price': price,
      'color': color,
      'description': description,
      'image_path': imagePath,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'Product(id: $id, name: $name, category: $category, price: $price)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Product && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}