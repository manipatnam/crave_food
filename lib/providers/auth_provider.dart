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
      print("🔍 Auth state changed: ${firebaseUser?.email ?? 'null'}");
      
      if (firebaseUser != null) {
        print("✅ User authenticated: ${firebaseUser.email}");
        _user = UserModel.fromFirebaseUser(firebaseUser);
        _status = AuthStatus.authenticated;
      } else {
        print("❌ User not authenticated");
        _user = null;
        _status = AuthStatus.unauthenticated;
      }
      
      print("📊 Updated auth status: $_status");
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
      
      print("🔐 Attempting sign in for: $email");
      
      final userModel = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      print("📊 Sign in result: ${userModel?.email ?? 'null'}");
      
      _setLoading(false);
      return userModel != null;
    } catch (e) {
      print("❌ Sign in error: $e");
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
      
      print("📝 Attempting registration for: $email");
      
      UserModel? userModel;
      try {
        userModel = await _authService.registerWithEmailAndPassword(
          email: email,
          password: password,
          displayName: displayName,
        );
      } catch (e) {
        print("⚠️ Registration threw error, but checking if user exists...");
        
        // Check if user was actually created despite the error
        final currentUser = _authService.currentUser;
        if (currentUser != null && currentUser.email == email.trim()) {
          print("✅ User was created successfully despite error");
          userModel = UserModel.fromFirebaseUser(currentUser);
        } else {
          rethrow; // Re-throw if user wasn't actually created
        }
      }
      
      print("📊 Final registration result: ${userModel?.email ?? 'null'}");
      
      _setLoading(false);
      
      if (userModel != null) {
        print("✅ Registration successful, waiting for auth state update...");
        // Give a moment for the auth state listener to update
        await Future.delayed(const Duration(milliseconds: 800));
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print("❌ Registration error: $e");
      _setError(e.toString());
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      clearError();
      _setLoading(true);
      
      print("🚪 Signing out user...");
      
      await _authService.signOut();
      
      _setLoading(false);
      print("✅ Sign out successful");
    } catch (e) {
      print("❌ Sign out error: $e");
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