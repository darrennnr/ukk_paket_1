// lib/providers/kategori_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paket_3_training/providers/alat_provider.dart';
import '../models/kategori_model.dart';
import '../services/kategori_services.dart';

// ============================================================================
// KATEGORI STATE
// ============================================================================
class KategoriState {
  final List<KategoriModel> kategoris;
  final bool isLoading;
  final String? errorMessage;

  const KategoriState({
    this.kategoris = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  KategoriState copyWith({
    List<KategoriModel>? kategoris,
    bool? isLoading,
    String? errorMessage,
  }) {
    return KategoriState(
      kategoris: kategoris ?? this.kategoris,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  KategoriState clearError() {
    return KategoriState(
      kategoris: kategoris,
      isLoading: isLoading,
      errorMessage: null,
    );
  }

  KategoriState setLoading(bool loading) {
    return KategoriState(
      kategoris: kategoris,
      isLoading: loading,
      errorMessage: errorMessage,
    );
  }
}



// ============================================================================
// KATEGORI NOTIFIER
// ============================================================================
class KategoriNotifier extends Notifier<KategoriState> {
  late final KategoriService _kategoriService;
  bool _hasInitialized = false;

  @override
  KategoriState build() {
    _kategoriService = KategoriService();
    // DO NOT auto-load here
    return const KategoriState();
  }

  void ensureInitialized() {
    if (!_hasInitialized && !state.isLoading) {
      loadKategoris();
    }
  }

  // Load all kategoris
  Future<void> loadKategoris() async {
    try {
      state = state.setLoading(true).clearError();

      final kategoris = await _kategoriService.getAllKategori();

      state = KategoriState(kategoris: kategoris, isLoading: false);
      _hasInitialized = true;
    } catch (e) {
      state = KategoriState(
        kategoris: state.kategoris,
        isLoading: false,
        errorMessage: 'Gagal memuat data kategori: ${e.toString()}',
      );
    }
  }

  // Create kategori
  Future<bool> createKategori(KategoriModel kategori) async {
    try {
      state = state.setLoading(true).clearError();

      await _kategoriService.createKategori(kategori);
      await loadKategoris();

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal menambah kategori: ${e.toString()}',
      );
      return false;
    }
  }

  // Update kategori
  Future<bool> updateKategori(KategoriModel kategori) async {
    try {
      state = state.setLoading(true).clearError();

      await _kategoriService.updateKategori(kategori);
      await loadKategoris();

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal mengubah kategori: ${e.toString()}',
      );
      return false;
    }
  }

  // Delete kategori
  Future<bool> deleteKategori(int kategoriId) async {
    try {
      state = state.setLoading(true).clearError();

      await _kategoriService.deleteKategori(kategoriId);
      await loadKategoris();

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal menghapus kategori: ${e.toString()}',
      );
      return false;
    }
  }

  // Refresh data
  Future<void> refresh() async {
    await loadKategoris();
  }

  // Clear error
  void clearError() {
    state = state.clearError();
  }
}

// ============================================================================
// PROVIDER
// ============================================================================
final kategoriProvider = NotifierProvider<KategoriNotifier, KategoriState>(() {
  return KategoriNotifier();
});

// ============================================================================
// HELPER PROVIDERS
// ============================================================================

// Kategori list provider (untuk dropdown)
final kategoriListProvider = Provider<List<KategoriModel>>((ref) {
  return ref.watch(kategoriProvider).kategoris;
});

// Kategori count provider
final kategoriCountProvider = Provider<int>((ref) {
  return ref.watch(kategoriProvider).kategoris.length;
});

// Get kategori by ID
final kategoriByIdProvider = Provider.family<KategoriModel?, int>((
  ref,
  kategoriId,
) {
  final kategoris = ref.watch(kategoriProvider).kategoris;
  try {
    return kategoris.firstWhere((k) => k.kategoriId == kategoriId);
  } catch (e) {
    return null;
  }
});

// Kategori dengan jumlah alat (requires alat provider)
final kategoriWithCountProvider = Provider<List<Map<String, dynamic>>>((ref) {
  final kategoris = ref.watch(kategoriProvider).kategoris;
  final alats = ref.watch(alatProvider).alats;

  return kategoris.map((kategori) {
    final alatCount = alats
        .where((alat) => alat.kategoriId == kategori.kategoriId)
        .length;

    return {'kategori': kategori, 'jumlah_alat': alatCount};
  }).toList();
});
