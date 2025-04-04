import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../services/firebase_service.dart';
import '../models/asset.dart';
import '../models/tenant.dart';
import '../models/transaction.dart';
import 'dart:developer' as developer;

class DataProvider with ChangeNotifier {
  final FirebaseService _firebase = FirebaseService();
  final _uuid = const Uuid();

  List<Asset> _assets = [];
  List<Tenant> _tenants = [];
  List<Transaction> _transactions = [];
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;

  // Getters
  List<Asset> get assets => _assets;
  List<Tenant> get tenants => _tenants;
  List<Transaction> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isInitialized => _isInitialized;

  // Initialize data
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await Future.wait([
        loadAssets(),
        loadTenants(),
        loadTransactions(),
      ]);

      _isInitialized = true;
      _error = null;
    } catch (e) {
      _error = e.toString();
      developer.log('Error initializing data: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadAssets() async {
    try {
      final assetsData = await _firebase.getAssets();
      _assets = assetsData.map((data) => Asset.fromMap(data)).toList();
      _error = null;
    } catch (e) {
      _error = e.toString();
      developer.log('Error loading assets: $_error');
      rethrow;
    }
  }

  Future<void> loadTenants() async {
    try {
      final tenantsData = await _firebase.getTenants();
      _tenants = tenantsData.map((data) => Tenant.fromMap(data)).toList();
      _error = null;
    } catch (e) {
      _error = e.toString();
      developer.log('Error loading tenants: $_error');
      rethrow;
    }
  }

  Future<void> loadTransactions() async {
    try {
      final transactionsData = await _firebase.getTransactions();
      _transactions =
          transactionsData.map((data) => Transaction.fromMap(data)).toList();
      _error = null;
    } catch (e) {
      _error = e.toString();
      developer.log('Error loading transactions: $_error');
      rethrow;
    }
  }

  // Asset operations
  Future<void> addAsset(Map<String, dynamic> assetData) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final newAsset = Asset(
        id: _uuid.v4(),
        name: assetData['name'] ?? '',
        address: assetData['address'] ?? '',
        type: assetData['type'] ?? 'Apartment',
        status: assetData['status'] ?? 'Vacant',
        unitNumber: assetData['unit_number'] ?? '',
        rentAmount: (assetData['rent_amount'] ?? 0.0).toDouble(),
        imageUrl: assetData['image_url'],
        createdAt: DateTime.now().millisecondsSinceEpoch,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );

      await _firebase.addAsset(newAsset.toMap());
      _assets.add(newAsset);
      _error = null;
    } catch (e) {
      _error = e.toString();
      developer.log('Error adding asset: $_error');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateAsset(String id, Map<String, dynamic> assetData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final index = _assets.indexWhere((asset) => asset.id == id);
      if (index != -1) {
        final updatedAsset = Asset(
          id: id,
          name: assetData['name'] ?? _assets[index].name,
          address: assetData['address'] ?? _assets[index].address,
          type: assetData['type'] ?? _assets[index].type,
          status: assetData['status'] ?? _assets[index].status,
          unitNumber: assetData['unit_number'] ?? _assets[index].unitNumber,
          rentAmount: (assetData['rent_amount'] ?? _assets[index].rentAmount)
              .toDouble(),
          imageUrl: assetData['image_url'] ?? _assets[index].imageUrl,
          createdAt: _assets[index].createdAt,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        );

        await _firebase.updateAsset(id, updatedAsset.toMap());
        _assets[index] = updatedAsset;
        _error = null;
      }
    } catch (e) {
      _error = e.toString();
      developer.log('Error updating asset: $_error');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> deleteAsset(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _firebase.deleteAsset(id);
      _assets.removeWhere((asset) => asset.id == id);
      _error = null;
    } catch (e) {
      _error = e.toString();
      developer.log('Error deleting asset: $_error');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Tenant operations
  Future<void> addTenant(Tenant tenant) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final tenantWithId = tenant.copyWith(id: _uuid.v4());
      await _firebase.addTenant(tenantWithId.toMap());
      _tenants.add(tenantWithId);
      _error = null;
    } catch (e) {
      _error = e.toString();
      developer.log('Error adding tenant: $_error');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateTenant(Tenant tenant) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final index = _tenants.indexWhere((t) => t.id == tenant.id);
      if (index != -1) {
        await _firebase.updateTenant(tenant.id, tenant.toMap());
        _tenants[index] = tenant;
        _error = null;
      }
    } catch (e) {
      _error = e.toString();
      developer.log('Error updating tenant: $_error');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> deleteTenant(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _firebase.deleteTenant(id);
      _tenants.removeWhere((tenant) => tenant.id == id);
      _error = null;
    } catch (e) {
      _error = e.toString();
      developer.log('Error deleting tenant: $_error');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Transaction operations
  Future<void> addTransaction(Map<String, dynamic> transactionData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newTransaction = Transaction(
        id: _uuid.v4(),
        assetId: transactionData['asset_id'] ?? '',
        tenantId: transactionData['tenant_id'],
        amount: (transactionData['amount'] ?? 0.0).toDouble(),
        type: transactionData['type']?.toLowerCase() ?? 'income',
        status: transactionData['status']?.toLowerCase() ?? 'pending',
        description: transactionData['description'] ?? '',
        date: transactionData['date'] ?? DateTime.now().millisecondsSinceEpoch,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );

      await _firebase.addTransaction(newTransaction.toMap());

      // Create a new list to trigger state update
      _transactions = [..._transactions, newTransaction];
      _error = null;

      developer
          .log('Transaction added successfully: ${newTransaction.toMap()}');
      developer.log('Total transactions: ${_transactions.length}');
      developer.log(
          'Total income: ${_transactions.where((t) => t.type.toLowerCase() == 'income').fold(0.0, (sum, t) => sum + t.amount)}');

      // Notify listeners after successful addition
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      developer.log('Error adding transaction: $_error');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateTransaction(
      String id, Map<String, dynamic> transactionData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final index =
          _transactions.indexWhere((transaction) => transaction.id == id);
      if (index != -1) {
        final updatedTransaction = Transaction(
          id: id,
          assetId: transactionData['asset_id'] ?? _transactions[index].assetId,
          tenantId:
              transactionData['tenant_id'] ?? _transactions[index].tenantId,
          amount: (transactionData['amount'] ?? _transactions[index].amount)
              .toDouble(),
          type: transactionData['type']?.toLowerCase() ??
              _transactions[index].type,
          status: transactionData['status']?.toLowerCase() ??
              _transactions[index].status,
          description: transactionData['description'] ??
              _transactions[index].description,
          date: transactionData['date'] ?? _transactions[index].date,
          createdAt: _transactions[index].createdAt,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        );

        await _firebase.updateTransaction(id, updatedTransaction.toMap());
        _transactions[index] = updatedTransaction;
        _error = null;

        // Notify listeners after successful update
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      developer.log('Error updating transaction: $_error');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> deleteTransaction(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _firebase.deleteTransaction(id);
      _transactions.removeWhere((transaction) => transaction.id == id);
      _error = null;
    } catch (e) {
      _error = e.toString();
      developer.log('Error deleting transaction: $_error');
    }

    _isLoading = false;
    notifyListeners();
  }
}
