import 'package:firebase_database/firebase_database.dart';
import 'dart:developer' as developer;
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  final FirebaseStorage _storage = FirebaseStorage.instance;

  factory FirebaseService() {
    return _instance;
  }

  FirebaseService._internal();

  // Asset operations
  Future<void> insertAsset(Map<String, dynamic> asset) async {
    try {
      // Use unit_number as the primary key for assets
      final unitNumber = asset['unit_number'] as String;
      if (unitNumber.isEmpty) {
        throw Exception('Unit number is required and cannot be empty');
      }

      // Check if an asset with this unit number already exists
      final existingAssets = await getAssets();
      final existingAsset = existingAssets.firstWhere(
        (a) => a['unit_number'] == unitNumber,
        orElse: () => <String, dynamic>{},
      );

      if (existingAsset.isNotEmpty && existingAsset['id'] != asset['id']) {
        throw Exception('An asset with unit number $unitNumber already exists');
      }

      await _db.child('assets').child(asset['id']).set(asset);
      developer.log(
          'Asset inserted successfully: ${asset['id']} with unit number: $unitNumber');
    } catch (e, stackTrace) {
      developer.log('Error inserting asset: $e\n$stackTrace');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getAssets() async {
    final snapshot = await _db.child('assets').get();
    if (snapshot.exists) {
      final Map<dynamic, dynamic> data =
          snapshot.value as Map<dynamic, dynamic>;
      return data.values
          .map((asset) => Map<String, dynamic>.from(asset))
          .toList();
    }
    return [];
  }

  Future<void> addAsset(Map<String, dynamic> asset) async {
    await _db.child('assets').child(asset['id']).set(asset);
  }

  Future<void> updateAsset(String id, Map<String, dynamic> asset) async {
    await _db.child('assets').child(id).update(asset);
  }

  Future<void> deleteAsset(String id) async {
    await _db.child('assets').child(id).remove();
  }

  // Tenant operations
  Future<void> insertTenant(Map<String, dynamic> tenant) async {
    try {
      await _db.child('tenants').child(tenant['id']).set(tenant);
      developer.log('Tenant inserted successfully: ${tenant['id']}');
    } catch (e, stackTrace) {
      developer.log('Error inserting tenant: $e\n$stackTrace');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getTenants() async {
    final snapshot = await _db.child('tenants').get();
    if (snapshot.exists) {
      final Map<dynamic, dynamic> data =
          snapshot.value as Map<dynamic, dynamic>;
      return data.values
          .map((tenant) => Map<String, dynamic>.from(tenant))
          .toList();
    }
    return [];
  }

  Future<void> addTenant(Map<String, dynamic> tenant) async {
    await _db.child('tenants').child(tenant['id']).set(tenant);
  }

  Future<void> updateTenant(String id, Map<String, dynamic> tenant) async {
    await _db.child('tenants').child(id).update(tenant);
  }

  Future<void> deleteTenant(String id) async {
    await _db.child('tenants').child(id).remove();
  }

  // Transaction operations
  Future<void> insertTransaction(Map<String, dynamic> transaction) async {
    try {
      await _db.child('transactions').child(transaction['id']).set(transaction);
      developer.log('Transaction inserted successfully: ${transaction['id']}');
    } catch (e, stackTrace) {
      developer.log('Error inserting transaction: $e\n$stackTrace');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getTransactions() async {
    final snapshot = await _db.child('transactions').get();
    if (snapshot.exists) {
      final Map<dynamic, dynamic> data =
          snapshot.value as Map<dynamic, dynamic>;
      return data.values
          .map((transaction) => Map<String, dynamic>.from(transaction))
          .toList();
    }
    return [];
  }

  Future<void> addTransaction(Map<String, dynamic> transaction) async {
    await _db.child('transactions').child(transaction['id']).set(transaction);
  }

  Future<void> updateTransaction(
      String id, Map<String, dynamic> transaction) async {
    await _db.child('transactions').child(id).update(transaction);
  }

  Future<void> deleteTransaction(String id) async {
    await _db.child('transactions').child(id).remove();
  }

  // Storage
  Future<String> uploadFile(String path, Uint8List bytes) async {
    final ref = _storage.ref().child(path);
    await ref.putData(bytes);
    return await ref.getDownloadURL();
  }

  Future<void> deleteFile(String path) async {
    await _storage.ref().child(path).delete();
  }
}
