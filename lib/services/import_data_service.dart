// lib/services/import_data_service.dart
import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:crypto/crypto.dart';
import '../main.dart';

/// Result dari proses import
class ImportResult {
  final int totalRows;
  final int successCount;
  final int failedCount;
  final int skippedCount;
  final List<ImportError> errors;
  final Duration duration;

  ImportResult({
    required this.totalRows,
    required this.successCount,
    required this.failedCount,
    required this.skippedCount,
    required this.errors,
    required this.duration,
  });

  bool get hasErrors => errors.isNotEmpty;
  double get successRate => totalRows > 0 ? successCount / totalRows : 0;
}

/// Error dari satu row import
class ImportError {
  final int rowNumber;
  final String field;
  final String message;
  final dynamic value;

  ImportError({
    required this.rowNumber,
    required this.field,
    required this.message,
    this.value,
  });

  @override
  String toString() => 'Row $rowNumber: $field - $message (value: $value)';
}

/// Options untuk proses import
enum DuplicateHandling { skip, update, error }

class ImportOptions {
  final DuplicateHandling duplicateHandling;
  final bool stopOnError;
  final int batchSize;

  const ImportOptions({
    this.duplicateHandling = DuplicateHandling.skip,
    this.stopOnError = false,
    this.batchSize = 50,
  });
}

/// Service untuk import data dari file CSV, JSON, XLSX
class ImportDataService {
  // Mapping tabel ke kolom unique
  static const Map<String, List<String>> _uniqueConstraints = {
    'users': ['username', 'email'],
    'alat': ['kode_alat'],
    'peminjaman': ['kode_peminjaman'],
    'kategori': ['nama_kategori'],
    'role': ['role'],
    'status_peminjaman': ['status_peminjaman'],
  };

  // Mapping tabel ke primary key
  static const Map<String, String> _primaryKeys = {
    'users': 'user_id',
    'alat': 'alat_id',
    'kategori': 'kategori_id',
    'peminjaman': 'peminjaman_id',
    'pengembalian': 'pengembalian_id',
    'role': 'id',
    'status_peminjaman': 'id',
  };

  // Mapping FK dependencies
  static const Map<String, List<String>> _dependencies = {
    'role': [],
    'status_peminjaman': [],
    'kategori': [],
    'users': ['role'],
    'alat': ['kategori'],
    'peminjaman': ['users', 'alat', 'status_peminjaman'],
    'pengembalian': ['peminjaman', 'users'],
  };

  // Valid kondisi values
  static const List<String> _validKondisi = ['baik', 'rusak', 'sedang'];

  /// Get daftar tabel yang bisa diimport (urut berdasarkan dependency)
  List<String> getImportableTables() {
    return ['role', 'status_peminjaman', 'kategori', 'users', 'alat', 'peminjaman', 'pengembalian'];
  }

  /// Get dependencies untuk sebuah tabel
  List<String> getTableDependencies(String tableName) {
    return _dependencies[tableName] ?? [];
  }

  /// Parse file menjadi List<Map>
  Future<List<Map<String, dynamic>>> parseFile(PlatformFile file) async {
    final bytes = file.bytes;
    if (bytes == null) {
      throw Exception('File bytes is null');
    }

    final extension = file.extension?.toLowerCase();
    
    switch (extension) {
      case 'csv':
        return _parseCsv(bytes);
      case 'json':
        return _parseJson(bytes);
      case 'xlsx':
      case 'xls':
        return _parseExcel(bytes);
      default:
        throw Exception('Format file tidak didukung: $extension');
    }
  }

  /// Parse CSV file
  List<Map<String, dynamic>> _parseCsv(List<int> bytes) {
    final csvString = utf8.decode(bytes);
    final rows = const CsvToListConverter(eol: '\n', shouldParseNumbers: true).convert(csvString);
    
    if (rows.isEmpty) return [];
    
    // First row is header
    final headers = rows.first.map((e) => e.toString().trim().toLowerCase()).toList();
    final dataRows = rows.skip(1).toList();
    
    return dataRows.map((row) {
      final map = <String, dynamic>{};
      for (int i = 0; i < headers.length && i < row.length; i++) {
        map[headers[i]] = row[i];
      }
      return map;
    }).toList();
  }

