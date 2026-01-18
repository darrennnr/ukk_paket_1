// lib\models\status_peminjaman_model.dart
class StatusPeminjamanModel {
  final int id;
  final String? statusPeminjaman;

  StatusPeminjamanModel({
    required this.id,
    this.statusPeminjaman,
  });

  // Factory constructor untuk membuat instance dari JSON
  factory StatusPeminjamanModel.fromJson(Map<String, dynamic> json) {
    return StatusPeminjamanModel(
      id: json['id'] as int,
      statusPeminjaman: json['status_peminjaman'] as String?,
    );
  }

  // Method untuk convert instance ke JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status_peminjaman': statusPeminjaman,
    };
  }

  // Method untuk insert/update
  Map<String, dynamic> toInsertJson() {
    return {
      'status_peminjaman': statusPeminjaman,
    };
  }

  // CopyWith method untuk immutability
  StatusPeminjamanModel copyWith({
    int? id,
    String? statusPeminjaman,
  }) {
    return StatusPeminjamanModel(
      id: id ?? this.id,
      statusPeminjaman: statusPeminjaman ?? this.statusPeminjaman,
    );
  }

  // Helper methods untuk checking status
  bool isPending() => statusPeminjaman?.toLowerCase() == 'pending' || 
                      statusPeminjaman?.toLowerCase() == 'menunggu';
  bool isApproved() => statusPeminjaman?.toLowerCase() == 'disetujui' || 
                       statusPeminjaman?.toLowerCase() == 'approved';
  bool isRejected() => statusPeminjaman?.toLowerCase() == 'ditolak' || 
                       statusPeminjaman?.toLowerCase() == 'rejected';
  bool isActive() => statusPeminjaman?.toLowerCase() == 'dipinjam' || 
                     statusPeminjaman?.toLowerCase() == 'active';
  bool isReturned() => statusPeminjaman?.toLowerCase() == 'dikembalikan' || 
                       statusPeminjaman?.toLowerCase() == 'returned';
  bool isCancelled() => statusPeminjaman?.toLowerCase() == 'dibatalkan' || 
                        statusPeminjaman?.toLowerCase() == 'cancelled';
}