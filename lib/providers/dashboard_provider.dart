// lib/providers/dashboard_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/dashboard_services.dart';
import 'auth_provider.dart';

// ============================================================================
// DASHBOARD STATE
// ============================================================================
class DashboardState {
  final Map<String, dynamic> statistics;
  final List<Map<String, dynamic>> recentActivities;
  final bool isLoading;
  final String? errorMessage;

  const DashboardState({
    this.statistics = const {},
    this.recentActivities = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  DashboardState copyWith({
    Map<String, dynamic>? statistics,
    List<Map<String, dynamic>>? recentActivities,
    bool? isLoading,
    String? errorMessage,
  }) {
    return DashboardState(
      statistics: statistics ?? this.statistics,
      recentActivities: recentActivities ?? this.recentActivities,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  DashboardState setLoading(bool loading) {
    return DashboardState(
      statistics: statistics,
      recentActivities: recentActivities,
      isLoading: loading,
      errorMessage: errorMessage,
    );
  }

  DashboardState clearError() {
    return DashboardState(
      statistics: statistics,
      recentActivities: recentActivities,
      isLoading: isLoading,
      errorMessage: null,
    );
  }
}

// ============================================================================
// DASHBOARD NOTIFIER
// ============================================================================
class DashboardNotifier extends Notifier<DashboardState> {
  late final DashboardService _dashboardService;
  bool _hasInitialized = false;

  @override
  DashboardState build() {
    _dashboardService = DashboardService();
    // DO NOT auto-load here - let screens call ensureInitialized()
    return const DashboardState();
  }

  // Call this from screens to ensure data is loaded
  void ensureInitialized() {
    if (!_hasInitialized && !state.isLoading) {
      loadStatistics();
    }
  }

  Future<void> loadStatistics() async {
    try {
      state = state.setLoading(true).clearError();

      final user = ref.read(authProvider).user;
      if (user == null) {
        throw Exception('User tidak ditemukan');
      }

      Map<String, dynamic> stats;
      final roleName = user.role?.role?.toLowerCase();

      if (roleName == 'admin') {
        stats = await _dashboardService.getAdminStats();
      } else if (roleName == 'petugas') {
        stats = await _dashboardService.getPetugasStats();
      } else {
        stats = await _dashboardService.getPeminjamStats(user.userId);
      }

      // Load recent activities
      final activities = await _dashboardService.getRecentActivities(limit: 10);

      state = DashboardState(
        statistics: stats,
        recentActivities: activities,
        isLoading: false,
      );
      _hasInitialized = true;
    } catch (e) {
      state = DashboardState(
        statistics: state.statistics,
        recentActivities: state.recentActivities,
        isLoading: false,
        errorMessage: 'Gagal memuat statistik: ${e.toString()}',
      );
    }
  }

  Future<void> refresh() async {
    await loadStatistics();
  }

  void clearError() {
    state = state.clearError();
  }
}

// ============================================================================
// PROVIDER
// ============================================================================
final dashboardProvider = NotifierProvider<DashboardNotifier, DashboardState>(
  () {
    return DashboardNotifier();
  },
);

// ============================================================================
// HELPER PROVIDERS
// ============================================================================

// Get specific statistic
final statisticProvider = Provider.family<dynamic, String>((ref, key) {
  final stats = ref.watch(dashboardProvider).statistics;
  return stats[key];
});

// Check if dashboard is loading
final isDashboardLoadingProvider = Provider<bool>((ref) {
  return ref.watch(dashboardProvider).isLoading;
});
