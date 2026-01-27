// lib/providers/alat_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/alat_model.dart';
import '../services/alat_services.dart';

// ============================================================================
// ALAT STATE (DITAMBAHKAN FIELD BARU, FIELD LAMA TETAP)
// ============================================================================
class AlatState {
  // FIELD LAMA (TETAP)
  final List<AlatModel> alats;
  final bool isLoading;
  final String? errorMessage;
  final String searchQuery;
  final int? selectedKategoriId;

  // FIELD BARU (TAMBAHAN UNTUK PAGINATION)
  final List<AlatModel> cachedAlats; // Full cache untuk pagination
  final int currentPage;
  final bool isLoadingMore;
  final bool hasMoreData;
  static const int pageSize = 16;

  const AlatState({
    this.alats = const [],
    this.isLoading = false,
    this.errorMessage,
    this.searchQuery = '',
    this.selectedKategoriId,
    // New fields for pagination
    this.cachedAlats = const [],
    this.currentPage = 0,
    this.isLoadingMore = false,
    this.hasMoreData = true,
  });

  AlatState copyWith({
    List<AlatModel>? alats,
    bool? isLoading,
    String? errorMessage,
    String? searchQuery,
    int? selectedKategoriId,
    // New parameters
    List<AlatModel>? cachedAlats,
    int? currentPage,
    bool? isLoadingMore,
    bool? hasMoreData,
  }) {
    return AlatState(
      alats: alats ?? this.alats,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedKategoriId: selectedKategoriId ?? this.selectedKategoriId,
      cachedAlats: cachedAlats ?? this.cachedAlats,
      currentPage: currentPage ?? this.currentPage,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMoreData: hasMoreData ?? this.hasMoreData,
    );
  }

  AlatState clearError() {
    return AlatState(
      alats: alats,
      isLoading: isLoading,
      errorMessage: null,
      searchQuery: searchQuery,
      selectedKategoriId: selectedKategoriId,
      cachedAlats: cachedAlats,
      currentPage: currentPage,
      isLoadingMore: isLoadingMore,
      hasMoreData: hasMoreData,
    );
  }

  AlatState setLoading(bool loading) {
    return AlatState(
      alats: alats,
      isLoading: loading,
      errorMessage: errorMessage,
      searchQuery: searchQuery,
      selectedKategoriId: selectedKategoriId,
      cachedAlats: cachedAlats,
      currentPage: currentPage,
      isLoadingMore: isLoadingMore,
      hasMoreData: hasMoreData,
    );
  }

  // GETTER BARU: untuk mendapatkan displayed alats (paginated)
  List<AlatModel> get displayedAlats => alats;

  // GETTER BARU: untuk total count
  int get totalCount =>
      cachedAlats.isNotEmpty ? cachedAlats.length : alats.length;
}

