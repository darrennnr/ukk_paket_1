// lib/screens/peminjam/dashboard_pengguna.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:paket_3_training/core/design_system/app_color.dart';
import 'package:paket_3_training/core/design_system/app_design_system.dart'
    hide AppTheme;
import 'package:paket_3_training/widgets/pengguna_sidebar.dart';
import '../../providers/peminjaman_provider.dart';
import '../../providers/alat_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/alat_model.dart';
import '../../models/peminjaman_model.dart' hide AlatModel;

class DashboardPeminjam extends ConsumerStatefulWidget {
  const DashboardPeminjam({Key? key}) : super(key: key);

  @override
  ConsumerState<DashboardPeminjam> createState() => _DashboardPeminjamState();
}

class _DashboardPeminjamState extends ConsumerState<DashboardPeminjam>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late TabController _tabController;
  bool get _isDesktop => MediaQuery.of(context).size.width >= 900;
  bool _hasInitializedProviders = false;

  // Form state
  final _formKey = GlobalKey<FormState>();
  int? _selectedBukuId;
  int _jumlahPinjam = 1;
  DateTime? _tanggalBerakhir;
  String _keperluan = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    // Provider initialization is now done in build method when auth is ready
  }

  void _initializeProviders() {
    if (!_hasInitializedProviders) {
      _hasInitializedProviders = true;
      ref.read(myPeminjamanProvider.notifier).ensureInitialized();
      ref.read(alatTersediaProvider.notifier).ensureInitialized();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final myPeminjamanState = ref.watch(myPeminjamanProvider);
    final alatTersediaState = ref.watch(alatTersediaProvider);
    final user = authState.user;

    // Wait for auth to complete before initializing providers
    if (!authState.isLoading &&
        authState.isAuthenticated &&
        !_hasInitializedProviders) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initializeProviders();
      });
    }

    // Show loading state while auth is loading
    if (authState.isLoading) {
      return Scaffold(
        key: _scaffoldKey,
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: _buildAppBar(context, 'Loading...'),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Filter peminjaman aktif dan pending
    final activePeminjamans = myPeminjamanState.peminjamans
        .where((p) => p.statusPeminjamanId == 2) // Status Dipinjam
        .toList();

    final pendingPeminjamans = myPeminjamanState.peminjamans
        .where((p) => p.statusPeminjamanId == 1) // Status Pending
        .toList();

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildAppBar(context, user?.namaLengkap ?? 'Peminjam'),
      drawer: _isDesktop
          ? null
          : PenggunaSidebar(currentRoute: '/peminjam/dashboard'),
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
              child: PenggunaSidebar(currentRoute: '/peminjam/dashboard'),
            ),
          Expanded(
            child: Column(
              children: [
                // Tab Bar
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade200, width: 1),
                    ),
                  ),
                  // child: TabBar(
                  //   controller: _tabController,
                  //   labelColor: AppTheme.primaryColor,
                  //   unselectedLabelColor: Colors.grey.shade600,
                  //   indicatorColor: AppTheme.primaryColor,
                  //   indicatorSize: TabBarIndicatorSize.label,
                  //   labelStyle: const TextStyle(
                  //     fontSize: 12,
                  //     fontWeight: FontWeight.w600,
                  //   ),
                  //   unselectedLabelStyle: const TextStyle(
                  //     fontSize: 12,
                  //     fontWeight: FontWeight.w500,
                  //   ),
                  //   tabs: [
                  //     Tab(
                  //       text: 'Dashboard',
                  //       icon: Icon(Icons.dashboard_rounded, size: 16),
                  //     ),
                  //     Tab(
                  //       text: 'Daftar Buku',
                  //       icon: Icon(Icons.menu_book_rounded, size: 16),
                  //     ),
                  //     Tab(
                  //       text: 'Ajukan Pinjam',
                  //       icon: Icon(Icons.add_circle_outline_rounded, size: 16),
                  //     ),
                  //     Tab(
                  //       text: 'Kembalikan',
                  //       icon: Icon(Icons.assignment_return_rounded, size: 16),
                  //     ),
                  //   ],
                  // ),
                ),

                // Tab Content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildDashboardTab(
                        myPeminjamanState,
                        activePeminjamans,
                        pendingPeminjamans,
                      ),
                      _buildDaftarBukuTab(alatTersediaState),
                      _buildAjukanPeminjamanTab(alatTersediaState),
                      _buildKembalikanBukuTab(activePeminjamans),
                    ],
                  ),
                ),
              ],
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
        'Dashboard Peminjam',
        style: TextStyle(
          color: const Color(0xFF1A1A1A),
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
      ),
      actions: [
        if (_isDesktop) ...[
          _buildIconButton(Icons.notifications_outlined, () {}, badge: '2'),
          const SizedBox(width: 4),
        ],
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

  Widget _buildIconButton(IconData icon, VoidCallback onTap, {String? badge}) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: Icon(icon, color: Colors.grey.shade700, size: 20),
          onPressed: onTap,
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        ),
        if (badge != null)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: const Color(0xFFFF5252),
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
              child: Text(
                badge,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
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
                color: Colors.grey.shade700,
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

  // ============================================================================
  // TAB 1: DASHBOARD
  // ============================================================================
  Widget _buildDashboardTab(
    PeminjamanState peminjamanState,
    List<PeminjamanModel> activePeminjamans,
    List<PeminjamanModel> pendingPeminjamans,
  ) {
    final totalPeminjaman = peminjamanState.peminjamans.length;

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(myPeminjamanProvider.notifier).refresh();
        await ref.read(alatTersediaProvider.notifier).refresh();
      },
      color: AppTheme.primaryColor,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(_isDesktop ? 24 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Header
            _buildWelcomeHeader(),
            const SizedBox(height: 24),

            // Statistics Grid
            _buildStatisticsGrid(
              totalPeminjaman,
              activePeminjamans.length,
              pendingPeminjamans.length,
            ),
            const SizedBox(height: 24),

            // Peminjaman Aktif
            if (activePeminjamans.isNotEmpty) ...[
              _buildSectionHeader(
                'Sedang Dipinjam',
                Icons.bookmark_rounded,
                Colors.blue,
              ),
              const SizedBox(height: 12),
              _buildPeminjamanList(activePeminjamans, true),
              const SizedBox(height: 24),
            ],

            // Peminjaman Pending
            if (pendingPeminjamans.isNotEmpty) ...[
              _buildSectionHeader(
                'Menunggu Persetujuan',
                Icons.pending_actions_rounded,
                Colors.orange,
              ),
              const SizedBox(height: 12),
              _buildPeminjamanList(pendingPeminjamans, false),
              const SizedBox(height: 24),
            ],

            // History Button
            _buildHistorySection(peminjamanState),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    final hour = DateTime.now().hour;
    String greeting = hour < 12
        ? 'Selamat Pagi'
        : hour < 18
        ? 'Selamat Siang'
        : 'Selamat Malam';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Selamat datang di Perpustakaan Digital',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
            letterSpacing: -0.3,
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0);
  }

  Widget _buildStatisticsGrid(int total, int aktif, int pending) {
    final stats = [
      _StatCard(
        title: 'Total Pinjaman',
        value: total.toString(),
        icon: Icons.book_rounded,
        color: const Color(0xFF4CAF50),
      ),
      _StatCard(
        title: 'Sedang Dipinjam',
        value: aktif.toString(),
        icon: Icons.bookmark_rounded,
        color: const Color(0xFF2196F3),
      ),
      _StatCard(
        title: 'Menunggu',
        value: pending.toString(),
        icon: Icons.pending_rounded,
        color: const Color(0xFFFF9800),
      ),
      _StatCard(
        title: 'Selesai',
        value: (total - aktif - pending).toString(),
        icon: Icons.check_circle_rounded,
        color: const Color(0xFF9C27B0),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = constraints.maxWidth > 1200
            ? 4
            : constraints.maxWidth > 900
            ? 2
            : 2;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 1.7,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: stats.length,
          itemBuilder: (context, index) => _buildStatCard(stats[index], index),
        );
      },
    );
  }

  Widget _buildStatCard(_StatCard stat, int index) {
    return Container(
      padding: const EdgeInsets.all(14),
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
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: stat.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(stat.icon, color: stat.color, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                stat.value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                stat.title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: (index * 50).ms);
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 14, color: color),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildPeminjamanList(
    List<PeminjamanModel> peminjamans,
    bool isActive,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: peminjamans.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          thickness: 1,
          color: Colors.grey.shade100,
          indent: 12,
          endIndent: 12,
        ),
        itemBuilder: (context, index) {
          final peminjaman = peminjamans[index];
          return _buildPeminjamanItem(peminjaman, index, isActive);
        },
      ),
    );
  }

  Widget _buildPeminjamanItem(
    PeminjamanModel peminjaman,
    int index,
    bool isActive,
  ) {
    final bukuNama = peminjaman.alat?.namaAlat ?? 'Buku';
    final tanggal = isActive
        ? (peminjaman.tanggalBerakhir != null
              ? DateFormat('dd MMM yyyy').format(peminjaman.tanggalBerakhir)
              : '-')
        : (peminjaman.tanggalPengajuan != null
              ? DateFormat('dd MMM yyyy').format(peminjaman.tanggalPengajuan!)
              : '-');

    final statusText = isActive ? 'Aktif' : 'Pending';
    final statusColor = isActive
        ? const Color(0xFF4CAF50)
        : const Color(0xFFFF9800);

    final daysInfo = isActive && peminjaman.isOverdue
        ? 'Terlambat ${peminjaman.daysOverdue} hari'
        : isActive
        ? 'Sisa ${peminjaman.daysRemaining} hari'
        : 'Menunggu persetujuan';

    return Container(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isActive ? Icons.bookmark_rounded : Icons.pending_rounded,
              color: statusColor,
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
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 11,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      tanggal,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  daysInfo,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: (index * 80).ms);
  }

  Widget _buildHistorySection(PeminjamanState peminjamanState) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.go('/peminjam/history'),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade200, width: 1),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
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
                      'History Peminjaman',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Lihat semua riwayat peminjaman buku',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryDialogContent(PeminjamanState peminjamanState) {
    final allPeminjamans = peminjamanState.peminjamans;

    if (allPeminjamans.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history_toggle_off_rounded,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Belum ada riwayat peminjaman',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: allPeminjamans.length,
      separatorBuilder: (context, index) =>
          Divider(height: 1, color: Colors.grey.shade200),
      itemBuilder: (context, index) {
        final peminjaman = allPeminjamans[index];
        final bukuNama = peminjaman.alat?.namaAlat ?? 'Buku';
        final tanggal = peminjaman.tanggalPengajuan != null
            ? DateFormat('dd MMM yyyy').format(peminjaman.tanggalPengajuan!)
            : '-';

        Color statusColor;
        String statusText;

        switch (peminjaman.statusPeminjamanId) {
          case 1:
            statusColor = Colors.orange;
            statusText = 'Pending';
            break;
          case 2:
            statusColor = Colors.blue;
            statusText = 'Dipinjam';
            break;
          case 3:
            statusColor = Colors.red;
            statusText = 'Ditolak';
            break;
          case 4:
            statusColor = Colors.green;
            statusText = 'Selesai';
            break;
          default:
            statusColor = Colors.grey;
            statusText = 'Unknown';
        }

        return ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.book_rounded, color: statusColor, size: 20),
          ),
          title: Text(
            bukuNama,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            tanggal,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              statusText,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ),
        );
      },
    );
  }

  // ============================================================================
  // TAB 2: DAFTAR BUKU
  // ============================================================================
  Widget _buildDaftarBukuTab(AlatState alatState) {
    final books = alatState.alats;

    return RefreshIndicator(
      onRefresh: () => ref.read(alatTersediaProvider.notifier).refresh(),
      color: AppTheme.primaryColor,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: EdgeInsets.all(_isDesktop ? 24 : 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Search Bar
                _buildSearchBar(),
                const SizedBox(height: 16),

                // Grid Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Buku Tersedia',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    Text(
                      '${books.length} buku',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ]),
            ),
          ),

          // Book Grid
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: _isDesktop ? 24 : 16),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _isDesktop ? 4 : 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.7,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                final book = books[index];
                return _buildBookCard(book, index);
              }, childCount: books.length),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.only(bottom: 24),
            sliver: SliverToBoxAdapter(child: Container()),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Cari buku...',
          hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          prefixIcon: Icon(
            Icons.search_rounded,
            size: 18,
            color: Colors.grey.shade500,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        style: const TextStyle(fontSize: 13),
        onChanged: (value) {
          ref.read(alatTersediaProvider.notifier).refresh();
        },
      ),
    );
  }

  Widget _buildBookCard(AlatModel book, int index) {
    final isAvailable = book.jumlahTersedia > 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (isAvailable) {
            _selectedBukuId = book.alatId;
            _showPinjamDialog(book);
          }
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade200, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Book Image Placeholder
              Container(
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10),
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.menu_book_rounded,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                ),
              ),

              // Book Info
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            book.namaAlat,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A1A),
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          if (book.kategori != null)
                            Text(
                              book.kategori!.namaKategori,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                        ],
                      ),

                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.inventory_2_outlined,
                                size: 11,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Tersedia: ${book.jumlahTersedia}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.attach_money_rounded,
                                size: 11,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                book.hargaPerhari != null
                                    ? 'Rp ${book.hargaPerhari!.toStringAsFixed(0)}/hari'
                                    : 'Gratis',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // Borrow Button
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: isAvailable
                              ? AppTheme.primaryColor
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: Text(
                            isAvailable ? 'PINJAM' : 'HABIS',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isAvailable
                                  ? Colors.white
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms, delay: (index * 50).ms);
  }

  void _showPinjamDialog(AlatModel book) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Icon(
              Icons.menu_book_rounded,
              color: AppTheme.primaryColor,
              size: 20,
            ),
            const SizedBox(width: 10),
            const Text(
              'Pinjam Buku',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.namaAlat,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),

                // Jumlah
                TextFormField(
                  initialValue: '1',
                  decoration: InputDecoration(
                    labelText: 'Jumlah',
                    hintText: 'Masukkan jumlah',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  style: const TextStyle(fontSize: 13),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Jumlah harus diisi';
                    }
                    final intVal = int.tryParse(value);
                    if (intVal == null || intVal <= 0) {
                      return 'Jumlah harus bilangan positif';
                    }
                    if (intVal > book.jumlahTersedia) {
                      return 'Maksimal ${book.jumlahTersedia} buku';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _jumlahPinjam = int.tryParse(value ?? '1') ?? 1;
                  },
                ),
                const SizedBox(height: 12),

                // Tanggal Berakhir
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(days: 7)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(DateTime.now().year + 1),
                    );
                    if (picked != null) {
                      setState(() {
                        _tanggalBerakhir = picked;
                      });
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 18,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _tanggalBerakhir != null
                                ? DateFormat(
                                    'dd MMMM yyyy',
                                  ).format(_tanggalBerakhir!)
                                : 'Pilih tanggal pengembalian',
                            style: TextStyle(
                              fontSize: 13,
                              color: _tanggalBerakhir != null
                                  ? Colors.black
                                  : Colors.grey.shade500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Keperluan
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Keperluan',
                    hintText: 'Tujuan peminjaman buku',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  style: const TextStyle(fontSize: 13),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Keperluan harus diisi';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _keperluan = value ?? '';
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Batal',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                _formKey.currentState!.save();
                if (_tanggalBerakhir == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Harap pilih tanggal pengembalian'),
                    ),
                  );
                  return;
                }
                _submitPeminjaman(book);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text(
              'Ajukan',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitPeminjaman(AlatModel book) async {
    final user = ref.read(authProvider).user;
    if (user == null) return;

    // Generate kode peminjaman
    final kode = 'PJN-${DateTime.now().millisecondsSinceEpoch}';

    final peminjaman = PeminjamanModel(
      peminjamanId: 0,
      peminjamId: user.userId,
      alatId: book.alatId,
      kodePeminjaman: kode,
      jumlahPinjam: _jumlahPinjam,
      tanggalBerakhir: _tanggalBerakhir!,
      keperluan: _keperluan,
    );

    try {
      final success = await ref
          .read(myPeminjamanProvider.notifier)
          .ajukanPeminjaman(peminjaman);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Peminjaman berhasil diajukan'),
            backgroundColor: Colors.green.shade600,
          ),
        );
        // Reset form
        _selectedBukuId = null;
        _jumlahPinjam = 1;
        _tanggalBerakhir = null;
        _keperluan = '';
        // Move to dashboard tab
        _tabController.index = 0;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengajukan peminjaman: $e'),
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
  }

  // ============================================================================
  // TAB 3: AJUKAN PEMINJAMAN
  // ============================================================================
  Widget _buildAjukanPeminjamanTab(AlatState alatState) {
    return RefreshIndicator(
      onRefresh: () => ref.read(alatTersediaProvider.notifier).refresh(),
      color: AppTheme.primaryColor,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(_isDesktop ? 24 : 16),
        child: Column(
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
                    Icons.add_circle_outline_rounded,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Ajukan Peminjaman Buku',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Pilih buku yang ingin dipinjam dan isi formulir di bawah',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),

            // Form
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pilih Buku
                  const Text(
                    'Pilih Buku',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  _buildBookDropdown(alatState.alats),
                  const SizedBox(height: 16),

                  // Jumlah
                  const Text(
                    'Jumlah Buku',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    initialValue: '1',
                    decoration: InputDecoration(
                      hintText: 'Masukkan jumlah',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    style: const TextStyle(fontSize: 13),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Jumlah harus diisi';
                      }
                      final intVal = int.tryParse(value);
                      if (intVal == null || intVal <= 0) {
                        return 'Jumlah harus bilangan positif';
                      }
                      if (_selectedBukuId != null) {
                        final book = alatState.alats.firstWhere(
                          (b) => b.alatId == _selectedBukuId,
                          orElse: () => AlatModel(
                            alatId: 0,
                            kodeAlat: '',
                            namaAlat: '',
                            jumlahTotal: 0,
                            jumlahTersedia: 0,
                          ),
                        );
                        if (intVal > book.jumlahTersedia) {
                          return 'Maksimal ${book.jumlahTersedia} buku';
                        }
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _jumlahPinjam = int.tryParse(value ?? '1') ?? 1;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Tanggal Berakhir
                  const Text(
                    'Tanggal Pengembalian',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().add(
                          const Duration(days: 7),
                        ),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(DateTime.now().year + 1),
                      );
                      if (picked != null) {
                        setState(() {
                          _tanggalBerakhir = picked;
                        });
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 18,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _tanggalBerakhir != null
                                  ? DateFormat(
                                      'dd MMMM yyyy',
                                    ).format(_tanggalBerakhir!)
                                  : 'Pilih tanggal pengembalian',
                              style: TextStyle(
                                fontSize: 13,
                                color: _tanggalBerakhir != null
                                    ? Colors.black
                                    : Colors.grey.shade500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Keperluan
                  const Text(
                    'Keperluan Peminjaman',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    decoration: InputDecoration(
                      hintText: 'Tujuan peminjaman buku',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    style: const TextStyle(fontSize: 13),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Keperluan harus diisi';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _keperluan = value ?? '';
                    },
                  ),
                  const SizedBox(height: 32),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          _formKey.currentState!.save();
                          if (_selectedBukuId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Harap pilih buku terlebih dahulu',
                                ),
                              ),
                            );
                            return;
                          }
                          if (_tanggalBerakhir == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Harap pilih tanggal pengembalian',
                                ),
                              ),
                            );
                            return;
                          }
                          _submitForm();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Ajukan Peminjaman',
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
          ],
        ),
      ),
    );
  }

  Widget _buildBookDropdown(List<AlatModel> books) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _selectedBukuId,
          isExpanded: true,
          hint: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              'Pilih buku...',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
          ),
          items: books.map((book) {
            return DropdownMenuItem<int>(
              value: book.alatId,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  '${book.namaAlat} (Tersedia: ${book.jumlahTersedia})',
                  style: const TextStyle(fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedBukuId = value;
            });
          },
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    final user = ref.read(authProvider).user;
    if (user == null || _selectedBukuId == null) return;

    final book = ref
        .read(alatTersediaProvider)
        .alats
        .firstWhere((b) => b.alatId == _selectedBukuId);

    // Generate kode peminjaman
    final kode = 'PJN-${DateTime.now().millisecondsSinceEpoch}';

    final peminjaman = PeminjamanModel(
      peminjamanId: 0,
      peminjamId: user.userId,
      alatId: book.alatId,
      kodePeminjaman: kode,
      jumlahPinjam: _jumlahPinjam,
      tanggalBerakhir: _tanggalBerakhir!,
      keperluan: _keperluan,
    );

    try {
      final success = await ref
          .read(myPeminjamanProvider.notifier)
          .ajukanPeminjaman(peminjaman);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Peminjaman berhasil diajukan'),
            backgroundColor: Colors.green.shade600,
          ),
        );
        // Reset form
        _selectedBukuId = null;
        _jumlahPinjam = 1;
        _tanggalBerakhir = null;
        _keperluan = '';
        _formKey.currentState?.reset();
        // Refresh data
        ref.read(myPeminjamanProvider.notifier).refresh();
        ref.read(alatTersediaProvider.notifier).refresh();
        // Move to dashboard tab
        _tabController.index = 0;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengajukan peminjaman: $e'),
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
  }

  // ============================================================================
  // TAB 4: KEMBALIKAN BUKU
  // ============================================================================
  Widget _buildKembalikanBukuTab(List<PeminjamanModel> activePeminjamans) {
    return RefreshIndicator(
      onRefresh: () => ref.read(myPeminjamanProvider.notifier).refresh(),
      color: AppTheme.primaryColor,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(_isDesktop ? 24 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.assignment_return_rounded,
                    color: const Color(0xFF4CAF50),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Kembalikan Buku',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Pilih buku yang akan dikembalikan',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),

            if (activePeminjamans.isEmpty) _buildEmptyState(),

            if (activePeminjamans.isNotEmpty)
              ...activePeminjamans.map((peminjaman) {
                final index = activePeminjamans.indexOf(peminjaman);
                return _buildReturnItem(peminjaman, index);
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'Tidak ada buku yang sedang dipinjam',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              'Semua buku sudah dikembalikan',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReturnItem(PeminjamanModel peminjaman, int index) {
    final bukuNama = peminjaman.alat?.namaAlat ?? 'Buku';
    final isOverdue = peminjaman.isOverdue;
    final denda = isOverdue
        ? (peminjaman.alat?.hargaPerhari ?? 0) * peminjaman.daysOverdue
        : 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isOverdue
                      ? const Color(0xFFFF5252).withOpacity(0.1)
                      : const Color(0xFF4CAF50).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isOverdue ? Icons.warning_rounded : Icons.book_rounded,
                  color: isOverdue
                      ? const Color(0xFFFF5252)
                      : const Color(0xFF4CAF50),
                  size: 20,
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
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 12,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Jatuh tempo: ${DateFormat('dd MMM yyyy').format(peminjaman.tanggalBerakhir)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 12,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isOverdue
                              ? 'Terlambat ${peminjaman.daysOverdue} hari'
                              : 'Sisa ${peminjaman.daysRemaining} hari',
                          style: TextStyle(
                            fontSize: 12,
                            color: isOverdue
                                ? const Color(0xFFFF5252)
                                : Colors.grey.shade600,
                            fontWeight: isOverdue
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                    if (isOverdue) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.money_outlined,
                            size: 12,
                            color: Colors.orange.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Denda: Rp ${denda.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _showReturnConfirmation(peminjaman),
              style: ElevatedButton.styleFrom(
                backgroundColor: isOverdue
                    ? const Color(0xFFFF5252)
                    : AppTheme.primaryColor,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              child: Text(
                isOverdue ? 'KEMBALIKAN & BAYAR DENDA' : 'KEMBALIKAN',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: (index * 80).ms);
  }

  void _showReturnConfirmation(PeminjamanModel peminjaman) {
    final isOverdue = peminjaman.isOverdue;
    final denda = isOverdue
        ? (peminjaman.alat?.hargaPerhari ?? 0) * peminjaman.daysOverdue
        : 0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Icon(
              isOverdue
                  ? Icons.warning_rounded
                  : Icons.check_circle_outline_rounded,
              color: isOverdue
                  ? const Color(0xFFFF5252)
                  : const Color(0xFF4CAF50),
              size: 20,
            ),
            const SizedBox(width: 10),
            Text(
              'Konfirmasi Pengembalian',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isOverdue
                    ? const Color(0xFFFF5252)
                    : const Color(0xFF4CAF50),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Apakah Anda yakin ingin mengembalikan buku:',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 8),
            Text(
              peminjaman.alat?.namaAlat ?? 'Buku',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            if (isOverdue) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF5252).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_rounded,
                      size: 16,
                      color: const Color(0xFFFF5252),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Buku terlambat ${peminjaman.daysOverdue} hari\nDenda: Rp ${denda.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: const Color(0xFFFF5252),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            Text(
              'Kondisi buku saat ini:',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildConditionButton('Baik', 'baik'),
                const SizedBox(width: 8),
                _buildConditionButton('Rusak Ringan', 'rusak_ringan'),
                const SizedBox(width: 8),
                _buildConditionButton('Rusak Berat', 'rusak_berat'),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Batal',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              // In a real app, you would call the pengembalian service
              // For now, just show success message
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Buku berhasil dikembalikan'),
                  backgroundColor: Colors.green.shade600,
                ),
              );
              // Refresh data
              ref.read(myPeminjamanProvider.notifier).refresh();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isOverdue
                  ? const Color(0xFFFF5252)
                  : const Color(0xFF4CAF50),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: Text(
              isOverdue ? 'Bayar & Kembalikan' : 'Kembalikan',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConditionButton(String label, String value) {
    return Expanded(
      child: OutlinedButton(
        onPressed: () {},
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          side: BorderSide(color: Colors.grey.shade300),
        ),
        child: Text(label, style: const TextStyle(fontSize: 11)),
      ),
    );
  }

  // ============================================================================
  // LOGOUT HANDLER
  // ============================================================================
  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Color(0xFFFF5252), size: 20),
            SizedBox(width: 10),
            Text(
              'Konfirmasi Keluar',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        content: const Text(
          'Apakah Anda yakin ingin keluar?',
          style: TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Batal',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(authProvider.notifier).logout();
              context.go('/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5252),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text(
              'Keluar',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// DATA MODELS
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
