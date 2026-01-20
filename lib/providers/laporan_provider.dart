// lib/providers/laporan_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/peminjaman_model.dart';
import '../models/pengembalian_model.dart' hide PeminjamanModel;
import '../services/laporan_services.dart';

// ============================================================================
// FILTER STATE
// ============================================================================

enum ReportType { peminjaman, pengembalian }
enum TimePreset { hariIni, mingguIni, bulanIni, tahunIni, lifetime, custom }

class LaporanFilterState {
  final ReportType reportType;
  final TimePreset timePreset;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? statusId;
  final int? alatId;
  final int? peminjamId;
  final String? kondisiAlat;
  final String? statusPembayaran;

  const LaporanFilterState({
    this.reportType = ReportType.peminjaman,
    this.timePreset = TimePreset.bulanIni,
    this.startDate,
    this.endDate,
    this.statusId,
    this.alatId,
    this.peminjamId,
    this.kondisiAlat,
    this.statusPembayaran,
  });

  LaporanFilterState copyWith({
    ReportType? reportType,
    TimePreset? timePreset,
    DateTime? startDate,
    DateTime? endDate,
    int? statusId,
    int? alatId,
    int? peminjamId,
    String? kondisiAlat,
    String? statusPembayaran,
    bool clearStatusId = false,
    bool clearAlatId = false,
    bool clearPeminjamId = false,
    bool clearKondisiAlat = false,
    bool clearStatusPembayaran = false,
  }) {
    return LaporanFilterState(
      reportType: reportType ?? this.reportType,
      timePreset: timePreset ?? this.timePreset,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      statusId: clearStatusId ? null : (statusId ?? this.statusId),
      alatId: clearAlatId ? null : (alatId ?? this.alatId),
      peminjamId: clearPeminjamId ? null : (peminjamId ?? this.peminjamId),
      kondisiAlat: clearKondisiAlat ? null : (kondisiAlat ?? this.kondisiAlat),
      statusPembayaran: clearStatusPembayaran ? null : (statusPembayaran ?? this.statusPembayaran),
    );
  }

  /// Get computed date range based on time preset
  (DateTime?, DateTime?) getDateRange() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (timePreset) {
      case TimePreset.hariIni:
        return (today, today);
      case TimePreset.mingguIni:
        final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
        return (startOfWeek, today);
      case TimePreset.bulanIni:
        final startOfMonth = DateTime(now.year, now.month, 1);
        return (startOfMonth, today);
      case TimePreset.tahunIni:
        final startOfYear = DateTime(now.year, 1, 1);
        return (startOfYear, today);
      case TimePreset.lifetime:
        return (null, null);
      case TimePreset.custom:
        return (startDate, endDate);
    }
  }

  LaporanFilterState clearAllFilters() {
    return LaporanFilterState(
      reportType: reportType,
      timePreset: TimePreset.bulanIni,
    );
  }
}

// ============================================================================
// LAPORAN DATA STATE
// ============================================================================

class LaporanState {
  final bool isLoading;
  final String? error;
  final List<PeminjamanModel> peminjamanData;
  final List<PengembalianModel> pengembalianData;
  final LaporanFilterState filter;

  const LaporanState({
    this.isLoading = false,
    this.error,
    this.peminjamanData = const [],
    this.pengembalianData = const [],
    this.filter = const LaporanFilterState(),
  });

  LaporanState copyWith({
    bool? isLoading,
    String? error,
    List<PeminjamanModel>? peminjamanData,
    List<PengembalianModel>? pengembalianData,
    LaporanFilterState? filter,
    bool clearError = false,
  }) {
    return LaporanState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      peminjamanData: peminjamanData ?? this.peminjamanData,
      pengembalianData: pengembalianData ?? this.pengembalianData,
      filter: filter ?? this.filter,
    );
  }

  LaporanState setLoading(bool loading) {
    return LaporanState(
      isLoading: loading,
      error: null,
      peminjamanData: peminjamanData,
      pengembalianData: pengembalianData,
      filter: filter,
    );
  }

  LaporanState clearError() {
    return LaporanState(
      isLoading: isLoading,
      error: null,
      peminjamanData: peminjamanData,
      pengembalianData: pengembalianData,
      filter: filter,
    );
  }

  // Computed properties for statistics
  int get totalRecords => filter.reportType == ReportType.peminjaman
      ? peminjamanData.length
      : pengembalianData.length;

  int get totalItems => filter.reportType == ReportType.peminjaman
      ? peminjamanData.fold<int>(0, (sum, p) => sum + p.jumlahPinjam)
      : pengembalianData.fold<int>(0, (sum, p) => sum + p.jumlahKembali);
}

