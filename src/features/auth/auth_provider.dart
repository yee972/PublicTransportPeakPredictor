import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/repositories/account_repository.dart';
import '../../models/user_profile.dart';

enum AuthStatus { checking, signedOut, signedIn }

class AuthProvider extends ChangeNotifier {
  final SupabaseClient _client;
  final AccountRepository _accounts;

  AuthStatus _status = AuthStatus.checking;
  UserProfile? _profile;
  String? _errorMessage;
  bool _busy = false;

  AuthProvider(this._client, this._accounts) {
    _status = _client.auth.currentSession == null
        ? AuthStatus.signedOut
        : AuthStatus.signedIn;
    if (_status == AuthStatus.signedIn) {
      _loadProfile();
    }
    _client.auth.onAuthStateChange.listen(_handleAuthChange);
  }

  AuthStatus get status => _status;
  UserProfile? get profile => _profile;
  String? get errorMessage => _errorMessage;
  bool get busy => _busy;
  String? get userId => _client.auth.currentUser?.id;
  String get email => _client.auth.currentUser?.email ?? '';

  String get displayName {
    final name = _profile?.fullName ?? '';
    if (name.trim().isNotEmpty) return name;
    final address = email;
    if (address.contains('@')) return address.split('@').first;
    return 'Commuter';
  }

  void _handleAuthChange(AuthState state) {
    final signedIn = state.session != null;
    _status = signedIn ? AuthStatus.signedIn : AuthStatus.signedOut;
    if (signedIn) {
      _loadProfile();
    } else {
      _profile = null;
    }
    notifyListeners();
  }

  Future<bool> signIn({required String email, required String password}) async {
    return _run(() async {
      await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      await _loadProfile();
    });
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    return _run(() async {
      final response = await _client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {'full_name': fullName.trim()},
      );
      if (response.session == null && response.user != null) {
        throw const AuthException(
          'Account created. Confirm your email, then sign in.',
        );
      }
      await _loadProfile();
    });
  }

  Future<void> signOut() async {
    await _accounts.clearLocalState();
    await _client.auth.signOut();
    _profile = null;
    _status = AuthStatus.signedOut;
    notifyListeners();
  }

  Future<void> updateProfile({
    String? fullName,
    String? homeStationId,
    bool? peakAlertsEnabled,
  }) async {
    final current = _profile;
    final id = userId;
    if (id == null) return;

    final updated = (current ??
            UserProfile(id: id, fullName: fullName ?? displayName))
        .copyWith(
      fullName: fullName,
      homeStationId: homeStationId,
      peakAlertsEnabled: peakAlertsEnabled,
    );

    try {
      _profile = await _accounts.saveProfile(updated);
      _errorMessage = null;
    } catch (error) {
      _errorMessage = error.toString();
    }
    notifyListeners();
  }

  Future<void> _loadProfile() async {
    final id = userId;
    if (id == null) return;
    try {
      _profile = await _accounts.loadProfile(id);
    } catch (_) {
      _profile = null;
    }
    notifyListeners();
  }

  Future<bool> _run(Future<void> Function() action) async {
    _busy = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await action();
      _busy = false;
      notifyListeners();
      return true;
    } on AuthException catch (error) {
      _errorMessage = _friendly(error.message);
    } catch (_) {
      _errorMessage = 'Something went wrong. Check your connection and try again.';
    }
    _busy = false;
    notifyListeners();
    return false;
  }

  String _friendly(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('invalid login')) {
      return 'That email and password combination is not recognised.';
    }
    if (lower.contains('already registered') || lower.contains('already been')) {
      return 'That email is already registered. Try signing in instead.';
    }
    if (lower.contains('password')) {
      return 'Password must be at least 8 characters.';
    }
    return raw;
  }

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }
}
