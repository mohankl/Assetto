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
    try {
      final snapshot = await _db.child('assets').get();
      if (snapshot.exists) {
        final Map<dynamic, dynamic> data =
            snapshot.value as Map<dynamic, dynamic>;
        return data.values
            .map((asset) => Map<String, dynamic>.from(asset))
            .toList();
      }
      return [];
    } catch (e, stackTrace) {
      developer.log('Error getting assets: $e\n$stackTrace');
      rethrow;
    }
  }

  Future<void> addAsset(Map<String, dynamic> asset) async {
    try {
      await _db.child('assets').child(asset['id']).set(asset);
      developer.log('Asset added successfully: ${asset['id']}');
    } catch (e, stackTrace) {
      developer.log('Error adding asset: $e\n$stackTrace');
      rethrow;
    }
  }

  Future<void> updateAsset(String id, Map<String, dynamic> asset) async {
    try {
      await _db.child('assets').child(id).update(asset);
      developer.log('Asset updated successfully: $id');
    } catch (e, stackTrace) {
      developer.log('Error updating asset: $e\n$stackTrace');
      rethrow;
    }
  }

  Future<void> deleteAsset(String id) async {
    try {
      await _db.child('assets').child(id).remove();
      developer.log('Asset deleted successfully: $id');
    } catch (e, stackTrace) {
      developer.log('Error deleting asset: $e\n$stackTrace');
      rethrow;
    }
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
    try {
      final snapshot = await _db.child('tenants').get();
      if (snapshot.exists) {
        final Map<dynamic, dynamic> data =
            snapshot.value as Map<dynamic, dynamic>;
        return data.values
            .map((tenant) => Map<String, dynamic>.from(tenant))
            .toList();
      }
      return [];
    } catch (e, stackTrace) {
      developer.log('Error getting tenants: $e\n$stackTrace');
      rethrow;
    }
  }

  Future<void> addTenant(Map<String, dynamic> tenant) async {
    try {
      await _db.child('tenants').child(tenant['id']).set(tenant);
      developer.log('Tenant added successfully: ${tenant['id']}');
    } catch (e, stackTrace) {
      developer.log('Error adding tenant: $e\n$stackTrace');
      rethrow;
    }
  }

  Future<void> updateTenant(String id, Map<String, dynamic> tenant) async {
    try {
      await _db.child('tenants').child(id).update(tenant);
      developer.log('Tenant updated successfully: $id');
    } catch (e, stackTrace) {
      developer.log('Error updating tenant: $e\n$stackTrace');
      rethrow;
    }
  }

  Future<void> deleteTenant(String id) async {
    try {
      await _db.child('tenants').child(id).remove();
      developer.log('Tenant deleted successfully: $id');
    } catch (e, stackTrace) {
      developer.log('Error deleting tenant: $e\n$stackTrace');
      rethrow;
    }
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
    try {
      final snapshot = await _db.child('transactions').get();
      if (snapshot.exists) {
        final Map<dynamic, dynamic> data =
            snapshot.value as Map<dynamic, dynamic>;
        return data.values
            .map((transaction) => Map<String, dynamic>.from(transaction))
            .toList();
      }
      return [];
    } catch (e, stackTrace) {
      developer.log('Error getting transactions: $e\n$stackTrace');
      rethrow;
    }
  }

  Future<void> addTransaction(Map<String, dynamic> transaction) async {
    try {
      await _db.child('transactions').child(transaction['id']).set(transaction);
      developer.log('Transaction added successfully: ${transaction['id']}');
    } catch (e, stackTrace) {
      developer.log('Error adding transaction: $e\n$stackTrace');
      rethrow;
    }
  }

  Future<void> updateTransaction(
      String id, Map<String, dynamic> transaction) async {
    try {
      await _db.child('transactions').child(id).update(transaction);
      developer.log('Transaction updated successfully: $id');
    } catch (e, stackTrace) {
      developer.log('Error updating transaction: $e\n$stackTrace');
      rethrow;
    }
  }

  Future<void> deleteTransaction(String id) async {
    try {
      await _db.child('transactions').child(id).remove();
      developer.log('Transaction deleted successfully: $id');
    } catch (e, stackTrace) {
      developer.log('Error deleting transaction: $e\n$stackTrace');
      rethrow;
    }
  }

  // Storage operations
  Future<String> uploadFile(String path, Uint8List data) async {
    try {
      final ref = _storage.ref().child(path);
      final uploadTask = ref.putData(data);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      developer.log('File uploaded successfully: $path');
      return downloadUrl;
    } catch (e, stackTrace) {
      developer.log('Error uploading file: $e\n$stackTrace');
      rethrow;
    }
  }

  Future<void> deleteFile(String path) async {
    try {
      final ref = _storage.ref().child(path);
      await ref.delete();
      developer.log('File deleted successfully: $path');
    } catch (e, stackTrace) {
      developer.log('Error deleting file: $e\n$stackTrace');
      rethrow;
    }
  }
}