  /// Parse JSON file
  List<Map<String, dynamic>> _parseJson(List<int> bytes) {
    final jsonString = utf8.decode(bytes);
    final decoded = json.decode(jsonString);
    
    if (decoded is List) {
      return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    } else if (decoded is Map && decoded.containsKey('data')) {
      // Support format { "data": [...] }
      return (decoded['data'] as List).map((e) => Map<String, dynamic>.from(e)).toList();
    }
    
    throw Exception('Format JSON tidak valid. Harus berupa array atau object dengan key "data"');
  }

  /// Parse Excel file
  List<Map<String, dynamic>> _parseExcel(List<int> bytes) {
    final excel = Excel.decodeBytes(bytes);
    final sheet = excel.tables.values.first;
    
    if (sheet.rows.isEmpty) return [];
    
    // First row is header
    final headerRow = sheet.rows.first;
    final headers = headerRow.map((cell) => 
      cell?.value?.toString().trim().toLowerCase() ?? ''
    ).toList();
    
    final dataRows = sheet.rows.skip(1).toList();
    
    return dataRows.map((row) {
      final map = <String, dynamic>{};
      for (int i = 0; i < headers.length && i < row.length; i++) {
        final cell = row[i];
        dynamic value = cell?.value;
        
        // Handle Excel date format
        if (value is int && value > 40000 && value < 60000) {
          // Likely an Excel date serial number
          value = _excelDateToDateTime(value);
        }
        
        map[headers[i]] = value;
      }
      return map;
    }).where((map) => map.values.any((v) => v != null && v.toString().isNotEmpty)).toList();
  }

  /// Convert Excel date serial to DateTime
  DateTime _excelDateToDateTime(int serial) {
    // Excel date serial starts from 1900-01-01 (serial = 1)
    // But Excel has a bug where it thinks 1900 is a leap year
    final base = DateTime(1899, 12, 30);
    return base.add(Duration(days: serial));
  }

  /// Hash password dengan SHA256
  String _hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  /// Validate satu row data
  Future<List<ImportError>> validateRow(
    Map<String, dynamic> row,
    int rowNumber,
    String tableName,
  ) async {
    final errors = <ImportError>[];

    switch (tableName) {
      case 'users':
        errors.addAll(_validateUserRow(row, rowNumber));
        break;
      case 'alat':
        errors.addAll(_validateAlatRow(row, rowNumber));
        break;
      case 'peminjaman':
        errors.addAll(_validatePeminjamanRow(row, rowNumber));
        break;
      case 'pengembalian':
        errors.addAll(_validatePengembalianRow(row, rowNumber));
        break;
      case 'kategori':
        errors.addAll(_validateKategoriRow(row, rowNumber));
        break;
    }

    return errors;
  }

  List<ImportError> _validateUserRow(Map<String, dynamic> row, int rowNumber) {
    final errors = <ImportError>[];
    
    // Validate required fields
    if (row['username'] == null || row['username'].toString().isEmpty) {
      errors.add(ImportError(rowNumber: rowNumber, field: 'username', message: 'Username wajib diisi'));
    }
    if (row['password'] == null || row['password'].toString().isEmpty) {
      errors.add(ImportError(rowNumber: rowNumber, field: 'password', message: 'Password wajib diisi'));
    }
    if (row['nama_lengkap'] == null || row['nama_lengkap'].toString().isEmpty) {
      errors.add(ImportError(rowNumber: rowNumber, field: 'nama_lengkap', message: 'Nama lengkap wajib diisi'));
    }
    if (row['email'] == null || row['email'].toString().isEmpty) {
      errors.add(ImportError(rowNumber: rowNumber, field: 'email', message: 'Email wajib diisi'));
    }
    
    // Validate email format
    final email = row['email']?.toString() ?? '';
    if (email.isNotEmpty && !_isValidEmail(email)) {
      errors.add(ImportError(rowNumber: rowNumber, field: 'email', message: 'Format email tidak valid', value: email));
    }
    
    return errors;
  }

