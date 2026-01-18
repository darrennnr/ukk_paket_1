// lib/services/peminjaman_services.dart
import 'package:paket_3_training/models/alat_model.dart';

import '../models/peminjaman_model.dart';
import '../main.dart';
import 'log_services.dart';

class PeminjamanService {
  final String _table = 'peminjaman';
  final LogService _logService = LogService();

  // Status Constants
  static const int STATUS_PENDING = 1;
  static const int STATUS_DIPINJAM = 2; // Approved
  static const int STATUS_DITOLAK = 3;
  static const int STATUS_KEMBALI = 4;

  // Ajukan Peminjaman
  Future<void> ajukanPeminjaman(PeminjamanModel peminjaman) async {
    // 1. Cek duplikasi peminjaman aktif
    final hasActive = await _hasActiveLoan(
      peminjaman.peminjamId!,
      peminjaman.alatId!,
    );

    if (hasActive) {
      throw Exception('Anda masih memiliki peminjaman aktif untuk alat ini');
    }

    // 2. Cek Ketersediaan Stok
    final alatData = await supabase
        .from('alat')
        .select()
        .eq('alat_id', peminjaman.alatId!)
        .single();
    final alat = AlatModel.fromJson(alatData);

    if (alat.jumlahTersedia < peminjaman.jumlahPinjam) {
      throw Exception('Stok alat tidak mencukupi');
    }

    // 3. Insert Peminjaman (Status Pending)
    final insertData = peminjaman
        .copyWith(
          statusPeminjamanId: STATUS_PENDING,
          tanggalPengajuan: DateTime.now(), // Set waktu pengajuan
        )
        .toInsertJson();

    final response = await supabase
        .from(_table)
        .insert(insertData)
        .select()
        .single();
    final newPeminjaman = PeminjamanModel.fromJson(response);

    // Log
    await _logService.logActivity(
      userId: peminjaman.peminjamId!,
      aktivitas: 'Ajukan Peminjaman',
      tabelTerkait: _table,
      idTerkait: newPeminjaman.peminjamanId,
      deskripsi: 'Kode: ${newPeminjaman.kodePeminjaman}',
    );
  }

  // Validasi: Cek apakah user sudah meminjam alat yang sama dan masih aktif
  Future<bool> _hasActiveLoan(int userId, int alatId) async {
    final activeLoan = await supabase
        .from(_table)
        .select()
        .eq('peminjam_id', userId)
        .eq('alat_id', alatId)
        .inFilter('status_peminjaman_id', [1, 2]) // Pending atau Dipinjam
        .maybeSingle();

    return activeLoan != null;
  }

  // Approve Peminjaman (Petugas Only)
  Future<void> approvePeminjaman(int peminjamanId, int petugasId) async {
    // Logic: Update status -> Kurangi Stok Alat

    // Ambil data peminjaman untuk tahu alat_id dan jumlah
    final pinjamData = await supabase
        .from(_table)
        .select()
        .eq('peminjaman_id', peminjamanId)
        .single();
    final peminjaman = PeminjamanModel.fromJson(pinjamData);

    // Ambil data alat saat ini
    final alatData = await supabase
        .from('alat')
        .select()
        .eq('alat_id', peminjaman.alatId!)
        .single();
    final alat = AlatModel.fromJson(alatData);

    if (alat.jumlahTersedia < peminjaman.jumlahPinjam) {
      throw Exception('Stok saat ini tidak mencukupi untuk disetujui');
    }

    // Update Status Peminjaman & Set Petugas
    await supabase
        .from(_table)
        .update({
          'status_peminjaman_id': STATUS_DIPINJAM,
          'petugas_id': petugasId,
          'tanggal_pinjam': DateTime.now().toIso8601String(),
        })
        .eq('peminjaman_id', peminjamanId);

    // Update Stok Alat (Kurangi)
    await supabase
        .from('alat')
        .update({
          'jumlah_tersedia': alat.jumlahTersedia - peminjaman.jumlahPinjam,
        })
        .eq('alat_id', alat.alatId);

    // Log
    await _logService.logActivity(
      userId: petugasId,
      aktivitas: 'Approve Peminjaman',
      tabelTerkait: _table,
      idTerkait: peminjamanId,
    );
  }

