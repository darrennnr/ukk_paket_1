// lib\models\alat_model.dart
class AlatModel {
  final int alatId;
  final int? kategoriId;
  final String kodeAlat;
  final String namaAlat;
  final String? kondisi;
  final int jumlahTotal;
  final int jumlahTersedia;
  final double? hargaPerhari;
  final String? fotoAlat;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  
  // Relational data (optional)
  final KategoriModel? kategori;

  AlatModel({
    required this.alatId,
    this.kategoriId,
    required this.kodeAlat,
    required this.namaAlat,
    this.kondisi = 'baik',
    this.jumlahTotal = 0,
    this.jumlahTersedia = 0,
    this.hargaPerhari,
    this.fotoAlat,
    this.createdAt,
    this.updatedAt,
    this.kategori,
  });

  // Factory constructor untuk membuat instance dari JSON
  factory AlatModel.fromJson(Map<String, dynamic> json) {
    return AlatModel(
      alatId: json['alat_id'] as int,
      kategoriId: json['kategori_id'] as int?,
      kodeAlat: json['kode_alat'] as String,
      namaAlat: json['nama_alat'] as String,
      kondisi: json['kondisi'] as String? ?? 'baik',
      jumlahTotal: json['jumlah_total'] as int? ?? 0,
      jumlahTersedia: json['jumlah_tersedia'] as int? ?? 0,
      hargaPerhari: json['harga_perhari'] != null
          ? (json['harga_perhari'] is int
              ? (json['harga_perhari'] as int).toDouble()
              : json['harga_perhari'] as double)
          : null,
      fotoAlat: json['foto_alat'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      kategori: json['kategori'] != null
          ? KategoriModel.fromJson(json['kategori'] as Map<String, dynamic>)
          : null,
    );
  }

  // Method untuk convert instance ke JSON
  Map<String, dynamic> toJson() {
    return {
      'alat_id': alatId,
      'kategori_id': kategoriId,
      'kode_alat': kodeAlat,
      'nama_alat': namaAlat,
      'kondisi': kondisi,
      'jumlah_total': jumlahTotal,
      'jumlah_tersedia': jumlahTersedia,
      'harga_perhari': hargaPerhari,
      'foto_alat': fotoAlat,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // Method untuk insert/update (tanpa alat_id, created_at, updated_at)
  Map<String, dynamic> toInsertJson() {
    return {
      'kategori_id': kategoriId,
      'kode_alat': kodeAlat,
      'nama_alat': namaAlat,
      'kondisi': kondisi,
      'jumlah_total': jumlahTotal,
      'jumlah_tersedia': jumlahTersedia,
      'harga_perhari': hargaPerhari,
      'foto_alat': fotoAlat,
    };
  }

  // CopyWith method untuk immutability
  AlatModel copyWith({
    int? alatId,
    int? kategoriId,
    String? kodeAlat,
    String? namaAlat,
    String? kondisi,
    int? jumlahTotal,
    int? jumlahTersedia,
    double? hargaPerhari,
    String? fotoAlat,
    DateTime? createdAt,
    DateTime? updatedAt,
    KategoriModel? kategori,
  }) {
    return AlatModel(
      alatId: alatId ?? this.alatId,
      kategoriId: kategoriId ?? this.kategoriId,
      kodeAlat: kodeAlat ?? this.kodeAlat,
      namaAlat: namaAlat ?? this.namaAlat,
      kondisi: kondisi ?? this.kondisi,
      jumlahTotal: jumlahTotal ?? this.jumlahTotal,
      jumlahTersedia: jumlahTersedia ?? this.jumlahTersedia,
      hargaPerhari: hargaPerhari ?? this.hargaPerhari,
      fotoAlat: fotoAlat ?? this.fotoAlat,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      kategori: kategori ?? this.kategori,
    );
  }

  // Helper method
  bool get isAvailable => jumlahTersedia > 0;
  bool get isGoodCondition => kondisi?.toLowerCase() == 'baik';
}

// Import untuk KategoriModel
class KategoriModel {
  final int kategoriId;
  final String namaKategori;
  final String? deskripsi;

  KategoriModel({
    required this.kategoriId,
    required this.namaKategori,
    this.deskripsi,
  });

  factory KategoriModel.fromJson(Map<String, dynamic> json) {
    return KategoriModel(
      kategoriId: json['kategori_id'] as int,
      namaKategori: json['nama_kategori'] as String,
      deskripsi: json['deskripsi'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'kategori_id': kategoriId,
      'nama_kategori': namaKategori,
      'deskripsi': deskripsi,
    };
  }
}