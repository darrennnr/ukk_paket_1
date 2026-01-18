// lib/providers/log_aktivitas_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/log_aktivitas_model.dart';
import '../services/log_services.dart';

// ============================================================================
// LOG AKTIVITAS STATE
// ============================================================================
class LogAktivitasState {
  final List<LogAktivitasModel> logs;
  final bool isLoading;
  final String? errorMessage;
  final String? filterAktivitas;
  final int? filterUserId;

  const LogAktivitasState({
    this.logs = const [],
    this.isLoading = false,
    this.errorMessage,
    this.filterAktivitas,
    this.filterUserId,
  });

  LogAktivitasState copyWith({
    List<LogAktivitasModel>? logs,
    bool? isLoading,
    String? errorMessage,
    String? filterAktivitas,
    int? filterUserId,
  }) {
    return LogAktivitasState(
      logs: logs ?? this.logs,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      filterAktivitas: filterAktivitas ?? this.filterAktivitas,
      filterUserId: filterUserId ?? this.filterUserId,
    );
  }

  LogAktivitasState clearError() {
    return LogAktivitasState(
      logs: logs,
      isLoading: isLoading,
      errorMessage: null,
      filterAktivitas: filterAktivitas,
      filterUserId: filterUserId,
    );
  }

  LogAktivitasState setLoading(bool loading) {
    return LogAktivitasState(
      logs: logs,
      isLoading: loading,
      errorMessage: errorMessage,
      filterAktivitas: filterAktivitas,
      filterUserId: filterUserId,
    );
  }
}

// ============================================================================
// LOG AKTIVITAS NOTIFIER
// ============================================================================
class LogAktivitasNotifier extends Notifier<LogAktivitasState> {
  late final LogService _logService;

  @override
  LogAktivitasState build() {
    _logService = LogService();
    loadLogs();
    return const LogAktivitasState();
  }

  Future<void> loadLogs() async {
    try {
      state = state.setLoading(true).clearError();

      final logs = await _logService.getAllLogs();

      state = LogAktivitasState(logs: logs, isLoading: false);
    } catch (e) {
      state = LogAktivitasState(
        logs: state.logs,
        isLoading: false,
        errorMessage: 'Gagal memuat log aktivitas: ${e.toString()}',
      );
    }
  }

  // Filter by aktivitas
  void filterByAktivitas(String? aktivitas) {
    state = state.copyWith(filterAktivitas: aktivitas);
  }

  // Filter by user
  void filterByUser(int? userId) {
    state = state.copyWith(filterUserId: userId);
  }

  // Clear filters
  void clearFilters() {
    state = LogAktivitasState(logs: state.logs, isLoading: state.isLoading);
  }

  Future<void> refresh() async {
    await loadLogs();
  }

  void clearError() {
    state = state.clearError();
  }
}

// ============================================================================
// PROVIDER
// ============================================================================
final logAktivitasProvider =
    NotifierProvider<LogAktivitasNotifier, LogAktivitasState>(() {
      return LogAktivitasNotifier();
    });

// ============================================================================
// HELPER PROVIDERS
// ============================================================================

// Filtered logs
final filteredLogsProvider = Provider<List<LogAktivitasModel>>((ref) {
  final state = ref.watch(logAktivitasProvider);
  var logs = state.logs;

  // Filter by aktivitas
  if (state.filterAktivitas != null && state.filterAktivitas!.isNotEmpty) {
    logs = logs
        .where(
          (log) => log.aktivitas.toLowerCase().contains(
            state.filterAktivitas!.toLowerCase(),
          ),
        )
        .toList();
  }

  // Filter by user
  if (state.filterUserId != null) {
    logs = logs.where((log) => log.userId == state.filterUserId).toList();
  }

  return logs;
});

// Log count by type
final logCountByTypeProvider = Provider<Map<String, int>>((ref) {
  final logs = ref.watch(logAktivitasProvider).logs;

  return {
    'login': logs.where((l) => l.isLogin).length,
    'logout': logs.where((l) => l.isLogout).length,
    'create': logs.where((l) => l.isCreate).length,
    'update': logs.where((l) => l.isUpdate).length,
    'delete': logs.where((l) => l.isDelete).length,
    'approval': logs.where((l) => l.isApproval).length,
  };
});

// Recent logs (last 10)
final recentLogsProvider = Provider<List<LogAktivitasModel>>((ref) {
  final logs = ref.watch(logAktivitasProvider).logs;
  return logs.take(10).toList();
});

// Today's logs
final todayLogsProvider = Provider<List<LogAktivitasModel>>((ref) {
  final logs = ref.watch(logAktivitasProvider).logs;
  final today = DateTime.now();
  final startOfDay = DateTime(today.year, today.month, today.day);
  final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

  return logs.where((log) {
    if (log.createdAt == null) return false;
    return log.createdAt!.isAfter(startOfDay) &&
        log.createdAt!.isBefore(endOfDay);
  }).toList();
});
