// lib/services/log_services.dart
import '../models/log_aktivitas_model.dart';
import '../main.dart'; // Akses ke variabel supabase global

class LogService {
  final String _table = 'log_aktivitas';

  // Log activity - auto called dari service lain
  Future<void> logActivity({
    required int userId,
    required String aktivitas,
    String? tabelTerkait,
    int? idTerkait,
    String? deskripsi,
  }) async {
    try {
      final log = LogAktivitasModel.create(
        userId: userId,
        aktivitas: aktivitas,
        tabelTerkait: tabelTerkait,
        idTerkait: idTerkait,
        deskripsi: deskripsi,
        userAgent:
            'Flutter App', // Bisa dikembangkan dengan package device_info
      );

      // Menggunakan toInsertJson sesuai model
      await supabase.from(_table).insert(log.toInsertJson());
    } catch (e) {
      print(
        'Gagal mencatat log: $e',
      ); // Fail-safe agar tidak menghentikan flow utama
    }
  }

  // Get All Logs (Admin)
  Future<List<LogAktivitasModel>> getAllLogs() async {
    final response = await supabase
        .from(_table)
        .select('*, user:users(*)') // Join dengan tabel users
        .order('created_at', ascending: false);

    return (response as List)
        .map((e) => LogAktivitasModel.fromJson(e))
        .toList();
  }
}
