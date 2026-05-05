import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';

const String _googleWebClientId =
    'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com';

String get _resolvedGoogleWebClientId {
  return _googleWebClientId.contains('YOUR_WEB_CLIENT_ID')
      ? ''
      : _googleWebClientId;
}

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

      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(userModel.toFirestore());

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
      final firebaseUser = _auth.currentUser;

      if (doc.exists) {
        final userModel = UserModel.fromFirestore(doc);
        // Update Firestore if Firebase user has more recent info (e.g., from Google)
        if (firebaseUser != null) {
          final needsUpdate = (userModel.displayName == null &&
                  firebaseUser.displayName != null) ||
              (userModel.email.isEmpty && firebaseUser.email != null) ||
              (userModel.avatarUrl == null && firebaseUser.photoURL != null);

          if (needsUpdate) {
            await _firestore.collection('users').doc(userId).update({
              if (userModel.displayName == null &&
                  firebaseUser.displayName != null)
                'displayName': firebaseUser.displayName,
              if (userModel.email.isEmpty && firebaseUser.email != null)
                'email': firebaseUser.email!,
              if (userModel.avatarUrl == null && firebaseUser.photoURL != null)
                'avatarUrl': firebaseUser.photoURL,
            });

            // Return updated model
            return UserModel(
              id: userId,
              email: firebaseUser.email ?? userModel.email,
              displayName: firebaseUser.displayName ?? userModel.displayName,
              avatarUrl: firebaseUser.photoURL ?? userModel.avatarUrl,
              createdAt: userModel.createdAt,
              onboardingData: userModel.onboardingData,
              avatarModelUrl: userModel.avatarModelUrl,
            );
          }
        }
        return userModel;
      } else {
        // Create user document if it doesn't exist
        final userModel = UserModel(
          id: userId,
          email: firebaseUser?.email ?? '',
          displayName: firebaseUser?.displayName,
          avatarUrl: firebaseUser?.photoURL,
          createdAt: DateTime.now(),
        );
        await _firestore
            .collection('users')
            .doc(userId)
            .set(userModel.toFirestore());
        return userModel;
      }
    } catch (e) {
      throw Exception('Failed to get user data: $e');
    }
  }

  /// Update user onboarding data
  Future<void> updateOnboardingData(
      String userId, OnboardingData onboardingData) async {
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
      UserCredential userCredential;
      String? googleEmail;
      String? googleDisplayName;
      String? googlePhotoUrl;

      if (kIsWeb) {
        // Use Firebase Auth popup flow on web. This avoids needing a separate
        // google_signin client_id configuration in most cases.
        final GoogleAuthProvider provider = GoogleAuthProvider();
        provider.addScope('email');
        provider.setCustomParameters({'prompt': 'select_account'});

        userCredential = await _auth.signInWithPopup(provider);
        final user = userCredential.user;
        if (user == null) {
          throw Exception('Sign in failed');
        }

        googleEmail = user.email;
        googleDisplayName = user.displayName;
        googlePhotoUrl = user.photoURL;
      } else {
        // Mobile / desktop flow: use google_sign_in package for native auth.
        final GoogleSignIn googleSignIn = GoogleSignIn(
          clientId: kIsWeb && _resolvedGoogleWebClientId.isNotEmpty
              ? _resolvedGoogleWebClientId
              : null,
          scopes: ['email'],
        );

        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
        if (googleUser == null) {
          throw Exception('Sign in was canceled');
        }

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        userCredential = await _auth.signInWithCredential(credential);
        final user = userCredential.user;
        if (user == null) {
          throw Exception('Sign in failed');
        }

        googleEmail = googleUser.email;
        googleDisplayName = googleUser.displayName;
        googlePhotoUrl = googleUser.photoUrl;
      }

      final user = userCredential.user;
      if (user == null) {
        throw Exception('Sign in failed');
      }

      // Update Firebase user profile with Google info if not already set
      if (googleDisplayName != null && user.displayName != googleDisplayName) {
        await user.updateDisplayName(googleDisplayName);
      }
      if (googlePhotoUrl != null && user.photoURL != googlePhotoUrl) {
        await user.updatePhotoURL(googlePhotoUrl);
      }

      await user.reload();
      final reloadedUser = _auth.currentUser;

      final doc = await _firestore.collection('users').doc(user.uid).get();
      final updateData = <String, dynamic>{
        'email': googleEmail?.isNotEmpty == true
            ? googleEmail
            : reloadedUser?.email ?? user.email,
        'displayName': googleDisplayName ??
            reloadedUser?.displayName ??
            user.displayName,
        'avatarUrl': googlePhotoUrl ?? reloadedUser?.photoURL ?? user.photoURL,
      };

      if (doc.exists && doc.data()?['createdAt'] != null) {
        updateData['createdAt'] = doc.data()!['createdAt'];
      } else {
        updateData['createdAt'] = Timestamp.fromDate(DateTime.now());
      }
      if (doc.exists && doc.data()?['onboardingData'] != null) {
        updateData['onboardingData'] = doc.data()!['onboardingData'];
      }

      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(updateData, SetOptions(merge: true));

      return UserModel(
        id: user.uid,
        email: googleEmail?.isNotEmpty == true
            ? googleEmail!
            : (reloadedUser?.email ?? user.email ?? ''),
        displayName: googleDisplayName ??
            reloadedUser?.displayName ??
            user.displayName,
        avatarUrl: googlePhotoUrl ?? reloadedUser?.photoURL ?? user.photoURL,
        createdAt: doc.exists
            ? (doc.data()?['createdAt'] as Timestamp?)?.toDate() ??
                DateTime.now()
            : DateTime.now(),
        onboardingData: doc.exists && doc.data()?['onboardingData'] != null
            ? OnboardingData.fromMap(
                doc.data()!['onboardingData'] as Map<String, dynamic>)
            : null,
      );
    } catch (e) {
      if (e.toString().contains('client_id') ||
          e.toString().contains('not configured') ||
          e.toString().contains('CLIENT_ID')) {
        throw Exception(
            'Google Sign-In is not configured. Please verify Firebase Google provider and web client settings.');
      }
      throw Exception('Google sign in failed: ${e.toString()}');
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
