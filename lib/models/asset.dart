class Asset {
  final String id;
  final String name;
  final String address;
  final String type;
  final String status;
  final String unitNumber;
  final String? imageUrl;
  final double rentAmount;
  final int createdAt;
  final int updatedAt;
  final Map<String, dynamic> additionalData;

  Asset({
    required this.id,
    required this.name,
    required this.address,
    required this.type,
    required this.status,
    required this.unitNumber,
    this.imageUrl,
    required this.rentAmount,
    required this.createdAt,
    required this.updatedAt,
    this.additionalData = const {},
  });

  factory Asset.empty() {
    return Asset(
      id: '',
      name: 'Unnamed Property',
      address: 'No address provided',
      type: 'Apartment',
      status: 'Vacant',
      unitNumber: '',
      imageUrl: null,
      rentAmount: 0.0,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'type': type,
      'status': status,
      'unit_number': unitNumber,
      'image_url': imageUrl,
      'rent_amount': rentAmount,
      'created_at': createdAt,
      'updated_at': updatedAt,
      ...additionalData,
    };
  }

  factory Asset.fromMap(Map<String, dynamic> map) {
    return Asset(
      id: map['id'] ?? '',
      name: map['name'] ?? 'Unnamed Property',
      address: map['address'] ?? 'No address provided',
      type: map['type'] ?? 'Unknown',
      status: map['status'] ?? 'Unknown',
      unitNumber: map['unit_number'] ?? '',
      imageUrl: map['image_url'],
      rentAmount: (map['rent_amount'] ?? 0.0).toDouble(),
      createdAt: map['created_at'] ?? DateTime.now().millisecondsSinceEpoch,
      updatedAt: map['updated_at'] ?? DateTime.now().millisecondsSinceEpoch,
      additionalData: Map<String, dynamic>.from(map)
        ..remove('id')
        ..remove('name')
        ..remove('address')
        ..remove('type')
        ..remove('status')
        ..remove('unit_number')
        ..remove('image_url')
        ..remove('rent_amount')
        ..remove('created_at')
        ..remove('updated_at'),
    );
  }

  Asset copyWith({
    String? id,
    String? name,
    String? address,
    String? type,
    String? status,
    String? unitNumber,
    String? imageUrl,
    double? rentAmount,
    int? createdAt,
    int? updatedAt,
    Map<String, dynamic>? additionalData,
  }) {
    return Asset(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      type: type ?? this.type,
      status: status ?? this.status,
      unitNumber: unitNumber ?? this.unitNumber,
      imageUrl: imageUrl ?? this.imageUrl,
      rentAmount: rentAmount ?? this.rentAmount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      additionalData: additionalData ?? this.additionalData,
    );
  }
}
