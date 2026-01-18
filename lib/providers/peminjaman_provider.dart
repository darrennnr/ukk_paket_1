// lib/providers/peminjaman_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/peminjaman_model.dart';
import '../services/peminjaman_services.dart';
import 'auth_provider.dart';

// ============================================================================
// PEMINJAMAN STATE
// ============================================================================
class PeminjamanState {
  final List<PeminjamanModel> peminjamans;
  final bool isLoading;
  final String? errorMessage;

  const PeminjamanState({
    this.peminjamans = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  PeminjamanState copyWith({
    List<PeminjamanModel>? peminjamans,
    bool? isLoading,
    String? errorMessage,
  }) {
    return PeminjamanState(
      peminjamans: peminjamans ?? this.peminjamans,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  PeminjamanState clearError() {
    return PeminjamanState(
      peminjamans: peminjamans,
      isLoading: isLoading,
      errorMessage: null,
    );
  }

  PeminjamanState setLoading(bool loading) {
    return PeminjamanState(
      peminjamans: peminjamans,
      isLoading: loading,
      errorMessage: errorMessage,
    );
  }
}

// ============================================================================
// PEMINJAMAN NOTIFIER (All peminjaman - Admin)
// ============================================================================
class PeminjamanNotifier extends Notifier<PeminjamanState> {
  late final PeminjamanService _peminjamanService;
  bool _hasInitialized = false;

  @override
  PeminjamanState build() {
    _peminjamanService = PeminjamanService();
    // DO NOT auto-load here
    return const PeminjamanState();
  }

  void ensureInitialized() {
    if (!_hasInitialized && !state.isLoading) {
      loadAllPeminjaman();
    }
  }

  Future<void> loadAllPeminjaman() async {
    try {
      state = state.setLoading(true).clearError();

      final peminjamans = await _peminjamanService.getAllPeminjaman();

      state = PeminjamanState(peminjamans: peminjamans, isLoading: false);
      _hasInitialized = true;
    } catch (e) {
      state = PeminjamanState(
        peminjamans: state.peminjamans,
        isLoading: false,
        errorMessage: 'Gagal memuat data peminjaman: ${e.toString()}',
      );
    }
  }

  // Get peminjaman by ID
  Future<PeminjamanModel?> getPeminjamanById(int peminjamanId) async {
    try {
      return await _peminjamanService.getPeminjamanById(peminjamanId);
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Gagal memuat detail peminjaman: ${e.toString()}',
      );
      return null;
    }
  }

  Future<void> refresh() async {
    await loadAllPeminjaman();
  }

  // Admin: Create peminjaman langsung (skip approval)
  Future<bool> createPeminjaman(PeminjamanModel peminjaman) async {
    try {
      state = state.setLoading(true).clearError();

      await _peminjamanService.ajukanPeminjaman(peminjaman);
      await loadAllPeminjaman();

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal membuat peminjaman: ${e.toString()}',
      );
      return false;
    }
  }

  // Admin: Update peminjaman (hanya pending)
  Future<bool> updatePeminjaman(PeminjamanModel peminjaman) async {
    try {
      state = state.setLoading(true).clearError();

      await _peminjamanService.updatePeminjaman(peminjaman);
      await loadAllPeminjaman();

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal update peminjaman: ${e.toString()}',
      );
      return false;
    }
  }

  // Admin: Delete/Cancel peminjaman (hanya pending)
  Future<bool> deletePeminjaman(int peminjamanId, int userId) async {
    try {
      state = state.setLoading(true).clearError();

      await _peminjamanService.cancelPeminjaman(peminjamanId, userId);
      await loadAllPeminjaman();

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal hapus peminjaman: ${e.toString()}',
      );
      return false;
    }
  }

  void clearError() {
    state = state.clearError();
  }
}

// ============================================================================
// PEMINJAMAN MENUNGGU NOTIFIER (Pending - Petugas)
// ============================================================================
class PeminjamanMenungguNotifier extends Notifier<PeminjamanState> {
  late final PeminjamanService _peminjamanService;
  bool _hasInitialized = false;

  @override
  PeminjamanState build() {
    _peminjamanService = PeminjamanService();
    // DO NOT auto-load here
    return const PeminjamanState();
  }

  void ensureInitialized() {
    if (!_hasInitialized && !state.isLoading) {
      loadPeminjamanMenunggu();
    }
  }

  Future<void> loadPeminjamanMenunggu() async {
    try {
      state = state.setLoading(true).clearError();

      final peminjamans = await _peminjamanService.getAllPeminjamanMenunggu();

      state = PeminjamanState(peminjamans: peminjamans, isLoading: false);
      _hasInitialized = true;
    } catch (e) {
      state = PeminjamanState(
        peminjamans: state.peminjamans,
        isLoading: false,
        errorMessage: 'Gagal memuat peminjaman menunggu: ${e.toString()}',
      );
    }
  }

