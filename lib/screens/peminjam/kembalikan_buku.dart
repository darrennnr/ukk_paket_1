// lib/screens/peminjam/kembalikan_buku.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:paket_3_training/core/design_system/app_color.dart';
import 'package:paket_3_training/widgets/pengguna_sidebar.dart';
import '../../providers/peminjaman_provider.dart';
import '../../providers/pengembalian_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/peminjaman_model.dart';

class KembalikanBukuScreen extends ConsumerStatefulWidget {
  const KembalikanBukuScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<KembalikanBukuScreen> createState() =>
      _KembalikanBukuScreenState();
}

class _KembalikanBukuScreenState extends ConsumerState<KembalikanBukuScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _searchQuery = '';
  bool _hasInitializedProviders = false;

  bool get _isDesktop => MediaQuery.of(context).size.width >= 900;
  bool get _isTablet =>
      MediaQuery.of(context).size.width >= 600 &&
      MediaQuery.of(context).size.width < 900;

  @override
  void initState() {
    super.initState();
    // Provider initialization is now done in build method when auth is ready
  }

  void _initializeProviders() {
    if (!_hasInitializedProviders) {
      _hasInitializedProviders = true;
      ref.read(myPeminjamanProvider.notifier).refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final peminjamanState = ref.watch(myPeminjamanProvider);
    final user = authState.user;

    // Wait for auth to complete before initializing providers
    if (!authState.isLoading && authState.isAuthenticated && !_hasInitializedProviders) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initializeProviders();
      });
    }

    // Filter hanya peminjaman yang sedang dipinjam (status 2 atau 5)
    final activePeminjaman = peminjamanState.peminjamans.where((p) {
      final isActive =
          p.statusPeminjamanId == 2 || p.statusPeminjamanId == 5;
      final matchesSearch = _searchQuery.isEmpty ||
          (p.alat?.namaAlat.toLowerCase().contains(_searchQuery.toLowerCase()) ??
              false) ||
          p.kodePeminjaman.toLowerCase().contains(_searchQuery.toLowerCase());

      return isActive && matchesSearch;
    }).toList();

    // Sort: overdue first, then by due date
    activePeminjaman.sort((a, b) {
      if (a.isOverdue && !b.isOverdue) return -1;
      if (!a.isOverdue && b.isOverdue) return 1;
      return a.tanggalBerakhir.compareTo(b.tanggalBerakhir);
    });

    // Statistics
    final totalAktif = activePeminjaman.length;
    final terlambat = activePeminjaman.where((p) => p.isOverdue).length;
    final totalDenda = activePeminjaman.fold<double>(0, (sum, p) {
      if (p.isOverdue) {
        final harga = p.alat?.hargaPerhari ?? 0;
        return sum + (p.daysOverdue * harga);
      }
      return sum;
    });

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildAppBar(context, user?.namaLengkap ?? 'Peminjam'),
      drawer: _isDesktop
          ? null
          : PenggunaSidebar(currentRoute: '/peminjam/kembalikan'),
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
              child: PenggunaSidebar(currentRoute: '/peminjam/kembalikan'),
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
                          _buildStatisticsGrid(totalAktif, terlambat, totalDenda),
                          const SizedBox(height: 20),
                          if (activePeminjaman.isNotEmpty) _buildSearchBar(),
                          if (activePeminjaman.isNotEmpty) const SizedBox(height: 20),
                          if (activePeminjaman.isNotEmpty)
                            _buildResultsHeader(activePeminjaman.length),
                        ],
                      ),
                    ),
                  ),

                  // Book List
                  if (peminjamanState.isLoading)
                    SliverFillRemaining(
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.primaryColor,
                          strokeWidth: 2,
                        ),
                      ),
                    )
                  else if (activePeminjaman.isEmpty)
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
                            final peminjaman = activePeminjaman[index];
                            return _buildBookCard(peminjaman, index);
                          },
                          childCount: activePeminjaman.length,
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
        'Kembalikan Buku',
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
        if (value == 'history') context.go('/peminjam/history');
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
        PopupMenuItem(
          value: 'history',
          height: 40,
          child: Row(
            children: [
              Icon(Icons.history_rounded, size: 18, color: Colors.grey.shade700),
              const SizedBox(width: 10),
              const Text('History', style: TextStyle(fontSize: 13)),
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
                Icons.assignment_return_rounded,
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
                    'Kembalikan Buku',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Pilih buku yang ingin dikembalikan',
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
  Widget _buildStatisticsGrid(int totalAktif, int terlambat, double totalDenda) {
    final stats = [
      _StatCard(
        title: 'Sedang Dipinjam',
        value: totalAktif.toString(),
        icon: Icons.bookmark_rounded,
        color: const Color(0xFF2196F3),
      ),
      _StatCard(
        title: 'Terlambat',
        value: terlambat.toString(),
        icon: Icons.warning_rounded,
        color: const Color(0xFFDC2626),
      ),
      _StatCard(
        title: 'Total Denda',
        value: 'Rp ${NumberFormat('#,###', 'id_ID').format(totalDenda)}',
        icon: Icons.payments_rounded,
        color: const Color(0xFFFF9800),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = _isDesktop ? 3 : 3;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: _isDesktop ? 1.8 : 1.3,
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
      padding: EdgeInsets.all(_isDesktop ? 14 : 12),
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
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: stat.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(stat.icon, color: stat.color, size: 18),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  stat.value,
                  style: TextStyle(
                    fontSize: _isDesktop ? 20 : 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A1A),
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                stat.title,
                style: TextStyle(
                  fontSize: 11,
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
          hintText: 'Cari buku yang dipinjam...',
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
  // RESULTS HEADER
  // ============================================================================
  Widget _buildResultsHeader(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Buku yang Dipinjam',
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
            '$count buku',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
            ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms, delay: 200.ms);
  }

  // ============================================================================
  // BOOK CARD
  // ============================================================================
  Widget _buildBookCard(PeminjamanModel peminjaman, int index) {
    final bukuNama = peminjaman.alat?.namaAlat ?? 'Buku';
    final isOverdue = peminjaman.isOverdue;
    final hargaPerhari = peminjaman.alat?.hargaPerhari ?? 0;
    final denda = isOverdue ? (peminjaman.daysOverdue * hargaPerhari) : 0.0;
    final totalBiaya = (peminjaman.jumlahPinjam * hargaPerhari) + denda;

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
                    color: isOverdue
                        ? const Color(0xFFDC2626).withOpacity(0.1)
                        : const Color(0xFF2196F3).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isOverdue ? Icons.warning_rounded : Icons.bookmark_rounded,
                    color: isOverdue
                        ? const Color(0xFFDC2626)
                        : const Color(0xFF2196F3),
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
                if (isOverdue)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDC2626).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'TERLAMBAT',
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFDC2626),
                        letterSpacing: 0.3,
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

            // Overdue Warning
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
                        'Terlambat ${peminjaman.daysOverdue} hari • Denda: Rp ${NumberFormat('#,###', 'id_ID').format(denda)}',
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

            const SizedBox(height: 12),

            // Payment Summary
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.primaryColor.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Biaya Peminjaman',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      Text(
                        'Rp ${NumberFormat('#,###', 'id_ID').format(peminjaman.jumlahPinjam * hargaPerhari)}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                    ],
                  ),
                  if (isOverdue) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Denda Keterlambatan',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        Text(
                          'Rp ${NumberFormat('#,###', 'id_ID').format(denda)}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFDC2626),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Divider(height: 1, color: Colors.grey.shade300),
                    const SizedBox(height: 8),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Pembayaran',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      Text(
                        'Rp ${NumberFormat('#,###', 'id_ID').format(totalBiaya)}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Return Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showReturnDialog(peminjaman, totalBiaya),
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
              Icons.check_circle_outline_rounded,
              size: 56,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Tidak Ada Buku yang Dipinjam',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Semua buku sudah dikembalikan',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.go('/peminjam/buku'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
            ),
            icon: const Icon(Icons.menu_book_rounded, size: 18),
            label: const Text(
              'Lihat Daftar Buku',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // RETURN DIALOG
  // ============================================================================
  void _showReturnDialog(PeminjamanModel peminjaman, double totalBiaya) {
    final kondisiController = TextEditingController(text: 'Baik');
    final catatanController = TextEditingController();
    final isOverdue = peminjaman.isOverdue;
    final user = ref.read(authProvider).user;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.all(20),
          content: SizedBox(
            width: _isDesktop ? 500 : double.maxFinite,
            child: SingleChildScrollView(
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
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.assignment_return_rounded,
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
                              'Konfirmasi Pengembalian',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              peminjaman.alat?.namaAlat ?? 'Buku',
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

                  // Overdue Warning
                  if (isOverdue) ...[
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
                      child: Row(
                        children: [
                          const Icon(
                            Icons.warning_rounded,
                            color: Color(0xFFDC2626),
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Peringatan Keterlambatan',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFDC2626),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Terlambat ${peminjaman.daysOverdue} hari dari tanggal jatuh tempo',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFFDC2626),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Payment Summary
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.primaryColor.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rincian Pembayaran',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildPaymentRow(
                          'Biaya Peminjaman',
                          'Rp ${NumberFormat('#,###', 'id_ID').format(peminjaman.jumlahPinjam * (peminjaman.alat?.hargaPerhari ?? 0))}',
                        ),
                        if (isOverdue) ...[
                          const SizedBox(height: 8),
                          _buildPaymentRow(
                            'Denda Keterlambatan (${peminjaman.daysOverdue} hari)',
                            'Rp ${NumberFormat('#,###', 'id_ID').format(peminjaman.daysOverdue * (peminjaman.alat?.hargaPerhari ?? 0))}',
                            isHighlight: true,
                          ),
                        ],
                        const SizedBox(height: 12),
                        Divider(height: 1, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Pembayaran',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            Text(
                              'Rp ${NumberFormat('#,###', 'id_ID').format(totalBiaya)}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Kondisi Buku
                  Text(
                    'Kondisi Buku',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300, width: 1),
                    ),
                    child: DropdownButtonFormField<String>(
                      value: kondisiController.text,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        prefixIcon: Icon(
                          Icons.check_circle_outline_rounded,
                          size: 18,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      style: const TextStyle(fontSize: 13, color: Color(0xFF1A1A1A)),
                      dropdownColor: Colors.white,
                      items: ['Baik', 'Rusak Ringan', 'Rusak Berat']
                          .map((kondisi) => DropdownMenuItem(
                                value: kondisi,
                                child: Text(kondisi),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          kondisiController.text = value ?? 'Baik';
                        });
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Catatan
                  Text(
                    'Catatan (Opsional)',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300, width: 1),
                    ),
                    child: TextField(
                      controller: catatanController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Tambahkan catatan jika diperlukan...',
                        hintStyle: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 13,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(14),
                      ),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(
                            'Batal',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () => _handleReturn(
                            context,
                            peminjaman,
                            kondisiController.text,
                            catatanController.text,
                            user?.userId ?? 0,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text(
                            'Konfirmasi Pengembalian',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentRow(String label, String value, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isHighlight
                ? const Color(0xFFDC2626)
                : Colors.grey.shade700,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isHighlight
                ? const Color(0xFFDC2626)
                : const Color(0xFF1A1A1A),
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // HANDLE RETURN
  // ============================================================================
  Future<void> _handleReturn(
    BuildContext context,
    PeminjamanModel peminjaman,
    String kondisi,
    String catatan,
    int userId,
  ) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: AppTheme.primaryColor,
                strokeWidth: 2,
              ),
              const SizedBox(height: 16),
              const Text(
                'Memproses pengembalian...',
                style: TextStyle(fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      // Process return
      final success = await ref.read(pengembalianProvider.notifier).prosesPengembalian(
            peminjamanId: peminjaman.peminjamanId,
            petugasId: userId, // User acts as their own processor
            kondisiAlat: kondisi,
            catatan: catatan.isEmpty ? null : catatan,
          );

      // Close loading
      if (mounted) Navigator.pop(context);

      if (success) {
        // Close dialog
        if (mounted) Navigator.pop(context);

        // Refresh data
        await ref.read(myPeminjamanProvider.notifier).refresh();

        // Show success
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Buku berhasil dikembalikan',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF4CAF50),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      } else {
        // Show error
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      ref.read(pengembalianProvider).errorMessage ??
                          'Gagal mengembalikan buku',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      }
    } catch (e) {
      // Close loading
      if (mounted) Navigator.pop(context);

      // Show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Terjadi kesalahan: ${e.toString()}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
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
