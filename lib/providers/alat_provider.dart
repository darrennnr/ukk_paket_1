// lib/providers/alat_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/alat_model.dart';
import '../services/alat_services.dart';

// ============================================================================
// ALAT STATE
// ============================================================================
class AlatState {
  final List<AlatModel> alats;
  final bool isLoading;
  final String? errorMessage;
  final String searchQuery;
  final int? selectedKategoriId;

  const AlatState({
    this.alats = const [],
    this.isLoading = false,
    this.errorMessage,
    this.searchQuery = '',
    this.selectedKategoriId,
  });

  AlatState copyWith({
    List<AlatModel>? alats,
    bool? isLoading,
    String? errorMessage,
    String? searchQuery,
    int? selectedKategoriId,
  }) {
    return AlatState(
      alats: alats ?? this.alats,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedKategoriId: selectedKategoriId ?? this.selectedKategoriId,
    );
  }

  AlatState clearError() {
    return AlatState(
      alats: alats,
      isLoading: isLoading,
      errorMessage: null,
      searchQuery: searchQuery,
      selectedKategoriId: selectedKategoriId,
    );
  }

  AlatState setLoading(bool loading) {
    return AlatState(
      alats: alats,
      isLoading: loading,
      errorMessage: errorMessage,
      searchQuery: searchQuery,
      selectedKategoriId: selectedKategoriId,
    );
  }
}

// ============================================================================
// ALAT NOTIFIER
// ============================================================================
class AlatNotifier extends Notifier<AlatState> {
  late final AlatService _alatService;
  bool _hasInitialized = false;

  @override
  AlatState build() {
    _alatService = AlatService();
    // DO NOT auto-load here
    return const AlatState();
  }

  void ensureInitialized() {
    if (!_hasInitialized && !state.isLoading) {
      loadAlats();
    }
  }

  // Load all alats with filters
  Future<void> loadAlats({String? search, int? kategoriId}) async {
    try {
      state = state.setLoading(true).clearError();

      final alats = await _alatService.getAllAlat(
        search: search,
        kategoriId: kategoriId,
      );

      state = AlatState(
        alats: alats,
        isLoading: false,
        searchQuery: search ?? '',
        selectedKategoriId: kategoriId,
      );
      _hasInitialized = true;
    } catch (e) {
      state = AlatState(
        alats: state.alats,
        isLoading: false,
        errorMessage: 'Gagal memuat data alat: ${e.toString()}',
        searchQuery: state.searchQuery,
        selectedKategoriId: state.selectedKategoriId,
      );
    }
  }

  // Search alats
  Future<void> searchAlats(String query) async {
    await loadAlats(
      search: query.isEmpty ? null : query,
      kategoriId: state.selectedKategoriId,
    );
  }

  // Filter by kategori
  Future<void> filterByKategori(int? kategoriId) async {
    await loadAlats(
      search: state.searchQuery.isEmpty ? null : state.searchQuery,
      kategoriId: kategoriId,
    );
  }

  // Clear filters
  Future<void> clearFilters() async {
    await loadAlats();
  }

  // Get alat by ID
  Future<AlatModel?> getAlatById(int alatId) async {
    try {
      return await _alatService.getAlatById(alatId);
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Gagal memuat detail alat: ${e.toString()}',
      );
      return null;
    }
  }

  // Create alat
  Future<bool> createAlat(AlatModel alat) async {
    try {
      state = state.setLoading(true).clearError();

      await _alatService.createAlat(alat);
      await loadAlats(
        search: state.searchQuery.isEmpty ? null : state.searchQuery,
        kategoriId: state.selectedKategoriId,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal menambah alat: ${e.toString()}',
      );
      return false;
    }
  }

  // Update alat
  // Update alat
  Future<bool> updateAlat(AlatModel alat, {String? oldFotoUrl}) async {
    try {
      state = state.setLoading(true).clearError();

      await _alatService.updateAlat(alat, oldFotoUrl: oldFotoUrl);
      await loadAlats(
        search: state.searchQuery.isEmpty ? null : state.searchQuery,
        kategoriId: state.selectedKategoriId,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal mengubah alat: ${e.toString()}',
      );
      return false;
    }
  }

  // Delete alat
  Future<bool> deleteAlat(int alatId) async {
    try {
      state = state.setLoading(true).clearError();

      await _alatService.deleteAlat(alatId);
      await loadAlats(
        search: state.searchQuery.isEmpty ? null : state.searchQuery,
        kategoriId: state.selectedKategoriId,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal menghapus alat: ${e.toString()}',
      );
      return false;
    }
  }

  // Refresh data
  Future<void> refresh() async {
    await loadAlats(
      search: state.searchQuery.isEmpty ? null : state.searchQuery,
      kategoriId: state.selectedKategoriId,
    );
  }

  // Clear error
  void clearError() {
    state = state.clearError();
  }
}

