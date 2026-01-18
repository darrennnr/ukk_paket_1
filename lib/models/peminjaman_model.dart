// lib/models/peminjaman_model.dart
import 'package:paket_3_training/models/alat_model.dart';

class PeminjamanModel {
  final int peminjamanId;
  final int? peminjamId;
  final int? alatId;
  final int? petugasId;
  final String kodePeminjaman;
  final int jumlahPinjam;
  final DateTime? tanggalPengajuan;
  final DateTime? tanggalPinjam;
  final DateTime tanggalBerakhir;
  final String? keperluan;
  final int? statusPeminjamanId;
  final String? catatanPetugas;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Relational data (optional)
  final UserModel? peminjam;
  final AlatModel? alat;
  final UserModel? petugas;
  final StatusPeminjamanModel? statusPeminjaman;

  PeminjamanModel({
    required this.peminjamanId,
    this.peminjamId,
    this.alatId,
    this.petugasId,
    required this.kodePeminjaman,
    this.jumlahPinjam = 1,
    this.tanggalPengajuan,
    this.tanggalPinjam,
    required this.tanggalBerakhir,
    this.keperluan,
    this.statusPeminjamanId,
    this.catatanPetugas,
    this.createdAt,
    this.updatedAt,
    this.peminjam,
    this.alat,
    this.petugas,
    this.statusPeminjaman,
  });

  factory PeminjamanModel.fromJson(Map<String, dynamic> json) {
    return PeminjamanModel(
      peminjamanId: json['peminjaman_id'] as int,
      peminjamId: json['peminjam_id'] as int?,
      alatId: json['alat_id'] as int?,
      petugasId: json['petugas_id'] as int?,
      kodePeminjaman: json['kode_peminjaman'] as String,
      jumlahPinjam: json['jumlah_pinjam'] as int? ?? 1,
      tanggalPengajuan: json['tanggal_pengajuan'] != null
          ? DateTime.parse(json['tanggal_pengajuan'] as String)
          : null,
      tanggalPinjam: json['tanggal_pinjam'] != null
          ? DateTime.parse(json['tanggal_pinjam'] as String)
          : null,
      tanggalBerakhir: DateTime.parse(json['tanggal_berakhir'] as String),
      keperluan: json['keperluan'] as String?,
      statusPeminjamanId: json['status_peminjaman_id'] as int?,
      catatanPetugas: json['catatan_petugas'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      peminjam: json['peminjam'] != null
          ? UserModel.fromJson(json['peminjam'] as Map<String, dynamic>)
          : null,
      alat: json['alat'] != null
          ? AlatModel.fromJson(json['alat'] as Map<String, dynamic>)
          : null,
      petugas: json['petugas'] != null
          ? UserModel.fromJson(json['petugas'] as Map<String, dynamic>)
          : null,
      statusPeminjaman: json['status_peminjaman'] != null
          ? StatusPeminjamanModel.fromJson(
              json['status_peminjaman'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'peminjaman_id': peminjamanId,
      'peminjam_id': peminjamId,
      'alat_id': alatId,
      'petugas_id': petugasId,
      'kode_peminjaman': kodePeminjaman,
      'jumlah_pinjam': jumlahPinjam,
      'tanggal_pengajuan': tanggalPengajuan?.toIso8601String(),
      'tanggal_pinjam': tanggalPinjam?.toIso8601String(),
      'tanggal_berakhir': tanggalBerakhir.toIso8601String(),
      'keperluan': keperluan,
      'status_peminjaman_id': statusPeminjamanId,
      'catatan_petugas': catatanPetugas,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'peminjam_id': peminjamId,
      'alat_id': alatId,
      'petugas_id': petugasId,
      'kode_peminjaman': kodePeminjaman,
      'jumlah_pinjam': jumlahPinjam,
      'tanggal_pengajuan': tanggalPengajuan?.toIso8601String(),
      'tanggal_pinjam': tanggalPinjam?.toIso8601String(),
      'tanggal_berakhir': tanggalBerakhir.toIso8601String(),
      'keperluan': keperluan,
      'status_peminjaman_id': statusPeminjamanId,
      'catatan_petugas': catatanPetugas,
    };
  }

  PeminjamanModel copyWith({
    int? peminjamanId,
    int? peminjamId,
    int? alatId,
    int? petugasId,
    String? kodePeminjaman,
    int? jumlahPinjam,
    DateTime? tanggalPengajuan,
    DateTime? tanggalPinjam,
    DateTime? tanggalBerakhir,
    String? keperluan,
    int? statusPeminjamanId,
    String? catatanPetugas,
    DateTime? createdAt,
    DateTime? updatedAt,
    UserModel? peminjam,
    AlatModel? alat,
    UserModel? petugas,
    StatusPeminjamanModel? statusPeminjaman,
  }) {
    return PeminjamanModel(
      peminjamanId: peminjamanId ?? this.peminjamanId,
      peminjamId: peminjamId ?? this.peminjamId,
      alatId: alatId ?? this.alatId,
      petugasId: petugasId ?? this.petugasId,
      kodePeminjaman: kodePeminjaman ?? this.kodePeminjaman,
      jumlahPinjam: jumlahPinjam ?? this.jumlahPinjam,
      tanggalPengajuan: tanggalPengajuan ?? this.tanggalPengajuan,
      tanggalPinjam: tanggalPinjam ?? this.tanggalPinjam,
      tanggalBerakhir: tanggalBerakhir ?? this.tanggalBerakhir,
      keperluan: keperluan ?? this.keperluan,
      statusPeminjamanId: statusPeminjamanId ?? this.statusPeminjamanId,
      catatanPetugas: catatanPetugas ?? this.catatanPetugas,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      peminjam: peminjam ?? this.peminjam,
      alat: alat ?? this.alat,
      petugas: petugas ?? this.petugas,
      statusPeminjaman: statusPeminjaman ?? this.statusPeminjaman,
    );
  }

  bool get isOverdue {
    return DateTime.now().isAfter(tanggalBerakhir);
  }

  int get daysOverdue {
    if (!isOverdue) return 0;
    return DateTime.now().difference(tanggalBerakhir).inDays;
  }

  int get daysRemaining {
    if (isOverdue) return 0;
    return tanggalBerakhir.difference(DateTime.now()).inDays;
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

// REMOVE THE ENTIRE AlatModel CLASS - IT'S NOW IMPORTED FROM alat_model.dart

class StatusPeminjamanModel {
  final int id;
  final String? statusPeminjaman;

  StatusPeminjamanModel({required this.id, this.statusPeminjaman});

  factory StatusPeminjamanModel.fromJson(Map<String, dynamic> json) {
    return StatusPeminjamanModel(
      id: json['id'] as int,
      statusPeminjaman: json['status_peminjaman'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'status_peminjaman': statusPeminjaman};
  }
}