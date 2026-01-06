import 'package:hive/hive.dart';

part 'address_model.g.dart';

@HiveType(typeId: 5)
class Address {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String receiverName;

  @HiveField(2)
  final String phoneNumber;

  @HiveField(3)
  final String address;

  @HiveField(4)
  final String? city;

  @HiveField(5)
  final String? postalCode;

  @HiveField(6)
  final double? latitude;

  @HiveField(7)
  final double? longitude;

  Address({
    required this.id,
    required this.receiverName,
    required this.phoneNumber,
    required this.address,
    this.city,
    this.postalCode,
    this.latitude,
    this.longitude,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id'],
      receiverName: json['receiver_name'],
      phoneNumber: json['phone_number'],
      address: json['address'],
      city: json['city'],
      postalCode: json['postal_code'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
    );
  }

  Map<String, dynamic> toJsonForUpsert() {
    return {
      'receiver_name': receiverName,
      'phone_number': phoneNumber,
      'address': address,
      'city': city,
      'postal_code': postalCode,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