// ============================================================================
// ALAT TERSEDIA NOTIFIER (Separate provider for available alats)
// ============================================================================
class AlatTersediaNotifier extends Notifier<AlatState> {
  late final AlatService _alatService;
  bool _hasInitialized = false;

  @override
  AlatState build() {
    _alatService = AlatService();
    // DO NOT auto-load here
    return const AlatState();
  }

  void ensureInitialized() {
    if (!_hasInitialized && !state.isLoading) {
      loadAlatTersedia();
    }
  }

  Future<void> loadAlatTersedia() async {
    try {
      state = state.setLoading(true).clearError();

      final alats = await _alatService.getAlatTersedia();

      state = AlatState(alats: alats, isLoading: false);
      _hasInitialized = true;
    } catch (e) {
      state = AlatState(
        alats: state.alats,
        isLoading: false,
        errorMessage: 'Gagal memuat alat tersedia: ${e.toString()}',
      );
    }
  }

  Future<void> refresh() async {
    await loadAlatTersedia();
  }
}

// ============================================================================
// PROVIDERS
// ============================================================================

// Main alat provider
final alatProvider = NotifierProvider<AlatNotifier, AlatState>(() {
  return AlatNotifier();
});

// Alat tersedia provider (untuk peminjaman)
final alatTersediaProvider = NotifierProvider<AlatTersediaNotifier, AlatState>(
  () {
    return AlatTersediaNotifier();
  },
);

// ============================================================================
// HELPER PROVIDERS
// ============================================================================

// Alat count provider
final alatCountProvider = Provider<int>((ref) {
  return ref.watch(alatProvider).alats.length;
});

// Alat tersedia count provider
final alatTersediaCountProvider = Provider<int>((ref) {
  return ref.watch(alatTersediaProvider).alats.length;
});

// Get alat by ID
final alatByIdProvider = Provider.family<AlatModel?, int>((ref, alatId) {
  final alats = ref.watch(alatProvider).alats;
  try {
    return alats.firstWhere((alat) => alat.alatId == alatId);
  } catch (e) {
    return null;
  }
});

// Filtered alats by kategori
final alatsByKategoriProvider = Provider.family<List<AlatModel>, int>((
  ref,
  kategoriId,
) {
  final alats = ref.watch(alatProvider).alats;
  return alats.where((alat) => alat.kategoriId == kategoriId).toList();
});

// Available alats only
final availableAlatsProvider = Provider<List<AlatModel>>((ref) {
  final alats = ref.watch(alatProvider).alats;
  return alats.where((alat) => alat.isAvailable).toList();
});

// Alat dengan stok rendah (< 3)
final lowStockAlatsProvider = Provider<List<AlatModel>>((ref) {
  final alats = ref.watch(alatProvider).alats;
  return alats
      .where((alat) => alat.jumlahTersedia > 0 && alat.jumlahTersedia < 3)
      .toList();
});

// Alat dengan kondisi tidak baik
final damagedAlatsProvider = Provider<List<AlatModel>>((ref) {
  final alats = ref.watch(alatProvider).alats;
  return alats.where((alat) => !alat.isGoodCondition).toList();
});

// Alat kosong (stok = 0)
final emptyStockAlatsProvider = Provider<List<AlatModel>>((ref) {
  final alats = ref.watch(alatProvider).alats;
  return alats.where((alat) => alat.jumlahTersedia == 0).toList();
});

// Total nilai inventori
final totalInventoryValueProvider = Provider<double>((ref) {
  final alats = ref.watch(alatProvider).alats;
  return alats.fold<double>(
    0,
    (sum, alat) => sum + ((alat.hargaPerhari ?? 0) * alat.jumlahTotal),
  );
});
