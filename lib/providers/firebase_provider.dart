import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import '../services/firebase_service.dart';

class FirebaseProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  bool _isInitialized = false;
  String? _error;

  FirebaseService get firebaseService => _firebaseService;
  bool get isInitialized => _isInitialized;
  String? get error => _error;

  Future<void> initialize() async {
    try {
      developer.log('Initializing FirebaseProvider...');
      _error = null;

      // Test the Firebase service
      await _firebaseService.testConnection();

      _isInitialized = true;
      developer.log('FirebaseProvider initialized successfully');
      notifyListeners();
    } catch (e, stackTrace) {
      _isInitialized = false;
      _error = e.toString();
      developer.log('Error initializing FirebaseProvider: $e\n$stackTrace');
      notifyListeners();
      rethrow;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
