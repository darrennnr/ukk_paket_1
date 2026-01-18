// lib/providers/role_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/role_model.dart';
import '../main.dart';

// ============================================================================
// ROLE STATE
// ============================================================================
class RoleState {
  final List<RoleModel> roles;
  final bool isLoading;
  final String? errorMessage;

  const RoleState({
    this.roles = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  RoleState copyWith({
    List<RoleModel>? roles,
    bool? isLoading,
    String? errorMessage,
  }) {
    return RoleState(
      roles: roles ?? this.roles,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  RoleState clearError() {
    return RoleState(roles: roles, isLoading: isLoading, errorMessage: null);
  }

  RoleState setLoading(bool loading) {
    return RoleState(
      roles: roles,
      isLoading: loading,
      errorMessage: errorMessage,
    );
  }
}

// ============================================================================
// ROLE NOTIFIER
// ============================================================================
class RoleNotifier extends Notifier<RoleState> {
  @override
  RoleState build() {
    loadRoles();
    return const RoleState();
  }

  Future<void> loadRoles() async {
    try {
      state = state.setLoading(true).clearError();

      final response = await supabase.from('role').select().order('id');

      final roles = (response as List)
          .map((e) => RoleModel.fromJson(e))
          .toList();

      state = RoleState(roles: roles, isLoading: false);
    } catch (e) {
      state = RoleState(
        roles: state.roles,
        isLoading: false,
        errorMessage: 'Gagal memuat data role: ${e.toString()}',
      );
    }
  }

  Future<void> refresh() async {
    await loadRoles();
  }

  void clearError() {
    state = state.clearError();
  }
}

// ============================================================================
// PROVIDER
// ============================================================================
final roleProvider = NotifierProvider<RoleNotifier, RoleState>(() {
  return RoleNotifier();
});

// ============================================================================
// HELPER PROVIDERS
// ============================================================================

// Role list provider (untuk dropdown)
final roleListProvider = Provider<List<RoleModel>>((ref) {
  return ref.watch(roleProvider).roles;
});

// Get role by ID
final roleByIdProvider = Provider.family<RoleModel?, int>((ref, roleId) {
  final roles = ref.watch(roleProvider).roles;
  try {
    return roles.firstWhere((r) => r.id == roleId);
  } catch (e) {
    return null;
  }
});

// Role constants
final adminRoleProvider = Provider<RoleModel?>((ref) {
  final roles = ref.watch(roleProvider).roles;
  try {
    return roles.firstWhere((r) => r.isAdmin());
  } catch (e) {
    return null;
  }
});

final petugasRoleProvider = Provider<RoleModel?>((ref) {
  final roles = ref.watch(roleProvider).roles;
  try {
    return roles.firstWhere((r) => r.isPetugas());
  } catch (e) {
    return null;
  }
});

final peminjamRoleProvider = Provider<RoleModel?>((ref) {
  final roles = ref.watch(roleProvider).roles;
  try {
    return roles.firstWhere((r) => r.isPeminjam());
  } catch (e) {
    return null;
  }
});
