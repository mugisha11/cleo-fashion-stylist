import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Sign up with email and password
  Future<UserModel> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) {
        throw Exception('User creation failed');
      }

      // Update display name if provided
      if (displayName != null) {
        await user.updateDisplayName(displayName);
      }

      // Create user document in Firestore
      final userModel = UserModel(
        id: user.uid,
        email: user.email ?? email,
        displayName: displayName ?? user.displayName,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('users').doc(user.uid).set(userModel.toFirestore());

      return userModel;
    } catch (e) {
      throw Exception('Sign up failed: $e');
    }
  }

  /// Sign in with email and password
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) {
        throw Exception('Sign in failed');
      }

      return await getUserData(user.uid);
    } catch (e) {
      throw Exception('Sign in failed: $e');
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Get user data from Firestore
  Future<UserModel> getUserData(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      } else {
        // Create user document if it doesn't exist
        final firebaseUser = _auth.currentUser;
        final userModel = UserModel(
          id: userId,
          email: firebaseUser?.email ?? '',
          displayName: firebaseUser?.displayName,
          createdAt: DateTime.now(),
        );
        await _firestore.collection('users').doc(userId).set(userModel.toFirestore());
        return userModel;
      }
    } catch (e) {
      throw Exception('Failed to get user data: $e');
    }
  }

  /// Update user onboarding data
  Future<void> updateOnboardingData(String userId, OnboardingData onboardingData) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'onboardingData': onboardingData.toMap(),
      });
    } catch (e) {
      throw Exception('Failed to update onboarding data: $e');
    }
  }

  /// Sign in with Google
  Future<UserModel> signInWithGoogle() async {
    try {
      // This method should be implemented with google_sign_in package
      // For now, throw an exception indicating it's not implemented
      throw Exception('Google Sign-In is not configured. Please add your Google Client ID to web/index.html');
    } catch (e) {
      throw Exception('Google sign in failed: $e');
    }
  }

  /// Sign in with Apple
  Future<UserModel> signInWithApple() async {
    try {
      // This method should be implemented with sign_in_with_apple package
      throw Exception('Apple Sign-In is not yet implemented');
    } catch (e) {
      throw Exception('Apple sign in failed: $e');
    }
  }

  /// Verify phone number
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String) codeSent,
    required Function(String) verificationFailed,
    required VoidCallback codeAutoRetrievalTimeout,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verification completed
        },
        verificationFailed: (FirebaseAuthException e) {
          verificationFailed(e.message ?? 'Verification failed');
        },
        codeSent: (String verificationId, int? resendToken) {
          codeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          codeAutoRetrievalTimeout();
        },
      );
    } catch (e) {
      throw Exception('Phone verification failed: $e');
    }
  }

  /// Sign in with phone credential
  Future<UserModel> signInWithPhoneCredential({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      
      if (user == null) {
        throw Exception('Sign in failed');
      }

      return await getUserData(user.uid);
    } catch (e) {
      throw Exception('Phone sign in failed: $e');
    }
  }
}

