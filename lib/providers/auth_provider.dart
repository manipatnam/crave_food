import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  UserModel? _user;
  AuthStatus _status = AuthStatus.unknown;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  UserModel? get user => _user;
  AuthStatus get status => _status;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  AuthProvider() {
    _initializeAuthListener();
  }

  // Initialize authentication state listener
  void _initializeAuthListener() {
    _authService.authStateChanges.listen((User? firebaseUser) async {
      if (firebaseUser != null) {
        _user = UserModel.fromFirebaseUser(firebaseUser);
        _status = AuthStatus.authenticated;
      } else {
        _user = null;
        _status = AuthStatus.unauthenticated;
      }
      notifyListeners();
    });
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Set error message
  void _setError(String error) {
    _errorMessage = error;
    _isLoading = false;
    notifyListeners();
  }

  // Sign in with email and password
  Future<bool> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      clearError();
      _setLoading(true);
      
      final userModel = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      _setLoading(false);
      return userModel != null;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // Register with email and password
  Future<bool> registerWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      clearError();
      _setLoading(true);
      
      final userModel = await _authService.registerWithEmailAndPassword(
        email: email,
        password: password,
        displayName: displayName,
      );
      
      _setLoading(false);
      return userModel != null;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      clearError();
      _setLoading(true);
      
      await _authService.signOut();
      
      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
    }
  }

  // Reset password
  Future<bool> resetPassword({required String email}) async {
    try {
      clearError();
      _setLoading(true);
      
      await _authService.resetPassword(email: email);
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // Send email verification
  Future<bool> sendEmailVerification() async {
    try {
      clearError();
      _setLoading(true);
      
      await _authService.sendEmailVerification();
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // Check email verification status
  Future<void> checkEmailVerification() async {
    try {
      await _authService.reloadUser();
      
      if (_user != null) {
        final updatedUser = await _authService.getCurrentUserModel();
        if (updatedUser != null) {
          _user = updatedUser;
          notifyListeners();
        }
      }
    } catch (e) {
      _setError(e.toString());
    }
  }

  // Get current user data
  bool get isEmailVerified => _authService.isEmailVerified;
}