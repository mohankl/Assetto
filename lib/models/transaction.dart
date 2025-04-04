class Transaction {
  final String id;
  final String assetId;
  final String? tenantId;
  final double amount;
  final String type; // 'rent', 'deposit', 'maintenance', etc.
  final String status; // 'pending', 'completed', 'cancelled'
  final String description;
  final int date;
  final int createdAt;
  final int updatedAt;
  final Map<String, dynamic> additionalData;

  Transaction({
    required this.id,
    required this.assetId,
    this.tenantId,
    required this.amount,
    required this.type,
    required this.status,
    required this.description,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
    this.additionalData = const {},
  });

  factory Transaction.empty() {
    return Transaction(
      id: '',
      assetId: '',
      tenantId: null,
      amount: 0.0,
      type: 'rent',
      status: 'pending',
      description: '',
      date: DateTime.now().millisecondsSinceEpoch,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
  }

  // Convert Transaction to Map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'asset_id': assetId,
      'tenant_id': tenantId,
      'amount': amount,
      'type': type,
      'status': status,
      'description': description,
      'date': date,
      'created_at': createdAt,
      'updated_at': updatedAt,
      ...additionalData,
    };
  }

  // Create Transaction from Firebase Map
  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] ?? '',
      assetId: map['asset_id'] ?? '',
      tenantId: map['tenant_id'],
      amount: (map['amount'] ?? 0.0).toDouble(),
      type: map['type'] ?? 'rent',
      status: map['status'] ?? 'pending',
      description: map['description'] ?? '',
      date: map['date'] ?? DateTime.now().millisecondsSinceEpoch,
      createdAt: map['created_at'] ?? DateTime.now().millisecondsSinceEpoch,
      updatedAt: map['updated_at'] ?? DateTime.now().millisecondsSinceEpoch,
      additionalData: Map<String, dynamic>.from(map)
        ..remove('id')
        ..remove('asset_id')
        ..remove('tenant_id')
        ..remove('amount')
        ..remove('type')
        ..remove('status')
        ..remove('description')
        ..remove('date')
        ..remove('created_at')
        ..remove('updated_at'),
    );
  }

  Transaction copyWith({
    String? id,
    String? assetId,
    String? tenantId,
    double? amount,
    String? type,
    String? status,
    String? description,
    int? date,
    int? createdAt,
    int? updatedAt,
    Map<String, dynamic>? additionalData,
  }) {
    return Transaction(
      id: id ?? this.id,
      assetId: assetId ?? this.assetId,
      tenantId: tenantId ?? this.tenantId,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      status: status ?? this.status,
      description: description ?? this.description,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      additionalData: additionalData ?? this.additionalData,
    );
  }
}
