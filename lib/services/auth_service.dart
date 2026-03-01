import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<UserCredential?> registerWithEmailAndPassword(
    String email,
    String password,
    String displayName,
  ) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name
      await credential.user?.updateDisplayName(displayName);

      // Create user profile in Firestore
      if (credential.user != null) {
        await _firestore.collection('users').doc(credential.user!.uid).set({
          'email': email,
          'display_name': displayName,
          'created_at': FieldValue.serverTimestamp(),
        });
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<UserProfile?> getUserProfile() async {
    final user = currentUser;
    if (user == null) return null;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        return UserProfile.fromMap(user.uid, doc.data()!);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> updateUserProfile({
    String? displayName,
    double? weight,
    double? height,
    double? waist,
    double? belly,
    double? arm,
    double? leg,
  }) async {
    final user = currentUser;
    if (user == null) return;

    final Map<String, dynamic> updates = {};
    if (displayName != null) updates['display_name'] = displayName;
    if (weight != null) updates['weight'] = weight;
    if (height != null) updates['height'] = height;
    if (waist != null) updates['waist'] = waist;
    if (belly != null) updates['belly'] = belly;
    if (arm != null) updates['arm'] = arm;
    if (leg != null) updates['leg'] = leg;

    if (updates.isNotEmpty) {
      await _firestore.collection('users').doc(user.uid).update(updates);
    }
  }

  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'Şifre çok zayıf.';
      case 'email-already-in-use':
        return 'Bu e-posta adresi zaten kullanılıyor.';
      case 'user-not-found':
        return 'Kullanıcı bulunamadı.';
      case 'wrong-password':
        return 'Yanlış şifre.';
      case 'invalid-email':
        return 'Geçersiz e-posta adresi.';
      default:
        return 'Bir hata oluştu: ${e.message}';
    }
  }
}

