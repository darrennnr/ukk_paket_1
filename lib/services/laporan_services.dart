// lib/services/laporan_services.dart
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../models/peminjaman_model.dart';
import '../models/pengembalian_model.dart' hide PeminjamanModel;
import '../main.dart';

class LaporanService {
  final _dateFormat = DateFormat('dd/MM/yyyy');

  // ============================================================================
  // DATA FETCHING WITH FILTERS
  // ============================================================================

  /// Get peminjaman data with comprehensive filters
  Future<List<PeminjamanModel>> getLaporanPeminjamanFiltered({
    DateTime? startDate,
    DateTime? endDate,
    int? statusId,
    int? alatId,
    int? peminjamId,
  }) async {
    var query = supabase.from('peminjaman').select(
      '*, peminjam:users!peminjam_id(*), alat(*), status_peminjaman(*), petugas:users!petugas_id(*)',
    );

    // Apply date filters
    if (startDate != null) {
      query = query.gte('tanggal_pengajuan', startDate.toIso8601String());
    }
    if (endDate != null) {
      // Add 1 day to end date to include the entire day
      final endOfDay = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
      query = query.lte('tanggal_pengajuan', endOfDay.toIso8601String());
    }

    // Apply additional filters
    if (statusId != null) {
      query = query.eq('status_peminjaman_id', statusId);
    }
    if (alatId != null) {
      query = query.eq('alat_id', alatId);
    }
    if (peminjamId != null) {
      query = query.eq('peminjam_id', peminjamId);
    }

    final response = await query.order('tanggal_pengajuan', ascending: false);
    return (response as List).map((e) => PeminjamanModel.fromJson(e)).toList();
  }

  /// Get pengembalian data with comprehensive filters
  Future<List<PengembalianModel>> getLaporanPengembalianFiltered({
    DateTime? startDate,
    DateTime? endDate,
    String? kondisiAlat,
    String? statusPembayaran,
    int? alatId,
    int? peminjamId,
  }) async {
    var query = supabase.from('pengembalian').select(
      '*, peminjaman(*, alat(*), peminjam:users!peminjam_id(*)), petugas:users!petugas_id(*)',
    );

    // Apply date filters
    if (startDate != null) {
      query = query.gte('tanggal_kembali', startDate.toIso8601String());
    }
    if (endDate != null) {
      final endOfDay = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
      query = query.lte('tanggal_kembali', endOfDay.toIso8601String());
    }

    // Apply additional filters
    if (kondisiAlat != null && kondisiAlat.isNotEmpty) {
      query = query.eq('kondisi_alat', kondisiAlat);
    }
    if (statusPembayaran != null && statusPembayaran.isNotEmpty) {
      query = query.eq('status_pembayaran', statusPembayaran);
    }

    final response = await query.order('tanggal_kembali', ascending: false);
    
    var results = (response as List).map((e) => PengembalianModel.fromJson(e)).toList();

    // Client-side filtering for alat and peminjam (nested relations)
    if (alatId != null) {
      results = results.where((p) => p.peminjaman?.alat?.alatId == alatId).toList();
    }
    if (peminjamId != null) {
      results = results.where((p) => p.peminjaman?.peminjam?.userId == peminjamId).toList();
    }

    return results;
  }

  // ============================================================================
  // PDF GENERATION
  // ============================================================================

