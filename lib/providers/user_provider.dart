// lib/providers/user_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/user_services.dart';

// ============================================================================
// USER STATE
// ============================================================================
class UserState {
  final List<UserModel> users;
  final bool isLoading;
  final String? errorMessage;
  final String searchQuery;

  const UserState({
    this.users = const [],
    this.isLoading = false,
    this.errorMessage,
    this.searchQuery = '',
  });

  UserState copyWith({
    List<UserModel>? users,
    bool? isLoading,
    String? errorMessage,
    String? searchQuery,
  }) {
    return UserState(
      users: users ?? this.users,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  UserState clearError() {
    return UserState(
      users: users,
      isLoading: isLoading,
      errorMessage: null,
      searchQuery: searchQuery,
    );
  }

  UserState setLoading(bool loading) {
    return UserState(
      users: users,
      isLoading: loading,
      errorMessage: errorMessage,
      searchQuery: searchQuery,
    );
  }
}

// ============================================================================
// USER NOTIFIER
// ============================================================================
class UserNotifier extends Notifier<UserState> {
  late final UserService _userService;

  @override
  UserState build() {
    _userService = UserService();
    // Auto-load users saat provider pertama kali dibuat
    loadUsers();
    return const UserState();
  }

  // Load all users with optional search
  Future<void> loadUsers({String? query}) async {
    try {
      state = state.setLoading(true).clearError();

      final users = await _userService.getAllUsers(query: query);

      state = UserState(
        users: users,
        isLoading: false,
        searchQuery: query ?? '',
      );
    } catch (e) {
      state = UserState(
        users: state.users,
        isLoading: false,
        errorMessage: 'Gagal memuat data user: ${e.toString()}',
        searchQuery: state.searchQuery,
      );
    }
  }

  // Search users
  Future<void> searchUsers(String query) async {
    await loadUsers(query: query.isEmpty ? null : query);
  }

  // Create user
  Future<bool> createUser(UserModel user) async {
    try {
      state = state.setLoading(true).clearError();

      await _userService.createUser(user);
      await loadUsers(
        query: state.searchQuery.isEmpty ? null : state.searchQuery,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal menambah user: ${e.toString()}',
      );
      return false;
    }
  }

  // Update user
  Future<bool> updateUser(UserModel user) async {
    try {
      state = state.setLoading(true).clearError();

      await _userService.updateUser(user);
      await loadUsers(
        query: state.searchQuery.isEmpty ? null : state.searchQuery,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal mengubah user: ${e.toString()}',
      );
      return false;
    }
  }

  // Delete user
  Future<bool> deleteUser(int userId) async {
    try {
      state = state.setLoading(true).clearError();

      await _userService.deleteUser(userId);
      await loadUsers(
        query: state.searchQuery.isEmpty ? null : state.searchQuery,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal menghapus user: ${e.toString()}',
      );
      return false;
    }
  }

  // Validasi username unique sebelum create
  Future<bool> isUsernameAvailable(
    String username, {
    int? excludeUserId,
  }) async {
    try {
      final users = state.users
          .where(
            (u) =>
                u.username.toLowerCase() == username.toLowerCase() &&
                (excludeUserId == null || u.userId != excludeUserId),
          )
          .toList();

      return users.isEmpty;
    } catch (e) {
      return false;
    }
  }

  // Get user by ID (cached dari state)
  UserModel? getUserById(int userId) {
    try {
      return state.users.firstWhere((u) => u.userId == userId);
    } catch (e) {
      return null;
    }
  }

  // Refresh data
  Future<void> refresh() async {
    await loadUsers(
      query: state.searchQuery.isEmpty ? null : state.searchQuery,
    );
  }

  // Clear error
  void clearError() {
    state = state.clearError();
  }

  // Clear search
  void clearSearch() {
    loadUsers();
  }
}

// ============================================================================
// PROVIDER
// ============================================================================
final userProvider = NotifierProvider<UserNotifier, UserState>(() {
  return UserNotifier();
});

// ============================================================================
// HELPER PROVIDERS
// ============================================================================

// Filtered users by role
final usersByRoleProvider = Provider.family<List<UserModel>, int>((
  ref,
  roleId,
) {
  final users = ref.watch(userProvider).users;
  return users.where((user) => user.roleId == roleId).toList();
});

// User count provider
final userCountProvider = Provider<int>((ref) {
  return ref.watch(userProvider).users.length;
});

final userByIdProvider = Provider.family<UserModel?, int>((ref, userId) {
  final users = ref.watch(userProvider).users;
  if (users.isEmpty) return null;

  try {
    return users.firstWhere((user) => user.userId == userId);
  } catch (e) {
    return null;
  }
});

// Active users only (bisa dikembangkan jika ada field is_active)
final activeUsersProvider = Provider<List<UserModel>>((ref) {
  return ref.watch(userProvider).users;
});

// Users by role name
final usersByRoleNameProvider = Provider.family<List<UserModel>, String>((
  ref,
  roleName,
) {
  final users = ref.watch(userProvider).users;
  return users
      .where((user) => user.role?.role?.toLowerCase() == roleName.toLowerCase())
      .toList();
});