  // Approve peminjaman
  Future<bool> approvePeminjaman(int peminjamanId, int petugasId) async {
    try {
      state = state.setLoading(true).clearError();

      await _peminjamanService.approvePeminjaman(peminjamanId, petugasId);
      await loadPeminjamanMenunggu();

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal menyetujui peminjaman: ${e.toString()}',
      );
      return false;
    }
  }

  // Reject peminjaman
  Future<bool> rejectPeminjaman(
    int peminjamanId,
    int petugasId,
    String catatan,
  ) async {
    try {
      state = state.setLoading(true).clearError();

      await _peminjamanService.rejectPeminjaman(
        peminjamanId,
        petugasId,
        catatan,
      );
      await loadPeminjamanMenunggu();

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal menolak peminjaman: ${e.toString()}',
      );
      return false;
    }
  }

  Future<void> refresh() async {
    await loadPeminjamanMenunggu();
  }

  void clearError() {
    state = state.clearError();
  }
}

// ============================================================================
// PEMINJAMAN AKTIF NOTIFIER (Dipinjam - Petugas)
// ============================================================================
class PeminjamanAktifNotifier extends Notifier<PeminjamanState> {
  late final PeminjamanService _peminjamanService;
  bool _hasInitialized = false;

  @override
  PeminjamanState build() {
    _peminjamanService = PeminjamanService();
    // DO NOT auto-load here
    return const PeminjamanState();
  }

  void ensureInitialized() {
    if (!_hasInitialized && !state.isLoading) {
      loadPeminjamanAktif();
    }
  }

  Future<void> loadPeminjamanAktif() async {
    try {
      state = state.setLoading(true).clearError();

      final peminjamans = await _peminjamanService.getAllPeminjamanAktif();

      state = PeminjamanState(peminjamans: peminjamans, isLoading: false);
      _hasInitialized = true;
    } catch (e) {
      state = PeminjamanState(
        peminjamans: state.peminjamans,
        isLoading: false,
        errorMessage: 'Gagal memuat peminjaman aktif: ${e.toString()}',
      );
    }
  }

  Future<void> refresh() async {
    await loadPeminjamanAktif();
  }

  void clearError() {
    state = state.clearError();
  }
}

// ============================================================================
// MY PEMINJAMAN NOTIFIER (User's own peminjaman - Peminjam)
// ============================================================================
class MyPeminjamanNotifier extends Notifier<PeminjamanState> {
  late final PeminjamanService _peminjamanService;
  bool _hasInitialized = false;

  @override
  PeminjamanState build() {
    _peminjamanService = PeminjamanService();
    // DO NOT auto-load here
    return const PeminjamanState();
  }

  void ensureInitialized() {
    if (!_hasInitialized && !state.isLoading) {
      final userId = ref.read(currentUserIdProvider);
      if (userId != null) {
        loadMyPeminjaman(userId);
      }
    }
  }

  Future<void> loadMyPeminjaman(int userId) async {
    try {
      state = state.setLoading(true).clearError();

      final peminjamans = await _peminjamanService.getPeminjamanByUser(userId);

      state = PeminjamanState(peminjamans: peminjamans, isLoading: false);
      _hasInitialized = true;
    } catch (e) {
      state = PeminjamanState(
        peminjamans: state.peminjamans,
        isLoading: false,
        errorMessage: 'Gagal memuat riwayat peminjaman: ${e.toString()}',
      );
    }
  }

  // Validasi apakah user bisa ajukan peminjaman baru
  Future<Map<String, dynamic>> canCreatePeminjaman(
    int userId,
    int alatId,
  ) async {
    try {
      // Cek peminjaman aktif untuk alat yang sama
      final activeLoan = state.peminjamans
          .where(
            (p) =>
                p.peminjamId == userId &&
                p.alatId == alatId &&
                (p.statusPeminjamanId == 1 ||
                    p.statusPeminjamanId == 2), // Pending atau Dipinjam
          )
          .toList();

      if (activeLoan.isNotEmpty) {
        return {
          'canCreate': false,
          'message': 'Anda masih memiliki peminjaman aktif untuk alat ini',
        };
      }

      return {'canCreate': true};
    } catch (e) {
      return {
        'canCreate': false,
        'message': 'Gagal memvalidasi peminjaman: ${e.toString()}',
      };
    }
  }

