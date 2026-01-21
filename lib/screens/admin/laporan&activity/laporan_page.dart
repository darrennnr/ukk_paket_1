// lib/screens/admin/laporan&activity/laporan_page.dart
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:paket_3_training/core/design_system/app_color.dart';
import 'package:paket_3_training/core/design_system/app_design_system.dart'
    hide AppTheme;
import 'package:paket_3_training/widgets/admin_sidebar.dart';
import 'package:paket_3_training/providers/auth_provider.dart';
import 'package:paket_3_training/services/laporan_services.dart';
import 'package:paket_3_training/models/peminjaman_model.dart';
import 'package:paket_3_training/models/pengembalian_model.dart'
    hide PeminjamanModel;

// ============================================================================
// PROVIDERS
// ============================================================================
final laporanServiceProvider = Provider((ref) => LaporanService());

final laporanTypeProvider = StateProvider<String>((ref) => 'peminjaman');

final startDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, 1);
});

final endDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

final statusFilterProvider = StateProvider<int?>((ref) => null);

final laporanPeminjamanDataProvider = FutureProvider<List<PeminjamanModel>>((
  ref,
) async {
  final service = ref.watch(laporanServiceProvider);
  final start = ref.watch(startDateProvider);
  final end = ref.watch(endDateProvider);
  final statusFilter = ref.watch(statusFilterProvider);

  final data = await service.getLaporanPeminjaman(start, end);

  if (statusFilter != null) {
    return data.where((p) => p.statusPeminjamanId == statusFilter).toList();
  }

  return data;
});

final laporanPengembalianDataProvider = FutureProvider<List<PengembalianModel>>(
  (ref) async {
    final service = ref.watch(laporanServiceProvider);
    final start = ref.watch(startDateProvider);
    final end = ref.watch(endDateProvider);

    return await service.getLaporanPengembalian(start, end);
  },
);

// ============================================================================
// MAIN PAGE
// ============================================================================
class LaporanPage extends ConsumerStatefulWidget {
  const LaporanPage({Key? key}) : super(key: key);

  @override
  ConsumerState<LaporanPage> createState() => _LaporanPageState();
}

