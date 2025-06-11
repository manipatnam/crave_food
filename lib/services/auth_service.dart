import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

enum AuthStatus {
  unknown,
  authenticated,
  unauthenticated,
}

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream to listen to authentication state changes
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // Get current user
  User? get currentUser => _firebaseAuth.currentUser;

  // Get current user as UserModel
  Future<UserModel?> getCurrentUserModel() async {
    final user = currentUser;
    if (user != null) {
      return UserModel.fromFirebaseUser(user);
    }
    return null;
  }

  // Sign in with email and password
  Future<UserModel?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      print("🔐 Firebase: Attempting sign in...");
      
      final UserCredential result = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final User? user = result.user;
      if (user != null) {
        print("✅ Firebase: Sign in successful for ${user.email}");
        
        // Small delay to ensure Firebase state is properly updated
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Update last login time in Firestore (non-blocking)
        _updateUserLoginTime(user.uid).catchError((e) {
          print("⚠️ Failed to update login time: $e");
          // Don't throw - this is not critical
        });
        
        return UserModel.fromFirebaseUser(user);
      }
      
      print("❌ Firebase: Sign in failed - no user returned");
      return null;
    } on FirebaseAuthException catch (e) {
      print("❌ Firebase Auth Exception: ${e.code} - ${e.message}");
      throw _handleAuthException(e);
    } catch (e) {
      print("❌ Firebase: Unexpected error during sign in: $e");
      
      // Check if user is actually signed in despite the error
      await Future.delayed(const Duration(milliseconds: 1000));
      final currentUser = _firebaseAuth.currentUser;
      
      if (currentUser != null && currentUser.email == email.trim()) {
        print("✅ User is actually signed in despite error - returning success");
        return UserModel.fromFirebaseUser(currentUser);
      }
      
      throw 'Sign in encountered an error, but may have succeeded. Please check if you are logged in.';
    }
  }

  // Register with email and password
  Future<UserModel?> registerWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      print("📝 Firebase: Attempting registration...");
      
      final UserCredential result = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final User? user = result.user;
      if (user != null) {
        print("✅ Firebase: Registration successful for ${user.email}");
        
        // Update display name if provided
        if (displayName != null && displayName.isNotEmpty) {
          try {
            await user.updateDisplayName(displayName);
            print("✅ Display name updated: $displayName");
          } catch (e) {
            print("⚠️ Display name update failed: $e");
            // Continue anyway - this isn't critical
          }
        }

        // Create user document in Firestore
        final userModel = UserModel.fromFirebaseUser(user);
        try {
          await _createUserDocument(userModel);
          print("✅ User document created in Firestore");
        } catch (e) {
          print("⚠️ Firestore document creation failed: $e");
          // Continue anyway - auth still works without Firestore doc
        }

        return userModel;
      } else {
        print("❌ Firebase: Registration failed - no user returned");
        return null;
      }
    } on FirebaseAuthException catch (e) {
      print("❌ Firebase Auth Exception during registration: ${e.code} - ${e.message}");
      throw _handleAuthException(e);
    } catch (e) {
      print("❌ Firebase: Unexpected error during registration: $e");
      
      // Check if user was actually created despite the error
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser != null && currentUser.email == email.trim()) {
        print("✅ User was created despite error - returning success");
        return UserModel.fromFirebaseUser(currentUser);
      }
      
      throw 'Registration encountered an error, but may have succeeded. Please try signing in.';
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
      print("✅ Firebase: Sign out successful");
    } catch (e) {
      print("❌ Firebase: Sign out error: $e");
      throw 'Error signing out. Please try again.';
    }
  }

  // Reset password
  Future<void> resetPassword({required String email}) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
      print("✅ Password reset email sent to: $email");
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'An unexpected error occurred. Please try again.';
    }
  }

  // Send email verification
  Future<void> sendEmailVerification() async {
    try {
      final user = currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        print("✅ Email verification sent");
      }
    } catch (e) {
      throw 'Error sending verification email. Please try again.';
    }
  }

  // Check if email is verified
  bool get isEmailVerified => currentUser?.emailVerified ?? false;

  // Reload user to get updated verification status
  Future<void> reloadUser() async {
    await currentUser?.reload();
  }

  // Create user document in Firestore
  Future<void> _createUserDocument(UserModel userModel) async {
    try {
      await _firestore.collection('users').doc(userModel.uid).set(userModel.toMap());
    } catch (e) {
      print('Error creating user document: $e');
      rethrow; // Let caller handle this
    }
  }

  // Update user login time
  Future<void> _updateUserLoginTime(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'lastLoginAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error updating login time: $e');
      // Don't rethrow - this is not critical
    }
  }

  // Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    print("🔍 Handling Firebase Auth Exception: ${e.code}");
    
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'Sign-in method is not enabled. Please contact support.';
      case 'invalid-credential':
        return 'Invalid credentials. Please check your email and password.';
      case 'network-request-failed':
        return 'Network error. Please check your connection and try again.';
      default:
        return e.message ?? 'An error occurred. Please try again.';
    }
  }
}