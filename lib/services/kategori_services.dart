// lib/services/kategori_services.dart
import '../models/kategori_model.dart';
import '../main.dart';
import 'auth_services.dart';
import 'log_services.dart';

class KategoriService {
  final String _table = 'kategori';
  final LogService _logService = LogService();
  final AuthService _authService = AuthService();

  Future<List<KategoriModel>> getAllKategori() async {
    final response = await supabase
        .from(_table)
        .select()
        .order('nama_kategori');
    return (response as List).map((e) => KategoriModel.fromJson(e)).toList();
  }

  Future<void> createKategori(KategoriModel kategori) async {
    final response = await supabase
        .from(_table)
        .insert(kategori.toInsertJson())
        .select()
        .single();
    final newKategori = KategoriModel.fromJson(response);

    final currentUser = await _authService.getCurrentUser();
    if (currentUser != null) {
      await _logService.logActivity(
        userId: currentUser.userId,
        aktivitas: 'Create Kategori',
        tabelTerkait: _table,
        idTerkait: newKategori.kategoriId,
      );
    }
  }

  Future<void> updateKategori(KategoriModel kategori) async {
    await supabase
        .from(_table)
        .update(kategori.toInsertJson())
        .eq('kategori_id', kategori.kategoriId);

    final currentUser = await _authService.getCurrentUser();
    if (currentUser != null) {
      await _logService.logActivity(
        userId: currentUser.userId,
        aktivitas: 'Update Kategori',
        tabelTerkait: _table,
        idTerkait: kategori.kategoriId,
      );
    }
  }

  Future<void> deleteKategori(int kategoriId) async {
    await supabase.from(_table).delete().eq('kategori_id', kategoriId);

    final currentUser = await _authService.getCurrentUser();
    if (currentUser != null) {
      await _logService.logActivity(
        userId: currentUser.userId,
        aktivitas: 'Delete Kategori',
        tabelTerkait: _table,
        idTerkait: kategoriId,
      );
    }
  }
}