// ============================================================================
// LAPORAN NOTIFIER (using Notifier pattern like other providers)
// ============================================================================

class LaporanNotifier extends Notifier<LaporanState> {
  late final LaporanService _service;
  bool _hasInitialized = false;

  @override
  LaporanState build() {
    _service = LaporanService();
    // DO NOT auto-load here
    return const LaporanState();
  }

  /// Ensure initialized (call once from UI)
  void ensureInitialized() {
    if (!_hasInitialized && !state.isLoading) {
      _loadData();
    }
  }

  /// Update report type (peminjaman or pengembalian)
  Future<void> setReportType(ReportType type) async {
    state = state.copyWith(
      filter: state.filter.copyWith(
        reportType: type,
        // Clear type-specific filters when switching
        clearStatusId: true,
        clearKondisiAlat: true,
        clearStatusPembayaran: true,
      ),
    );
    await _loadData();
  }

  /// Update time preset
  Future<void> setTimePreset(TimePreset preset) async {
    state = state.copyWith(
      filter: state.filter.copyWith(timePreset: preset),
    );
    await _loadData();
  }

  /// Set custom date range
  Future<void> setCustomDateRange(DateTime start, DateTime end) async {
    state = state.copyWith(
      filter: state.filter.copyWith(
        timePreset: TimePreset.custom,
        startDate: start,
        endDate: end,
      ),
    );
    await _loadData();
  }

  /// Set status filter (for peminjaman)
  Future<void> setStatusFilter(int? statusId) async {
    state = state.copyWith(
      filter: statusId == null
          ? state.filter.copyWith(clearStatusId: true)
          : state.filter.copyWith(statusId: statusId),
    );
    await _loadData();
  }

  /// Set alat filter
  Future<void> setAlatFilter(int? alatId) async {
    state = state.copyWith(
      filter: alatId == null
          ? state.filter.copyWith(clearAlatId: true)
          : state.filter.copyWith(alatId: alatId),
    );
    await _loadData();
  }

  /// Set peminjam filter
  Future<void> setPeminjamFilter(int? peminjamId) async {
    state = state.copyWith(
      filter: peminjamId == null
          ? state.filter.copyWith(clearPeminjamId: true)
          : state.filter.copyWith(peminjamId: peminjamId),
    );
    await _loadData();
  }

  /// Set kondisi alat filter (for pengembalian)
  Future<void> setKondisiAlatFilter(String? kondisi) async {
    state = state.copyWith(
      filter: kondisi == null
          ? state.filter.copyWith(clearKondisiAlat: true)
          : state.filter.copyWith(kondisiAlat: kondisi),
    );
    await _loadData();
  }

  /// Set status pembayaran filter (for pengembalian)
  Future<void> setStatusPembayaranFilter(String? status) async {
    state = state.copyWith(
      filter: status == null
          ? state.filter.copyWith(clearStatusPembayaran: true)
          : state.filter.copyWith(statusPembayaran: status),
    );
    await _loadData();
  }

  /// Clear all filters
  Future<void> clearFilters() async {
    state = state.copyWith(filter: state.filter.clearAllFilters());
    await _loadData();
  }

  /// Refresh data
  Future<void> refresh() async {
    await _loadData();
  }

  /// Load data based on current filters
  Future<void> _loadData() async {
    state = state.setLoading(true);

    try {
      final (startDate, endDate) = state.filter.getDateRange();

      if (state.filter.reportType == ReportType.peminjaman) {
        final data = await _service.getLaporanPeminjamanFiltered(
          startDate: startDate,
          endDate: endDate,
          statusId: state.filter.statusId,
          alatId: state.filter.alatId,
          peminjamId: state.filter.peminjamId,
        );
        state = state.copyWith(isLoading: false, peminjamanData: data, clearError: true);
      } else {
        final data = await _service.getLaporanPengembalianFiltered(
          startDate: startDate,
          endDate: endDate,
          kondisiAlat: state.filter.kondisiAlat,
          statusPembayaran: state.filter.statusPembayaran,
          alatId: state.filter.alatId,
          peminjamId: state.filter.peminjamId,
        );
        state = state.copyWith(isLoading: false, pengembalianData: data, clearError: true);
      }
      _hasInitialized = true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

// ============================================================================
// PROVIDERS
// ============================================================================

final laporanServiceProvider = Provider((ref) => LaporanService());

final laporanProvider = NotifierProvider<LaporanNotifier, LaporanState>(() {
  return LaporanNotifier();
});
