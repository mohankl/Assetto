class Transaction {
  final String id;
  final String assetId;
  final String tenantId;
  final double amount;
  final String type; // 'rent', 'deposit', 'maintenance', 'other'
  final String status; // 'pending', 'completed', 'failed'
  final DateTime date;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;

  Transaction({
    required this.id,
    required this.assetId,
    required this.tenantId,
    required this.amount,
    required this.type,
    required this.status,
    required this.date,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  // Convert Transaction to Map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'assetId': assetId,
      'tenantId': tenantId,
      'amount': amount,
      'type': type,
      'status': status,
      'date': date.toIso8601String(),
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Create Transaction from Firebase Map
  factory Transaction.fromMap(Map<String, dynamic> map) {
    try {
      return Transaction(
        id: map['id'] as String? ?? '',
        assetId: map['assetId'] as String? ?? '',
        tenantId: map['tenantId'] as String? ?? '',
        amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
        type: map['type'] as String? ?? 'other',
        status: map['status'] as String? ?? 'pending',
        date: map['date'] != null
            ? DateTime.parse(map['date'] as String)
            : DateTime.now(),
        description: map['description'] as String?,
        createdAt: map['createdAt'] != null
            ? DateTime.parse(map['createdAt'] as String)
            : DateTime.now(),
        updatedAt: map['updatedAt'] != null
            ? DateTime.parse(map['updatedAt'] as String)
            : DateTime.now(),
      );
    } catch (e) {
      print('Error creating Transaction from map: $e');
      rethrow;
    }
  }
}
