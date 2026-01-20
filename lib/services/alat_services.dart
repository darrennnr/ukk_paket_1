// lib/services/alat_services.dart
import 'package:paket_3_training/services/storage_services.dart';

import '../models/alat_model.dart';
import '../main.dart';
import 'auth_services.dart';
import 'log_services.dart';

class AlatService {
  final String _table = 'alat';
  final LogService _logService = LogService();
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();

  // GetAllAlat dengan search dan filter kategori
  Future<List<AlatModel>> getAllAlat({String? search, int? kategoriId}) async {
    var query = supabase.from(_table).select('*, kategori(*)'); // Join kategori

    if (search != null && search.isNotEmpty) {
      query = query.ilike('nama_alat', '%$search%');
    }
    if (kategoriId != null) {
      query = query.eq('kategori_id', kategoriId);
    }

    final response = await query.order('nama_alat');
    return (response as List).map((e) => AlatModel.fromJson(e)).toList();
  }

  // Get Alat Tersedia (Stok > 0)
  Future<List<AlatModel>> getAlatTersedia() async {
    final response = await supabase
        .from(_table)
        .select('*, kategori(*)')
        .gt('jumlah_tersedia', 0) // Filter jumlah_tersedia > 0
        .order('nama_alat');

    return (response as List).map((e) => AlatModel.fromJson(e)).toList();
  }

  // Get Alat By ID
  Future<AlatModel?> getAlatById(int alatId) async {
    final response = await supabase
        .from(_table)
        .select('*, kategori(*)')
        .eq('alat_id', alatId)
        .maybeSingle();

    if (response == null) return null;
    return AlatModel.fromJson(response);
  }

  // Create Alat
  Future<void> createAlat(AlatModel alat) async {
    // Generate kode_alat unik jika belum ada logic di UI
    // Disini kita asumsikan kode_alat sudah diinput atau digenerate di UI

    final response = await supabase
        .from(_table)
        .insert(alat.toInsertJson())
        .select()
        .single();
    final newAlat = AlatModel.fromJson(response);

    final currentUser = await _authService.getCurrentUser();
    if (currentUser != null) {
      await _logService.logActivity(
        userId: currentUser.userId,
        aktivitas: 'Create Alat',
        tabelTerkait: _table,
        idTerkait: newAlat.alatId,
        deskripsi: 'Tambah alat: ${newAlat.namaAlat}',
      );
    }
  }

  // Update Alat
  // Update Alat
  Future<void> updateAlat(AlatModel alat, {String? oldFotoUrl}) async {
    // Delete old image if it exists and is from Supabase Storage
    if (oldFotoUrl != null &&
        oldFotoUrl.isNotEmpty &&
        _storageService.isSupabaseUrl(oldFotoUrl) &&
        oldFotoUrl != alat.fotoAlat) {
      await _storageService.deleteImage(oldFotoUrl);
    }

    await supabase
        .from(_table)
        .update(alat.toInsertJson())
        .eq('alat_id', alat.alatId);

    final currentUser = await _authService.getCurrentUser();
    if (currentUser != null) {
      await _logService.logActivity(
        userId: currentUser.userId,
        aktivitas: 'Update Alat',
        tabelTerkait: _table,
        idTerkait: alat.alatId,
      );
    }
  }

  // Delete Alat (dengan validasi peminjaman aktif)
  // Delete Alat (dengan validasi peminjaman aktif)
  Future<void> deleteAlat(int alatId) async {
    // Cek apakah ada peminjaman aktif
    final activeLoan = await supabase
        .from('peminjaman')
        .select()
        .eq('alat_id', alatId)
        .inFilter('status_peminjaman_id', [1, 2]) // Pending atau Dipinjam
        .maybeSingle();

    if (activeLoan != null) {
      throw Exception(
        'Tidak dapat menghapus alat yang sedang dipinjam atau menunggu approval',
      );
    }

    // Get alat data to delete image
    final alatData = await getAlatById(alatId);

    // Delete image from storage if exists
    if (alatData?.fotoAlat != null &&
        alatData!.fotoAlat!.isNotEmpty &&
        _storageService.isSupabaseUrl(alatData.fotoAlat!)) {
      await _storageService.deleteImage(alatData.fotoAlat!);
    }

    await supabase.from(_table).delete().eq('alat_id', alatId);

    final currentUser = await _authService.getCurrentUser();
    if (currentUser != null) {
      await _logService.logActivity(
        userId: currentUser.userId,
        aktivitas: 'Delete Alat',
        tabelTerkait: _table,
        idTerkait: alatId,
      );
    }
  }
}
