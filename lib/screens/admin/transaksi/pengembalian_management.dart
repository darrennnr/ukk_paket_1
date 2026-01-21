// lib/screens/admin/transaksi/pengembalian_management.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:paket_3_training/core/design_system/app_color.dart';
import 'package:paket_3_training/core/design_system/app_design_system.dart'
    hide AppTheme;
import 'package:paket_3_training/widgets/admin_sidebar.dart';
import 'package:paket_3_training/providers/pengembalian_provider.dart';
import 'package:paket_3_training/providers/peminjaman_provider.dart';
import 'package:paket_3_training/providers/auth_provider.dart';
import 'package:paket_3_training/models/pengembalian_model.dart';
import 'package:paket_3_training/models/peminjaman_model.dart' as pnj;

class PengembalianManagement extends ConsumerStatefulWidget {
  const PengembalianManagement({Key? key}) : super(key: key);

  @override
  ConsumerState<PengembalianManagement> createState() =>
      _PengembalianManagementState();
}

class _PengembalianManagementState extends ConsumerState<PengembalianManagement>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;

  // Local State for Filtering
  String _searchQuery = '';
  String? _selectedPaymentStatus; // 'Lunas', 'Belum Lunas'

  // Responsive Breakpoints
  bool get _isDesktop => MediaQuery.of(context).size.width >= 900;
  bool get _isTablet =>
      MediaQuery.of(context).size.width >= 600 &&
      MediaQuery.of(context).size.width < 900;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Initial Data Fetch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(pengembalianProvider.notifier).ensureInitialized();
      ref.read(pengembalianBelumLunasProvider.notifier).ensureInitialized();
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
          : AdminSidebar(currentRoute: '/admin/pengembalian'),
      body: Row(
        children: [
          // Desktop Sidebar
          if (_isDesktop)
            Container(
              width: 260,
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  right: BorderSide(color: AppColors.borderMedium, width: 1),
                ),
              ),
              child: AdminSidebar(currentRoute: '/admin/pengembalian'),
            ),

          // Main Content
          Expanded(
            child: Column(
              children: [
                _buildTabBar(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildAllPengembalianTab(),
                      _buildBelumLunasTab(),
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
        'Riwayat Pengembalian',
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
  // TAB BAR & BADGES
  // ============================================================================
  Widget _buildTabBar() {
    final allCount = ref.watch(pengembalianCountProvider);
    final belumLunasCount = ref.watch(pengembalianBelumLunasCountProvider);

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
            dividerColor: Colors.transparent,
            tabs: [
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Semua Riwayat'),
                    const SizedBox(width: 6),
                    _buildCountBadge(allCount, _tabController.index == 0),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Denda Belum Lunas'),
                    const SizedBox(width: 6),
                    _buildCountBadge(
                      belumLunasCount,
                      _tabController.index == 1,
                      isAlert: true,
                    ),
                  ],
                ),
              ),
            ],
            onTap: (index) => setState(() {}),
          ),
          Divider(height: 1, color: AppColors.borderMedium),
        ],
      ),
    );
  }

  Widget _buildCountBadge(int count, bool isActive, {bool isAlert = false}) {
    final bgColor = isAlert
        ? (isActive
              ? const Color(0xFFFF5252)
              : const Color(0xFFFF5252).withOpacity(0.2))
        : (isActive ? AppTheme.primaryColor : AppColors.borderDark);

    final textColor = isAlert
        ? (isActive ? AppColors.surface : const Color(0xFFFF5252))
        : (isActive ? AppColors.surface : AppColors.textPrimary);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }

  // ============================================================================
  // TABS CONTENT
  // ============================================================================

  // Tab 1: Semua Pengembalian
  Widget _buildAllPengembalianTab() {
    final state = ref.watch(pengembalianProvider);
    return _buildContentLayout(
      title: 'Semua Pengembalian',
      count: state.pengembalians.length,
      isLoading: state.isLoading,
      data: state.pengembalians,
      onRefresh: () => ref.read(pengembalianProvider.notifier).refresh(),
      emptyMessage: 'Belum ada riwayat pengembalian',
    );
  }

  // Tab 2: Belum Lunas
  Widget _buildBelumLunasTab() {
    final state = ref.watch(pengembalianBelumLunasProvider);
    return _buildContentLayout(
      title: 'Denda Belum Lunas',
      count: state.pengembalians.length,
      isLoading: state.isLoading,
      data: state.pengembalians,
      onRefresh: () =>
          ref.read(pengembalianBelumLunasProvider.notifier).refresh(),
      emptyMessage: 'Tidak ada denda yang belum dibayar',
      isActionTab: true,
    );
  }

  // Generic Layout Wrapper
  Widget _buildContentLayout({
    required String title,
    required int count,
    required bool isLoading,
    required List<PengembalianModel> data,
    required Future<void> Function() onRefresh,
    required String emptyMessage,
    bool isActionTab = false,
  }) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppTheme.primaryColor,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(_isDesktop ? 24 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(title, count),
            const SizedBox(height: 20),
            _buildSearchAndFilter(),
            const SizedBox(height: 20),
            if (isLoading && data.isEmpty)
              _buildLoadingSkeleton()
            else if (_getFilteredList(data).isEmpty)
              _buildEmptyState(emptyMessage)
            else
              _buildTableList(_getFilteredList(data), isActionTab: isActionTab),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // HEADER & FILTER LOGIC
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
          icon: const Icon(Icons.assignment_return_outlined, size: 18),
          label: const Text('Proses Pengembalian'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: AppColors.surface,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0);
  }

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
              onChanged: (value) =>
                  setState(() => _searchQuery = value.toLowerCase()),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Filter Status Pembayaran
        Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.borderMedium, width: 1),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              value: _selectedPaymentStatus,
              hint: Text(
                'Status Bayar',
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
                  child: Text('Semua', style: TextStyle(fontSize: 13)),
                ),
                DropdownMenuItem(
                  value: 'lunas',
                  child: Text('Lunas', style: TextStyle(fontSize: 13)),
                ),
                DropdownMenuItem(
                  value: 'belum lunas',
                  child: Text('Belum Lunas', style: TextStyle(fontSize: 13)),
                ),
              ],
              onChanged: (value) =>
                  setState(() => _selectedPaymentStatus = value),
            ),
          ),
        ),
      ],
    );
  }

  List<PengembalianModel> _getFilteredList(List<PengembalianModel> list) {
    return list.where((item) {
      // 1. Search Logic
      final kode = item.peminjaman?.kodePeminjaman.toLowerCase() ?? '';
      final nama = item.peminjaman?.peminjam?.namaLengkap.toLowerCase() ?? '';
      final alat = item.peminjaman?.alat?.namaAlat.toLowerCase() ?? '';

      final matchesSearch =
          kode.contains(_searchQuery) ||
          nama.contains(_searchQuery) ||
          alat.contains(_searchQuery);

      // 2. Filter Logic
      bool matchesStatus = true;
      if (_selectedPaymentStatus != null) {
        final statusDb = item.statusPembayaran?.toLowerCase() ?? 'belum lunas';
        matchesStatus = statusDb == _selectedPaymentStatus;
      }

      return matchesSearch && matchesStatus;
    }).toList();
  }

  // ============================================================================
  // LIST RENDERER (DESKTOP & MOBILE)
  // ============================================================================
  Widget _buildTableList(
    List<PengembalianModel> list, {
    bool isActionTab = false,
  }) {
    if (_isDesktop || _isTablet) {
      return _buildDesktopTable(list, isActionTab: isActionTab);
    }
    return _buildMobileList(list, isActionTab: isActionTab);
  }

  // --- Desktop Table ---
  Widget _buildDesktopTable(
    List<PengembalianModel> list, {
    bool isActionTab = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderMedium, width: 1),
      ),
      child: Column(
        children: [
          // Header
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
                    'Kode Pinjam',
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
                    'Tgl Kembali',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
                const Expanded(
                  flex: 2,
                  child: Text(
                    'Kondisi',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
                const Expanded(
                  flex: 2,
                  child: Text(
                    'Total Tagihan',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
                const Expanded(
                  flex: 2,
                  child: Text(
                    'Status Bayar',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
                SizedBox(width: isActionTab ? 100 : 50),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.borderMedium),
          // Rows
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: list.length,
            separatorBuilder: (_, __) =>
                Divider(height: 1, color: AppColors.surfaceContainerLow),
            itemBuilder: (context, index) =>
                _buildTableRow(list[index], index, isActionTab),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 150.ms);
  }

  Widget _buildTableRow(PengembalianModel item, int index, bool isActionTab) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return InkWell(
      onTap: () => _showDetailDialog(item),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Kode
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  if (item.peminjaman?.alat?.fotoAlat != null &&
                      item.peminjaman!.alat!.fotoAlat!.isNotEmpty)
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
                          item.peminjaman!.alat!.fotoAlat!,
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.peminjaman?.kodePeminjaman ?? '-',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.peminjaman?.alat?.namaAlat ?? '-',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Peminjam
            Expanded(
              flex: 2,
              child: Text(
                item.peminjaman?.peminjam?.namaLengkap ?? '-',
                style: const TextStyle(fontSize: 12, color: Color(0xFF1A1A1A)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Tgl Kembali
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.tanggalKembali != null
                        ? DateFormat('dd MMM yyyy').format(item.tanggalKembali!)
                        : '-',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  if (item.isLate)
                    Text(
                      'Telat ${item.keterlambatanHari} hari',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFFFF5252),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
            // Kondisi
            Expanded(flex: 2, child: _buildConditionBadge(item.kondisiAlat)),
            // Total Tagihan
            Expanded(
              flex: 2,
              child: Text(
                (item.totalPembayaran ?? 0) > 0
                    ? currencyFormat.format(item.totalPembayaran)
                    : 'Gratis',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: (item.totalPembayaran ?? 0) > 0
                      ? const Color(0xFF1A1A1A)
                      : AppColors.textSecondary,
                ),
              ),
            ),
            // Status Bayar
            Expanded(
              flex: 2,
              child: _buildPaymentStatusBadge(item.statusPembayaran),
            ),
            // Actions
            SizedBox(
              width: isActionTab ? 100 : 80,
              child: isActionTab
                  ? ElevatedButton(
                      onPressed: () => _processPaymentDialog(item),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Bayar',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.surface,
                        ),
                      ),
                    )
                  : PopupMenuButton(
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
                            () => _showDetailDialog(item),
                          ),
                        ),
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
                            () => _showEditDialog(item),
                          ),
                        ),
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
                            () => _showDeleteDialog(item),
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

  // --- Mobile List ---
  Widget _buildMobileList(
    List<PengembalianModel> list, {
    bool isActionTab = false,
  }) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) =>
          _buildMobileCard(list[index], index, isActionTab),
    );
  }

  Widget _buildMobileCard(PengembalianModel item, int index, bool isActionTab) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return InkWell(
          onTap: () => _showDetailDialog(item),
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
                // Top Row: Kode & Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.peminjaman?.kodePeminjaman ?? '-',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    _buildPaymentStatusBadge(item.statusPembayaran),
                  ],
                ),
                const SizedBox(height: 12),

                // Middle: Info
                _buildInfoRow(
                  Icons.person_outline_rounded,
                  'Peminjam',
                  item.peminjaman?.peminjam?.namaLengkap ?? '-',
                ),
                const SizedBox(height: 8),
                _buildInfoRow(
                  Icons.inventory_2_outlined,
                  'Alat',
                  item.peminjaman?.alat?.namaAlat ?? '-',
                ),
                const SizedBox(height: 8),
                _buildInfoRow(
                  Icons.event_available_outlined,
                  'Dikembalikan',
                  item.tanggalKembali != null
                      ? DateFormat('dd MMM yyyy').format(item.tanggalKembali!)
                      : '-',
                ),

                Divider(height: 24, color: AppColors.surfaceContainerLow),

                // Bottom: Financials & Actions
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Tagihan',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            (item.totalPembayaran ?? 0) > 0
                                ? currencyFormat.format(item.totalPembayaran)
                                : 'Gratis',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isActionTab)
                      ElevatedButton(
                        onPressed: () => _processPaymentDialog(item),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 0,
                          ),
                          minimumSize: const Size(0, 32),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Bayar Denda',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.surface,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 400.ms, delay: (index * 50).ms)
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
  // BADGES
  // ============================================================================
  Widget _buildConditionBadge(String? condition) {
    Color color;
    String text = condition ?? '-';

    if (text.toLowerCase() == 'baik') {
      color = const Color(0xFF4CAF50);
    } else if (text.toLowerCase() == 'rusak') {
      color = const Color(0xFFFF9800);
    } else {
      color = const Color(0xFFFF5252); // Hilang
    }

    return Text(
      text[0].toUpperCase() + text.substring(1),
      style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600),
    );
  }

  Widget _buildPaymentStatusBadge(String? status) {
    final isPaid = status?.toLowerCase() == 'lunas';
    final isFree = status == null; // Asumsi null = tidak ada denda

    Color bg;
    Color text;
    String label;

    if (isPaid) {
      bg = const Color(0xFF4CAF50);
      text = const Color(0xFF4CAF50);
      label = 'Lunas';
    } else if (isFree) {
      bg = AppColors.textDisabled;
      text = AppColors.textSecondary;
      label = '-';
    } else {
      bg = const Color(0xFFFF5252);
      text = const Color(0xFFFF5252);
      label = 'Belum Lunas';
    }

    if (isFree) {
      return Text(
        '-',
        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: bg.withOpacity(0.3), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: text,
          fontWeight: FontWeight.w700,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  // ============================================================================
  // DIALOGS
  // ============================================================================

  // Detail Dialog
  void _showDetailDialog(PengembalianModel item) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: _isDesktop ? 500 : double.infinity,
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Dialog
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.assignment_return_outlined,
                        color: AppTheme.primaryColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Detail Pengembalian',
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

                // Content
                _buildDetailRow(
                  'Kode Peminjaman',
                  item.peminjaman?.kodePeminjaman ?? '-',
                ),
                _buildDetailRow(
                  'Peminjam',
                  item.peminjaman?.peminjam?.namaLengkap ?? '-',
                ),
                _buildDetailRow('Alat', item.peminjaman?.alat?.namaAlat ?? '-'),
                _buildDetailRow(
                  'Kondisi Alat',
                  item.kondisiAlat?.toUpperCase() ?? '-',
                ),
                _buildDetailRow(
                  'Tgl Kembali',
                  item.tanggalKembali != null
                      ? DateFormat(
                          'dd MMMM yyyy, HH:mm',
                        ).format(item.tanggalKembali!)
                      : '-',
                ),

                if (item.catatan != null && item.catatan!.isNotEmpty)
                  _buildDetailRow('Catatan', item.catatan!),

                const SizedBox(height: 12),
                Divider(color: AppColors.borderMedium),
                const SizedBox(height: 12),

                // Financial Info
                if (item.isLate)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF5252).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.access_time_filled_rounded,
                          color: Color(0xFFFF5252),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Terlambat ${item.keterlambatanHari} hari',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFFFF5252),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                _buildDetailRow(
                  'Total Tagihan',
                  currencyFormat.format(item.totalPembayaran ?? 0),
                ),
                _buildDetailRow(
                  'Status Pembayaran',
                  item.statusPembayaran ?? 'Lunas (Gratis)',
                ),

                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.surface,
                      foregroundColor: AppTheme.primaryColor,
                      elevation: 0,
                      side: BorderSide(color: AppColors.borderDark),
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

  // Helper for Detail Row
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

  // Payment Confirmation Dialog
  void _processPaymentDialog(PengembalianModel item) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.all(20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.payments_outlined,
                color: AppTheme.primaryColor,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Konfirmasi Pembayaran',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text.rich(
              TextSpan(
                text: 'Proses pembayaran denda sebesar ',
                style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
                children: [
                  TextSpan(
                    text: currencyFormat.format(item.totalPembayaran ?? 0),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const TextSpan(text: ' untuk peminjaman ini?'),
                ],
              ),
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

                      // Call Provider Method
                      final success = await ref
                          .read(pengembalianBelumLunasProvider.notifier)
                          .lunaskanDenda(item.pengembalianId, petugasId);

                      // Refresh Main Data
                      ref.read(pengembalianProvider.notifier).refresh();

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              success
                                  ? 'Pembayaran berhasil dikonfirmasi'
                                  : 'Gagal memproses pembayaran',
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
                      'Bayar Lunas',
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
  // EMPTY STATE & LOADING
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
                Icons.history_toggle_off_rounded,
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
                  : 'Data akan muncul setelah transaksi',
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
            borderRadius: BorderRadius.circular(10),
          ),
          height: 400,
        )
        .animate(onPlay: (controller) => controller.repeat())
        .shimmer(duration: 1200.ms);
  }

  // ============================================================================
  // CREATE DIALOG (Proses Pengembalian)
  // ============================================================================
  void _showCreateDialog() {
    // Ensure data is loaded
    ref.read(peminjamanAktifProvider.notifier).ensureInitialized();

    int? selectedPeminjamanId;
    String kondisiAlat = 'Baik';
    final catatanController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final peminjamanState = ref.watch(peminjamanAktifProvider);

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
                              Icons.assignment_return_outlined,
                              color: AppTheme.primaryColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Proses Pengembalian',
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
                            // Peminjaman Aktif Dropdown
                            _buildFormLabel('Peminjaman Aktif'),
                            const SizedBox(height: 8),
                            if (peminjamanState.isLoading)
                              const CircularProgressIndicator()
                            else if (peminjamanState.peminjamans.isEmpty)
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceContainerLow,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Tidak ada peminjaman aktif',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF666666),
                                  ),
                                ),
                              )
                            else
                              DropdownButtonFormField<int>(
                                value: selectedPeminjamanId,
                                decoration: _inputDecoration(
                                  'Pilih peminjaman',
                                ),
                                items: peminjamanState.peminjamans.map((p) {
                                  return DropdownMenuItem(
                                    value: p.peminjamanId,
                                    child: Text(
                                      '${p.kodePeminjaman} - ${p.peminjam?.namaLengkap ?? 'Unknown'}',
                                      style: const TextStyle(fontSize: 13),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (v) => setDialogState(
                                  () => selectedPeminjamanId = v,
                                ),
                                validator: (v) =>
                                    v == null ? 'Pilih peminjaman' : null,
                              ),
                            const SizedBox(height: 16),

                            // Kondisi Alat
                            _buildFormLabel('Kondisi Alat'),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              value: kondisiAlat,
                              decoration: _inputDecoration('Pilih kondisi'),
                              items: const [
                                DropdownMenuItem(
                                  value: 'Baik',
                                  child: Text(
                                    'Baik',
                                    style: TextStyle(fontSize: 13),
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'Rusak',
                                  child: Text(
                                    'Rusak',
                                    style: TextStyle(fontSize: 13),
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'Hilang',
                                  child: Text(
                                    'Hilang',
                                    style: TextStyle(fontSize: 13),
                                  ),
                                ),
                              ],
                              onChanged: (v) {
                                if (v != null) {
                                  setDialogState(() => kondisiAlat = v);
                                }
                              },
                            ),
                            const SizedBox(height: 16),

                            // Catatan
                            _buildFormLabel('Catatan (Opsional)'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: catatanController,
                              maxLines: 3,
                              decoration: _inputDecoration(
                                'Masukkan catatan pengembalian',
                              ),
                              style: const TextStyle(fontSize: 13),
                            ),
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
                              onPressed: peminjamanState.peminjamans.isEmpty
                                  ? null
                                  : () async {
                                      if (!formKey.currentState!.validate()) {
                                        return;
                                      }
                                      if (selectedPeminjamanId == null) return;

                                      Navigator.pop(context);

                                      final petugasId = ref
                                          .read(authProvider)
                                          .user
                                          ?.userId;
                                      if (petugasId == null) return;

                                      final success = await ref
                                          .read(pengembalianProvider.notifier)
                                          .prosesPengembalian(
                                            peminjamanId: selectedPeminjamanId!,
                                            petugasId: petugasId,
                                            kondisiAlat: kondisiAlat,
                                            catatan:
                                                catatanController.text.isEmpty
                                                ? null
                                                : catatanController.text,
                                          );

                                      // Refresh related providers
                                      ref
                                          .read(
                                            peminjamanAktifProvider.notifier,
                                          )
                                          .refresh();
                                      ref
                                          .read(peminjamanProvider.notifier)
                                          .refresh();

                                      if (mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              success
                                                  ? 'Pengembalian berhasil diproses'
                                                  : 'Gagal memproses pengembalian',
                                              style: const TextStyle(
                                                fontSize: 13,
                                              ),
                                            ),
                                            backgroundColor: success
                                                ? const Color(0xFF4CAF50)
                                                : const Color(0xFFFF5252),
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
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
  void _showEditDialog(PengembalianModel item) {
    String kondisiAlat = item.kondisiAlat ?? 'Baik';
    String statusPembayaran = item.statusPembayaran ?? 'Belum Lunas';
    final catatanController = TextEditingController(text: item.catatan ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: _isDesktop ? 500 : double.infinity,
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
                                  'Edit Pengembalian',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  item.peminjaman?.kodePeminjaman ?? '-',
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
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Kondisi Alat
                          _buildFormLabel('Kondisi Alat'),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: kondisiAlat,
                            decoration: _inputDecoration('Pilih kondisi'),
                            items: const [
                              DropdownMenuItem(
                                value: 'Baik',
                                child: Text(
                                  'Baik',
                                  style: TextStyle(fontSize: 13),
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'Rusak',
                                child: Text(
                                  'Rusak',
                                  style: TextStyle(fontSize: 13),
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'Hilang',
                                child: Text(
                                  'Hilang',
                                  style: TextStyle(fontSize: 13),
                                ),
                              ),
                            ],
                            onChanged: (v) {
                              if (v != null) {
                                setDialogState(() => kondisiAlat = v);
                              }
                            },
                          ),
                          const SizedBox(height: 16),

                          // Status Pembayaran
                          _buildFormLabel('Status Pembayaran'),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: statusPembayaran,
                            decoration: _inputDecoration('Pilih status'),
                            items: const [
                              DropdownMenuItem(
                                value: 'Belum Lunas',
                                child: Text(
                                  'Belum Lunas',
                                  style: TextStyle(fontSize: 13),
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'Lunas',
                                child: Text(
                                  'Lunas',
                                  style: TextStyle(fontSize: 13),
                                ),
                              ),
                            ],
                            onChanged: (v) {
                              if (v != null) {
                                setDialogState(() => statusPembayaran = v);
                              }
                            },
                          ),
                          const SizedBox(height: 16),

                          // Catatan
                          _buildFormLabel('Catatan'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: catatanController,
                            maxLines: 3,
                            decoration: _inputDecoration('Masukkan catatan'),
                            style: const TextStyle(fontSize: 13),
                          ),
                        ],
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
                                Navigator.pop(context);

                                final petugasId = ref
                                    .read(authProvider)
                                    .user
                                    ?.userId;
                                if (petugasId == null) return;

                                final success = await ref
                                    .read(pengembalianProvider.notifier)
                                    .updatePengembalian(
                                      item.pengembalianId,
                                      kondisiAlat: kondisiAlat,
                                      catatan: catatanController.text.isEmpty
                                          ? null
                                          : catatanController.text,
                                      statusPembayaran: statusPembayaran,
                                      petugasId: petugasId,
                                    );

                                // Refresh belum lunas provider
                                ref
                                    .read(
                                      pengembalianBelumLunasProvider.notifier,
                                    )
                                    .refresh();

                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        success
                                            ? 'Pengembalian berhasil diperbarui'
                                            : 'Gagal memperbarui pengembalian',
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
  void _showDeleteDialog(PengembalianModel item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
              'Hapus Pengembalian?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Data pengembalian akan dihapus dan peminjaman akan kembali ke status aktif.',
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
                          .read(pengembalianProvider.notifier)
                          .deletePengembalian(item.pengembalianId, petugasId);

                      // Refresh related providers
                      ref
                          .read(pengembalianBelumLunasProvider.notifier)
                          .refresh();
                      ref.read(peminjamanAktifProvider.notifier).refresh();
                      ref.read(peminjamanProvider.notifier).refresh();

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              success
                                  ? 'Pengembalian berhasil dihapus'
                                  : 'Gagal menghapus pengembalian',
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
