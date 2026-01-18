// lib/providers/pengembalian_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/pengembalian_model.dart';
import '../services/pengembalian_services.dart';

// ============================================================================
// PENGEMBALIAN STATE
// ============================================================================
class PengembalianState {
  final List<PengembalianModel> pengembalians;
  final bool isLoading;
  final String? errorMessage;

  const PengembalianState({
    this.pengembalians = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  PengembalianState copyWith({
    List<PengembalianModel>? pengembalians,
    bool? isLoading,
    String? errorMessage,
  }) {
    return PengembalianState(
      pengembalians: pengembalians ?? this.pengembalians,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  PengembalianState clearError() {
    return PengembalianState(
      pengembalians: pengembalians,
      isLoading: isLoading,
      errorMessage: null,
    );
  }

  PengembalianState setLoading(bool loading) {
    return PengembalianState(
      pengembalians: pengembalians,
      isLoading: loading,
      errorMessage: errorMessage,
    );
  }
}

// ============================================================================
// PENGEMBALIAN NOTIFIER (All pengembalian)
// ============================================================================
class PengembalianNotifier extends Notifier<PengembalianState> {
  late final PengembalianService _pengembalianService;

  @override
  PengembalianState build() {
    _pengembalianService = PengembalianService();
    loadAllPengembalian();
    return const PengembalianState();
  }

  Future<void> loadAllPengembalian() async {
    try {
      state = state.setLoading(true).clearError();

      final pengembalians = await _pengembalianService.getAllPengembalian();

      state = PengembalianState(pengembalians: pengembalians, isLoading: false);
    } catch (e) {
      state = PengembalianState(
        pengembalians: state.pengembalians,
        isLoading: false,
        errorMessage: 'Gagal memuat data pengembalian: ${e.toString()}',
      );
    }
  }

  // Proses pengembalian
  Future<bool> prosesPengembalian({
    required int peminjamanId,
    required int petugasId,
    required String kondisiAlat,
    String? catatan,
  }) async {
    try {
      state = state.setLoading(true).clearError();

      await _pengembalianService.prosesPengembalian(
        peminjamanId: peminjamanId,
        petugasId: petugasId,
        kondisiAlat: kondisiAlat,
        catatan: catatan,
      );

      await loadAllPengembalian();

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal memproses pengembalian: ${e.toString()}',
      );
      return false;
    }
  }

  // Get pengembalian by peminjaman ID
  Future<PengembalianModel?> getPengembalianByPeminjamanId(
    int peminjamanId,
  ) async {
    try {
      return await _pengembalianService.getPengembalianByPeminjamanId(
        peminjamanId,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Gagal memuat detail pengembalian: ${e.toString()}',
      );
      return null;
    }
  }

  // Get statistik pengembalian
  Map<String, dynamic> getStatistics() {
    final pengembalians = state.pengembalians;

    final totalPengembalian = pengembalians.length;
    final totalTerlambat = pengembalians.where((p) => p.isLate).length;
    final totalDenda = pengembalians.fold<int>(
      0,
      (sum, p) => sum + (p.totalPembayaran ?? 0),
    );
    final totalBelumLunas = pengembalians.where((p) => !p.isPaid).length;
    final totalLunas = pengembalians.where((p) => p.isPaid).length;

    return {
      'total_pengembalian': totalPengembalian,
      'total_terlambat': totalTerlambat,
      'total_denda': totalDenda,
      'total_belum_lunas': totalBelumLunas,
      'total_lunas': totalLunas,
      'persentase_terlambat': totalPengembalian > 0
          ? (totalTerlambat / totalPengembalian * 100).toStringAsFixed(1)
          : '0.0',
    };
  }

  // Update status pembayaran
  Future<bool> updateStatusPembayaran(
    int pengembalianId,
    String status,
    int petugasId,
  ) async {
    try {
      state = state.setLoading(true).clearError();

      await _pengembalianService.updateStatusPembayaran(
        pengembalianId,
        status,
        petugasId,
      );

      await loadAllPengembalian();

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal update status pembayaran: ${e.toString()}',
      );
      return false;
    }
  }

  Future<void> refresh() async {
    await loadAllPengembalian();
  }

  void clearError() {
    state = state.clearError();
  }
}

// ============================================================================
// PENGEMBALIAN BELUM LUNAS NOTIFIER
// ============================================================================
class PengembalianBelumLunasNotifier extends Notifier<PengembalianState> {
  late final PengembalianService _pengembalianService;

  @override
  PengembalianState build() {
    _pengembalianService = PengembalianService();
    loadPengembalianBelumLunas();
    return const PengembalianState();
  }

  Future<void> loadPengembalianBelumLunas() async {
    try {
      state = state.setLoading(true).clearError();

      final pengembalians = await _pengembalianService
          .getPengembalianBelumLunas();

      state = PengembalianState(pengembalians: pengembalians, isLoading: false);
    } catch (e) {
      state = PengembalianState(
        pengembalians: state.pengembalians,
        isLoading: false,
        errorMessage: 'Gagal memuat denda belum lunas: ${e.toString()}',
      );
    }
  }

  // Update status pembayaran
  Future<bool> lunaskanDenda(int pengembalianId, int petugasId) async {
    try {
      state = state.setLoading(true).clearError();

      await _pengembalianService.updateStatusPembayaran(
        pengembalianId,
        'Lunas',
        petugasId,
      );

      await loadPengembalianBelumLunas();

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal melunaskan denda: ${e.toString()}',
      );
      return false;
    }
  }

  Future<void> refresh() async {
    await loadPengembalianBelumLunas();
  }

  void clearError() {
    state = state.clearError();
  }
}

// ============================================================================
// PROVIDERS
// ============================================================================

// All pengembalian
final pengembalianProvider =
    NotifierProvider<PengembalianNotifier, PengembalianState>(() {
      return PengembalianNotifier();
    });

// Pengembalian belum lunas
final pengembalianBelumLunasProvider =
    NotifierProvider<PengembalianBelumLunasNotifier, PengembalianState>(() {
      return PengembalianBelumLunasNotifier();
    });

// ============================================================================
// HELPER PROVIDERS
// ============================================================================

// Count providers
final pengembalianCountProvider = Provider<int>((ref) {
  return ref.watch(pengembalianProvider).pengembalians.length;
});

final pengembalianBelumLunasCountProvider = Provider<int>((ref) {
  return ref.watch(pengembalianBelumLunasProvider).pengembalians.length;
});

// Total denda belum lunas
final totalDendaBelumLunasProvider = Provider<int>((ref) {
  final pengembalians = ref.watch(pengembalianBelumLunasProvider).pengembalians;
  return pengembalians.fold<int>(0, (sum, p) => sum + (p.totalPembayaran ?? 0));
});

// Pengembalian terlambat (ada keterlambatan > 0)
final pengembalianTerlambatProvider = Provider<List<PengembalianModel>>((ref) {
  final pengembalians = ref.watch(pengembalianProvider).pengembalians;
  return pengembalians.where((p) => p.isLate).toList();
});

// Pengembalian hari ini
final pengembalianHariIniProvider = Provider<List<PengembalianModel>>((ref) {
  final pengembalians = ref.watch(pengembalianProvider).pengembalians;
  final today = DateTime.now();
  final startOfDay = DateTime(today.year, today.month, today.day);
  final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

  return pengembalians.where((p) {
    if (p.tanggalKembali == null) return false;
    return p.tanggalKembali!.isAfter(startOfDay) &&
        p.tanggalKembali!.isBefore(endOfDay);
  }).toList();
});

// Get pengembalian by ID
final pengembalianByIdProvider = Provider.family<PengembalianModel?, int>((
  ref,
  pengembalianId,
) {
  final pengembalians = ref.watch(pengembalianProvider).pengembalians;
  try {
    return pengembalians.firstWhere((p) => p.pengembalianId == pengembalianId);
  } catch (e) {
    return null;
  }
});

// Pengembalian by date range
final pengembalianByDateRangeProvider =
    Provider.family<List<PengembalianModel>, Map<String, DateTime>>((
      ref,
      dateRange,
    ) {
      final pengembalians = ref.watch(pengembalianProvider).pengembalians;
      final start = dateRange['start']!;
      final end = dateRange['end']!;

      return pengembalians.where((p) {
        if (p.tanggalKembali == null) return false;
        return p.tanggalKembali!.isAfter(start) &&
            p.tanggalKembali!.isBefore(end);
      }).toList();
    });

// Pengembalian dengan kondisi rusak
final pengembalianRusakProvider = Provider<List<PengembalianModel>>((ref) {
  final pengembalians = ref.watch(pengembalianProvider).pengembalians;
  return pengembalians.where((p) => !p.isGoodCondition).toList();
});

// Total pendapatan dari denda
final totalDendaIncomeProvider = Provider<int>((ref) {
  final pengembalians = ref.watch(pengembalianProvider).pengembalians;
  return pengembalians
      .where((p) => p.isPaid)
      .fold<int>(0, (sum, p) => sum + (p.totalPembayaran ?? 0));
});

// Statistik pengembalian
final pengembalianStatisticsProvider = Provider<Map<String, dynamic>>((ref) {
  final notifier = ref.read(pengembalianProvider.notifier);
  return notifier.getStatistics();
});
