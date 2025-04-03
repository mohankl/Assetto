class Tenant {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? currentAssetId;
  final DateTime leaseStartDate;
  final DateTime leaseEndDate;
  final double monthlyRent;
  final String status; // 'active', 'past', 'pending'
  final DateTime createdAt;
  final DateTime updatedAt;

  Tenant({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.currentAssetId,
    required this.leaseStartDate,
    required this.leaseEndDate,
    required this.monthlyRent,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  // Convert Tenant to Map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'currentAssetId': currentAssetId,
      'leaseStartDate': leaseStartDate.toIso8601String(),
      'leaseEndDate': leaseEndDate.toIso8601String(),
      'monthlyRent': monthlyRent,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Create Tenant from Firebase Map
  factory Tenant.fromMap(Map<String, dynamic> map) {
    try {
      return Tenant(
        id: map['id'] as String? ?? '',
        name: map['name'] as String? ?? '',
        email: map['email'] as String? ?? '',
        phone: map['phone'] as String? ?? '',
        currentAssetId: map['currentAssetId'] as String?,
        leaseStartDate: map['leaseStartDate'] != null
            ? DateTime.parse(map['leaseStartDate'] as String)
            : DateTime.now(),
        leaseEndDate: map['leaseEndDate'] != null
            ? DateTime.parse(map['leaseEndDate'] as String)
            : DateTime.now().add(const Duration(days: 365)),
        monthlyRent: (map['monthlyRent'] as num?)?.toDouble() ?? 0.0,
        status: map['status'] as String? ?? 'pending',
        createdAt: map['createdAt'] != null
            ? DateTime.parse(map['createdAt'] as String)
            : DateTime.now(),
        updatedAt: map['updatedAt'] != null
            ? DateTime.parse(map['updatedAt'] as String)
            : DateTime.now(),
      );
    } catch (e) {
      print('Error creating Tenant from map: $e');
      rethrow;
    }
  }
}
