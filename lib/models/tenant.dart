class Tenant {
  final String id;
  final String name;
  final String? remarks;
  final String phone;
  final String? aadharNumber;
  final String? aadharImage;
  final String assetId;
  final String? assetName;
  final int? leaseStart;
  final int? leaseEnd;
  final double? advanceAmount;
  final int createdAt;
  final int updatedAt;
  final Map<String, dynamic> additionalData;

  Tenant({
    required this.id,
    required this.name,
    this.remarks,
    required this.phone,
    this.aadharNumber,
    this.aadharImage,
    required this.assetId,
    this.assetName,
    this.leaseStart,
    this.leaseEnd,
    this.advanceAmount,
    required this.createdAt,
    required this.updatedAt,
    this.additionalData = const {},
  });

  factory Tenant.empty() {
    return Tenant(
      id: '',
      name: 'Unknown Tenant',
      remarks: null,
      phone: '',
      aadharNumber: null,
      aadharImage: null,
      assetId: '',
      assetName: null,
      leaseStart: null,
      leaseEnd: null,
      advanceAmount: null,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
      additionalData: {},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'remarks': remarks,
      'phone': phone,
      'aadhar_number': aadharNumber,
      'aadhar_image': aadharImage,
      'asset_id': assetId,
      'asset_name': assetName,
      'lease_start': leaseStart,
      'lease_end': leaseEnd,
      'advance_amount': advanceAmount,
      'created_at': createdAt,
      'updated_at': updatedAt,
      ...additionalData,
    };
  }

  factory Tenant.fromMap(Map<String, dynamic> map) {
    return Tenant(
      id: map['id'] ?? '',
      name: map['name'] ?? 'Unnamed Tenant',
      remarks: map['remarks'],
      phone: map['phone'] ?? '',
      aadharNumber: map['aadhar_number'],
      aadharImage: map['aadhar_image'],
      assetId: map['asset_id'] ?? '',
      assetName: map['asset_name'],
      leaseStart: map['lease_start'],
      leaseEnd: map['lease_end'],
      advanceAmount: map['advance_amount'] != null
          ? (map['advance_amount'] as num).toDouble()
          : null,
      createdAt: map['created_at'] ?? DateTime.now().millisecondsSinceEpoch,
      updatedAt: map['updated_at'] ?? DateTime.now().millisecondsSinceEpoch,
      additionalData: Map<String, dynamic>.from(map)
        ..remove('id')
        ..remove('name')
        ..remove('remarks')
        ..remove('phone')
        ..remove('aadhar_number')
        ..remove('aadhar_image')
        ..remove('asset_id')
        ..remove('asset_name')
        ..remove('lease_start')
        ..remove('lease_end')
        ..remove('advance_amount')
        ..remove('created_at')
        ..remove('updated_at'),
    );
  }

  Tenant copyWith({
    String? id,
    String? name,
    String? remarks,
    String? phone,
    String? aadharNumber,
    String? aadharImage,
    String? assetId,
    String? assetName,
    int? leaseStart,
    int? leaseEnd,
    double? advanceAmount,
    int? createdAt,
    int? updatedAt,
    Map<String, dynamic>? additionalData,
  }) {
    return Tenant(
      id: id ?? this.id,
      name: name ?? this.name,
      remarks: remarks ?? this.remarks,
      phone: phone ?? this.phone,
      aadharNumber: aadharNumber ?? this.aadharNumber,
      aadharImage: aadharImage ?? this.aadharImage,
      assetId: assetId ?? this.assetId,
      assetName: assetName ?? this.assetName,
      leaseStart: leaseStart ?? this.leaseStart,
      leaseEnd: leaseEnd ?? this.leaseEnd,
      advanceAmount: advanceAmount ?? this.advanceAmount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      additionalData: additionalData ?? this.additionalData,
    );
  }
}
