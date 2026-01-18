// lib/services/pengembalian_services.dart
import '../models/pengembalian_model.dart';
import '../models/peminjaman_model.dart' as peminjaman_pkg;
import '../models/alat_model.dart' as alat_pkg;
import '../main.dart';
import 'log_services.dart';

class PengembalianService {
  final String _table = 'pengembalian';
  final LogService _logService = LogService();

  // Helper: Hitung Denda
  int hitungDenda(DateTime tanggalBerakhir, int hargaPerHari) {
    final now = DateTime.now();
    if (now.isAfter(tanggalBerakhir)) {
      final difference = now.difference(tanggalBerakhir).inDays;
      return difference * hargaPerHari;
    }
    return 0;
  }

  // Proses Pengembalian
  Future<void> prosesPengembalian({
    required int peminjamanId,
    required int petugasId,
    required String kondisiAlat,
    String? catatan,
  }) async {
    // 1. Get Data Peminjaman & Alat
    final pinjamRes = await supabase
        .from('peminjaman')
        .select('*, alat(*)')
        .eq('peminjaman_id', peminjamanId)
        .single();

    final peminjaman = peminjaman_pkg.PeminjamanModel.fromJson(pinjamRes);

    // Parse alat menggunakan AlatModel yang lengkap dari alat_model.dart
    final alat = alat_pkg.AlatModel.fromJson(
      pinjamRes['alat'] as Map<String, dynamic>,
    );

    // 2. Hitung Keterlambatan & Denda
    final now = DateTime.now();
    int terlambatHari = 0;
    int totalDenda = 0;

    if (now.isAfter(peminjaman.tanggalBerakhir)) {
      terlambatHari = now.difference(peminjaman.tanggalBerakhir).inDays;
      double harga = alat.hargaPerhari ?? 0;
      totalDenda = (terlambatHari * harga).toInt();
    }

    // 3. Insert ke Tabel Pengembalian
    final pengembalian = PengembalianModel(
      pengembalianId: 0,
      peminjamanId: peminjamanId,
      petugasId: petugasId,
      tanggalKembali: now,
      kondisiAlat: kondisiAlat,
      jumlahKembali: peminjaman.jumlahPinjam,
      keterlambatanHari: terlambatHari,
      catatan: catatan,
      totalPembayaran: totalDenda,
      statusPembayaran: totalDenda > 0 ? 'Belum Lunas' : 'Lunas',
    );

    await supabase.from(_table).insert(pengembalian.toInsertJson());

    // 4. Update Status Peminjaman -> Kembali (ID 4)
    await supabase
        .from('peminjaman')
        .update({'status_peminjaman_id': 4})
        .eq('peminjaman_id', peminjamanId);

    // 5. Update Stok Alat
    await supabase
        .from('alat')
        .update({
          'jumlah_tersedia': alat.jumlahTersedia + peminjaman.jumlahPinjam,
        })
        .eq('alat_id', alat.alatId);

    // Log
    await _logService.logActivity(
      userId: petugasId,
      aktivitas: 'Proses Pengembalian',
      tabelTerkait: _table,
      deskripsi: 'Peminjaman ID: $peminjamanId dikembalikan',
    );
  }

  Future<List<PengembalianModel>> getAllPengembalian() async {
    final response = await supabase
        .from(_table)
        .select(
          '*, peminjaman(*, peminjam:users!peminjam_id(*)), petugas:users!petugas_id(*)',
        )
        .order('created_at', ascending: false);

    return (response as List)
        .map((e) => PengembalianModel.fromJson(e))
        .toList();
  }

  // Get Pengembalian by Peminjaman ID
  Future<PengembalianModel?> getPengembalianByPeminjamanId(
    int peminjamanId,
  ) async {
    final response = await supabase
        .from(_table)
        .select(
          '*, peminjaman(*, peminjam:users!peminjam_id(*), alat(*)), petugas:users!petugas_id(*)',
        )
        .eq('peminjaman_id', peminjamanId)
        .maybeSingle();

    if (response == null) return null;
    return PengembalianModel.fromJson(response);
  }

  // Update Status Pembayaran Denda
  Future<void> updateStatusPembayaran(
    int pengembalianId,
    String status,
    int petugasId,
  ) async {
    await supabase
        .from(_table)
        .update({'status_pembayaran': status})
        .eq('pengembalian_id', pengembalianId);

    await _logService.logActivity(
      userId: petugasId,
      aktivitas: 'Update Status Pembayaran',
      tabelTerkait: _table,
      idTerkait: pengembalianId,
      deskripsi: 'Status pembayaran: $status',
    );
  }

  // Get Pengembalian dengan Denda Belum Lunas
  Future<List<PengembalianModel>> getPengembalianBelumLunas() async {
    final response = await supabase
        .from(_table)
        .select(
          '*, peminjaman(*, peminjam:users!peminjam_id(*), alat(*)), petugas:users!petugas_id(*)',
        )
        .eq('status_pembayaran', 'Belum Lunas')
        .order('created_at', ascending: false);

    return (response as List)
        .map((e) => PengembalianModel.fromJson(e))
        .toList();
  }
}
