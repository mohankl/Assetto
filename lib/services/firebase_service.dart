import 'package:firebase_database/firebase_database.dart' as firebase;
import 'dart:developer' as developer;
import '../models/asset.dart';
import '../models/tenant.dart';
import '../models/transaction.dart';

class FirebaseService {
  final firebase.DatabaseReference _db =
      firebase.FirebaseDatabase.instance.ref();

  Future<void> testConnection() async {
    try {
      developer.log('Testing Firebase connection...');
      await _db.child('.info/connected').get();
      developer.log('Firebase connection successful');
    } catch (e, stackTrace) {
      developer.log('Firebase connection failed: $e\n$stackTrace');
      rethrow;
    }
  }

  // Asset operations
  Future<void> createAsset(Asset asset) async {
    try {
      developer.log('Creating asset: ${asset.id}');
      await _db.child('assets/${asset.id}').set(asset.toMap());
      developer.log('Asset created successfully');
    } catch (e) {
      developer.log('Error creating asset: $e');
      throw Exception('Failed to create asset: $e');
    }
  }

  Future<void> updateAsset(Asset asset) async {
    try {
      developer.log('Updating asset: ${asset.id}');
      await _db.child('assets/${asset.id}').update(asset.toMap());
      developer.log('Asset updated successfully');
    } catch (e) {
      developer.log('Error updating asset: $e');
      throw Exception('Failed to update asset: $e');
    }
  }

  Future<void> deleteAsset(String id) async {
    try {
      developer.log('Deleting asset: $id');
      await _db.child('assets/$id').remove();
      developer.log('Asset deleted successfully');
    } catch (e) {
      developer.log('Error deleting asset: $e');
      throw Exception('Failed to delete asset: $e');
    }
  }

  Stream<List<Asset>> getAssets() {
    try {
      developer.log('Fetching assets from Firebase...');
      return _db.child('assets').onValue.map((event) {
        final data = event.snapshot.value as Map?;
        if (data == null) {
          developer.log('No assets found in Firebase');
          return [];
        }
        return data.entries
            .map((e) {
              try {
                final map = Map<String, dynamic>.from(e.value as Map);
                map['id'] = e.key;
                return Asset.fromMap(map);
              } catch (error, stackTrace) {
                developer
                    .log('Error parsing asset ${e.key}: $error\n$stackTrace');
                return null;
              }
            })
            .whereType<Asset>()
            .toList();
      });
    } catch (e, stackTrace) {
      developer.log('Error in getAssets: $e\n$stackTrace');
      rethrow;
    }
  }

  // Tenant operations
  Future<void> createTenant(Tenant tenant) async {
    try {
      developer.log('Creating tenant: ${tenant.id}');
      await _db.child('tenants/${tenant.id}').set(tenant.toMap());
      developer.log('Tenant created successfully');
    } catch (e) {
      developer.log('Error creating tenant: $e');
      throw Exception('Failed to create tenant: $e');
    }
  }

  Future<void> updateTenant(Tenant tenant) async {
    try {
      developer.log('Updating tenant: ${tenant.id}');
      await _db.child('tenants/${tenant.id}').update(tenant.toMap());
      developer.log('Tenant updated successfully');
    } catch (e) {
      developer.log('Error updating tenant: $e');
      throw Exception('Failed to update tenant: $e');
    }
  }

  Future<void> deleteTenant(String id) async {
    try {
      developer.log('Deleting tenant: $id');
      await _db.child('tenants/$id').remove();
      developer.log('Tenant deleted successfully');
    } catch (e) {
      developer.log('Error deleting tenant: $e');
      throw Exception('Failed to delete tenant: $e');
    }
  }

  Stream<List<Tenant>> getTenants() {
    try {
      developer.log('Fetching tenants from Firebase...');
      return _db.child('tenants').onValue.map((event) {
        final data = event.snapshot.value as Map?;
        if (data == null) {
          developer.log('No tenants found in Firebase');
          return [];
        }
        return data.entries
            .map((e) {
              try {
                final map = Map<String, dynamic>.from(e.value as Map);
                map['id'] = e.key;
                return Tenant.fromMap(map);
              } catch (error, stackTrace) {
                developer
                    .log('Error parsing tenant ${e.key}: $error\n$stackTrace');
                return null;
              }
            })
            .whereType<Tenant>()
            .toList();
      });
    } catch (e, stackTrace) {
      developer.log('Error in getTenants: $e\n$stackTrace');
      rethrow;
    }
  }

  // Transaction operations
  Future<void> createTransaction(Transaction transaction) async {
    try {
      developer.log('Creating transaction: ${transaction.id}');
      await _db
          .child('transactions/${transaction.id}')
          .set(transaction.toMap());
      developer.log('Transaction created successfully');
    } catch (e) {
      developer.log('Error creating transaction: $e');
      throw Exception('Failed to create transaction: $e');
    }
  }

  Future<void> updateTransaction(Transaction transaction) async {
    try {
      developer.log('Updating transaction: ${transaction.id}');
      await _db
          .child('transactions/${transaction.id}')
          .update(transaction.toMap());
      developer.log('Transaction updated successfully');
    } catch (e) {
      developer.log('Error updating transaction: $e');
      throw Exception('Failed to update transaction: $e');
    }
  }

  Future<void> deleteTransaction(String id) async {
    try {
      developer.log('Deleting transaction: $id');
      await _db.child('transactions/$id').remove();
      developer.log('Transaction deleted successfully');
    } catch (e) {
      developer.log('Error deleting transaction: $e');
      throw Exception('Failed to delete transaction: $e');
    }
  }

  Stream<List<Transaction>> getTransactions() {
    try {
      developer.log('Fetching transactions from Firebase...');
      return _db.child('transactions').onValue.map((event) {
        final data = event.snapshot.value as Map?;
        if (data == null) {
          developer.log('No transactions found in Firebase');
          return [];
        }
        return data.entries
            .map((e) {
              try {
                final map = Map<String, dynamic>.from(e.value as Map);
                map['id'] = e.key;
                return Transaction.fromMap(map);
              } catch (error, stackTrace) {
                developer.log(
                    'Error parsing transaction ${e.key}: $error\n$stackTrace');
                return null;
              }
            })
            .whereType<Transaction>()
            .toList();
      });
    } catch (e, stackTrace) {
      developer.log('Error in getTransactions: $e\n$stackTrace');
      rethrow;
    }
  }

  // Dashboard data
  Stream<Map<String, dynamic>> getDashboardData() {
    developer.log('Starting dashboard data stream');
    return _db.child('dashboard').onValue.map((event) {
      try {
        final Map<dynamic, dynamic>? data =
            event.snapshot.value as Map<dynamic, dynamic>?;
        if (data == null) {
          developer.log('No dashboard data found');
          return {};
        }
        final dashboardData = Map<String, dynamic>.from(data);
        developer.log('Retrieved dashboard data: $dashboardData');
        return dashboardData;
      } catch (e) {
        developer.log('Error getting dashboard data: $e');
        return {};
      }
    });
  }
}