  List<ImportError> _validateAlatRow(Map<String, dynamic> row, int rowNumber) {
    final errors = <ImportError>[];
    
    if (row['kode_alat'] == null || row['kode_alat'].toString().isEmpty) {
      errors.add(ImportError(rowNumber: rowNumber, field: 'kode_alat', message: 'Kode alat wajib diisi'));
    }
    if (row['nama_alat'] == null || row['nama_alat'].toString().isEmpty) {
      errors.add(ImportError(rowNumber: rowNumber, field: 'nama_alat', message: 'Nama alat wajib diisi'));
    }
    
    // Validate kondisi
    final kondisi = row['kondisi']?.toString().toLowerCase() ?? 'baik';
    if (!_validKondisi.contains(kondisi)) {
      errors.add(ImportError(
        rowNumber: rowNumber, 
        field: 'kondisi', 
        message: 'Kondisi harus salah satu dari: ${_validKondisi.join(", ")}',
        value: kondisi
      ));
    }
    
    // Validate numeric fields
    final jumlahTotal = _parseNumber(row['jumlah_total']);
    final jumlahTersedia = _parseNumber(row['jumlah_tersedia']);
    
    if (jumlahTotal != null && jumlahTersedia != null && jumlahTersedia > jumlahTotal) {
      errors.add(ImportError(
        rowNumber: rowNumber, 
        field: 'jumlah_tersedia', 
        message: 'Jumlah tersedia tidak boleh lebih dari jumlah total',
        value: '$jumlahTersedia > $jumlahTotal'
      ));
    }
    
    return errors;
  }

  List<ImportError> _validatePeminjamanRow(Map<String, dynamic> row, int rowNumber) {
    final errors = <ImportError>[];
    
    if (row['kode_peminjaman'] == null || row['kode_peminjaman'].toString().isEmpty) {
      errors.add(ImportError(rowNumber: rowNumber, field: 'kode_peminjaman', message: 'Kode peminjaman wajib diisi'));
    }
    if (row['tanggal_berakhir'] == null || row['tanggal_berakhir'].toString().isEmpty) {
      errors.add(ImportError(rowNumber: rowNumber, field: 'tanggal_berakhir', message: 'Tanggal berakhir wajib diisi'));
    }
    
    // Validate dates
    final tanggalPinjam = _parseDate(row['tanggal_pinjam']);
    final tanggalBerakhir = _parseDate(row['tanggal_berakhir']);
    
    if (tanggalPinjam != null && tanggalBerakhir != null && tanggalPinjam.isAfter(tanggalBerakhir)) {
      errors.add(ImportError(
        rowNumber: rowNumber, 
        field: 'tanggal_pinjam', 
        message: 'Tanggal pinjam harus sebelum tanggal berakhir'
      ));
    }
    
    return errors;
  }

  List<ImportError> _validatePengembalianRow(Map<String, dynamic> row, int rowNumber) {
    final errors = <ImportError>[];
    
    if (row['kode_peminjaman'] == null || row['kode_peminjaman'].toString().isEmpty) {
      errors.add(ImportError(rowNumber: rowNumber, field: 'kode_peminjaman', message: 'Kode peminjaman wajib diisi'));
    }
    if (row['jumlah_kembali'] == null) {
      errors.add(ImportError(rowNumber: rowNumber, field: 'jumlah_kembali', message: 'Jumlah kembali wajib diisi'));
    }
    
    // Validate kondisi_alat
    final kondisi = row['kondisi_alat']?.toString().toLowerCase() ?? 'baik';
    if (!_validKondisi.contains(kondisi)) {
      errors.add(ImportError(
        rowNumber: rowNumber, 
        field: 'kondisi_alat', 
        message: 'Kondisi alat harus salah satu dari: ${_validKondisi.join(", ")}',
        value: kondisi
      ));
    }
    
    return errors;
  }

