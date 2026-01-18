// lib/providers/auth_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/auth_services.dart';

// ============================================================================
// AUTH STATE
// ============================================================================
class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? errorMessage;

  const AuthState({this.user, this.isLoading = false, this.errorMessage});

  bool get isAuthenticated => user != null;

  // Helper methods langsung check string
  bool get isAdmin => user?.role?.role?.toLowerCase() == 'admin';
  bool get isPetugas => user?.role?.role?.toLowerCase() == 'petugas';
  bool get isPeminjam => user?.role?.role?.toLowerCase() == 'peminjam';

  AuthState copyWith({UserModel? user, bool? isLoading, String? errorMessage}) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  AuthState clearError() {
    return AuthState(user: user, isLoading: isLoading, errorMessage: null);
  }

  AuthState setLoading(bool loading) {
    return AuthState(
      user: user,
      isLoading: loading,
      errorMessage: errorMessage,
    );
  }
}

// ============================================================================
// AUTH NOTIFIER
// ============================================================================
class AuthNotifier extends Notifier<AuthState> with ChangeNotifier {
  late final AuthService _authService;

  @override
  AuthState build() {
    _authService = AuthService();
    // Check session saat app start
    _checkSession();
    return const AuthState(isLoading: true);
  }
  
  // Override state setter to notify listeners for GoRouter
  @override
  set state(AuthState value) {
    super.state = value;
    notifyListeners(); // Notify GoRouter to re-evaluate redirects
  }

  // Check existing session
  Future<void> _checkSession() async {
    try {
      state = state.setLoading(true);
      final user = await _authService.getCurrentUser();

      if (user != null) {
        state = AuthState(user: user, isLoading: false);
      } else {
        state = const AuthState(isLoading: false);
      }
    } catch (e) {
      // Silent fail untuk check session
      state = const AuthState(isLoading: false);
    }
  }

  // Login
  Future<bool> login(String username, String password) async {
    try {
      state = state.setLoading(true).clearError();

      final user = await _authService.login(username, password);

      if (user == null) {
        state = const AuthState(
          isLoading: false,
          errorMessage: 'Username atau password salah',
        );
        return false;
      }

      state = AuthState(user: user, isLoading: false);
      return true;
    } catch (e) {
      state = AuthState(
        isLoading: false,
        errorMessage: 'Login gagal: ${e.toString()}',
      );
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      state = state.setLoading(true);
      await _authService.logout();
      state = const AuthState(isLoading: false);
    } catch (e) {
      state = AuthState(
        user: state.user,
        isLoading: false,
        errorMessage: 'Logout gagal: ${e.toString()}',
      );
    }
  }

  // Refresh current user data
  Future<void> refreshUser() async {
    try {
      final user = await _authService.getCurrentUser();
      state = AuthState(user: user, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Gagal refresh user: ${e.toString()}',
      );
    }
  }

  // Clear error message
  void clearError() {
    state = state.clearError();
  }

  // Check if user has permission
  bool hasPermission(String permission) {
    if (state.user == null) return false;

    switch (permission.toLowerCase()) {
      case 'manage_users':
      case 'manage_alat':
      case 'manage_kategori':
      case 'view_logs':
        return state.isAdmin;

      case 'approve_peminjaman':
      case 'process_pengembalian':
      case 'view_all_peminjaman':
        return state.isAdmin || state.isPetugas;

      case 'create_peminjaman':
      case 'view_my_peminjaman':
        return state.isPeminjam || state.isPetugas || state.isAdmin;

      default:
        return false;
    }
  }
}

// ============================================================================
// PROVIDER
// ============================================================================
final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});

// ============================================================================
// HELPER PROVIDERS (untuk akses cepat)
// ============================================================================

// Current user provider
final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authProvider).user;
});

// Is authenticated provider
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});

// User role providers
final isAdminProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAdmin;
});

final isPetugasProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isPetugas;
});

final isPeminjamProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isPeminjam;
});

// User ID provider (untuk parameter di provider lain)
final currentUserIdProvider = Provider<int?>((ref) {
  return ref.watch(authProvider).user?.userId;
});