// ============================================================================
// ALAT NOTIFIER (FUNGSI LAMA TETAP, FUNGSI BARU DITAMBAHKAN)
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

  // ============================================================================
  // FUNGSI LAMA (TIDAK DIUBAH) - Untuk halaman lain yang sudah ada
  // ============================================================================

  // Load all alats with filters (FUNGSI LAMA - TETAP)
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

  // Search alats (FUNGSI LAMA - TETAP)
  Future<void> searchAlats(String query) async {
    await loadAlats(
      search: query.isEmpty ? null : query,
      kategoriId: state.selectedKategoriId,
    );
  }

  // Filter by kategori (FUNGSI LAMA - TETAP)
  Future<void> filterByKategori(int? kategoriId) async {
    await loadAlats(
      search: state.searchQuery.isEmpty ? null : state.searchQuery,
      kategoriId: kategoriId,
    );
  }

  // Clear filters (FUNGSI LAMA - TETAP)
  Future<void> clearFilters() async {
    await loadAlats();
  }

  // Get alat by ID (FUNGSI LAMA - TETAP)
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

  // Create alat (FUNGSI LAMA - TETAP)
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

  // Update alat (FUNGSI LAMA - TETAP)
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

  // Delete alat (FUNGSI LAMA - TETAP)
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

  // Refresh data (FUNGSI LAMA - TETAP)
  Future<void> refresh() async {
    await loadAlats(
      search: state.searchQuery.isEmpty ? null : state.searchQuery,
      kategoriId: state.selectedKategoriId,
    );
  }

  // Clear error (FUNGSI LAMA - TETAP)
  void clearError() {
    state = state.clearError();
  }

  // ============================================================================
  // FUNGSI BARU (TAMBAHAN) - Khusus untuk pagination di alat_management
  // ============================================================================

  // FUNGSI BARU: Load alats dengan pagination
  Future<void> loadAlatsPaginated({String? search, int? kategoriId}) async {
    try {
      state = state.setLoading(true).clearError();

      // Fetch ALL data dan simpan di cache
      final allAlats = await _alatService.getAllAlat(
        search: search,
        kategoriId: kategoriId,
      );

      // Display hanya 16 items pertama
      final displayedAlats = allAlats.take(AlatState.pageSize).toList();

      state = state.copyWith(
        alats: displayedAlats, // alats = displayed (untuk UI)
        cachedAlats: allAlats, // cachedAlats = full data
        isLoading: false,
        searchQuery: search ?? '',
        selectedKategoriId: kategoriId,
        currentPage: 1,
        hasMoreData: allAlats.length > AlatState.pageSize,
      );

      _hasInitialized = true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal memuat data alat: ${e.toString()}',
      );
    }
  }

  // FUNGSI BARU: Load more items (lazy loading)
  Future<void> loadMoreAlats() async {
    // Don't load if already loading, no more data, or not using pagination
    if (state.isLoadingMore ||
        !state.hasMoreData ||
        state.cachedAlats.isEmpty) {
      return;
    }

    try {
      state = state.copyWith(isLoadingMore: true);

      // Calculate next batch from cache
      final startIndex = state.currentPage * AlatState.pageSize;
      final endIndex = startIndex + AlatState.pageSize;

      if (startIndex < state.cachedAlats.length) {
        final nextBatch = state.cachedAlats
            .skip(startIndex)
            .take(AlatState.pageSize)
            .toList();

        final updatedDisplayed = [...state.alats, ...nextBatch];

        state = state.copyWith(
          alats: updatedDisplayed,
          isLoadingMore: false,
          currentPage: state.currentPage + 1,
          hasMoreData: endIndex < state.cachedAlats.length,
        );
      } else {
        state = state.copyWith(isLoadingMore: false, hasMoreData: false);
      }
    } catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        errorMessage: 'Gagal memuat data tambahan: ${e.toString()}',
      );
    }
  }

  // FUNGSI BARU: Search dengan pagination
  Future<void> searchAlatsPaginated(String query) async {
    await loadAlatsPaginated(
      search: query.isEmpty ? null : query,
      kategoriId: state.selectedKategoriId,
    );
  }

  // FUNGSI BARU: Filter dengan pagination
  Future<void> filterByKategoriPaginated(int? kategoriId) async {
    await loadAlatsPaginated(
      search: state.searchQuery.isEmpty ? null : state.searchQuery,
      kategoriId: kategoriId,
    );
  }

  // FUNGSI BARU: Refresh dengan pagination
  Future<void> refreshPaginated() async {
    await loadAlatsPaginated(
      search: state.searchQuery.isEmpty ? null : state.searchQuery,
      kategoriId: state.selectedKategoriId,
    );
  }

  // FUNGSI BARU: Create alat dengan pagination
  Future<bool> createAlatPaginated(AlatModel alat) async {
    try {
      state = state.setLoading(true).clearError();

      await _alatService.createAlat(alat);

      // Refresh dengan pagination
      await loadAlatsPaginated(
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

  // FUNGSI BARU: Update alat dengan pagination
  Future<bool> updateAlatPaginated(AlatModel alat, {String? oldFotoUrl}) async {
    try {
      state = state.setLoading(true).clearError();

      await _alatService.updateAlat(alat, oldFotoUrl: oldFotoUrl);

      // Refresh dengan pagination
      await loadAlatsPaginated(
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

  // FUNGSI BARU: Delete alat dengan pagination
  Future<bool> deleteAlatPaginated(int alatId) async {
    try {
      state = state.setLoading(true).clearError();

      await _alatService.deleteAlat(alatId);

      // Refresh dengan pagination
      await loadAlatsPaginated(
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

  // FUNGSI BARU: Initialize dengan pagination
  void ensureInitializedPaginated() {
    if (!_hasInitialized && !state.isLoading) {
      loadAlatsPaginated();
    }
  }
}

// ============================================================================
// ALAT TERSEDIA NOTIFIER (TIDAK DIUBAH)
// ============================================================================
class AlatTersediaNotifier extends Notifier<AlatState> {
  late final AlatService _alatService;
  bool _hasInitialized = false;

  @override
  AlatState build() {
    _alatService = AlatService();
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
// PROVIDERS (TIDAK DIUBAH)
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
// HELPER PROVIDERS (TIDAK DIUBAH - Tetap pakai state.alats)
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
