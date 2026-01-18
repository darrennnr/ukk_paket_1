// lib/services/dashboard_services.dart
import '../main.dart';

class DashboardService {
  // Statistik untuk Admin Dashboard
  Future<Map<String, dynamic>> getAdminStats() async {
    // Total Users
    final usersData = await supabase.from('users').select();
    final usersCount = usersData.length;

    // Total Alat
    final alatData = await supabase.from('alat').select();
    final alatCount = alatData.length;

    // Total Kategori
    final kategoriData = await supabase.from('kategori').select();
    final kategoriCount = kategoriData.length;

    // Peminjaman Pending
    final pendingData = await supabase
        .from('peminjaman')
        .select()
        .eq('status_peminjaman_id', 1);
    final pendingCount = pendingData.length;

    // Peminjaman Aktif
    final activeData = await supabase
        .from('peminjaman')
        .select()
        .eq('status_peminjaman_id', 2);
    final activeCount = activeData.length;

    // Alat Tersedia
    final alatTersediaData = await supabase
        .from('alat')
        .select()
        .gt('jumlah_tersedia', 0);
    final alatTersediaCount = alatTersediaData.length;

    return {
      'total_users': usersCount,
      'total_alat': alatCount,
      'total_kategori': kategoriCount,
      'peminjaman_pending': pendingCount,
      'peminjaman_aktif': activeCount,
      'alat_tersedia': alatTersediaCount,
    };
  }

  // TAMBAHKAN di dalam class DashboardService, setelah getAdminStats()

  // Helper: Get total alat yang sedang dipinjam
  Future<int> _getAlatDipinjam() async {
    final result = await supabase
        .from('alat')
        .select('jumlah_total, jumlah_tersedia');

    int totalDipinjam = 0;
    for (var alat in result) {
      final total = alat['jumlah_total'] as int? ?? 0;
      final tersedia = alat['jumlah_tersedia'] as int? ?? 0;
      totalDipinjam += (total - tersedia);
    }

    return totalDipinjam;
  }

  // Tambahkan setelah method getPeminjamStats()

  // Get recent activities (last 10)
  Future<List<Map<String, dynamic>>> getRecentActivities({
    int limit = 10,
  }) async {
    try {
      final result = await supabase
          .from('log_aktivitas')
          .select(
            '*, user:users!log_aktivitas_user_id_fkey(user_id, nama_lengkap)',
          )
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(result);
    } catch (e) {
      print('Error fetching recent activities: $e');
      return [];
    }
  }

  // Get statistics trend (compare with previous period)
  Future<Map<String, String>> getStatisticsTrend() async {
    // Untuk implementasi lengkap, kita perlu query data periode sebelumnya
    // Untuk sementara, return empty map (akan dihapus dari UI)
    return {};
  }

  // Statistik untuk Petugas Dashboard
  Future<Map<String, dynamic>> getPetugasStats() async {
    // Peminjaman Menunggu Approval
    final menungguData = await supabase
        .from('peminjaman')
        .select()
        .eq('status_peminjaman_id', 1);
    final menungguCount = menungguData.length;

    // Peminjaman Aktif (yang perlu dimonitor)
    final activeData = await supabase
        .from('peminjaman')
        .select()
        .eq('status_peminjaman_id', 2);
    final activeCount = activeData.length;

    // Pengembalian Hari Ini
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final pengembalianTodayData = await supabase
        .from('pengembalian')
        .select()
        .gte('tanggal_kembali', startOfDay.toIso8601String());
    final pengembalianTodayCount = pengembalianTodayData.length;

    // Denda Belum Lunas
    final dendaBelumLunasData = await supabase
        .from('pengembalian')
        .select()
        .eq('status_pembayaran', 'Belum Lunas');
    final dendaBelumLunasCount = dendaBelumLunasData.length;

    return {
      'menunggu_approval': menungguCount,
      'peminjaman_aktif': activeCount,
      'pengembalian_hari_ini': pengembalianTodayCount,
      'denda_belum_lunas': dendaBelumLunasCount,
    };
  }

  // Statistik untuk Peminjam Dashboard
  Future<Map<String, dynamic>> getPeminjamStats(int userId) async {
    // Peminjaman Pending milik user
    final pendingData = await supabase
        .from('peminjaman')
        .select()
        .eq('peminjam_id', userId)
        .eq('status_peminjaman_id', 1);
    final pendingCount = pendingData.length;

    // Peminjaman Aktif milik user
    final activeData = await supabase
        .from('peminjaman')
        .select()
        .eq('peminjam_id', userId)
        .eq('status_peminjaman_id', 2);
    final activeCount = activeData.length;

    // Total Peminjaman milik user
    final totalData = await supabase
        .from('peminjaman')
        .select()
        .eq('peminjam_id', userId);
    final totalCount = totalData.length;

    // Alat Tersedia untuk dipinjam
    final alatTersediaData = await supabase
        .from('alat')
        .select()
        .gt('jumlah_tersedia', 0);
    final alatTersediaCount = alatTersediaData.length;

    return {
      'peminjaman_pending': pendingCount,
      'peminjaman_aktif': activeCount,
      'total_peminjaman': totalCount,
      'alat_tersedia': alatTersediaCount,
    };
  }
}