  // Ajukan peminjaman
  Future<bool> ajukanPeminjaman(PeminjamanModel peminjaman) async {
    try {
      state = state.setLoading(true).clearError();

      await _peminjamanService.ajukanPeminjaman(peminjaman);

      if (peminjaman.peminjamId != null) {
        await loadMyPeminjaman(peminjaman.peminjamId!);
      }

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal mengajukan peminjaman: ${e.toString()}',
      );
      return false;
    }
  }

  // Update peminjaman (hanya jika pending)
  Future<bool> updatePeminjaman(PeminjamanModel peminjaman) async {
    try {
      state = state.setLoading(true).clearError();

      await _peminjamanService.updatePeminjaman(peminjaman);

      if (peminjaman.peminjamId != null) {
        await loadMyPeminjaman(peminjaman.peminjamId!);
      }

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal mengubah peminjaman: ${e.toString()}',
      );
      return false;
    }
  }

  // Cancel peminjaman (hanya jika pending)
  Future<bool> cancelPeminjaman(int peminjamanId, int userId) async {
    try {
      state = state.setLoading(true).clearError();

      await _peminjamanService.cancelPeminjaman(peminjamanId, userId);
      await loadMyPeminjaman(userId);

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal membatalkan peminjaman: ${e.toString()}',
      );
      return false;
    }
  }

  Future<void> refresh() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId != null) {
      await loadMyPeminjaman(userId);
    }
  }

  void clearError() {
    state = state.clearError();
  }
}

// ============================================================================
// PROVIDERS
// ============================================================================

// All peminjaman (Admin)
final peminjamanProvider =
    NotifierProvider<PeminjamanNotifier, PeminjamanState>(() {
      return PeminjamanNotifier();
    });

// Peminjaman menunggu approval (Petugas)
final peminjamanMenungguProvider =
    NotifierProvider<PeminjamanMenungguNotifier, PeminjamanState>(() {
      return PeminjamanMenungguNotifier();
    });

// Peminjaman aktif (Petugas)
final peminjamanAktifProvider =
    NotifierProvider<PeminjamanAktifNotifier, PeminjamanState>(() {
      return PeminjamanAktifNotifier();
    });

// My peminjaman (Peminjam)
final myPeminjamanProvider =
    NotifierProvider<MyPeminjamanNotifier, PeminjamanState>(() {
      return MyPeminjamanNotifier();
    });

// ============================================================================
// HELPER PROVIDERS
// ============================================================================

// Count providers
final peminjamanCountProvider = Provider<int>((ref) {
  return ref.watch(peminjamanProvider).peminjamans.length;
});

final peminjamanMenungguCountProvider = Provider<int>((ref) {
  return ref.watch(peminjamanMenungguProvider).peminjamans.length;
});

final peminjamanAktifCountProvider = Provider<int>((ref) {
  return ref.watch(peminjamanAktifProvider).peminjamans.length;
});

final myPeminjamanCountProvider = Provider<int>((ref) {
  return ref.watch(myPeminjamanProvider).peminjamans.length;
});

// Get peminjaman by status
final peminjamanByStatusProvider = Provider.family<List<PeminjamanModel>, int>((
  ref,
  statusId,
) {
  final peminjamans = ref.watch(peminjamanProvider).peminjamans;
  return peminjamans.where((p) => p.statusPeminjamanId == statusId).toList();
});

// Overdue peminjaman
final overduePeminjamanProvider = Provider<List<PeminjamanModel>>((ref) {
  final peminjamans = ref.watch(peminjamanAktifProvider).peminjamans;
  return peminjamans.where((p) => p.isOverdue).toList();
});

// My active peminjaman count
final myActivePeminjamanCountProvider = Provider<int>((ref) {
  final peminjamans = ref.watch(myPeminjamanProvider).peminjamans;
  return peminjamans.where((p) => p.statusPeminjamanId == 2).length;
});

// My pending peminjaman count
final myPendingPeminjamanCountProvider = Provider<int>((ref) {
  final peminjamans = ref.watch(myPeminjamanProvider).peminjamans;
  return peminjamans.where((p) => p.statusPeminjamanId == 1).length;
});

// Peminjaman by date range
final peminjamanByDateRangeProvider =
    Provider.family<List<PeminjamanModel>, Map<String, DateTime>>((
      ref,
      dateRange,
    ) {
      final peminjamans = ref.watch(peminjamanProvider).peminjamans;
      final start = dateRange['start']!;
      final end = dateRange['end']!;

      return peminjamans.where((p) {
        if (p.tanggalPinjam == null) return false;
        return p.tanggalPinjam!.isAfter(start) &&
            p.tanggalPinjam!.isBefore(end);
      }).toList();
    });

// Today's peminjaman
final todayPeminjamanProvider = Provider<List<PeminjamanModel>>((ref) {
  final peminjamans = ref.watch(peminjamanProvider).peminjamans;
  final today = DateTime.now();
  final startOfDay = DateTime(today.year, today.month, today.day);
  final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

  return peminjamans.where((p) {
    if (p.tanggalPinjam == null) return false;
    return p.tanggalPinjam!.isAfter(startOfDay) &&
        p.tanggalPinjam!.isBefore(endOfDay);
  }).toList();
});
