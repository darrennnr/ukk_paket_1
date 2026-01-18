// lib/services/laporan_services.dart
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/peminjaman_model.dart';
import '../models/pengembalian_model.dart' hide PeminjamanModel;
import '../main.dart';

class LaporanService {
  // Get Data untuk Laporan Peminjaman
  Future<List<PeminjamanModel>> getLaporanPeminjaman(
    DateTime start,
    DateTime end,
  ) async {
    final response = await supabase
        .from('peminjaman')
        .select(
          '*, peminjam:users!peminjam_id(*), alat(*), status_peminjaman(*)',
        )
        .gte('tanggal_pinjam', start.toIso8601String())
        .lte('tanggal_pinjam', end.toIso8601String())
        .order('tanggal_pinjam');

    return (response as List).map((e) => PeminjamanModel.fromJson(e)).toList();
  }

  // Get Data untuk Laporan Pengembalian
  Future<List<PengembalianModel>> getLaporanPengembalian(
    DateTime start,
    DateTime end,
  ) async {
    final response = await supabase
        .from('pengembalian')
        .select('*, peminjaman(*, alat(*)), petugas:users!petugas_id(*)')
        .gte('tanggal_kembali', start.toIso8601String())
        .lte('tanggal_kembali', end.toIso8601String());

    return (response as List)
        .map((e) => PengembalianModel.fromJson(e))
        .toList();
  }

  // Export PDF Example
  Future<Uint8List> generateLaporanPDF(
    String title,
    List<PeminjamanModel> data,
  ) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Header(
                level: 0,
                child: pw.Text(title, style: pw.TextStyle(fontSize: 24)),
              ),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                context: context,
                headers: ['Kode', 'Peminjam', 'Alat', 'Tgl Pinjam', 'Status'],
                data: data
                    .map(
                      (item) => [
                        item.kodePeminjaman,
                        item.peminjam?.namaLengkap ?? '-',
                        item.alat?.namaAlat ?? '-',
                        item.tanggalPinjam.toString().split(' ')[0],
                        item.statusPeminjaman?.statusPeminjaman ?? '-',
                      ],
                    )
                    .toList(),
              ),
            ],
          );
        },
      ),
    );

    return await pdf.save();
  }
}
