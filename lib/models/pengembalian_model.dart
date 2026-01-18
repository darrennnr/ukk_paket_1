// lib/models/pengembalian_model.dart
import 'package:paket_3_training/models/alat_model.dart';

class PengembalianModel {
  final int pengembalianId;
  final int? peminjamanId;
  final int? petugasId;
  final DateTime? tanggalKembali;
  final String? kondisiAlat;
  final int jumlahKembali;
  final int? keterlambatanHari;
  final String? catatan;
  final DateTime? createdAt;
  final int? totalPembayaran;
  final String? statusPembayaran;
  
  // Relational data (optional)
  final PeminjamanModel? peminjaman;
  final UserModel? petugas;

  PengembalianModel({
    required this.pengembalianId,
    this.peminjamanId,
    this.petugasId,
    this.tanggalKembali,
    this.kondisiAlat = 'baik',
    required this.jumlahKembali,
    this.keterlambatanHari = 0,
    this.catatan,
    this.createdAt,
    this.totalPembayaran,
    this.statusPembayaran,
    this.peminjaman,
    this.petugas,
  });

  // Factory constructor untuk membuat instance dari JSON
  factory PengembalianModel.fromJson(Map<String, dynamic> json) {
    return PengembalianModel(
      pengembalianId: json['pengembalian_id'] as int,
      peminjamanId: json['peminjaman_id'] as int?,
      petugasId: json['petugas_id'] as int?,
      tanggalKembali: json['tanggal_kembali'] != null
          ? DateTime.parse(json['tanggal_kembali'] as String)
          : null,
      kondisiAlat: json['kondisi_alat'] as String? ?? 'baik',
      jumlahKembali: json['jumlah_kembali'] as int,
      keterlambatanHari: json['keterlambatan_hari'] as int? ?? 0,
      catatan: json['catatan'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      totalPembayaran: json['total_pembayaran'] as int?,
      statusPembayaran: json['status_pembayaran'] as String?,
      peminjaman: json['peminjaman'] != null
          ? PeminjamanModel.fromJson(
              json['peminjaman'] as Map<String, dynamic>)
          : null,
      petugas: json['petugas'] != null
          ? UserModel.fromJson(json['petugas'] as Map<String, dynamic>)
          : null,
    );
  }

  // Method untuk convert instance ke JSON
  Map<String, dynamic> toJson() {
    return {
      'pengembalian_id': pengembalianId,
      'peminjaman_id': peminjamanId,
      'petugas_id': petugasId,
      'tanggal_kembali': tanggalKembali?.toIso8601String(),
      'kondisi_alat': kondisiAlat,
      'jumlah_kembali': jumlahKembali,
      'keterlambatan_hari': keterlambatanHari,
      'catatan': catatan,
      'created_at': createdAt?.toIso8601String(),
      'total_pembayaran': totalPembayaran,
      'status_pembayaran': statusPembayaran,
    };
  }

  // Method untuk insert/update (tanpa pengembalian_id, created_at)
  Map<String, dynamic> toInsertJson() {
    return {
      'peminjaman_id': peminjamanId,
      'petugas_id': petugasId,
      'tanggal_kembali': tanggalKembali?.toIso8601String(),
      'kondisi_alat': kondisiAlat,
      'jumlah_kembali': jumlahKembali,
      'keterlambatan_hari': keterlambatanHari,
      'catatan': catatan,
      'total_pembayaran': totalPembayaran,
      'status_pembayaran': statusPembayaran,
    };
  }

  // CopyWith method untuk immutability
  PengembalianModel copyWith({
    int? pengembalianId,
    int? peminjamanId,
    int? petugasId,
    DateTime? tanggalKembali,
    String? kondisiAlat,
    int? jumlahKembali,
    int? keterlambatanHari,
    String? catatan,
    DateTime? createdAt,
    int? totalPembayaran,
    String? statusPembayaran,
    PeminjamanModel? peminjaman,
    UserModel? petugas,
  }) {
    return PengembalianModel(
      pengembalianId: pengembalianId ?? this.pengembalianId,
      peminjamanId: peminjamanId ?? this.peminjamanId,
      petugasId: petugasId ?? this.petugasId,
      tanggalKembali: tanggalKembali ?? this.tanggalKembali,
      kondisiAlat: kondisiAlat ?? this.kondisiAlat,
      jumlahKembali: jumlahKembali ?? this.jumlahKembali,
      keterlambatanHari: keterlambatanHari ?? this.keterlambatanHari,
      catatan: catatan ?? this.catatan,
      createdAt: createdAt ?? this.createdAt,
      totalPembayaran: totalPembayaran ?? this.totalPembayaran,
      statusPembayaran: statusPembayaran ?? this.statusPembayaran,
      peminjaman: peminjaman ?? this.peminjaman,
      petugas: petugas ?? this.petugas,
    );
  }

  // Helper methods
  bool get isLate => (keterlambatanHari ?? 0) > 0;
  bool get isPaid => statusPembayaran?.toLowerCase() == 'lunas';
  bool get isGoodCondition => kondisiAlat?.toLowerCase() == 'baik';

  // Hitung total denda berdasarkan keterlambatan dan harga per hari
  int calculateLateFee(double? hargaPerhari) {
    if (!isLate || hargaPerhari == null) return 0;
    return ((keterlambatanHari ?? 0) * hargaPerhari).toInt();
  }
}

// Import models untuk relasi
class PeminjamanModel {
  final int peminjamanId;
  final String kodePeminjaman;
  final int jumlahPinjam;
  final DateTime? tanggalPinjam;
  final DateTime tanggalBerakhir;
  final AlatModel? alat;
  final UserModel? peminjam;

  PeminjamanModel({
    required this.peminjamanId,
    required this.kodePeminjaman,
    required this.jumlahPinjam,
    this.tanggalPinjam,
    required this.tanggalBerakhir,
    this.alat,
    this.peminjam,
  });

  factory PeminjamanModel.fromJson(Map<String, dynamic> json) {
    return PeminjamanModel(
      peminjamanId: json['peminjaman_id'] as int,
      kodePeminjaman: json['kode_peminjaman'] as String,
      jumlahPinjam: json['jumlah_pinjam'] as int? ?? 1,
      tanggalPinjam: json['tanggal_pinjam'] != null
          ? DateTime.parse(json['tanggal_pinjam'] as String)
          : null,
      tanggalBerakhir: DateTime.parse(json['tanggal_berakhir'] as String),
      alat: json['alat'] != null
          ? AlatModel.fromJson(json['alat'] as Map<String, dynamic>)
          : null,
      peminjam: json['peminjam'] != null
          ? UserModel.fromJson(json['peminjam'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'peminjaman_id': peminjamanId,
      'kode_peminjaman': kodePeminjaman,
      'jumlah_pinjam': jumlahPinjam,
      'tanggal_pinjam': tanggalPinjam?.toIso8601String(),
      'tanggal_berakhir': tanggalBerakhir.toIso8601String(),
    };
  }
}

class UserModel {
  final int userId;
  final String username;
  final String namaLengkap;
  final String email;

  UserModel({
    required this.userId,
    required this.username,
    required this.namaLengkap,
    required this.email,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['user_id'] as int,
      username: json['username'] as String,
      namaLengkap: json['nama_lengkap'] as String,
      email: json['email'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'username': username,
      'nama_lengkap': namaLengkap,
      'email': email,
    };
  }
}

// AlatModel class DIHAPUS - sekarang diimport dari alat_model.dart