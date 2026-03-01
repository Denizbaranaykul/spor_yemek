import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/user_profile.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  UserProfile? _userProfile;
  bool _isLoading = false;

  User? get currentUser => _authService.currentUser;
  UserProfile? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => currentUser != null;
  Stream<User?> get authStateChanges => _authService.authStateChanges;

  AuthProvider() {
    _authService.authStateChanges.listen((user) {
      if (user != null) {
        _loadUserProfile();
      } else {
        _userProfile = null;
        notifyListeners();
      }
    });
  }

  Future<void> _loadUserProfile() async {
    _userProfile = await _authService.getUserProfile();
    notifyListeners();
  }

  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.signInWithEmailAndPassword(email, password);
      await _loadUserProfile();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<bool> register(
    String email,
    String password,
    String displayName,
  ) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.registerWithEmailAndPassword(
        email,
        password,
        displayName,
      );
      await _loadUserProfile();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _userProfile = null;
    notifyListeners();
  }

  Future<void> updateProfile({
    String? displayName,
    double? weight,
    double? height,
    double? waist,
    double? belly,
    double? arm,
    double? leg,
  }) async {
    await _authService.updateUserProfile(
      displayName: displayName,
      weight: weight,
      height: height,
      waist: waist,
      belly: belly,
      arm: arm,
      leg: leg,
    );
    await _loadUserProfile();
  }
}