  // Reject Peminjaman
  Future<void> rejectPeminjaman(
    int peminjamanId,
    int petugasId,
    String catatan,
  ) async {
    await supabase
        .from(_table)
        .update({
          'status_peminjaman_id': STATUS_DITOLAK,
          'petugas_id': petugasId,
          'catatan_petugas': catatan,
        })
        .eq('peminjaman_id', peminjamanId);

    await _logService.logActivity(
      userId: petugasId,
      aktivitas: 'Reject Peminjaman',
      tabelTerkait: _table,
      idTerkait: peminjamanId,
    );
  }

  // Get All Menunggu (Untuk Dashboard Petugas)
  Future<List<PeminjamanModel>> getAllPeminjamanMenunggu() async {
    final response = await supabase
        .from(_table)
        .select(
          '*, peminjam:users!peminjam_id(*), alat(*), status_peminjaman(*)',
        )
        .eq('status_peminjaman_id', STATUS_PENDING)
        .order('tanggal_pengajuan', ascending: true);

    return (response as List).map((e) => PeminjamanModel.fromJson(e)).toList();
  }

  // Get Peminjaman By ID
  Future<PeminjamanModel?> getPeminjamanById(int peminjamanId) async {
    final response = await supabase
        .from(_table)
        .select(
          '*, peminjam:users!peminjam_id(*), alat(*), status_peminjaman(*), petugas:users!petugas_id(*)',
        )
        .eq('peminjaman_id', peminjamanId)
        .maybeSingle();

    if (response == null) return null;
    return PeminjamanModel.fromJson(response);
  }

  // Get Peminjaman By User (History Peminjam)
  Future<List<PeminjamanModel>> getPeminjamanByUser(int userId) async {
    final response = await supabase
        .from(_table)
        .select('*, alat(*), status_peminjaman(*)')
        .eq('peminjam_id', userId)
        .order('created_at', ascending: false);

    return (response as List).map((e) => PeminjamanModel.fromJson(e)).toList();
  }

  // Get All Peminjaman yang Sedang Dipinjam (Status ID = 2)
  Future<List<PeminjamanModel>> getAllPeminjamanAktif() async {
    final response = await supabase
        .from(_table)
        .select(
          '*, peminjam:users!peminjam_id(*), alat(*), status_peminjaman(*), petugas:users!petugas_id(*)',
        )
        .eq('status_peminjaman_id', STATUS_DIPINJAM)
        .order('tanggal_pinjam', ascending: true);

    return (response as List).map((e) => PeminjamanModel.fromJson(e)).toList();
  }

  // Get All Peminjaman (Untuk Admin - Semua Status)
  Future<List<PeminjamanModel>> getAllPeminjaman() async {
    final response = await supabase
        .from(_table)
        .select(
          '*, peminjam:users!peminjam_id(*), alat(*), status_peminjaman(*), petugas:users!petugas_id(*)',
        )
        .order('created_at', ascending: false);

    return (response as List).map((e) => PeminjamanModel.fromJson(e)).toList();
  }

  // Update Peminjaman (untuk edit data peminjaman yang masih pending)
  Future<void> updatePeminjaman(PeminjamanModel peminjaman) async {
    // Hanya bisa update jika masih pending
    final currentData = await supabase
        .from(_table)
        .select()
        .eq('peminjaman_id', peminjaman.peminjamanId)
        .single();

    if (currentData['status_peminjaman_id'] != STATUS_PENDING) {
      throw Exception('Tidak dapat mengubah peminjaman yang sudah diproses');
    }

    await supabase
        .from(_table)
        .update(peminjaman.toInsertJson())
        .eq('peminjaman_id', peminjaman.peminjamanId);

    await _logService.logActivity(
      userId: peminjaman.peminjamId!,
      aktivitas: 'Update Peminjaman',
      tabelTerkait: _table,
      idTerkait: peminjaman.peminjamanId,
    );
  }

  // Cancel/Delete Peminjaman (hanya jika masih pending)
  Future<void> cancelPeminjaman(int peminjamanId, int userId) async {
    final currentData = await supabase
        .from(_table)
        .select()
        .eq('peminjaman_id', peminjamanId)
        .single();

    if (currentData['status_peminjaman_id'] != STATUS_PENDING) {
      throw Exception('Tidak dapat membatalkan peminjaman yang sudah diproses');
    }

    await supabase.from(_table).delete().eq('peminjaman_id', peminjamanId);

    await _logService.logActivity(
      userId: userId,
      aktivitas: 'Cancel Peminjaman',
      tabelTerkait: _table,
      idTerkait: peminjamanId,
    );
  }
}
