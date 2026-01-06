import 'package:hive/hive.dart';

part 'order_model.g.dart';

@HiveType(typeId: 2)
class Order {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final int totalPrice;

  @HiveField(3)
  final String status;

  @HiveField(4)
  final DateTime? createdAt;

  @HiveField(5)
  final DateTime? updatedAt;

  @HiveField(6)
  final int addressId; // ✅ baru ditambahkan

  Order({
    required this.id,
    required this.userId,
    required this.totalPrice,
    required this.status,
    this.createdAt,
    this.updatedAt,
    required this.addressId, // wajib di konstruktor
  });

  // Untuk create order baru (tanpa ID)
  factory Order.create({
    required String userId,
    required int totalPrice,
    required int addressId, // tambah addressId
  }) {
    return Order(
      id: 0,
      userId: userId,
      totalPrice: totalPrice,
      status: 'pending',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      addressId: addressId,
    );
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? '',
      totalPrice: json['total_price'] ?? 0,
      status: json['status'] ?? 'pending',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      addressId: json['address_id'] ?? 0, // mapping kolom address_id
    );
  }

  Map<String, dynamic> toJsonForCreate() {
    return {
      'user_id': userId,
      'total_price': totalPrice,
      'status': status,
      'address_id': addressId, // sertakan addressId
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'Order(id: $id, total: $totalPrice, status: $status, addressId: $addressId)';
  }

  Order copyWith({
    int? id,
    String? userId,
    int? totalPrice,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? addressId,
  }) {
    return Order(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      totalPrice: totalPrice ?? this.totalPrice,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      addressId: addressId ?? this.addressId,
    );
  }
}