  /// Generate PDF for peminjaman report
  Future<Uint8List> generatePeminjamanPDF({
    required String title,
    required List<PeminjamanModel> data,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return [
            // Header
            pw.Header(
              level: 0,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(title, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Periode: ${startDate != null ? _dateFormat.format(startDate) : 'Awal'} - ${endDate != null ? _dateFormat.format(endDate) : 'Sekarang'}',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(
                    'Tanggal Cetak: ${_dateFormat.format(DateTime.now())}',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 10),

            // Summary
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(width: 0.5),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  _buildPdfSummaryItem('Total Data', '${data.length}'),
                  _buildPdfSummaryItem('Total Item', '${data.fold<int>(0, (sum, p) => sum + p.jumlahPinjam)}'),
                  _buildPdfSummaryItem('Pending', '${data.where((p) => p.statusPeminjamanId == 1).length}'),
                  _buildPdfSummaryItem('Dipinjam', '${data.where((p) => p.statusPeminjamanId == 2).length}'),
                  _buildPdfSummaryItem('Dikembalikan', '${data.where((p) => p.statusPeminjamanId == 4).length}'),
                ],
              ),
            ),
            pw.SizedBox(height: 15),

            // Table
            pw.Table.fromTextArray(
              context: context,
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
              cellStyle: const pw.TextStyle(fontSize: 8),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
              cellHeight: 25,
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.centerLeft,
                3: pw.Alignment.center,
                4: pw.Alignment.center,
                5: pw.Alignment.center,
                6: pw.Alignment.center,
              },
              headers: ['Kode', 'Peminjam', 'Alat', 'Jumlah', 'Tgl Pinjam', 'Tgl Berakhir', 'Status'],
              data: data.map((item) => [
                item.kodePeminjaman,
                item.peminjam?.namaLengkap ?? '-',
                item.alat?.namaAlat ?? '-',
                '${item.jumlahPinjam}',
                item.tanggalPinjam != null ? _dateFormat.format(item.tanggalPinjam!) : '-',
                _dateFormat.format(item.tanggalBerakhir),
                item.statusPeminjaman?.statusPeminjaman ?? '-',
              ]).toList(),
            ),
          ];
        },
      ),
    );

    return await pdf.save();
  }

  /// Generate PDF for pengembalian report
  Future<Uint8List> generatePengembalianPDF({
    required String title,
    required List<PengembalianModel> data,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final pdf = pw.Document();
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          final totalDenda = data.fold<int>(0, (sum, p) => sum + (p.totalPembayaran ?? 0));
          final totalTerlambat = data.where((p) => (p.keterlambatanHari ?? 0) > 0).length;

          return [
            // Header
            pw.Header(
              level: 0,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(title, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Periode: ${startDate != null ? _dateFormat.format(startDate) : 'Awal'} - ${endDate != null ? _dateFormat.format(endDate) : 'Sekarang'}',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(
                    'Tanggal Cetak: ${_dateFormat.format(DateTime.now())}',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 10),

            // Summary
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(width: 0.5),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  _buildPdfSummaryItem('Total Data', '${data.length}'),
                  _buildPdfSummaryItem('Terlambat', '$totalTerlambat'),
                  _buildPdfSummaryItem('Kondisi Baik', '${data.where((p) => p.kondisiAlat?.toLowerCase() == 'baik').length}'),
                  _buildPdfSummaryItem('Total Denda', currencyFormat.format(totalDenda)),
                ],
              ),
            ),
            pw.SizedBox(height: 15),

            // Table
            pw.Table.fromTextArray(
              context: context,
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
              cellStyle: const pw.TextStyle(fontSize: 8),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
              cellHeight: 25,
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.centerLeft,
                3: pw.Alignment.center,
                4: pw.Alignment.center,
                5: pw.Alignment.center,
                6: pw.Alignment.centerRight,
              },
              headers: ['Kode', 'Peminjam', 'Alat', 'Tgl Kembali', 'Kondisi', 'Terlambat', 'Denda'],
              data: data.map((item) => [
                item.peminjaman?.kodePeminjaman ?? '-',
                item.peminjaman?.peminjam?.namaLengkap ?? '-',
                item.peminjaman?.alat?.namaAlat ?? '-',
                item.tanggalKembali != null ? _dateFormat.format(item.tanggalKembali!) : '-',
                item.kondisiAlat ?? '-',
                '${item.keterlambatanHari ?? 0} hari',
                currencyFormat.format(item.totalPembayaran ?? 0),
              ]).toList(),
            ),
          ];
        },
      ),
    );

    return await pdf.save();
  }

  pw.Widget _buildPdfSummaryItem(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(value, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 2),
        pw.Text(label, style: const pw.TextStyle(fontSize: 9)),
      ],
    );
  }

  // ============================================================================
  // CSV/EXCEL GENERATION
  // ============================================================================

  /// Generate CSV string for peminjaman data
  String generatePeminjamanCSV(List<PeminjamanModel> data) {
    final buffer = StringBuffer();
    
    // Header
    buffer.writeln('Kode Peminjaman,Peminjam,Email,Alat,Jumlah Pinjam,Tanggal Pengajuan,Tanggal Pinjam,Tanggal Berakhir,Status,Keperluan,Catatan Petugas');
    
    // Data rows
    for (final item in data) {
      buffer.writeln([
        _escapeCSV(item.kodePeminjaman),
        _escapeCSV(item.peminjam?.namaLengkap ?? '-'),
        _escapeCSV(item.peminjam?.email ?? '-'),
        _escapeCSV(item.alat?.namaAlat ?? '-'),
        item.jumlahPinjam,
        item.tanggalPengajuan != null ? _dateFormat.format(item.tanggalPengajuan!) : '-',
        item.tanggalPinjam != null ? _dateFormat.format(item.tanggalPinjam!) : '-',
        _dateFormat.format(item.tanggalBerakhir),
        _escapeCSV(item.statusPeminjaman?.statusPeminjaman ?? '-'),
        _escapeCSV(item.keperluan ?? '-'),
        _escapeCSV(item.catatanPetugas ?? '-'),
      ].join(','));
    }
    
    return buffer.toString();
  }

  /// Generate CSV string for pengembalian data
  String generatePengembalianCSV(List<PengembalianModel> data) {
    final buffer = StringBuffer();
    
    // Header
    buffer.writeln('Kode Peminjaman,Peminjam,Email,Alat,Jumlah Kembali,Tanggal Kembali,Kondisi Alat,Keterlambatan (Hari),Total Denda,Status Pembayaran,Catatan');
    
    // Data rows
    for (final item in data) {
      buffer.writeln([
        _escapeCSV(item.peminjaman?.kodePeminjaman ?? '-'),
        _escapeCSV(item.peminjaman?.peminjam?.namaLengkap ?? '-'),
        _escapeCSV(item.peminjaman?.peminjam?.email ?? '-'),
        _escapeCSV(item.peminjaman?.alat?.namaAlat ?? '-'),
        item.jumlahKembali,
        item.tanggalKembali != null ? _dateFormat.format(item.tanggalKembali!) : '-',
        _escapeCSV(item.kondisiAlat ?? '-'),
        item.keterlambatanHari ?? 0,
        item.totalPembayaran ?? 0,
        _escapeCSV(item.statusPembayaran ?? '-'),
        _escapeCSV(item.catatan ?? '-'),
      ].join(','));
    }
    
    return buffer.toString();
  }

  String _escapeCSV(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  // ============================================================================
  // LEGACY METHODS (kept for backward compatibility)
  // ============================================================================

  Future<List<PeminjamanModel>> getLaporanPeminjaman(DateTime start, DateTime end) async {
    return getLaporanPeminjamanFiltered(startDate: start, endDate: end);
  }

  Future<List<PengembalianModel>> getLaporanPengembalian(DateTime start, DateTime end) async {
    return getLaporanPengembalianFiltered(startDate: start, endDate: end);
  }

  Future<Uint8List> generateLaporanPDF(String title, List<PeminjamanModel> data) async {
    return generatePeminjamanPDF(title: title, data: data);
  }
}
