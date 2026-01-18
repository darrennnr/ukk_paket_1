// lib/screens/peminjam/history.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:paket_3_training/core/design_system/app_color.dart';
import 'package:paket_3_training/widgets/pengguna_sidebar.dart';
import '../../providers/peminjaman_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/peminjaman_model.dart';

class HistoryPeminjamanScreen extends ConsumerStatefulWidget {
  const HistoryPeminjamanScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HistoryPeminjamanScreen> createState() =>
      _HistoryPeminjamanScreenState();
}

class _HistoryPeminjamanScreenState
    extends ConsumerState<HistoryPeminjamanScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _searchQuery = '';
  int? _selectedStatusFilter; // null = semua

  bool get _isDesktop => MediaQuery.of(context).size.width >= 900;
  bool get _isTablet =>
      MediaQuery.of(context).size.width >= 600 &&
      MediaQuery.of(context).size.width < 900;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(myPeminjamanProvider.notifier).refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final peminjamanState = ref.watch(myPeminjamanProvider);
    final user = ref.watch(authProvider).user;

    // Filter peminjaman berdasarkan search dan status
    final filteredPeminjaman = peminjamanState.peminjamans.where((p) {
      final matchesSearch = _searchQuery.isEmpty ||
          (p.alat?.namaAlat.toLowerCase().contains(_searchQuery.toLowerCase()) ??
              false) ||
          p.kodePeminjaman.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesStatus =
          _selectedStatusFilter == null || p.statusPeminjamanId == _selectedStatusFilter;

      return matchesSearch && matchesStatus;
    }).toList();

    // Sort by date (newest first)
    filteredPeminjaman.sort((a, b) {
      final dateA = a.tanggalPengajuan ?? a.createdAt ?? DateTime.now();
      final dateB = b.tanggalPengajuan ?? b.createdAt ?? DateTime.now();
      return dateB.compareTo(dateA);
    });

    // Statistics
    final totalPeminjaman = peminjamanState.peminjamans.length;
    final pending = peminjamanState.peminjamans
        .where((p) => p.statusPeminjamanId == 1)
        .length;
    final aktif = peminjamanState.peminjamans
        .where((p) => p.statusPeminjamanId == 2)
        .length;
    final selesai = peminjamanState.peminjamans
        .where((p) => p.statusPeminjamanId == 4)
        .length;
    final ditolak = peminjamanState.peminjamans
        .where((p) => p.statusPeminjamanId == 3)
        .length;
    final terlambat = peminjamanState.peminjamans
        .where((p) => p.statusPeminjamanId == 5)
        .length;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildAppBar(context, user?.namaLengkap ?? 'Peminjam'),
      drawer: _isDesktop
          ? null
          : PenggunaSidebar(currentRoute: '/peminjam/history'),
      body: Row(
        children: [
          if (_isDesktop)
            Container(
              width: 260,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  right: BorderSide(color: Colors.grey.shade200, width: 1),
                ),
              ),
              child: PenggunaSidebar(currentRoute: '/peminjam/history'),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.read(myPeminjamanProvider.notifier).refresh(),
              color: AppTheme.primaryColor,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // Header Section
                  SliverToBoxAdapter(
                    child: Container(
                      padding: EdgeInsets.all(_isDesktop ? 24 : 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildPageHeader(),
                          const SizedBox(height: 20),
                          _buildStatisticsGrid(
                            totalPeminjaman,
                            pending,
                            aktif,
                            selesai,
                            ditolak,
                            terlambat,
                          ),
                          const SizedBox(height: 20),
                          _buildSearchBar(),
                          const SizedBox(height: 16),
                          _buildStatusFilter(),
                          const SizedBox(height: 20),
                          _buildResultsHeader(filteredPeminjaman.length),
                        ],
                      ),
                    ),
                  ),

                  // History List
                  if (peminjamanState.isLoading)
                    SliverFillRemaining(
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.primaryColor,
                          strokeWidth: 2,
                        ),
                      ),
                    )
                  else if (filteredPeminjaman.isEmpty)
                    SliverFillRemaining(
                      child: _buildEmptyState(),
                    )
                  else
                    SliverPadding(
                      padding: EdgeInsets.symmetric(
                        horizontal: _isDesktop ? 24 : 16,
                        vertical: 0,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final peminjaman = filteredPeminjaman[index];
                            return _buildHistoryCard(peminjaman, index);
                          },
                          childCount: filteredPeminjaman.length,
                        ),
                      ),
                    ),

                  // Bottom Padding
                  SliverPadding(
                    padding: const EdgeInsets.only(bottom: 24),
                    sliver: SliverToBoxAdapter(child: Container()),
                  ),
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
  PreferredSizeWidget _buildAppBar(BuildContext context, String userName) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      leading: _isDesktop
          ? null
          : IconButton(
              icon: Icon(
                Icons.menu_rounded,
                color: Colors.grey.shade700,
                size: 22,
              ),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
      title: Text(
        'History Peminjaman',
        style: TextStyle(
          color: const Color(0xFF1A1A1A),
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
        child: Container(height: 1, color: Colors.grey.shade200),
      ),
    );
  }

  Widget _buildProfileMenu(String userName) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 45),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
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
                    color: Colors.white,
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
              color: Colors.grey.shade600,
            ),
          ],
        ),
      ),
      onSelected: (value) {
        if (value == 'dashboard') context.go('/peminjam/dashboard');
        if (value == 'logout') _handleLogout();
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'dashboard',
          height: 40,
          child: Row(
            children: [
              Icon(Icons.dashboard_rounded,
                  size: 18, color: Colors.grey.shade700),
              const SizedBox(width: 10),
              const Text('Dashboard', style: TextStyle(fontSize: 13)),
            ],
          ),
        ),
        const PopupMenuDivider(height: 1),
        PopupMenuItem(
          value: 'logout',
          height: 40,
          child: Row(
            children: [
              const Icon(Icons.logout_rounded,
                  size: 18, color: Color(0xFFFF5252)),
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
  // PAGE HEADER
  // ============================================================================
  Widget _buildPageHeader() {
    return Column(
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
                Icons.history_rounded,
                color: AppTheme.primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Riwayat Peminjaman',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Lihat semua riwayat peminjaman dan pengembalian buku',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0);
  }

  // ============================================================================
  // STATISTICS GRID
  // ============================================================================
  Widget _buildStatisticsGrid(
    int total,
    int pending,
    int aktif,
    int selesai,
    int ditolak,
    int terlambat,
  ) {
    final stats = [
      _StatCard(
        title: 'Total',
        value: total.toString(),
        icon: Icons.book_rounded,
        color: const Color(0xFF6366F1),
      ),
      _StatCard(
        title: 'Menunggu',
        value: pending.toString(),
        icon: Icons.pending_rounded,
        color: const Color(0xFFFF9800),
      ),
      _StatCard(
        title: 'Dipinjam',
        value: aktif.toString(),
        icon: Icons.bookmark_rounded,
        color: const Color(0xFF2196F3),
      ),
      _StatCard(
        title: 'Selesai',
        value: selesai.toString(),
        icon: Icons.check_circle_rounded,
        color: const Color(0xFF4CAF50),
      ),
      _StatCard(
        title: 'Ditolak',
        value: ditolak.toString(),
        icon: Icons.cancel_rounded,
        color: const Color(0xFFEF4444),
      ),
      _StatCard(
        title: 'Terlambat',
        value: terlambat.toString(),
        icon: Icons.warning_rounded,
        color: const Color(0xFFDC2626),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = _isDesktop
            ? 6
            : _isTablet
                ? 3
                : 3;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: _isDesktop ? 1.3 : 1.1,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: stats.length,
          itemBuilder: (context, index) => _buildStatCard(stats[index], index),
        );
      },
    ).animate().fadeIn(duration: 400.ms, delay: 100.ms);
  }

  Widget _buildStatCard(_StatCard stat, int index) {
    return Container(
      padding: EdgeInsets.all(_isDesktop ? 12 : 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: stat.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(stat.icon, color: stat.color, size: 16),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                stat.value,
                style: TextStyle(
                  fontSize: _isDesktop ? 20 : 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A1A),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                stat.title,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // SEARCH BAR
  // ============================================================================
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Cari kode peminjaman atau nama buku...',
          hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          prefixIcon: Icon(
            Icons.search_rounded,
            size: 20,
            color: Colors.grey.shade500,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear_rounded,
                      size: 18, color: Colors.grey.shade500),
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        style: const TextStyle(fontSize: 13),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 150.ms);
  }

  // ============================================================================
  // STATUS FILTER
  // ============================================================================
  Widget _buildStatusFilter() {
    final filters = [
      {'id': null, 'label': 'Semua', 'icon': Icons.all_inclusive_rounded},
      {'id': 1, 'label': 'Menunggu', 'icon': Icons.pending_rounded},
      {'id': 2, 'label': 'Dipinjam', 'icon': Icons.bookmark_rounded},
      {'id': 4, 'label': 'Selesai', 'icon': Icons.check_circle_rounded},
      {'id': 3, 'label': 'Ditolak', 'icon': Icons.cancel_rounded},
      {'id': 5, 'label': 'Terlambat', 'icon': Icons.warning_rounded},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Filter Status',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: filters.map((filter) {
              final isSelected = _selectedStatusFilter == filter['id'];
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildFilterChip(
                  label: filter['label'] as String,
                  icon: filter['icon'] as IconData,
                  isSelected: isSelected,
                  onTap: () {
                    setState(() {
                      _selectedStatusFilter = filter['id'] as int?;
                    });
                  },
                ),
              );
            }).toList(),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms, delay: 200.ms);
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryColor : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? AppTheme.primaryColor
                  : Colors.grey.shade300,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected ? Colors.white : Colors.grey.shade700,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // RESULTS HEADER
  // ============================================================================
  Widget _buildResultsHeader(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Hasil Pencarian',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
            letterSpacing: -0.1,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '$count transaksi',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
            ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms, delay: 250.ms);
  }

  // ============================================================================
  // HISTORY CARD
  // ============================================================================
  Widget _buildHistoryCard(PeminjamanModel peminjaman, int index) {
    final statusInfo = _getStatusInfo(peminjaman.statusPeminjamanId ?? 0);
    final bukuNama = peminjaman.alat?.namaAlat ?? 'Buku';
    final isOverdue = peminjaman.isOverdue &&
        (peminjaman.statusPeminjamanId == 2 ||
            peminjaman.statusPeminjamanId == 5);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOverdue
              ? const Color(0xFFDC2626).withOpacity(0.3)
              : Colors.grey.shade200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showDetailDialog(peminjaman),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: statusInfo['color'].withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        statusInfo['icon'],
                        color: statusInfo['color'],
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bukuNama,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A1A),
                              letterSpacing: -0.1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            peminjaman.kodePeminjaman,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: statusInfo['color'].withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        statusInfo['label'],
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: statusInfo['color'],
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                Divider(height: 1, color: Colors.grey.shade200),
                const SizedBox(height: 12),

                // Details Grid
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (_isDesktop || _isTablet) {
                      return Row(
                        children: [
                          Expanded(
                            child: _buildDetailItem(
                              Icons.calendar_today_outlined,
                              'Tanggal Pinjam',
                              peminjaman.tanggalPinjam != null
                                  ? DateFormat('dd MMM yyyy')
                                      .format(peminjaman.tanggalPinjam!)
                                  : '-',
                            ),
                          ),
                          Expanded(
                            child: _buildDetailItem(
                              Icons.event_outlined,
                              'Jatuh Tempo',
                              DateFormat('dd MMM yyyy')
                                  .format(peminjaman.tanggalBerakhir),
                            ),
                          ),
                          Expanded(
                            child: _buildDetailItem(
                              Icons.numbers_rounded,
                              'Jumlah',
                              '${peminjaman.jumlahPinjam} buku',
                            ),
                          ),
                        ],
                      );
                    } else {
                      return Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildDetailItem(
                                  Icons.calendar_today_outlined,
                                  'Tanggal Pinjam',
                                  peminjaman.tanggalPinjam != null
                                      ? DateFormat('dd MMM yyyy')
                                          .format(peminjaman.tanggalPinjam!)
                                      : '-',
                                ),
                              ),
                              Expanded(
                                child: _buildDetailItem(
                                  Icons.event_outlined,
                                  'Jatuh Tempo',
                                  DateFormat('dd MMM yyyy')
                                      .format(peminjaman.tanggalBerakhir),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _buildDetailItem(
                            Icons.numbers_rounded,
                            'Jumlah',
                            '${peminjaman.jumlahPinjam} buku',
                          ),
                        ],
                      );
                    }
                  },
                ),

                // Warning for overdue
                if (isOverdue) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDC2626).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFDC2626).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.warning_rounded,
                          color: Color(0xFFDC2626),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Terlambat ${peminjaman.daysOverdue} hari • Denda: ${_calculateDenda(peminjaman)}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFDC2626),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms, delay: (index * 50).ms);
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade600),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // EMPTY STATE
  // ============================================================================
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.history_toggle_off_rounded,
              size: 56,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Tidak Ada Riwayat',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty || _selectedStatusFilter != null
                ? 'Tidak ada hasil yang sesuai dengan filter'
                : 'Belum ada riwayat peminjaman',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // DETAIL DIALOG
  // ============================================================================
  void _showDetailDialog(PeminjamanModel peminjaman) {
    final statusInfo = _getStatusInfo(peminjaman.statusPeminjamanId ?? 0);
    final isOverdue = peminjaman.isOverdue &&
        (peminjaman.statusPeminjamanId == 2 ||
            peminjaman.statusPeminjamanId == 5);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.all(20),
        content: SizedBox(
          width: _isDesktop ? 500 : double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: statusInfo['color'].withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      statusInfo['icon'],
                      color: statusInfo['color'],
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Detail Peminjaman',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          peminjaman.kodePeminjaman,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                    iconSize: 20,
                  ),
                ],
              ),

              const SizedBox(height: 16),
              Divider(height: 1, color: Colors.grey.shade200),
              const SizedBox(height: 16),

              // Details
              _buildDialogDetailRow(
                'Buku',
                peminjaman.alat?.namaAlat ?? '-',
              ),
              _buildDialogDetailRow(
                'Kategori',
                peminjaman.alat?.kategori?.namaKategori ?? '-',
              ),
              _buildDialogDetailRow(
                'Jumlah Pinjam',
                '${peminjaman.jumlahPinjam} buku',
              ),
              _buildDialogDetailRow(
                'Tanggal Pengajuan',
                peminjaman.tanggalPengajuan != null
                    ? DateFormat('dd MMMM yyyy, HH:mm')
                        .format(peminjaman.tanggalPengajuan!)
                    : '-',
              ),
              _buildDialogDetailRow(
                'Tanggal Pinjam',
                peminjaman.tanggalPinjam != null
                    ? DateFormat('dd MMMM yyyy')
                        .format(peminjaman.tanggalPinjam!)
                    : '-',
              ),
              _buildDialogDetailRow(
                'Tanggal Jatuh Tempo',
                DateFormat('dd MMMM yyyy').format(peminjaman.tanggalBerakhir),
              ),
              _buildDialogDetailRow(
                'Status',
                statusInfo['label'],
                valueColor: statusInfo['color'],
              ),
              if (peminjaman.keperluan != null)
                _buildDialogDetailRow(
                  'Keperluan',
                  peminjaman.keperluan!,
                ),
              if (peminjaman.catatanPetugas != null)
                _buildDialogDetailRow(
                  'Catatan Petugas',
                  peminjaman.catatanPetugas!,
                ),

              // Overdue Warning
              if (isOverdue) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDC2626).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFDC2626).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.warning_rounded,
                            color: Color(0xFFDC2626),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Peringatan Keterlambatan',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFDC2626),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Terlambat ${peminjaman.daysOverdue} hari',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFDC2626),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Denda: ${_calculateDenda(peminjaman)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFDC2626),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Action Button
              if (peminjaman.statusPeminjamanId == 2 ||
                  peminjaman.statusPeminjamanId == 5)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      context.go('/peminjam/kembalikan');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.assignment_return_rounded, size: 18),
                    label: const Text(
                      'Kembalikan Buku',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDialogDetailRow(String label, String value,
      {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: valueColor ?? const Color(0xFF1A1A1A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // HELPERS
  // ============================================================================
  Map<String, dynamic> _getStatusInfo(int statusId) {
    switch (statusId) {
      case 1:
        return {
          'label': 'Menunggu',
          'icon': Icons.pending_rounded,
          'color': const Color(0xFFFF9800),
        };
      case 2:
        return {
          'label': 'Dipinjam',
          'icon': Icons.bookmark_rounded,
          'color': const Color(0xFF2196F3),
        };
      case 3:
        return {
          'label': 'Ditolak',
          'icon': Icons.cancel_rounded,
          'color': const Color(0xFFEF4444),
        };
      case 4:
        return {
          'label': 'Selesai',
          'icon': Icons.check_circle_rounded,
          'color': const Color(0xFF4CAF50),
        };
      case 5:
        return {
          'label': 'Terlambat',
          'icon': Icons.warning_rounded,
          'color': const Color(0xFFDC2626),
        };
      default:
        return {
          'label': 'Unknown',
          'icon': Icons.help_outline_rounded,
          'color': Colors.grey,
        };
    }
  }

  String _calculateDenda(PeminjamanModel peminjaman) {
    if (!peminjaman.isOverdue) return 'Rp 0';
    final hargaPerhari = peminjaman.alat?.hargaPerhari ?? 0;
    final denda = peminjaman.daysOverdue * hargaPerhari;
    return 'Rp ${NumberFormat('#,###', 'id_ID').format(denda)}';
  }
}

// ============================================================================
// STAT CARD MODEL
// ============================================================================
class _StatCard {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });
}
