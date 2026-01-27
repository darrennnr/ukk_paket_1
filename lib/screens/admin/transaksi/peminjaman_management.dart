// lib/screens/admin/transaksi/peminjaman_management.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:paket_3_training/core/design_system/app_color.dart';
import 'package:paket_3_training/core/design_system/app_design_system.dart'
    hide AppTheme;
import 'package:paket_3_training/widgets/admin_sidebar.dart';
import 'package:paket_3_training/providers/peminjaman_provider.dart';
import 'package:paket_3_training/providers/auth_provider.dart';
import 'package:paket_3_training/providers/alat_provider.dart';
import 'package:paket_3_training/providers/user_provider.dart';
import 'package:paket_3_training/models/peminjaman_model.dart';
import 'package:paket_3_training/models/alat_model.dart';
import 'package:paket_3_training/models/user_model.dart';

class PeminjamanManagement extends ConsumerStatefulWidget {
  const PeminjamanManagement({Key? key}) : super(key: key);

  @override
  ConsumerState<PeminjamanManagement> createState() =>
      _PeminjamanManagementState();
}

class _PeminjamanManagementState extends ConsumerState<PeminjamanManagement>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();

  late TabController _tabController;
  int? _selectedStatusFilter;
  String _searchQuery = '';

  bool get _isDesktop => MediaQuery.of(context).size.width >= 900;
  bool get _isTablet =>
      MediaQuery.of(context).size.width >= 600 &&
      MediaQuery.of(context).size.width < 900;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(peminjamanProvider.notifier).ensureInitialized();
      ref.read(peminjamanMenungguProvider.notifier).ensureInitialized();
      ref.read(peminjamanAktifProvider.notifier).ensureInitialized();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildAppBar(),
      drawer: _isDesktop
          ? null
          : AdminSidebar(currentRoute: '/admin/peminjaman'),
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
              child: AdminSidebar(currentRoute: '/admin/peminjaman'),
            ),
          Expanded(
            child: Column(
              children: [
                _buildTabBar(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildAllPeminjamanTab(),
                      _buildPendingPeminjamanTab(),
                      _buildActivePeminjamanTab(),
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
        'Kelola Peminjaman',
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
  // TAB BAR
  // ============================================================================
  Widget _buildTabBar() {
    final allCount = ref.watch(peminjamanCountProvider);
    final pendingCount = ref.watch(peminjamanMenungguCountProvider);
    final activeCount = ref.watch(peminjamanAktifCountProvider);

    return Container(
      color: AppColors.surface,
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: AppColors.textSecondary,
            labelStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            indicatorColor: AppTheme.primaryColor,
            indicatorWeight: 2,
            tabs: [
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Semua'),
                    const SizedBox(width: 6),
                    _buildCountBadge(allCount, _tabController.index == 0),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Menunggu'),
                    const SizedBox(width: 6),
                    _buildCountBadge(pendingCount, _tabController.index == 1),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Aktif'),
                    const SizedBox(width: 6),
                    _buildCountBadge(activeCount, _tabController.index == 2),
                  ],
                ),
              ),
            ],
          ),
          Divider(height: 1, color: AppColors.borderMedium),
        ],
      ),
    );
  }

  Widget _buildCountBadge(int count, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isActive ? AppTheme.primaryColor : AppColors.borderDark,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: isActive ? AppColors.surface : AppColors.textPrimary,
        ),
      ),
    );
  }

  // ============================================================================
  // ALL PEMINJAMAN TAB
  // ============================================================================
  Widget _buildAllPeminjamanTab() {
    final peminjamanState = ref.watch(peminjamanProvider);

    return RefreshIndicator(
      onRefresh: () => ref.read(peminjamanProvider.notifier).refresh(),
      color: AppTheme.primaryColor,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(_isDesktop ? 24 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(
              'Semua Peminjaman',
              peminjamanState.peminjamans.length,
            ),
            const SizedBox(height: 20),
            _buildSearchAndFilter(),
            const SizedBox(height: 20),
            if (peminjamanState.isLoading &&
                peminjamanState.peminjamans.isEmpty)
              _buildLoadingSkeleton()
            else if (_getFilteredPeminjaman(
              peminjamanState.peminjamans,
            ).isEmpty)
              _buildEmptyState('Tidak ada data peminjaman')
            else
              _buildPeminjamanList(
                _getFilteredPeminjaman(peminjamanState.peminjamans),
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // PENDING PEMINJAMAN TAB
  // ============================================================================
  Widget _buildPendingPeminjamanTab() {
    final peminjamanState = ref.watch(peminjamanMenungguProvider);

    return RefreshIndicator(
      onRefresh: () => ref.read(peminjamanMenungguProvider.notifier).refresh(),
      color: AppTheme.primaryColor,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(_isDesktop ? 24 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(
              'Menunggu Persetujuan',
              peminjamanState.peminjamans.length,
            ),
            const SizedBox(height: 20),
            _buildSearchAndFilter(),
            const SizedBox(height: 20),
            if (peminjamanState.isLoading &&
                peminjamanState.peminjamans.isEmpty)
              _buildLoadingSkeleton()
            else if (_getFilteredPeminjaman(
              peminjamanState.peminjamans,
            ).isEmpty)
              _buildEmptyState('Tidak ada peminjaman menunggu')
            else
              _buildPeminjamanList(
                _getFilteredPeminjaman(peminjamanState.peminjamans),
                showActions: true,
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // ACTIVE PEMINJAMAN TAB
  // ============================================================================
  Widget _buildActivePeminjamanTab() {
    final peminjamanState = ref.watch(peminjamanAktifProvider);

    return RefreshIndicator(
      onRefresh: () => ref.read(peminjamanAktifProvider.notifier).refresh(),
      color: AppTheme.primaryColor,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(_isDesktop ? 24 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(
              'Peminjaman Aktif',
              peminjamanState.peminjamans.length,
            ),
            const SizedBox(height: 20),
            _buildSearchAndFilter(),
            const SizedBox(height: 20),
            if (peminjamanState.isLoading &&
                peminjamanState.peminjamans.isEmpty)
              _buildLoadingSkeleton()
            else if (_getFilteredPeminjaman(
              peminjamanState.peminjamans,
            ).isEmpty)
              _buildEmptyState('Tidak ada peminjaman aktif')
            else
              _buildPeminjamanList(
                _getFilteredPeminjaman(peminjamanState.peminjamans),
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // HEADER
  // ============================================================================
  Widget _buildHeader(String title, int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$count data ditemukan',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () => _showCreateDialog(),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Tambah Peminjaman'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: AppColors.surface,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 150.ms).slideY(begin: -0.1, end: 0);
  }

  // ============================================================================
  // SEARCH & FILTER
  // ============================================================================
  Widget _buildSearchAndFilter() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.borderMedium, width: 1),
            ),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(fontSize: 13, color: Color(0xFF1A1A1A)),
              decoration: InputDecoration(
                hintText: 'Cari kode peminjaman, nama peminjam...',
                hintStyle: TextStyle(fontSize: 13, color: AppColors.textHint),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  size: 18,
                  color: AppColors.textTertiary,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: AppColors.textTertiary,
                        ),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value.toLowerCase());
              },
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.borderMedium, width: 1),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int?>(
              value: _selectedStatusFilter,
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
                DropdownMenuItem<int?>(
                  value: null,
                  child: Text('Semua Status', style: TextStyle(fontSize: 13)),
                ),
                DropdownMenuItem<int?>(
                  value: 1,
                  child: Text('Pending', style: TextStyle(fontSize: 13)),
                ),
                DropdownMenuItem<int?>(
                  value: 2,
                  child: Text('Dipinjam', style: TextStyle(fontSize: 13)),
                ),
                DropdownMenuItem<int?>(
                  value: 3,
                  child: Text('Ditolak', style: TextStyle(fontSize: 13)),
                ),
                DropdownMenuItem<int?>(
                  value: 4,
                  child: Text('Kembali', style: TextStyle(fontSize: 13)),
                ),
              ],
              onChanged: (value) =>
                  setState(() => _selectedStatusFilter = value),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // FILTERED PEMINJAMAN
  // ============================================================================
  List<PeminjamanModel> _getFilteredPeminjaman(
    List<PeminjamanModel> peminjamans,
  ) {
    var filtered = peminjamans;

    // Filter by status
    if (_selectedStatusFilter != null) {
      filtered = filtered
          .where((p) => p.statusPeminjamanId == _selectedStatusFilter)
          .toList();
    }

    // Filter by search
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((p) {
        final kodePeminjaman = p.kodePeminjaman.toLowerCase();
        final namaPeminjam = p.peminjam?.namaLengkap.toLowerCase() ?? '';
        final namaAlat = p.alat?.namaAlat.toLowerCase() ?? '';
        return kodePeminjaman.contains(_searchQuery) ||
            namaPeminjam.contains(_searchQuery) ||
            namaAlat.contains(_searchQuery);
      }).toList();
    }

    return filtered;
  }

  // ============================================================================
  // PEMINJAMAN LIST
  // ============================================================================
  Widget _buildPeminjamanList(
    List<PeminjamanModel> peminjamans, {
    bool showActions = false,
  }) {
    if (_isDesktop || _isTablet) {
      return _buildDesktopTable(peminjamans, showActions: showActions);
    }
    return _buildMobileList(peminjamans, showActions: showActions);
  }

  Widget _buildDesktopTable(
    List<PeminjamanModel> peminjamans, {
    bool showActions = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderMedium, width: 1),
      ),
      child: Column(
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(10),
              ),
            ),
            child: Row(
              children: [
                const Expanded(
                  flex: 2,
                  child: Text(
                    'Kode',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
                const Expanded(
                  flex: 2,
                  child: Text(
                    'Peminjam',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
                const Expanded(
                  flex: 2,
                  child: Text(
                    'Alat',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
                const Expanded(
                  flex: 2,
                  child: Text(
                    'Tanggal',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
                const Expanded(
                  flex: 1,
                  child: Text(
                    'Status',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
                SizedBox(width: showActions ? 140 : 60),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.borderMedium),
          // Table Body
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: peminjamans.length,
            separatorBuilder: (_, __) =>
                Divider(height: 1, color: AppColors.surfaceContainerLow),
            itemBuilder: (context, index) => _buildPeminjamanRow(
              peminjamans[index],
              index,
              showActions: showActions,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 150.ms, delay: 150.ms);
  }

  Widget _buildPeminjamanRow(
    PeminjamanModel peminjaman,
    int index, {
    bool showActions = false,
  }) {
    return InkWell(
          onTap: () => _showDetailDialog(peminjaman),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Kode Peminjaman
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        peminjaman.kodePeminjaman,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Qty: ${peminjaman.jumlahPinjam}',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Peminjam
                Expanded(
                  flex: 2,
                  child: Text(
                    peminjaman.peminjam?.namaLengkap ?? '-',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF1A1A1A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Alat
                Expanded(
                  flex: 2,
                  child: Row(
                    children: [
                      if (peminjaman.alat?.fotoAlat != null &&
                          peminjaman.alat!.fotoAlat!.isNotEmpty)
                        Container(
                          width: 32,
                          height: 32,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.network(
                              peminjaman.alat!.fotoAlat!,
                              width: 32,
                              height: 32,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.inventory_2_outlined,
                                size: 16,
                                color: AppColors.textHint,
                              ),
                            ),
                          ),
                        ),
                      Expanded(
                        child: Text(
                          peminjaman.alat?.namaAlat ?? '-',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF1A1A1A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                // Tanggal
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        peminjaman.tanggalPinjam != null
                            ? DateFormat(
                                'dd MMM yyyy',
                              ).format(peminjaman.tanggalPinjam!)
                            : '-',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Sampai: ${DateFormat('dd MMM yyyy').format(peminjaman.tanggalBerakhir)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Status
                Expanded(
                  flex: 1,
                  child: _buildStatusBadge(
                    peminjaman.statusPeminjamanId,
                    peminjaman.statusPeminjaman?.statusPeminjaman,
                  ),
                ),
                // Actions
                SizedBox(
                  width: showActions ? 140 : 60,
                  child: showActions
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            _buildActionButton(
                              icon: Icons.check_circle_outline_rounded,
                              color: const Color(0xFF4CAF50),
                              onTap: () => _approveDialog(peminjaman),
                            ),
                            const SizedBox(width: 6),
                            _buildActionButton(
                              icon: Icons.cancel_outlined,
                              color: const Color(0xFFFF5252),
                              onTap: () => _rejectDialog(peminjaman),
                            ),
                            const SizedBox(width: 6),
                            _buildActionButton(
                              icon: Icons.visibility_outlined,
                              color: AppTheme.primaryColor,
                              onTap: () => _showDetailDialog(peminjaman),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            PopupMenuButton(
                              icon: Icon(
                                Icons.more_vert_rounded,
                                size: 18,
                                color: AppColors.textSecondary,
                              ),
                              offset: const Offset(0, 35),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  height: 36,
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.visibility_outlined,
                                        size: 16,
                                        color: AppColors.textPrimary,
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Detail',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                  onTap: () => Future.delayed(
                                    Duration.zero,
                                    () => _showDetailDialog(peminjaman),
                                  ),
                                ),
                                // Edit - only for pending
                                if (peminjaman.statusPeminjamanId == 1)
                                  PopupMenuItem(
                                    height: 36,
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.edit_outlined,
                                          size: 16,
                                          color: AppColors.textPrimary,
                                        ),
                                        const SizedBox(width: 8),
                                        const Text(
                                          'Edit',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                    onTap: () => Future.delayed(
                                      Duration.zero,
                                      () => _showEditDialog(peminjaman),
                                    ),
                                  ),
                                // Delete - only for pending
                                if (peminjaman.statusPeminjamanId == 1)
                                  PopupMenuItem(
                                    height: 36,
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.delete_outline_rounded,
                                          size: 16,
                                          color: const Color(0xFFFF5252),
                                        ),
                                        const SizedBox(width: 8),
                                        const Text(
                                          'Hapus',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFFFF5252),
                                          ),
                                        ),
                                      ],
                                    ),
                                    onTap: () => Future.delayed(
                                      Duration.zero,
                                      () => _showDeleteDialog(peminjaman),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 150.ms, delay: (150 + index * 30).ms)
        .slideX(begin: 0.03, end: 0);
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }

  Widget _buildMobileList(
    List<PeminjamanModel> peminjamans, {
    bool showActions = false,
  }) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: peminjamans.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) =>
          _buildMobileCard(peminjamans[index], index, showActions: showActions),
    );
  }

  Widget _buildMobileCard(
    PeminjamanModel peminjaman,
    int index, {
    bool showActions = false,
  }) {
    return InkWell(
          onTap: () => _showDetailDialog(peminjaman),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderMedium, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      peminjaman.kodePeminjaman,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    _buildStatusBadge(
                      peminjaman.statusPeminjamanId,
                      peminjaman.statusPeminjaman?.statusPeminjaman,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  Icons.person_outline_rounded,
                  'Peminjam',
                  peminjaman.peminjam?.namaLengkap ?? '-',
                ),
                const SizedBox(height: 8),
                _buildInfoRow(
                  Icons.inventory_2_outlined,
                  'Alat',
                  peminjaman.alat?.namaAlat ?? '-',
                ),
                const SizedBox(height: 8),
                _buildInfoRow(
                  Icons.calendar_today_outlined,
                  'Tanggal Pinjam',
                  peminjaman.tanggalPinjam != null
                      ? DateFormat(
                          'dd MMM yyyy',
                        ).format(peminjaman.tanggalPinjam!)
                      : '-',
                ),
                const SizedBox(height: 8),
                _buildInfoRow(
                  Icons.event_outlined,
                  'Tanggal Berakhir',
                  DateFormat('dd MMM yyyy').format(peminjaman.tanggalBerakhir),
                ),
                if (showActions) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _rejectDialog(peminjaman),
                          icon: const Icon(Icons.cancel_outlined, size: 16),
                          label: const Text(
                            'Tolak',
                            style: TextStyle(fontSize: 12),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFFF5252),
                            side: const BorderSide(color: Color(0xFFFF5252)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _approveDialog(peminjaman),
                          icon: const Icon(
                            Icons.check_circle_outline_rounded,
                            size: 16,
                          ),
                          label: const Text(
                            'Setujui',
                            style: TextStyle(fontSize: 12),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4CAF50),
                            foregroundColor: AppColors.surface,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 150.ms, delay: (index * 50).ms)
        .scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textTertiary),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(fontSize: 12, color: AppColors.textPrimary),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                TextSpan(
                  text: value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // STATUS BADGE
  // ============================================================================
  Widget _buildStatusBadge(int? statusId, String? statusText) {
    Color color;
    String text = statusText ?? '-';

    switch (statusId) {
      case 1:
        color = const Color(0xFFFF9800);
        break;
      case 2:
        color = const Color(0xFF2196F3);
        break;
      case 3:
        color = const Color(0xFFFF5252);
        break;
      case 4:
        color = const Color(0xFF4CAF50);
        break;
      default:
        color = AppColors.textDisabled;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  // ============================================================================
  // DETAIL DIALOG
  // ============================================================================
  void _showDetailDialog(PeminjamanModel peminjaman) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: AppColors.surface,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: _isDesktop ? 500 : double.infinity,
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
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
                        Icons.assignment_outlined,
                        color: AppTheme.primaryColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Detail Peminjaman',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildDetailRow('Kode Peminjaman', peminjaman.kodePeminjaman),
                _buildDetailRow(
                  'Peminjam',
                  peminjaman.peminjam?.namaLengkap ?? '-',
                ),
                _buildDetailRow('Alat', peminjaman.alat?.namaAlat ?? '-'),
                _buildDetailRow('Jumlah', '${peminjaman.jumlahPinjam} unit'),
                _buildDetailRow(
                  'Tanggal Pengajuan',
                  peminjaman.tanggalPengajuan != null
                      ? DateFormat(
                          'dd MMMM yyyy, HH:mm',
                        ).format(peminjaman.tanggalPengajuan!)
                      : '-',
                ),
                _buildDetailRow(
                  'Tanggal Pinjam',
                  peminjaman.tanggalPinjam != null
                      ? DateFormat(
                          'dd MMMM yyyy',
                        ).format(peminjaman.tanggalPinjam!)
                      : '-',
                ),
                _buildDetailRow(
                  'Tanggal Berakhir',
                  DateFormat('dd MMMM yyyy').format(peminjaman.tanggalBerakhir),
                ),
                _buildDetailRow('Keperluan', peminjaman.keperluan ?? '-'),
                _buildDetailRow(
                  'Status',
                  peminjaman.statusPeminjaman?.statusPeminjaman ?? '-',
                ),
                if (peminjaman.petugas != null)
                  _buildDetailRow(
                    'Diproses oleh',
                    peminjaman.petugas!.namaLengkap,
                  ),
                if (peminjaman.catatanPetugas != null &&
                    peminjaman.catatanPetugas!.isNotEmpty)
                  _buildDetailRow(
                    'Catatan Petugas',
                    peminjaman.catatanPetugas!,
                  ),
                if (peminjaman.isOverdue) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF5252).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFFF5252).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.warning_rounded,
                          color: Color(0xFFFF5252),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Terlambat ${peminjaman.daysOverdue} hari',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFFFF5252),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Tutup',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF1A1A1A),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // APPROVE DIALOG
  // ============================================================================
  void _approveDialog(PeminjamanModel peminjaman) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: AppColors.surface,
        contentPadding: const EdgeInsets.all(20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_outline_rounded,
                color: Color(0xFF4CAF50),
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Setujui Peminjaman?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Peminjaman dengan kode "${peminjaman.kodePeminjaman}" akan disetujui dan stok alat akan dikurangi.',
              style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: AppColors.borderDark),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Batal',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      final petugasId = ref.read(authProvider).user?.userId;
                      if (petugasId == null) return;

                      final success = await ref
                          .read(peminjamanMenungguProvider.notifier)
                          .approvePeminjaman(
                            peminjaman.peminjamanId,
                            petugasId,
                          );

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              success
                                  ? 'Peminjaman berhasil disetujui'
                                  : 'Gagal menyetujui peminjaman',
                              style: const TextStyle(fontSize: 13),
                            ),
                            backgroundColor: success
                                ? const Color(0xFF4CAF50)
                                : const Color(0xFFFF5252),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Setujui',
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
    );
  }

  // ============================================================================
  // REJECT DIALOG
  // ============================================================================
  void _rejectDialog(PeminjamanModel peminjaman) {
    final catatanController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: AppColors.surface,
        contentPadding: const EdgeInsets.all(20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF5252).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.cancel_outlined,
                    color: Color(0xFFFF5252),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Tolak Peminjaman',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Berikan alasan penolakan untuk peminjaman "${peminjaman.kodePeminjaman}"',
              style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: catatanController,
              maxLines: 3,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Masukkan alasan penolakan...',
                hintStyle: TextStyle(fontSize: 13, color: AppColors.textHint),
                filled: true,
                fillColor: AppColors.surfaceContainerLowest,
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.borderMedium),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.borderMedium),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: AppTheme.primaryColor,
                    width: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: AppColors.borderDark),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Batal',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      if (catatanController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text(
                              'Alasan penolakan wajib diisi',
                              style: TextStyle(fontSize: 13),
                            ),
                            backgroundColor: const Color(0xFFFF5252),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        );
                        return;
                      }

                      Navigator.pop(context);
                      final petugasId = ref.read(authProvider).user?.userId;
                      if (petugasId == null) return;

                      final success = await ref
                          .read(peminjamanMenungguProvider.notifier)
                          .rejectPeminjaman(
                            peminjaman.peminjamanId,
                            petugasId,
                            catatanController.text.trim(),
                          );

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              success
                                  ? 'Peminjaman berhasil ditolak'
                                  : 'Gagal menolak peminjaman',
                              style: const TextStyle(fontSize: 13),
                            ),
                            backgroundColor: success
                                ? const Color(0xFF4CAF50)
                                : const Color(0xFFFF5252),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF5252),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Tolak',
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
    );
  }

  // ============================================================================
  // EMPTY STATE
  // ============================================================================
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
                Icons.assignment_outlined,
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
            ),
            const SizedBox(height: 4),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Coba kata kunci lain'
                  : 'Belum ada data',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // LOADING SKELETON
  // ============================================================================
  Widget _buildLoadingSkeleton() {
    return Container(
          decoration: BoxDecoration(
            color: AppColors.borderMedium,
            borderRadius: BorderRadius.circular(10),
          ),
          height: 400,
        )
        .animate(onPlay: (controller) => controller.repeat())
        .shimmer(duration: 1200.ms);
  }

  // ============================================================================
  // CREATE DIALOG
  // ============================================================================
  void _showCreateDialog() {
    // Ensure data is loaded
    ref.read(alatTersediaProvider.notifier).ensureInitialized();
    ref.read(userProvider.notifier).ensureInitialized();

    int? selectedPeminjamId;
    int? selectedAlatId;
    int jumlahPinjam = 1;
    int selectedStatusId = 1; // Default: Pending
    DateTime tanggalBerakhir = DateTime.now().add(const Duration(days: 7));
    final keperluanController = TextEditingController();
    final catatanPetugasController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final alatsState = ref.watch(alatTersediaProvider);
          final usersState = ref.watch(userProvider);

          // Filter users to show only peminjam (role_id = 3)
          final peminjamList = usersState.users
              .where((u) => u.roleId == 3)
              .toList();

          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: AppColors.surface,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: _isDesktop ? 500 : double.infinity,
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: AppColors.borderMedium),
                        ),
                      ),
                      child: Row(
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
                          const Expanded(
                            child: Text(
                              'Tambah Peminjaman',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close_rounded, size: 20),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Form Content
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Peminjam Dropdown
                            _buildFormLabel('Peminjam'),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<int>(
                              value: selectedPeminjamId,
                              decoration: _inputDecoration('Pilih peminjam'),
                              items: peminjamList
                                  .map(
                                    (u) => DropdownMenuItem(
                                      value: u.userId,
                                      child: Text(
                                        u.namaLengkap,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) =>
                                  setDialogState(() => selectedPeminjamId = v),
                              validator: (v) =>
                                  v == null ? 'Pilih peminjam' : null,
                            ),
                            const SizedBox(height: 16),

                            // Alat Dropdown
                            _buildFormLabel('Alat'),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<int>(
                              value: selectedAlatId,
                              decoration: _inputDecoration('Pilih alat'),
                              items: alatsState.alats
                                  .map(
                                    (a) => DropdownMenuItem(
                                      value: a.alatId,
                                      child: Text(
                                        '${a.namaAlat} (Stok: ${a.jumlahTersedia})',
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) =>
                                  setDialogState(() => selectedAlatId = v),
                              validator: (v) => v == null ? 'Pilih alat' : null,
                            ),
                            const SizedBox(height: 16),

                            // Jumlah Pinjam
                            _buildFormLabel('Jumlah Pinjam'),
                            const SizedBox(height: 8),
                            TextFormField(
                              initialValue: jumlahPinjam.toString(),
                              keyboardType: TextInputType.number,
                              decoration: _inputDecoration('1'),
                              style: const TextStyle(fontSize: 13),
                              onChanged: (v) {
                                jumlahPinjam = int.tryParse(v) ?? 1;
                              },
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'Masukkan jumlah';
                                }
                                final num = int.tryParse(v);
                                if (num == null || num < 1) {
                                  return 'Minimal 1';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Tanggal Berakhir
                            _buildFormLabel('Tanggal Berakhir'),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: tanggalBerakhir,
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(
                                    const Duration(days: 365),
                                  ),
                                );
                                if (picked != null) {
                                  setDialogState(
                                    () => tanggalBerakhir = picked,
                                  );
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceContainerLowest,
                                  border: Border.all(
                                    color: AppColors.borderMedium,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today_outlined,
                                      size: 16,
                                      color: AppColors.textSecondary,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      DateFormat(
                                        'dd MMMM yyyy',
                                      ).format(tanggalBerakhir),
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Keperluan
                            _buildFormLabel('Keperluan'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: keperluanController,
                              maxLines: 3,
                              decoration: _inputDecoration(
                                'Masukkan keperluan peminjaman',
                              ),
                              style: const TextStyle(fontSize: 13),
                            ),
                            const SizedBox(height: 16),

                            // Status Peminjaman
                            _buildFormLabel('Status Peminjaman'),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<int>(
                              value: selectedStatusId,
                              decoration: _inputDecoration('Pilih status'),
                              items: const [
                                DropdownMenuItem(
                                  value: 1,
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.hourglass_empty_rounded,
                                        size: 16,
                                        color: Color(0xFFFF9800),
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Pending',
                                        style: TextStyle(fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 2,
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle_rounded,
                                        size: 16,
                                        color: Color(0xFF4CAF50),
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Diterima / Dipinjam',
                                        style: TextStyle(fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 3,
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.cancel_rounded,
                                        size: 16,
                                        color: Color(0xFFFF5252),
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Ditolak',
                                        style: TextStyle(fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              onChanged: (v) => setDialogState(
                                () => selectedStatusId = v ?? 1,
                              ),
                            ),

                            // Catatan Petugas (muncul jika status ditolak)
                            if (selectedStatusId == 3) ...[
                              const SizedBox(height: 16),
                              _buildFormLabel('Alasan Penolakan'),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: catatanPetugasController,
                                maxLines: 3,
                                decoration: _inputDecoration(
                                  'Masukkan alasan penolakan',
                                ),
                                style: const TextStyle(fontSize: 13),
                                validator: (v) {
                                  if (selectedStatusId == 3 &&
                                      (v == null || v.trim().isEmpty)) {
                                    return 'Alasan penolakan wajib diisi';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    // Actions
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: AppColors.borderMedium),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                side: BorderSide(color: AppColors.borderDark),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'Batal',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1A1A1A),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                if (!formKey.currentState!.validate()) return;
                                if (selectedPeminjamId == null ||
                                    selectedAlatId == null) {
                                  return;
                                }

                                Navigator.pop(context);

                                final petugasId = ref
                                    .read(authProvider)
                                    .user
                                    ?.userId;
                                final peminjaman = PeminjamanModel(
                                  peminjamanId: 0,
                                  peminjamId: selectedPeminjamId,
                                  alatId: selectedAlatId,
                                  petugasId: selectedStatusId != 1
                                      ? petugasId
                                      : null,
                                  kodePeminjaman:
                                      'PMJ-${const Uuid().v4().substring(0, 8).toUpperCase()}',
                                  jumlahPinjam: jumlahPinjam,
                                  tanggalBerakhir: tanggalBerakhir,
                                  tanggalPinjam: selectedStatusId == 2
                                      ? DateTime.now()
                                      : null,
                                  keperluan: keperluanController.text.isEmpty
                                      ? null
                                      : keperluanController.text,
                                  catatanPetugas: selectedStatusId == 3
                                      ? catatanPetugasController.text.trim()
                                      : null,
                                  statusPeminjamanId: selectedStatusId,
                                );

                                final success = await ref
                                    .read(peminjamanProvider.notifier)
                                    .createPeminjaman(peminjaman);

                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        success
                                            ? 'Peminjaman berhasil ditambahkan'
                                            : 'Gagal menambah peminjaman',
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                      backgroundColor: success
                                          ? const Color(0xFF4CAF50)
                                          : const Color(0xFFFF5252),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'Simpan',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.surface,
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
            ),
          );
        },
      ),
    );
  }

  // ============================================================================
  // EDIT DIALOG
  // ============================================================================
  void _showEditDialog(PeminjamanModel peminjaman) {
    ref.read(alatTersediaProvider.notifier).ensureInitialized();

    int? selectedAlatId = peminjaman.alatId;
    int jumlahPinjam = peminjaman.jumlahPinjam;
    int selectedStatusId = peminjaman.statusPeminjamanId ?? 1;
    DateTime tanggalBerakhir = peminjaman.tanggalBerakhir;
    final keperluanController = TextEditingController(
      text: peminjaman.keperluan ?? '',
    );
    final catatanPetugasController = TextEditingController(
      text: peminjaman.catatanPetugas ?? '',
    );
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final alatsState = ref.watch(alatTersediaProvider);

          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: AppColors.surface,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: _isDesktop ? 500 : double.infinity,
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: AppColors.borderMedium),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2196F3).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.edit_outlined,
                              color: Color(0xFF2196F3),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Edit Peminjaman',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  peminjaman.kodePeminjaman,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close_rounded, size: 20),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Form Content
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Alat Dropdown
                            _buildFormLabel('Alat'),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<int>(
                              value: selectedAlatId,
                              decoration: _inputDecoration('Pilih alat'),
                              items: alatsState.alats
                                  .map(
                                    (a) => DropdownMenuItem(
                                      value: a.alatId,
                                      child: Text(
                                        '${a.namaAlat} (Stok: ${a.jumlahTersedia})',
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) =>
                                  setDialogState(() => selectedAlatId = v),
                              validator: (v) => v == null ? 'Pilih alat' : null,
                            ),
                            const SizedBox(height: 16),

                            // Jumlah Pinjam
                            _buildFormLabel('Jumlah Pinjam'),
                            const SizedBox(height: 8),
                            TextFormField(
                              initialValue: jumlahPinjam.toString(),
                              keyboardType: TextInputType.number,
                              decoration: _inputDecoration('1'),
                              style: const TextStyle(fontSize: 13),
                              onChanged: (v) {
                                jumlahPinjam = int.tryParse(v) ?? 1;
                              },
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'Masukkan jumlah';
                                }
                                final num = int.tryParse(v);
                                if (num == null || num < 1) return 'Minimal 1';
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Tanggal Berakhir
                            _buildFormLabel('Tanggal Berakhir'),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: tanggalBerakhir,
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(
                                    const Duration(days: 365),
                                  ),
                                );
                                if (picked != null) {
                                  setDialogState(
                                    () => tanggalBerakhir = picked,
                                  );
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceContainerLowest,
                                  border: Border.all(
                                    color: AppColors.borderMedium,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today_outlined,
                                      size: 16,
                                      color: AppColors.textSecondary,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      DateFormat(
                                        'dd MMMM yyyy',
                                      ).format(tanggalBerakhir),
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Keperluan
                            _buildFormLabel('Keperluan'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: keperluanController,
                              maxLines: 3,
                              decoration: _inputDecoration(
                                'Masukkan keperluan peminjaman',
                              ),
                              style: const TextStyle(fontSize: 13),
                            ),
                            const SizedBox(height: 16),

                            // Status Peminjaman
                            _buildFormLabel('Status Peminjaman'),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<int>(
                              value: selectedStatusId,
                              decoration: _inputDecoration('Pilih status'),
                              items: const [
                                DropdownMenuItem(
                                  value: 1,
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.hourglass_empty_rounded,
                                        size: 16,
                                        color: Color(0xFFFF9800),
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Pending',
                                        style: TextStyle(fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 2,
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle_rounded,
                                        size: 16,
                                        color: Color(0xFF4CAF50),
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Diterima / Dipinjam',
                                        style: TextStyle(fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 3,
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.cancel_rounded,
                                        size: 16,
                                        color: Color(0xFFFF5252),
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Ditolak',
                                        style: TextStyle(fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              onChanged: (v) => setDialogState(
                                () => selectedStatusId = v ?? 1,
                              ),
                            ),

                            // Catatan Petugas (muncul jika status ditolak)
                            if (selectedStatusId == 3) ...[
                              const SizedBox(height: 16),
                              _buildFormLabel('Alasan Penolakan'),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: catatanPetugasController,
                                maxLines: 3,
                                decoration: _inputDecoration(
                                  'Masukkan alasan penolakan',
                                ),
                                style: const TextStyle(fontSize: 13),
                                validator: (v) {
                                  if (selectedStatusId == 3 &&
                                      (v == null || v.trim().isEmpty)) {
                                    return 'Alasan penolakan wajib diisi';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    // Actions
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: AppColors.borderMedium),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                side: BorderSide(color: AppColors.borderDark),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'Batal',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1A1A1A),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                if (!formKey.currentState!.validate()) return;

                                Navigator.pop(context);

                                final petugasId = ref
                                    .read(authProvider)
                                    .user
                                    ?.userId;
                                final oldStatusId =
                                    peminjaman.statusPeminjamanId ?? 1;

                                final updated = peminjaman.copyWith(
                                  alatId: selectedAlatId,
                                  jumlahPinjam: jumlahPinjam,
                                  tanggalBerakhir: tanggalBerakhir,
                                  tanggalPinjam:
                                      selectedStatusId == 2 &&
                                          peminjaman.tanggalPinjam == null
                                      ? DateTime.now()
                                      : peminjaman.tanggalPinjam,
                                  keperluan: keperluanController.text.isEmpty
                                      ? null
                                      : keperluanController.text,
                                  catatanPetugas: selectedStatusId == 3
                                      ? catatanPetugasController.text.trim()
                                      : null,
                                  statusPeminjamanId: selectedStatusId,
                                  petugasId: selectedStatusId != 1
                                      ? petugasId
                                      : peminjaman.petugasId,
                                );

                                final success = await ref
                                    .read(peminjamanProvider.notifier)
                                    .updatePeminjaman(updated);

                                // Refresh other providers as well
                                ref
                                    .read(peminjamanMenungguProvider.notifier)
                                    .refresh();

                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        success
                                            ? 'Peminjaman berhasil diperbarui'
                                            : 'Gagal memperbarui peminjaman',
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                      backgroundColor: success
                                          ? const Color(0xFF4CAF50)
                                          : const Color(0xFFFF5252),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2196F3),
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'Simpan',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.surface,
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
            ),
          );
        },
      ),
    );
  }

  // ============================================================================
  // DELETE DIALOG
  // ============================================================================
  void _showDeleteDialog(PeminjamanModel peminjaman) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: AppColors.surface,
        contentPadding: const EdgeInsets.all(20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFF5252).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                color: Color(0xFFFF5252),
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Hapus Peminjaman?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Peminjaman dengan kode "${peminjaman.kodePeminjaman}" akan dihapus permanen.',
              style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: AppColors.borderDark),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Batal',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      final userId = ref.read(authProvider).user?.userId;
                      if (userId == null) return;

                      final success = await ref
                          .read(peminjamanProvider.notifier)
                          .deletePeminjaman(peminjaman.peminjamanId, userId);

                      // Refresh other providers
                      ref.read(peminjamanMenungguProvider.notifier).refresh();

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              success
                                  ? 'Peminjaman berhasil dihapus'
                                  : 'Gagal menghapus peminjaman',
                              style: const TextStyle(fontSize: 13),
                            ),
                            backgroundColor: success
                                ? const Color(0xFF4CAF50)
                                : const Color(0xFFFF5252),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF5252),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Hapus',
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
    );
  }

  // ============================================================================
  // HELPER WIDGETS
  // ============================================================================
  Widget _buildFormLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1A1A1A),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(fontSize: 13, color: AppColors.textHint),
      filled: true,
      fillColor: AppColors.surfaceContainerLowest,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.borderMedium),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.borderMedium),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppTheme.primaryColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFFF5252)),
      ),
    );
  }
}
