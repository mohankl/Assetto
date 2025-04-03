class Asset {
  final String id;
  final String name;
  final String address;
  final double rentAmount;
  final String status; // 'available', 'rented', 'maintenance'
  final String? currentTenantId;
  final DateTime createdAt;
  final DateTime updatedAt;

  Asset({
    required this.id,
    required this.name,
    required this.address,
    required this.rentAmount,
    required this.status,
    this.currentTenantId,
    required this.createdAt,
    required this.updatedAt,
  });

  // Convert Asset to Map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'rentAmount': rentAmount,
      'status': status,
      'currentTenantId': currentTenantId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Create Asset from Firebase Map
  factory Asset.fromMap(Map<String, dynamic> map) {
    try {
      return Asset(
        id: map['id'] as String? ?? '',
        name: map['name'] as String? ?? '',
        address: map['address'] as String? ?? '',
        rentAmount: (map['rentAmount'] as num?)?.toDouble() ?? 0.0,
        status: map['status'] as String? ?? 'available',
        currentTenantId: map['currentTenantId'] as String?,
        createdAt: map['createdAt'] != null
            ? DateTime.parse(map['createdAt'] as String)
            : DateTime.now(),
        updatedAt: map['updatedAt'] != null
            ? DateTime.parse(map['updatedAt'] as String)
            : DateTime.now(),
      );
    } catch (e) {
      print('Error creating Asset from map: $e');
      rethrow;
    }
  }
}