class _LaporanPageState extends ConsumerState<LaporanPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool get _isDesktop => MediaQuery.of(context).size.width >= 900;
  bool get _isTablet =>
      MediaQuery.of(context).size.width >= 600 &&
      MediaQuery.of(context).size.width < 900;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildAppBar(),
      drawer: _isDesktop ? null : AdminSidebar(currentRoute: '/admin/laporan'),
      body: Row(
        children: [
          if (_isDesktop)
            Container(
              width: 260,
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  right: BorderSide(color: AppColors.borderMedium, width: 1),
                ),
              ),
              child: AdminSidebar(currentRoute: '/admin/laporan'),
            ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(_isDesktop ? 24 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildFilterSection(),
                  const SizedBox(height: 24),
                  _buildPreviewSection(),
                ],
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
  PreferredSizeWidget _buildAppBar() {
    final user = ref.watch(authProvider).user;
    final userName = user?.namaLengkap ?? 'Admin';

    return AppBar(
      elevation: 0,
      backgroundColor: AppColors.surface,
      surfaceTintColor: AppColors.surface,
      leading: _isDesktop
          ? null
          : IconButton(
              icon: Icon(
                Icons.menu_rounded,
                color: AppColors.textPrimary,
                size: 22,
              ),
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
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
          child: _buildProfileMenu(userName),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppColors.borderMedium),
      ),
    );
  }

  Widget _buildProfileMenu(String userName) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 45),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      color: AppColors.surface,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.borderMedium),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  userName[0].toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.surface,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            if (_isDesktop) ...[
              const SizedBox(width: 8),
              Text(
                userName.split(' ').first,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ],
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
      onSelected: (value) {
        if (value == 'logout') _handleLogout();
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'profile',
          height: 40,
          child: Row(
            children: [
              Icon(
                Icons.person_outline_rounded,
                size: 18,
                color: AppColors.textPrimary,
              ),
              const SizedBox(width: 10),
              const Text('Profil', style: TextStyle(fontSize: 13)),
            ],
          ),
        ),
        const PopupMenuDivider(height: 1),
        PopupMenuItem(
          value: 'logout',
          height: 40,
          child: Row(
            children: [
              const Icon(
                Icons.logout_rounded,
                size: 18,
                color: Color(0xFFFF5252),
              ),
              const SizedBox(width: 10),
              const Text(
                'Keluar',
                style: TextStyle(fontSize: 13, color: Color(0xFFFF5252)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _handleLogout() {
    ref.read(authProvider.notifier).logout();
    context.go('/login');
  }

  // ============================================================================
  // HEADER
  // ============================================================================
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Laporan & Statistik',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Generate laporan berdasarkan periode dan filter tertentu',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0);
  }

  // ============================================================================
  // FILTER SECTION
  // ============================================================================
  Widget _buildFilterSection() {
    final laporanType = ref.watch(laporanTypeProvider);
    final startDate = ref.watch(startDateProvider);
    final endDate = ref.watch(endDateProvider);
    final statusFilter = ref.watch(statusFilterProvider);

    return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderMedium, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.filter_list_rounded,
                      color: AppTheme.primaryColor,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Filter Laporan',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Type Selector
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildTypeChip(
                    'peminjaman',
                    'Peminjaman',
                    Icons.assignment_outlined,
                    laporanType,
                  ),
                  _buildTypeChip(
                    'pengembalian',
                    'Pengembalian',
                    Icons.assignment_return_outlined,
                    laporanType,
                  ),
                ],
              ),

              const SizedBox(height: 20),
              Divider(height: 1, color: AppColors.borderMedium),
              const SizedBox(height: 20),

              // Date Range
              if (_isDesktop || _isTablet)
                Row(
                  children: [
                    Expanded(
                      child: _buildDatePicker('Dari Tanggal', startDate, true),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildDatePicker('Sampai Tanggal', endDate, false),
                    ),
                    if (laporanType == 'peminjaman') ...[
                      const SizedBox(width: 16),
                      Expanded(child: _buildStatusFilter(statusFilter)),
                    ],
                  ],
                )
              else
                Column(
                  children: [
                    _buildDatePicker('Dari Tanggal', startDate, true),
                    const SizedBox(height: 12),
                    _buildDatePicker('Sampai Tanggal', endDate, false),
                    if (laporanType == 'peminjaman') ...[
                      const SizedBox(height: 12),
                      _buildStatusFilter(statusFilter),
                    ],
                  ],
                ),

              const SizedBox(height: 20),
              Divider(height: 1, color: AppColors.borderMedium),
              const SizedBox(height: 20),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _resetFilters,
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: const Text(
                        'Reset',
                        style: TextStyle(fontSize: 13),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: AppColors.borderDark),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Trigger refresh
                        ref.invalidate(laporanPeminjamanDataProvider);
                        ref.invalidate(laporanPengembalianDataProvider);
                      },
                      icon: const Icon(Icons.search_rounded, size: 16),
                      label: const Text(
                        'Tampilkan Laporan',
                        style: TextStyle(fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: AppColors.surface,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 400.ms, delay: 100.ms)
        .slideY(begin: 0.05, end: 0);
  }

  Widget _buildTypeChip(
    String value,
    String label,
    IconData icon,
    String current,
  ) {
    final isSelected = current == value;

    return InkWell(
      onTap: () => ref.read(laporanTypeProvider.notifier).state = value,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor
              : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : AppColors.borderMedium,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? AppColors.surface : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppColors.surface : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePicker(String label, DateTime selectedDate, bool isStart) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: selectedDate,
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(primary: AppTheme.primaryColor),
              ),
              child: child!,
            );
          },
        );

        if (picked != null) {
          if (isStart) {
            ref.read(startDateProvider.notifier).state = picked;
          } else {
            ref.read(endDateProvider.notifier).state = picked;
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.borderMedium, width: 1),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 16,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('dd MMM yyyy').format(selectedDate),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusFilter(int? selected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderMedium, width: 1),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          value: selected,
          isExpanded: true,
          hint: Text(
            'Status',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          icon: Icon(
            Icons.arrow_drop_down_rounded,
            size: 20,
            color: AppColors.textSecondary,
          ),
          style: const TextStyle(fontSize: 13, color: Color(0xFF1A1A1A)),
          items: const [
            DropdownMenuItem(
              value: null,
              child: Text('Semua Status', style: TextStyle(fontSize: 13)),
            ),
            DropdownMenuItem(
              value: 1,
              child: Text('Pending', style: TextStyle(fontSize: 13)),
            ),
            DropdownMenuItem(
              value: 2,
              child: Text('Dipinjam', style: TextStyle(fontSize: 13)),
            ),
            DropdownMenuItem(
              value: 3,
              child: Text('Ditolak', style: TextStyle(fontSize: 13)),
            ),
            DropdownMenuItem(
              value: 4,
              child: Text('Kembali', style: TextStyle(fontSize: 13)),
            ),
          ],
          onChanged: (value) =>
              ref.read(statusFilterProvider.notifier).state = value,
        ),
      ),
    );
  }

  void _resetFilters() {
    final now = DateTime.now();
    ref.read(startDateProvider.notifier).state = DateTime(
      now.year,
      now.month,
      1,
    );
    ref.read(endDateProvider.notifier).state = now;
    ref.read(statusFilterProvider.notifier).state = null;
    ref.read(laporanTypeProvider.notifier).state = 'peminjaman';
  }

  // ============================================================================
  // PREVIEW SECTION
  // ============================================================================
  Widget _buildPreviewSection() {
    final laporanType = ref.watch(laporanTypeProvider);

    return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderMedium, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.preview_outlined,
                          color: AppTheme.primaryColor,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Preview Laporan',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      _buildActionButton(
                        icon: Icons.print_rounded,
                        label: 'Print',
                        onTap: _handlePrint,
                      ),
                      const SizedBox(width: 8),
                      _buildActionButton(
                        icon: Icons.file_download_outlined,
                        label: 'Export PDF',
                        onTap: _handleExportPDF,
                        isPrimary: true,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Divider(height: 1, color: AppColors.borderMedium),
              const SizedBox(height: 20),

              if (laporanType == 'peminjaman')
                _buildPeminjamanPreview()
              else
                _buildPengembalianPreview(),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 400.ms, delay: 200.ms)
        .slideY(begin: 0.05, end: 0);
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isPrimary ? AppTheme.primaryColor : AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isPrimary ? AppTheme.primaryColor : AppColors.borderDark,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isPrimary ? AppColors.surface : AppColors.textPrimary,
            ),
            if (!_isDesktop && _isTablet) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isPrimary ? AppColors.surface : AppColors.textPrimary,
                ),
              ),
            ] else if (_isDesktop) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isPrimary ? AppColors.surface : AppColors.textPrimary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // PEMINJAMAN PREVIEW
  // ============================================================================
  Widget _buildPeminjamanPreview() {
    final dataAsync = ref.watch(laporanPeminjamanDataProvider);

    return dataAsync.when(
      data: (data) {
        if (data.isEmpty) {
          return _buildEmptyState('Tidak ada data peminjaman pada periode ini');
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryCards(
              total: data.length,
              approved: data.where((p) => p.statusPeminjamanId == 2).length,
              pending: data.where((p) => p.statusPeminjamanId == 1).length,
              rejected: data.where((p) => p.statusPeminjamanId == 3).length,
            ),
            const SizedBox(height: 20),
            _buildPeminjamanTable(data),
          ],
        );
      },
      loading: () => _buildLoadingSkeleton(),
      error: (err, stack) => _buildErrorState('Gagal memuat data: $err'),
    );
  }

  Widget _buildSummaryCards({
    required int total,
    required int approved,
    required int pending,
    required int rejected,
  }) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _buildSummaryCard(
          'Total',
          total,
          Icons.assignment_outlined,
          const Color(0xFF2196F3),
        ),
        _buildSummaryCard(
          'Disetujui',
          approved,
          Icons.check_circle_outline,
          const Color(0xFF4CAF50),
        ),
        _buildSummaryCard(
          'Pending',
          pending,
          Icons.pending_outlined,
          const Color(0xFFFF9800),
        ),
        _buildSummaryCard(
          'Ditolak',
          rejected,
          Icons.cancel_outlined,
          const Color(0xFFFF5252),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    String label,
    int value,
    IconData icon,
    Color color,
  ) {
    return Container(
      width: _isDesktop ? 160 : (_isTablet ? 140 : double.infinity),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$value',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeminjamanTable(List<PeminjamanModel> data) {
    if (_isDesktop || _isTablet) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.borderMedium, width: 1),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8),
                ),
              ),
              child: const Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Kode',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Peminjam',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Alat',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Tanggal',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      'Status',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: AppColors.borderMedium),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: data.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: AppColors.surfaceContainerLow),
              itemBuilder: (context, index) {
                final item = data[index];
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          item.kodePeminjaman,
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          item.peminjam?.namaLengkap ?? '-',
                          style: const TextStyle(fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          item.alat?.namaAlat ?? '-',
                          style: const TextStyle(fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          item.tanggalPinjam != null
                              ? DateFormat(
                                  'dd/MM/yyyy',
                                ).format(item.tanggalPinjam!)
                              : '-',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: _buildMiniStatusBadge(
                          item.statusPeminjaman?.statusPeminjaman ?? '-',
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      );
    }

    // Mobile
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: data.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = data[index];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.borderMedium, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    item.kodePeminjaman,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  _buildMiniStatusBadge(
                    item.statusPeminjaman?.statusPeminjaman ?? '-',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${item.peminjam?.namaLengkap ?? '-'} - ${item.alat?.namaAlat ?? '-'}',
                style: TextStyle(fontSize: 11, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 4),
              Text(
                item.tanggalPinjam != null
                    ? DateFormat('dd MMM yyyy').format(item.tanggalPinjam!)
                    : '-',
                style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================================
  // PENGEMBALIAN PREVIEW
  // ============================================================================
  Widget _buildPengembalianPreview() {
    final dataAsync = ref.watch(laporanPengembalianDataProvider);

    return dataAsync.when(
      data: (data) {
        if (data.isEmpty) {
          return _buildEmptyState(
            'Tidak ada data pengembalian pada periode ini',
          );
        }

        final totalDenda = data.fold<int>(
          0,
          (sum, p) => sum + (p.totalPembayaran ?? 0),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPengembalianSummary(
              total: data.length,
              terlambat: data.where((p) => p.isLate).length,
              totalDenda: totalDenda,
            ),
            const SizedBox(height: 20),
            _buildPengembalianTable(data),
          ],
        );
      },
      loading: () => _buildLoadingSkeleton(),
      error: (err, stack) => _buildErrorState('Gagal memuat data: $err'),
    );
  }

  Widget _buildPengembalianSummary({
    required int total,
    required int terlambat,
    required int totalDenda,
  }) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _buildSummaryCard(
          'Total',
          total,
          Icons.assignment_return_outlined,
          const Color(0xFF2196F3),
        ),
        _buildSummaryCard(
          'Terlambat',
          terlambat,
          Icons.warning_outlined,
          const Color(0xFFFF5252),
        ),
        // Container(
        //   width: _isDesktop ? 220 : double.infinity,
        //   padding: const EdgeInsets.all(14),
        //   decoration: BoxDecoration(
        //     color: const Color(0xFF4CAF50).withOpacity(0.05),
        //     borderRadius: BorderRadius.circular(8),
        //     border: Border.all(
        //       color: const Color(0xFF4CAF50).withOpacity(0.2),
        //       width: 1,
        //     ),
        //   ),
        //   child: Row(
        //     children: [
        //       Container(
        //         padding: const EdgeInsets.all(8),
        //         decoration: BoxDecoration(
        //           color: const Color(0xFF4CAF50).withOpacity(0.1),
        //           borderRadius: BorderRadius.circular(6),
        //         ),
        //         child: const Icon(
        //           Icons.payments_outlined,
        //           size: 18,
        //           color: Color(0xFF4CAF50),
        //         ),
        //       ),
        //       const SizedBox(width: 12),
        //       Expanded(
        //         child: Column(
        //           crossAxisAlignment: CrossAxisAlignment.start,
        //           children: [
        //             Text(
        //               'Total Denda',
        //               style: TextStyle(
        //                 fontSize: 11,
        //                 color: AppColors.textSecondary,
        //                 fontWeight: FontWeight.w500,
        //               ),
        //             ),
        //             const SizedBox(height: 2),
        //             Text(
        //               currencyFormat.format(totalDenda),
        //               style: const TextStyle(
        //                 fontSize: 14,
        //                 fontWeight: FontWeight.w700,
        //                 color: Color(0xFF4CAF50),
        //               ),
        //               maxLines: 1,
        //               overflow: TextOverflow.ellipsis,
        //             ),
        //           ],
        //         ),
        //       ),
        //     ],
        //   ),
        // ),
      ],
    );
  }

  Widget _buildPengembalianTable(List<PengembalianModel> data) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    if (_isDesktop || _isTablet) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.borderMedium, width: 1),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8),
                ),
              ),
              child: const Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Kode',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Peminjam',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Tgl Kembali',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Kondisi',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Bayar',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: AppColors.borderMedium),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: data.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: AppColors.surfaceContainerLow),
              itemBuilder: (context, index) {
                final item = data[index];
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          item.peminjaman?.kodePeminjaman ?? '-',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          item.peminjaman?.peminjam?.namaLengkap ?? '-',
                          style: const TextStyle(fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          item.tanggalKembali != null
                              ? DateFormat(
                                  'dd/MM/yyyy',
                                ).format(item.tanggalKembali!)
                              : '-',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          item.kondisiAlat ?? '-',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          (item.totalPembayaran ?? 0) > 0
                              ? currencyFormat.format(item.totalPembayaran)
                              : '-',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      );
    }

    // Mobile
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: data.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = data[index];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.borderMedium, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.peminjaman?.kodePeminjaman ?? '-',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${item.peminjaman?.peminjam?.namaLengkap ?? '-'} - ${item.kondisiAlat ?? '-'}',
                style: TextStyle(fontSize: 11, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    item.tanggalKembali != null
                        ? DateFormat('dd MMM yyyy').format(item.tanggalKembali!)
                        : '-',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if ((item.totalPembayaran ?? 0) > 0)
                    Text(
                      currencyFormat.format(item.totalPembayaran),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFFF5252),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================================
  // HELPER WIDGETS
  // ============================================================================
  Widget _buildMiniStatusBadge(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'pending':
        color = const Color(0xFFFF9800);
        break;
      case 'dipinjam':
        color = const Color(0xFF2196F3);
        break;
      case 'ditolak':
        color = const Color(0xFFFF5252);
        break;
      case 'kembali':
        color = const Color(0xFF4CAF50);
        break;
      default:
        color = AppColors.textDisabled;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 9,
          color: color,
          fontWeight: FontWeight.w700,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.receipt_long_outlined,
                size: 48,
                color: AppColors.textHint,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Coba ubah filter atau periode',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return Container(
          decoration: BoxDecoration(
            color: AppColors.borderMedium,
            borderRadius: BorderRadius.circular(8),
          ),
          height: 300,
        )
        .animate(onPlay: (controller) => controller.repeat())
        .shimmer(duration: 1200.ms);
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFFFF5252),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // PDF & PRINT HANDLERS
  // ============================================================================
  Future<void> _handleExportPDF() async {
    try {
      final laporanType = ref.read(laporanTypeProvider);
      final startDate = ref.read(startDateProvider);
      final endDate = ref.read(endDateProvider);

      if (laporanType == 'peminjaman') {
        final data = await ref.read(laporanPeminjamanDataProvider.future);
        if (data.isEmpty) {
          _showMessage('Tidak ada data untuk diekspor', isError: true);
          return;
        }

        final pdfBytes = await ref
            .read(laporanServiceProvider)
            .generateLaporanPDF(
              'Laporan Peminjaman\n${DateFormat('dd MMM yyyy').format(startDate)} - ${DateFormat('dd MMM yyyy').format(endDate)}',
              data,
            );

        await Printing.sharePdf(
          bytes: pdfBytes,
          filename:
              'laporan_peminjaman_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
        );

        _showMessage('PDF berhasil diekspor');
      } else {
        final data = await ref.read(laporanPengembalianDataProvider.future);
        if (data.isEmpty) {
          _showMessage('Tidak ada data untuk diekspor', isError: true);
          return;
        }

        final pdfBytes = await _generatePengembalianPDF(
          'Laporan Pengembalian\n${DateFormat('dd MMM yyyy').format(startDate)} - ${DateFormat('dd MMM yyyy').format(endDate)}',
          data,
        );

        await Printing.sharePdf(
          bytes: pdfBytes,
          filename:
              'laporan_pengembalian_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
        );

        _showMessage('PDF berhasil diekspor');
      }
    } catch (e) {
      _showMessage('Gagal mengekspor PDF: $e', isError: true);
    }
  }

  Future<void> _handlePrint() async {
    try {
      final laporanType = ref.read(laporanTypeProvider);
      final startDate = ref.read(startDateProvider);
      final endDate = ref.read(endDateProvider);

      if (laporanType == 'peminjaman') {
        final data = await ref.read(laporanPeminjamanDataProvider.future);
        if (data.isEmpty) {
          _showMessage('Tidak ada data untuk dicetak', isError: true);
          return;
        }

        final pdfBytes = await ref
            .read(laporanServiceProvider)
            .generateLaporanPDF(
              'Laporan Peminjaman\n${DateFormat('dd MMM yyyy').format(startDate)} - ${DateFormat('dd MMM yyyy').format(endDate)}',
              data,
            );

        await Printing.layoutPdf(onLayout: (_) => pdfBytes);
      } else {
        final data = await ref.read(laporanPengembalianDataProvider.future);
        if (data.isEmpty) {
          _showMessage('Tidak ada data untuk dicetak', isError: true);
          return;
        }

        final pdfBytes = await _generatePengembalianPDF(
          'Laporan Pengembalian\n${DateFormat('dd MMM yyyy').format(startDate)} - ${DateFormat('dd MMM yyyy').format(endDate)}',
          data,
        );

        await Printing.layoutPdf(onLayout: (_) => pdfBytes);
      }
    } catch (e) {
      _showMessage('Gagal mencetak: $e', isError: true);
    }
  }

  Future<Uint8List> _generatePengembalianPDF(
    String title,
    List<PengembalianModel> data,
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
                headers: [
                  'Kode',
                  'Peminjam',
                  'Tgl Kembali',
                  'Kondisi',
                  'Bayar',
                ],
                data: data.map((item) {
                  final currencyFormat = NumberFormat.currency(
                    locale: 'id_ID',
                    symbol: 'Rp ',
                    decimalDigits: 0,
                  );
                  return [
                    item.peminjaman?.kodePeminjaman ?? '-',
                    item.peminjaman?.peminjam?.namaLengkap ?? '-',
                    item.tanggalKembali != null
                        ? DateFormat('dd/MM/yyyy').format(item.tanggalKembali!)
                        : '-',
                    item.kondisiAlat ?? '-',
                    (item.totalPembayaran ?? 0) > 0
                        ? currencyFormat.format(item.totalPembayaran)
                        : '-',
                  ];
                }).toList(),
              ),
            ],
          );
        },
      ),
    );

    return await pdf.save();
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontSize: 13)),
        backgroundColor: isError
            ? const Color(0xFFFF5252)
            : const Color(0xFF4CAF50),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