  List<ImportError> _validateKategoriRow(Map<String, dynamic> row, int rowNumber) {
    final errors = <ImportError>[];
    
    if (row['nama_kategori'] == null || row['nama_kategori'].toString().isEmpty) {
      errors.add(ImportError(rowNumber: rowNumber, field: 'nama_kategori', message: 'Nama kategori wajib diisi'));
    }
    
    return errors;
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  int? _parseNumber(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value.toString());
  }

  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString());
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    try {
      return DateTime.parse(value.toString());
    } catch (_) {
      return null;
    }
  }

  /// Lookup FK ID berdasarkan nama
  Future<int?> lookupForeignKey(String tableName, String lookupColumn, dynamic value) async {
    if (value == null || value.toString().isEmpty) return null;
    
    try {
      final response = await supabase
        .from(tableName)
        .select(_primaryKeys[tableName] ?? 'id')
        .eq(lookupColumn, value.toString())
        .maybeSingle();
      
      if (response == null) return null;
      return response[_primaryKeys[tableName] ?? 'id'] as int?;
    } catch (e) {
      return null;
    }
  }

  /// Check apakah data sudah ada (untuk unique constraint)
  Future<Map<String, dynamic>?> checkExisting(String tableName, Map<String, dynamic> row) async {
    final uniqueCols = _uniqueConstraints[tableName];
    if (uniqueCols == null || uniqueCols.isEmpty) return null;
    
    for (final col in uniqueCols) {
      final value = row[col];
      if (value == null || value.toString().isEmpty) continue;
      
      try {
        final response = await supabase
          .from(tableName)
          .select()
          .eq(col, value.toString())
          .maybeSingle();
        
        if (response != null) return response;
      } catch (_) {}
    }
    
    return null;
  }

  /// Import data ke database
  Future<ImportResult> importData({
    required List<Map<String, dynamic>> rows,
    required String tableName,
    required ImportOptions options,
    Function(int processed, int total)? onProgress,
  }) async {
    final startTime = DateTime.now();
    final errors = <ImportError>[];
    int successCount = 0;
    int skippedCount = 0;
    int failedCount = 0;

    for (int i = 0; i < rows.length; i++) {
      final row = rows[i];
      final rowNumber = i + 2; // +2 karena header di row 1 dan index mulai dari 0
      
      try {
        // Validate row
        final validationErrors = await validateRow(row, rowNumber, tableName);
        if (validationErrors.isNotEmpty) {
          errors.addAll(validationErrors);
          failedCount++;
          if (options.stopOnError) break;
          continue;
        }

        // Prepare data with FK lookups
        final preparedData = await _prepareRowData(row, tableName, rowNumber, errors);
        if (preparedData == null) {
          failedCount++;
          if (options.stopOnError) break;
          continue;
        }

        // Check for existing data
        final existing = await checkExisting(tableName, row);
        
        if (existing != null) {
          switch (options.duplicateHandling) {
            case DuplicateHandling.skip:
              skippedCount++;
              continue;
            case DuplicateHandling.update:
              await _updateRow(tableName, existing, preparedData);
              successCount++;
              break;
            case DuplicateHandling.error:
              final uniqueCol = _uniqueConstraints[tableName]?.first ?? 'id';
              errors.add(ImportError(
                rowNumber: rowNumber,
                field: uniqueCol,
                message: 'Data sudah ada di database',
                value: row[uniqueCol],
              ));
              failedCount++;
              if (options.stopOnError) break;
              continue;
          }
        } else {
          // Insert new row
          await _insertRow(tableName, preparedData);
          successCount++;
        }
      } catch (e) {
        errors.add(ImportError(
          rowNumber: rowNumber,
          field: 'general',
          message: e.toString(),
        ));
        failedCount++;
        if (options.stopOnError) break;
      }

      // Report progress
      onProgress?.call(i + 1, rows.length);
    }

    return ImportResult(
      totalRows: rows.length,
      successCount: successCount,
      failedCount: failedCount,
      skippedCount: skippedCount,
      errors: errors,
      duration: DateTime.now().difference(startTime),
    );
  }

  /// Prepare row data dengan FK lookups dan transformasi
  Future<Map<String, dynamic>?> _prepareRowData(
    Map<String, dynamic> row, 
    String tableName, 
    int rowNumber,
    List<ImportError> errors,
  ) async {
    final data = <String, dynamic>{};

    switch (tableName) {
      case 'kategori':
        data['nama_kategori'] = row['nama_kategori']?.toString();
        data['deskripsi'] = row['deskripsi']?.toString();
        break;

      case 'role':
        data['role'] = row['role']?.toString();
        break;

      case 'status_peminjaman':
        data['status_peminjaman'] = row['status_peminjaman']?.toString();
        break;

      case 'users':
        data['username'] = row['username']?.toString();
        data['password'] = _hashPassword(row['password'].toString());
        data['nama_lengkap'] = row['nama_lengkap']?.toString();
        data['email'] = row['email']?.toString();
        data['no_telepon'] = row['no_telepon']?.toString();
        
        // Lookup role_id dari role_name
        if (row['role_name'] != null || row['role'] != null) {
          final roleName = row['role_name'] ?? row['role'];
          final roleId = await lookupForeignKey('role', 'role', roleName);
          if (roleId == null) {
            errors.add(ImportError(
              rowNumber: rowNumber,
              field: 'role_name',
              message: 'Role "$roleName" tidak ditemukan',
              value: roleName,
            ));
            return null;
          }
          data['role_id'] = roleId;
        }
        break;

      case 'alat':
        data['kode_alat'] = row['kode_alat']?.toString();
        data['nama_alat'] = row['nama_alat']?.toString();
        data['kondisi'] = row['kondisi']?.toString().toLowerCase() ?? 'baik';
        data['jumlah_total'] = _parseNumber(row['jumlah_total']) ?? 0;
        data['jumlah_tersedia'] = _parseNumber(row['jumlah_tersedia']) ?? data['jumlah_total'];
        data['harga_perhari'] = _parseDouble(row['harga_perhari']);
        data['foto_alat'] = row['foto_alat']?.toString();
        
        // Lookup kategori_id dari nama_kategori
        if (row['nama_kategori'] != null) {
          final kategoriId = await lookupForeignKey('kategori', 'nama_kategori', row['nama_kategori']);
          if (kategoriId == null) {
            errors.add(ImportError(
              rowNumber: rowNumber,
              field: 'nama_kategori',
              message: 'Kategori "${row['nama_kategori']}" tidak ditemukan',
              value: row['nama_kategori'],
            ));
            return null;
          }
          data['kategori_id'] = kategoriId;
        }
        break;

      case 'peminjaman':
        data['kode_peminjaman'] = row['kode_peminjaman']?.toString();
        data['jumlah_pinjam'] = _parseNumber(row['jumlah_pinjam']) ?? 1;
        data['tanggal_pinjam'] = _parseDate(row['tanggal_pinjam'])?.toIso8601String();
        data['tanggal_berakhir'] = _parseDate(row['tanggal_berakhir'])?.toIso8601String();
        data['keperluan'] = row['keperluan']?.toString();
        data['catatan_petugas'] = row['catatan_petugas']?.toString();
        
        // Lookup peminjam_id dari username
        if (row['username_peminjam'] != null) {
          final userId = await lookupForeignKey('users', 'username', row['username_peminjam']);
          if (userId == null) {
            errors.add(ImportError(
              rowNumber: rowNumber,
              field: 'username_peminjam',
              message: 'User "${row['username_peminjam']}" tidak ditemukan',
              value: row['username_peminjam'],
            ));
            return null;
          }
          data['peminjam_id'] = userId;
        }
        
        // Lookup alat_id dari kode_alat
        if (row['kode_alat'] != null) {
          final alatId = await lookupForeignKey('alat', 'kode_alat', row['kode_alat']);
          if (alatId == null) {
            errors.add(ImportError(
              rowNumber: rowNumber,
              field: 'kode_alat',
              message: 'Alat "${row['kode_alat']}" tidak ditemukan',
              value: row['kode_alat'],
            ));
            return null;
          }
          data['alat_id'] = alatId;
        }
        
        // Lookup status_peminjaman_id
        if (row['status_peminjaman'] != null) {
          final statusId = await lookupForeignKey('status_peminjaman', 'status_peminjaman', row['status_peminjaman']);
          if (statusId == null) {
            errors.add(ImportError(
              rowNumber: rowNumber,
              field: 'status_peminjaman',
              message: 'Status "${row['status_peminjaman']}" tidak ditemukan',
              value: row['status_peminjaman'],
            ));
            return null;
          }
          data['status_peminjaman_id'] = statusId;
        }
        break;

      case 'pengembalian':
        data['tanggal_kembali'] = _parseDate(row['tanggal_kembali'])?.toIso8601String();
        data['kondisi_alat'] = row['kondisi_alat']?.toString().toLowerCase() ?? 'baik';
        data['jumlah_kembali'] = _parseNumber(row['jumlah_kembali']) ?? 1;
        data['keterlambatan_hari'] = _parseNumber(row['keterlambatan_hari']) ?? 0;
        data['catatan'] = row['catatan']?.toString();
        data['total_pembayaran'] = _parseNumber(row['total_pembayaran']);
        data['status_pembayaran'] = row['status_pembayaran']?.toString();
        
        // Lookup peminjaman_id dari kode_peminjaman
        if (row['kode_peminjaman'] != null) {
          final peminjamanId = await lookupForeignKey('peminjaman', 'kode_peminjaman', row['kode_peminjaman']);
          if (peminjamanId == null) {
            errors.add(ImportError(
              rowNumber: rowNumber,
              field: 'kode_peminjaman',
              message: 'Peminjaman "${row['kode_peminjaman']}" tidak ditemukan',
              value: row['kode_peminjaman'],
            ));
            return null;
          }
          data['peminjaman_id'] = peminjamanId;
        }
        
        // Lookup petugas_id dari username
        if (row['username_petugas'] != null) {
          final petugasId = await lookupForeignKey('users', 'username', row['username_petugas']);
          if (petugasId == null) {
            errors.add(ImportError(
              rowNumber: rowNumber,
              field: 'username_petugas',
              message: 'User "${row['username_petugas']}" tidak ditemukan',
              value: row['username_petugas'],
            ));
            return null;
          }
          data['petugas_id'] = petugasId;
        }
        break;

      default:
        // Copy all fields as-is
        data.addAll(row);
    }

    // Remove null values
    data.removeWhere((key, value) => value == null);
    
    return data;
  }

  /// Insert row ke database
  Future<void> _insertRow(String tableName, Map<String, dynamic> data) async {
    await supabase.from(tableName).insert(data);
  }

  /// Update row di database
  Future<void> _updateRow(String tableName, Map<String, dynamic> existing, Map<String, dynamic> newData) async {
    final pk = _primaryKeys[tableName] ?? 'id';
    final id = existing[pk];
    await supabase.from(tableName).update(newData).eq(pk, id);
  }

  /// Generate template CSV untuk sebuah tabel
  String generateTemplateCsv(String tableName) {
    final headers = getTemplateHeaders(tableName);
    return headers.join(',');
  }

  /// Get template headers untuk sebuah tabel
  List<String> getTemplateHeaders(String tableName) {
    switch (tableName) {
      case 'kategori':
        return ['nama_kategori', 'deskripsi'];
      case 'role':
        return ['role'];
      case 'status_peminjaman':
        return ['status_peminjaman'];
      case 'users':
        return ['username', 'password', 'nama_lengkap', 'email', 'no_telepon', 'role_name'];
      case 'alat':
        return ['kode_alat', 'nama_alat', 'kondisi', 'jumlah_total', 'jumlah_tersedia', 'harga_perhari', 'foto_alat', 'nama_kategori'];
      case 'peminjaman':
        return ['kode_peminjaman', 'username_peminjam', 'kode_alat', 'jumlah_pinjam', 'tanggal_pinjam', 'tanggal_berakhir', 'keperluan', 'status_peminjaman'];
      case 'pengembalian':
        return ['kode_peminjaman', 'username_petugas', 'tanggal_kembali', 'kondisi_alat', 'jumlah_kembali', 'keterlambatan_hari', 'catatan', 'total_pembayaran', 'status_pembayaran'];
      default:
        return [];
    }
  }

  /// Get contoh data untuk template
  List<String> getTemplateExampleRow(String tableName) {
    switch (tableName) {
      case 'kategori':
        return ['Elektronik', 'Alat-alat elektronik'];
      case 'role':
        return ['admin'];
      case 'status_peminjaman':
        return ['pending'];
      case 'users':
        return ['john_doe', 'password123', 'John Doe', 'john@email.com', '081234567890', 'peminjam'];
      case 'alat':
        return ['ALT001', 'Laptop Lenovo', 'baik', '10', '10', '50000', '', 'Elektronik'];
      case 'peminjaman':
        return ['PMJ001', 'john_doe', 'ALT001', '1', '2026-01-01', '2026-01-07', 'Untuk project', 'pending'];
      case 'pengembalian':
        return ['PMJ001', 'admin', '2026-01-05', 'baik', '1', '0', 'Dikembalikan tepat waktu', '0', 'lunas'];
      default:
        return [];
    }
  }
}
