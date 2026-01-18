// lib\models\kategori_model.dart
class KategoriModel {
  final int kategoriId;
  final String namaKategori;
  final String? deskripsi;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  KategoriModel({
    required this.kategoriId,
    required this.namaKategori,
    this.deskripsi,
    this.createdAt,
    this.updatedAt,
  });

  // Factory constructor untuk membuat instance dari JSON
  factory KategoriModel.fromJson(Map<String, dynamic> json) {
    return KategoriModel(
      kategoriId: json['kategori_id'] as int,
      namaKategori: json['nama_kategori'] as String,
      deskripsi: json['deskripsi'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  // Method untuk convert instance ke JSON
  Map<String, dynamic> toJson() {
    return {
      'kategori_id': kategoriId,
      'nama_kategori': namaKategori,
      'deskripsi': deskripsi,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // Method untuk insert/update (tanpa kategori_id, created_at, updated_at)
  Map<String, dynamic> toInsertJson() {
    return {
      'nama_kategori': namaKategori,
      'deskripsi': deskripsi,
    };
  }

  // CopyWith method untuk immutability
  KategoriModel copyWith({
    int? kategoriId,
    String? namaKategori,
    String? deskripsi,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return KategoriModel(
      kategoriId: kategoriId ?? this.kategoriId,
      namaKategori: namaKategori ?? this.namaKategori,
      deskripsi: deskripsi ?? this.deskripsi,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}