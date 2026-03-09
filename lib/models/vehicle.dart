import 'package:cloud_firestore/cloud_firestore.dart';

class Vehicle {
  final String id;
  final String make;
  final String model;
  final int year;
  final String licensePlate;
  final int mileage;

  Vehicle({
    required this.id,
    required this.make,
    required this.model,
    required this.year,
    required this.licensePlate,
    required this.mileage,
  });

  factory Vehicle.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Vehicle(
      id: doc.id,
      make: data['make'] ?? '',
      model: data['model'] ?? '',
      year: data['year'] ?? 0,
      licensePlate: data['licensePlate'] ?? '',
      mileage: data['mileage'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'make': make,
      'model': model,
      'year': year,
      'licensePlate': licensePlate,
      'mileage': mileage,
    };
  }

  Vehicle copyWith({
    String? id,
    String? make,
    String? model,
    int? year,
    String? licensePlate,
    int? mileage,
  }) {
    return Vehicle(
      id: id ?? this.id,
      make: make ?? this.make,
      model: model ?? this.model,
      year: year ?? this.year,
      licensePlate: licensePlate ?? this.licensePlate,
      mileage: mileage ?? this.mileage,
    );
  }

  String get displayName => '$year $make $model';

  String get formattedMileage {
    final formatted = mileage.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
    return '$formatted mi';
  }

  @override
  String toString() => 'Vehicle(id: $id, $displayName, $formattedMileage)';
}
