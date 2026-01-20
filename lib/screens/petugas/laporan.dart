// lib/screens/petugas/laporan.dart
import 'dart:convert';
import 'dart:io' show File, Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:universal_html/html.dart' as html;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:paket_3_training/core/design_system/app_color.dart';
import 'package:paket_3_training/widgets/petugas_sidebar.dart';
import 'package:paket_3_training/providers/laporan_provider.dart';
import 'package:paket_3_training/providers/alat_provider.dart';
import 'package:paket_3_training/providers/user_provider.dart';
import 'package:paket_3_training/providers/auth_provider.dart';

class LaporanPetugas extends ConsumerStatefulWidget {
  const LaporanPetugas({Key? key}) : super(key: key);

  @override
  ConsumerState<LaporanPetugas> createState() => _LaporanPetugasState();
}

class _LaporanPetugasState extends ConsumerState<LaporanPetugas> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool get _isDesktop => MediaQuery.of(context).size.width >= 900;
  bool _hasInitialized = false;

  final _dateFormat = DateFormat('dd MMM yyyy');
  final _currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
  }

  void _initialize() {
    if (!_hasInitialized) {
      _hasInitialized = true;
      ref.read(laporanProvider.notifier).ensureInitialized();
      ref.read(alatProvider.notifier).ensureInitialized();
      ref.read(userProvider.notifier).ensureInitialized();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final laporanState = ref.watch(laporanProvider);
    final alatState = ref.watch(alatProvider);
    final userState = ref.watch(userProvider);
    final user = authState.user;

    // Initialize after auth is ready
    if (!authState.isLoading && authState.isAuthenticated && !_hasInitialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _initialize());
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildAppBar(context, user?.namaLengkap ?? 'Petugas'),
      drawer: _isDesktop ? null : PetugasSidebar(currentRoute: '/petugas/laporan'),
      body: Row(
        children: [
          if (_isDesktop)
            Container(
              width: 260,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(right: BorderSide(color: Colors.grey.shade200, width: 1)),
              ),
              child: PetugasSidebar(currentRoute: '/petugas/laporan'),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.read(laporanProvider.notifier).refresh(),
              color: AppTheme.primaryColor,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(_isDesktop ? 24 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPageHeader(),
                    const SizedBox(height: 20),
                    _buildReportTypeToggle(laporanState.filter),
                    const SizedBox(height: 16),
                    _buildFiltersSection(laporanState.filter, alatState, userState),
                    const SizedBox(height: 20),
                    _buildStatisticsCards(laporanState),
                    const SizedBox(height: 20),
                    _buildExportButtons(laporanState),
                    const SizedBox(height: 16),
                    _buildDataTable(laporanState),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // APP BAR
  // ============================================================================
  PreferredSizeWidget _buildAppBar(BuildContext context, String userName) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      leading: _isDesktop
          ? null
          : IconButton(
              icon: Icon(Icons.menu_rounded, color: Colors.grey.shade700, size: 22),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
      title: const Text(
        'Laporan',
        style: TextStyle(
          color: Color(0xFF1A1A1A),
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: Colors.grey.shade200),
      ),
    );
  }

  // ============================================================================
  // PAGE HEADER
  // ============================================================================
  Widget _buildPageHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF9C27B0).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.bar_chart_rounded, color: Color(0xFF9C27B0), size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Laporan & Export Data',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Lihat dan unduh laporan peminjaman & pengembalian',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0);
  }

  // ============================================================================
  // REPORT TYPE TOGGLE
  // ============================================================================
  Widget _buildReportTypeToggle(LaporanFilterState filter) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(child: _buildToggleButton('Peminjaman', ReportType.peminjaman, filter.reportType)),
          Expanded(child: _buildToggleButton('Pengembalian', ReportType.pengembalian, filter.reportType)),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 50.ms);
  }

  Widget _buildToggleButton(String label, ReportType type, ReportType current) {
    final isActive = type == current;
    return InkWell(
      onTap: () => ref.read(laporanProvider.notifier).setReportType(type),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isActive ? Colors.white : Colors.grey.shade600,
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // FILTERS SECTION
  // ============================================================================
  Widget _buildFiltersSection(LaporanFilterState filter, AlatState alatState, UserState userState) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.filter_list_rounded, size: 18, color: Colors.grey.shade700),
              const SizedBox(width: 8),
              const Text(
                'Filter',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => ref.read(laporanProvider.notifier).clearFilters(),
                icon: Icon(Icons.refresh_rounded, size: 16, color: Colors.grey.shade600),
                label: Text('Reset', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Time Presets
          Text('Periode', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey.shade700)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildTimeChip('Hari Ini', TimePreset.hariIni, filter.timePreset),
              _buildTimeChip('Minggu Ini', TimePreset.mingguIni, filter.timePreset),
              _buildTimeChip('Bulan Ini', TimePreset.bulanIni, filter.timePreset),
              _buildTimeChip('Tahun Ini', TimePreset.tahunIni, filter.timePreset),
              _buildTimeChip('Semua', TimePreset.lifetime, filter.timePreset),
              _buildCustomDateChip(filter),
            ],
          ),
          const SizedBox(height: 16),

          // Additional Filters Row
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 600;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: isWide ? 180 : constraints.maxWidth,
                    child: _buildAlatDropdown(filter, alatState),
                  ),
                  SizedBox(
                    width: isWide ? 180 : constraints.maxWidth,
                    child: _buildPeminjamDropdown(filter, userState),
                  ),
                  if (filter.reportType == ReportType.peminjaman)
                    SizedBox(
                      width: isWide ? 180 : constraints.maxWidth,
                      child: _buildStatusDropdown(filter),
                    ),
                  if (filter.reportType == ReportType.pengembalian) ...[
                    SizedBox(
                      width: isWide ? 180 : constraints.maxWidth,
                      child: _buildKondisiDropdown(filter),
                    ),
                    SizedBox(
                      width: isWide ? 180 : constraints.maxWidth,
                      child: _buildPembayaranDropdown(filter),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 100.ms);
  }

  Widget _buildTimeChip(String label, TimePreset preset, TimePreset current) {
    final isActive = preset == current;
    return InkWell(
      onTap: () => ref.read(laporanProvider.notifier).setTimePreset(preset),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primaryColor : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? AppTheme.primaryColor : Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isActive ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  Widget _buildCustomDateChip(LaporanFilterState filter) {
    final isActive = filter.timePreset == TimePreset.custom;
    return InkWell(
      onTap: () async {
        final range = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
          initialDateRange: filter.startDate != null && filter.endDate != null
              ? DateTimeRange(start: filter.startDate!, end: filter.endDate!)
              : null,
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(primary: AppTheme.primaryColor),
              ),
              child: child!,
            );
          },
        );
        if (range != null) {
          ref.read(laporanProvider.notifier).setCustomDateRange(range.start, range.end);
        }
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primaryColor : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? AppTheme.primaryColor : Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.date_range_rounded,
              size: 14,
              color: isActive ? Colors.white : Colors.grey.shade700,
            ),
            const SizedBox(width: 4),
            Text(
              isActive && filter.startDate != null && filter.endDate != null
                  ? '${_dateFormat.format(filter.startDate!)} - ${_dateFormat.format(filter.endDate!)}'
                  : 'Pilih Tanggal',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isActive ? Colors.white : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlatDropdown(LaporanFilterState filter, AlatState alatState) {
    return DropdownButtonFormField<int?>(
      value: filter.alatId,
      decoration: InputDecoration(
        labelText: 'Alat',
        labelStyle: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      isExpanded: true,
      icon: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey.shade600),
      style: const TextStyle(fontSize: 13, color: Color(0xFF1A1A1A)),
      items: [
        const DropdownMenuItem(value: null, child: Text('Semua Alat')),
        ...alatState.alats.map((a) => DropdownMenuItem(value: a.alatId, child: Text(a.namaAlat, overflow: TextOverflow.ellipsis))),
      ],
      onChanged: (value) => ref.read(laporanProvider.notifier).setAlatFilter(value),
    );
  }

  Widget _buildPeminjamDropdown(LaporanFilterState filter, UserState userState) {
    return DropdownButtonFormField<int?>(
      value: filter.peminjamId,
      decoration: InputDecoration(
        labelText: 'Peminjam',
        labelStyle: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      isExpanded: true,
      icon: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey.shade600),
      style: const TextStyle(fontSize: 13, color: Color(0xFF1A1A1A)),
      items: [
        const DropdownMenuItem(value: null, child: Text('Semua Peminjam')),
        ...userState.users.map((u) => DropdownMenuItem(value: u.userId, child: Text(u.namaLengkap, overflow: TextOverflow.ellipsis))),
      ],
      onChanged: (value) => ref.read(laporanProvider.notifier).setPeminjamFilter(value),
    );
  }

  Widget _buildStatusDropdown(LaporanFilterState filter) {
    return DropdownButtonFormField<int?>(
      value: filter.statusId,
      decoration: InputDecoration(
        labelText: 'Status',
        labelStyle: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      isExpanded: true,
      icon: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey.shade600),
      style: const TextStyle(fontSize: 13, color: Color(0xFF1A1A1A)),
      items: const [
        DropdownMenuItem(value: null, child: Text('Semua Status')),
        DropdownMenuItem(value: 1, child: Text('Pending')),
        DropdownMenuItem(value: 2, child: Text('Dipinjam')),
        DropdownMenuItem(value: 3, child: Text('Ditolak')),
        DropdownMenuItem(value: 4, child: Text('Dikembalikan')),
      ],
      onChanged: (value) => ref.read(laporanProvider.notifier).setStatusFilter(value),
    );
  }

  Widget _buildKondisiDropdown(LaporanFilterState filter) {
    return DropdownButtonFormField<String?>(
      value: filter.kondisiAlat,
      decoration: InputDecoration(
        labelText: 'Kondisi Alat',
        labelStyle: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      isExpanded: true,
      icon: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey.shade600),
      style: const TextStyle(fontSize: 13, color: Color(0xFF1A1A1A)),
      items: const [
        DropdownMenuItem(value: null, child: Text('Semua Kondisi')),
        DropdownMenuItem(value: 'baik', child: Text('Baik')),
        DropdownMenuItem(value: 'rusak ringan', child: Text('Rusak Ringan')),
        DropdownMenuItem(value: 'rusak berat', child: Text('Rusak Berat')),
      ],
      onChanged: (value) => ref.read(laporanProvider.notifier).setKondisiAlatFilter(value),
    );
  }

  Widget _buildPembayaranDropdown(LaporanFilterState filter) {
    return DropdownButtonFormField<String?>(
      value: filter.statusPembayaran,
      decoration: InputDecoration(
        labelText: 'Status Pembayaran',
        labelStyle: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      isExpanded: true,
      icon: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey.shade600),
      style: const TextStyle(fontSize: 13, color: Color(0xFF1A1A1A)),
      items: const [
        DropdownMenuItem(value: null, child: Text('Semua')),
        DropdownMenuItem(value: 'Lunas', child: Text('Lunas')),
        DropdownMenuItem(value: 'Belum Lunas', child: Text('Belum Lunas')),
      ],
      onChanged: (value) => ref.read(laporanProvider.notifier).setStatusPembayaranFilter(value),
    );
  }

  // ============================================================================
  // STATISTICS CARDS
  // ============================================================================
  Widget _buildStatisticsCards(LaporanState state) {
    if (state.isLoading) {
      return _buildLoadingCards();
    }

    final isPeminjaman = state.filter.reportType == ReportType.peminjaman;

    if (isPeminjaman) {
      final data = state.peminjamanData;
      return LayoutBuilder(
        builder: (context, constraints) {
          final cardWidth = constraints.maxWidth > 800 ? (constraints.maxWidth - 36) / 4 : (constraints.maxWidth - 12) / 2;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(width: cardWidth, child: _buildStatCard('Total Data', '${data.length}', Icons.assignment_outlined, const Color(0xFF2196F3))),
              SizedBox(width: cardWidth, child: _buildStatCard('Total Item', '${data.fold<int>(0, (sum, p) => sum + p.jumlahPinjam)}', Icons.inventory_2_outlined, const Color(0xFF4CAF50))),
              SizedBox(width: cardWidth, child: _buildStatCard('Pending', '${data.where((p) => p.statusPeminjamanId == 1).length}', Icons.pending_outlined, const Color(0xFFFF9800))),
              SizedBox(width: cardWidth, child: _buildStatCard('Dipinjam', '${data.where((p) => p.statusPeminjamanId == 2).length}', Icons.assignment_turned_in_outlined, const Color(0xFF9C27B0))),
            ],
          );
        },
      ).animate().fadeIn(duration: 400.ms, delay: 150.ms);
    } else {
      final data = state.pengembalianData;
      final totalDenda = data.fold<int>(0, (sum, p) => sum + (p.totalPembayaran ?? 0));
      return LayoutBuilder(
        builder: (context, constraints) {
          final cardWidth = constraints.maxWidth > 800 ? (constraints.maxWidth - 36) / 4 : (constraints.maxWidth - 12) / 2;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(width: cardWidth, child: _buildStatCard('Total Data', '${data.length}', Icons.assignment_return_outlined, const Color(0xFF2196F3))),
              SizedBox(width: cardWidth, child: _buildStatCard('Terlambat', '${data.where((p) => (p.keterlambatanHari ?? 0) > 0).length}', Icons.schedule_outlined, const Color(0xFFFF5252))),
              SizedBox(width: cardWidth, child: _buildStatCard('Kondisi Baik', '${data.where((p) => p.kondisiAlat?.toLowerCase() == 'baik').length}', Icons.check_circle_outline, const Color(0xFF4CAF50))),
              SizedBox(width: cardWidth, child: _buildStatCard('Total Denda', _currencyFormat.format(totalDenda), Icons.payments_outlined, const Color(0xFFFF9800))),
            ],
          );
        },
      ).animate().fadeIn(duration: 400.ms, delay: 150.ms);
    }
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(title, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingCards() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth > 800 ? (constraints.maxWidth - 36) / 4 : (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: List.generate(4, (index) => SizedBox(
            width: cardWidth,
            child: Container(
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          )),
        );
      },
    );
  }

  // ============================================================================
  // EXPORT BUTTONS
  // ============================================================================
  Widget _buildExportButtons(LaporanState state) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: state.isLoading ? null : () => _exportPDF(state),
            icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
            label: const Text('Export PDF'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: state.isLoading ? null : () => _exportExcel(state),
            icon: const Icon(Icons.table_chart_rounded, size: 18),
            label: const Text('Export Excel'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms, delay: 200.ms);
  }

  Future<void> _exportPDF(LaporanState state) async {
    final service = ref.read(laporanServiceProvider);
    final (startDate, endDate) = state.filter.getDateRange();

    try {
      if (state.filter.reportType == ReportType.peminjaman) {
        final pdfBytes = await service.generatePeminjamanPDF(
          title: 'Laporan Peminjaman',
          data: state.peminjamanData,
          startDate: startDate,
          endDate: endDate,
        );
        await Printing.layoutPdf(onLayout: (_) => pdfBytes);
      } else {
        final pdfBytes = await service.generatePengembalianPDF(
          title: 'Laporan Pengembalian',
          data: state.pengembalianData,
          startDate: startDate,
          endDate: endDate,
        );
        await Printing.layoutPdf(onLayout: (_) => pdfBytes);
      }
    } catch (e) {
      _showSnackBar('Gagal export PDF: $e', isError: true);
    }
  }

  Future<void> _exportExcel(LaporanState state) async {
    final service = ref.read(laporanServiceProvider);
    
    try {
      String csvData;
      String filename;

      if (state.filter.reportType == ReportType.peminjaman) {
        csvData = service.generatePeminjamanCSV(state.peminjamanData);
        filename = 'laporan_peminjaman_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv';
      } else {
        csvData = service.generatePengembalianCSV(state.pengembalianData);
        filename = 'laporan_pengembalian_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv';
      }

      final bytes = utf8.encode(csvData);

      if (kIsWeb) {
        // Download file for web
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', filename)
          ..click();
        html.Url.revokeObjectUrl(url);
        _showSnackBar('File $filename berhasil diunduh');
      } else {
        // For mobile, save to Downloads directory and open
        final directory = await getApplicationDocumentsDirectory();
        final filePath = '${directory.path}/$filename';
        final file = File(filePath);
        await file.writeAsBytes(bytes);
        await OpenFilex.open(filePath);
        _showSnackBar('File $filename berhasil disimpan');
      }
    } catch (e) {
      _showSnackBar('Gagal export Excel: $e', isError: true);
    }
  }

  // ============================================================================
  // DATA TABLE
  // ============================================================================
  Widget _buildDataTable(LaporanState state) {
    if (state.isLoading) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (state.error != null) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
              const SizedBox(height: 12),
              Text('Error: ${state.error}', style: TextStyle(color: Colors.grey.shade600)),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => ref.read(laporanProvider.notifier).refresh(),
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    final isPeminjaman = state.filter.reportType == ReportType.peminjaman;
    final isEmpty = isPeminjaman ? state.peminjamanData.isEmpty : state.pengembalianData.isEmpty;

    if (isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.inbox_outlined, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              Text('Tidak ada data', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
              const SizedBox(height: 4),
              Text('Coba ubah filter untuk melihat data lainnya', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: isPeminjaman ? _buildPeminjamanTable(state.peminjamanData) : _buildPengembalianTable(state.pengembalianData),
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 250.ms);
  }

  Widget _buildPeminjamanTable(List data) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
        headingTextStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)),
        dataTextStyle: TextStyle(fontSize: 12, color: Colors.grey.shade800),
        columnSpacing: 20,
        columns: const [
          DataColumn(label: Text('Kode')),
          DataColumn(label: Text('Peminjam')),
          DataColumn(label: Text('Alat')),
          DataColumn(label: Text('Jumlah')),
          DataColumn(label: Text('Tgl Pinjam')),
          DataColumn(label: Text('Tgl Berakhir')),
          DataColumn(label: Text('Status')),
        ],
        rows: data.map<DataRow>((item) {
          final statusColor = _getStatusColor(item.statusPeminjamanId);
          return DataRow(cells: [
            DataCell(Text(item.kodePeminjaman, style: const TextStyle(fontWeight: FontWeight.w500))),
            DataCell(Text(item.peminjam?.namaLengkap ?? '-')),
            DataCell(ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 150),
              child: Text(item.alat?.namaAlat ?? '-', overflow: TextOverflow.ellipsis),
            )),
            DataCell(Text('${item.jumlahPinjam}')),
            DataCell(Text(item.tanggalPinjam != null ? _dateFormat.format(item.tanggalPinjam!) : '-')),
            DataCell(Text(_dateFormat.format(item.tanggalBerakhir))),
            DataCell(Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                item.statusPeminjaman?.statusPeminjaman ?? '-',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: statusColor),
              ),
            )),
          ]);
        }).toList(),
      ),
    );
  }

  Widget _buildPengembalianTable(List data) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
        headingTextStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)),
        dataTextStyle: TextStyle(fontSize: 12, color: Colors.grey.shade800),
        columnSpacing: 20,
        columns: const [
          DataColumn(label: Text('Kode')),
          DataColumn(label: Text('Peminjam')),
          DataColumn(label: Text('Alat')),
          DataColumn(label: Text('Tgl Kembali')),
          DataColumn(label: Text('Kondisi')),
          DataColumn(label: Text('Terlambat')),
          DataColumn(label: Text('Denda')),
        ],
        rows: data.map<DataRow>((item) {
          final isLate = (item.keterlambatanHari ?? 0) > 0;
          return DataRow(cells: [
            DataCell(Text(item.peminjaman?.kodePeminjaman ?? '-', style: const TextStyle(fontWeight: FontWeight.w500))),
            DataCell(Text(item.peminjaman?.peminjam?.namaLengkap ?? '-')),
            DataCell(ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 150),
              child: Text(item.peminjaman?.alat?.namaAlat ?? '-', overflow: TextOverflow.ellipsis),
            )),
            DataCell(Text(item.tanggalKembali != null ? _dateFormat.format(item.tanggalKembali!) : '-')),
            DataCell(_buildKondisiBadge(item.kondisiAlat ?? '-')),
            DataCell(Text(
              '${item.keterlambatanHari ?? 0} hari',
              style: TextStyle(color: isLate ? Colors.red : Colors.grey.shade700),
            )),
            DataCell(Text(_currencyFormat.format(item.totalPembayaran ?? 0))),
          ]);
        }).toList(),
      ),
    );
  }

  Widget _buildKondisiBadge(String kondisi) {
    Color color;
    switch (kondisi.toLowerCase()) {
      case 'baik':
        color = const Color(0xFF4CAF50);
        break;
      case 'rusak ringan':
        color = const Color(0xFFFF9800);
        break;
      case 'rusak berat':
        color = const Color(0xFFFF5252);
        break;
      default:
        color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        kondisi,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: color),
      ),
    );
  }

  Color _getStatusColor(int? statusId) {
    switch (statusId) {
      case 1: return const Color(0xFFFF9800); // Pending
      case 2: return const Color(0xFF2196F3); // Dipinjam
      case 3: return const Color(0xFFFF5252); // Ditolak
      case 4: return const Color(0xFF4CAF50); // Dikembalikan
      default: return Colors.grey;
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : AppTheme.primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
