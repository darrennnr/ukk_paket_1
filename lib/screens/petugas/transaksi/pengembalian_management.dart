// lib/screens/petugas/transaksi/pengembalian_management.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:paket_3_training/core/design_system/app_color.dart';
import 'package:paket_3_training/core/design_system/app_design_system.dart' hide AppTheme;
import 'package:paket_3_training/widgets/petugas_sidebar.dart';
import 'package:paket_3_training/providers/pengembalian_provider.dart';
import 'package:paket_3_training/providers/auth_provider.dart';
import 'package:paket_3_training/models/pengembalian_model.dart';

class PetugasPengembalianManagement extends ConsumerStatefulWidget {
  const PetugasPengembalianManagement({Key? key}) : super(key: key);

  @override
  ConsumerState<PetugasPengembalianManagement> createState() =>
      _PetugasPengembalianManagementState();
}

class _PetugasPengembalianManagementState
    extends ConsumerState<PetugasPengembalianManagement>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;

  // Filter States
  String _searchQuery = '';
  String? _selectedPaymentStatus; // 'Lunas', 'Belum Lunas'
  String? _selectedCondition; // 'Baik', 'Rusak', 'Hilang'
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  String? _selectedPetugas;

  // Responsive Breakpoints
  bool get _isDesktop => MediaQuery.of(context).size.width >= 900;
  bool get _isTablet =>
      MediaQuery.of(context).size.width >= 600 &&
      MediaQuery.of(context).size.width < 900;
  bool get _isMobile => MediaQuery.of(context).size.width < 600;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Initial Data Fetch
    Future.microtask(() {
      ref.read(pengembalianProvider.notifier).refresh();
      ref.read(pengembalianBelumLunasProvider.notifier).refresh();
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
      drawer: _isDesktop ? null : const PetugasSidebar(currentRoute: '/petugas/pengembalian'),
      body: Row(
        children: [
          // Desktop Sidebar
          if (_isDesktop)
            Container(
              width: 260,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  right: BorderSide(color: Colors.grey.shade200, width: 1),
                ),
              ),
              child: const PetugasSidebar(currentRoute: '/petugas/pengembalian'),
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
    final userName = user?.namaLengkap ?? 'Petugas';
    
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
      title: const Text(
        'Pantau Pengembalian',
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
        child: Container(height: 1, color: Colors.grey.shade200),
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
              Icon(Icons.person_outline_rounded, size: 18, color: Colors.grey.shade700),
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
              const Icon(Icons.logout_rounded, size: 18, color: Color(0xFFFF5252)),
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
      color: Colors.white,
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: Colors.grey.shade600,
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
                    const Text('Semua Pengembalian'),
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
          Divider(height: 1, color: Colors.grey.shade200),
        ],
      ),
    );
  }

  Widget _buildCountBadge(int count, bool isActive, {bool isAlert = false}) {
    final bgColor = isAlert
        ? (isActive
            ? const Color(0xFFFF5252)
            : const Color(0xFFFF5252).withOpacity(0.2))
        : (isActive ? AppTheme.primaryColor : Colors.grey.shade300);

    final textColor = isAlert
        ? (isActive ? Colors.white : const Color(0xFFFF5252))
        : (isActive ? Colors.white : Colors.grey.shade700);

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
      isDendaTab: true,
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
    bool isDendaTab = false,
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
            _buildAdvancedFilterPanel(),
            const SizedBox(height: 20),
            if (isLoading && data.isEmpty)
              _buildLoadingSkeleton()
            else if (_getFilteredList(data, isDendaTab: isDendaTab).isEmpty)
              _buildEmptyState(emptyMessage)
            else
              _buildTableList(_getFilteredList(data, isDendaTab: isDendaTab)),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // HEADER & FILTER LOGIC
  // ============================================================================
  Widget _buildHeader(String title, int count) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
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
            if (_isMobile) const Spacer(),
            if (_isMobile)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.visibility_outlined, size: 12, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      'Read-Only',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '$count data ditemukan',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0);
  }

  Widget _buildAdvancedFilterPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search Bar
        Container(
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200, width: 1),
          ),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(fontSize: 13, color: Color(0xFF1A1A1A)),
            decoration: InputDecoration(
              hintText: 'Cari kode peminjaman, nama peminjam, judul buku...',
              hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
              prefixIcon: Icon(
                Icons.search_rounded,
                size: 18,
                color: Colors.grey.shade500,
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: Colors.grey.shade500,
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
        
        const SizedBox(height: 12),
        
        // Filter Row
        _isDesktop || _isTablet
            ? _buildDesktopFilterRow()
            : _buildMobileFilterColumn(),
        
        // Clear Filters Button
        if (_hasActiveFilters())
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _clearAllFilters,
                icon: Icon(Icons.clear_all, size: 14, color: Colors.grey.shade600),
                label: Text(
                  'Hapus Semua Filter',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDesktopFilterRow() {
    return Row(
      children: [
        // Status Pembayaran
        _buildFilterDropdown(
          value: _selectedPaymentStatus,
          hint: 'Status Pembayaran',
          items: const [
            DropdownMenuItem(value: null, child: Text('Semua Status')),
            DropdownMenuItem(value: 'lunas', child: Text('Lunas')),
            DropdownMenuItem(value: 'belum lunas', child: Text('Belum Lunas')),
          ],
          onChanged: (value) => setState(() => _selectedPaymentStatus = value),
          width: 180,
        ),
        
        const SizedBox(width: 12),
        
        // Kondisi Buku
        _buildFilterDropdown(
          value: _selectedCondition,
          hint: 'Kondisi Buku',
          items: const [
            DropdownMenuItem(value: null, child: Text('Semua Kondisi')),
            DropdownMenuItem(value: 'baik', child: Text('Baik')),
            DropdownMenuItem(value: 'rusak', child: Text('Rusak')),
            DropdownMenuItem(value: 'hilang', child: Text('Hilang')),
          ],
          onChanged: (value) => setState(() => _selectedCondition = value),
          width: 160,
        ),
        
        const SizedBox(width: 12),
        
        // Tanggal Mulai
        _buildDateFilter(
          value: _selectedStartDate,
          hint: 'Tanggal Mulai',
          onChanged: (date) => setState(() => _selectedStartDate = date),
          width: 160,
        ),
        
        const SizedBox(width: 12),
        
        // Tanggal Akhir
        _buildDateFilter(
          value: _selectedEndDate,
          hint: 'Tanggal Akhir',
          onChanged: (date) => setState(() => _selectedEndDate = date),
          width: 160,
        ),
      ],
    );
  }

  Widget _buildMobileFilterColumn() {
    return Column(
      children: [
        // Row 1
        Row(
          children: [
            Expanded(
              child: _buildFilterDropdown(
                value: _selectedPaymentStatus,
                hint: 'Status Bayar',
                items: const [
                  DropdownMenuItem(value: null, child: Text('Semua')),
                  DropdownMenuItem(value: 'lunas', child: Text('Lunas')),
                  DropdownMenuItem(value: 'belum lunas', child: Text('Belum Lunas')),
                ],
                onChanged: (value) => setState(() => _selectedPaymentStatus = value),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildFilterDropdown(
                value: _selectedCondition,
                hint: 'Kondisi',
                items: const [
                  DropdownMenuItem(value: null, child: Text('Semua')),
                  DropdownMenuItem(value: 'baik', child: Text('Baik')),
                  DropdownMenuItem(value: 'rusak', child: Text('Rusak')),
                  DropdownMenuItem(value: 'hilang', child: Text('Hilang')),
                ],
                onChanged: (value) => setState(() => _selectedCondition = value),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // Row 2
        Row(
          children: [
            Expanded(
              child: _buildDateFilter(
                value: _selectedStartDate,
                hint: 'Dari Tanggal',
                onChanged: (date) => setState(() => _selectedStartDate = date),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDateFilter(
                value: _selectedEndDate,
                hint: 'Sampai Tanggal',
                onChanged: (date) => setState(() => _selectedEndDate = date),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterDropdown({
    required String? value,
    required String hint,
    required List<DropdownMenuItem<String?>> items,
    required ValueChanged<String?> onChanged,
    double? width,
  }) {
    return Container(
      height: 42,
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: value,
          hint: Text(
            hint,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            overflow: TextOverflow.ellipsis,
          ),
          icon: Icon(
            Icons.arrow_drop_down_rounded,
            size: 20,
            color: Colors.grey.shade600,
          ),
          isExpanded: true,
          style: const TextStyle(fontSize: 13, color: Color(0xFF1A1A1A)),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildDateFilter({
    required DateTime? value,
    required String hint,
    required ValueChanged<DateTime?> onChanged,
    double? width,
  }) {
    return Container(
      height: 42,
      width: width,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: InkWell(
        onTap: () async {
          final date = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime(2020),
            lastDate: DateTime.now().add(const Duration(days: 365)),
          );
          if (date != null) {
            onChanged(date);
          }
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 16,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  value != null
                      ? DateFormat('dd/MM/yyyy').format(value)
                      : hint,
                  style: TextStyle(
                    fontSize: 13,
                    color: value != null ? const Color(0xFF1A1A1A) : Colors.grey.shade600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (value != null)
                IconButton(
                  icon: Icon(Icons.clear, size: 16, color: Colors.grey.shade500),
                  onPressed: () => onChanged(null),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                ),
            ],
          ),
        ),
      ),
    );
  }

  bool _hasActiveFilters() {
    return _selectedPaymentStatus != null ||
        _selectedCondition != null ||
        _selectedStartDate != null ||
        _selectedEndDate != null;
  }

  void _clearAllFilters() {
    setState(() {
      _selectedPaymentStatus = null;
      _selectedCondition = null;
      _selectedStartDate = null;
      _selectedEndDate = null;
    });
  }

  List<PengembalianModel> _getFilteredList(
    List<PengembalianModel> list, {
    bool isDendaTab = false,
  }) {
    return list.where((item) {
      // 1. Search Logic
      final kode = item.peminjaman?.kodePeminjaman.toLowerCase() ?? '';
      final nama = item.peminjaman?.peminjam?.namaLengkap.toLowerCase() ?? '';
      final alat = item.peminjaman?.alat?.namaAlat.toLowerCase() ?? '';

      final matchesSearch = _searchQuery.isEmpty ||
          kode.contains(_searchQuery) ||
          nama.contains(_searchQuery) ||
          alat.contains(_searchQuery);

      // 2. Filter Status Pembayaran
      bool matchesStatus = true;
      if (_selectedPaymentStatus != null) {
        final statusDb = item.statusPembayaran?.toLowerCase() ?? 'lunas';
        matchesStatus = statusDb == _selectedPaymentStatus;
      }

      // 3. Filter Kondisi Buku
      bool matchesCondition = true;
      if (_selectedCondition != null) {
        final kondisiDb = item.kondisiAlat?.toLowerCase() ?? 'baik';
        matchesCondition = kondisiDb == _selectedCondition;
      }

      // 4. Filter Tanggal
      bool matchesDate = true;
      if (_selectedStartDate != null) {
        matchesDate = item.tanggalKembali != null &&
            item.tanggalKembali!.isAfter(
              DateTime(
                _selectedStartDate!.year,
                _selectedStartDate!.month,
                _selectedStartDate!.day,
              ),
            );
      }
      if (_selectedEndDate != null) {
        matchesDate = matchesDate &&
            item.tanggalKembali != null &&
            item.tanggalKembali!.isBefore(
              DateTime(
                _selectedEndDate!.year,
                _selectedEndDate!.month,
                _selectedEndDate!.day,
                23,
                59,
                59,
              ),
            );
      }

      return matchesSearch && matchesStatus && matchesCondition && matchesDate;
    }).toList();
  }

  // ============================================================================
  // LIST RENDERER (DESKTOP & MOBILE)
  // ============================================================================
  Widget _buildTableList(List<PengembalianModel> list) {
    if (_isDesktop || _isTablet) {
      return _buildDesktopTable(list);
    }
    return _buildMobileList(list);
  }

  // --- Desktop Table ---
  Widget _buildDesktopTable(List<PengembalianModel> list) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
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
                    'Judul Buku',
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
                const SizedBox(width: 50),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          // Rows
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: list.length,
            separatorBuilder: (_, __) =>
                Divider(height: 1, color: Colors.grey.shade100),
            itemBuilder: (context, index) => _buildTableRow(list[index], index),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 150.ms);
  }

  Widget _buildTableRow(PengembalianModel item, int index) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return InkWell(
      onTap: () => _showDetailDialog(item),
      hoverColor: Colors.grey.shade50,
      borderRadius: BorderRadius.circular(0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Kode
            Expanded(
              flex: 2,
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
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
            // Judul Buku
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  if (item.peminjaman?.alat?.fotoAlat != null && item.peminjaman!.alat!.fotoAlat!.isNotEmpty)
                    Container(
                      width: 32,
                      height: 32,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
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
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ),
                    ),
                  Expanded(
                    child: Text(
                      item.peminjaman?.alat?.namaAlat ?? '-',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF1A1A1A)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
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
                      : Colors.grey.shade600,
                ),
              ),
            ),
            // Status Bayar
            Expanded(
              flex: 2,
              child: _buildPaymentStatusBadge(item.statusPembayaran),
            ),
            // View Button
            SizedBox(
              width: 50,
              child: IconButton(
                icon: Icon(
                  Icons.visibility_outlined,
                  size: 18,
                  color: Colors.grey.shade500,
                ),
                onPressed: () => _showDetailDialog(item),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Mobile List ---
  Widget _buildMobileList(List<PengembalianModel> list) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _buildMobileCard(list[index], index),
    );
  }

  Widget _buildMobileCard(PengembalianModel item, int index) {
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Kode & Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item.peminjaman?.kodePeminjaman ?? '-',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
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
              Icons.menu_book_rounded,
              'Judul Buku',
              item.peminjaman?.alat?.namaAlat ?? '-',
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.event_available_outlined, size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dikembalikan',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.tanggalKembali != null
                            ? DateFormat('dd MMM yyyy').format(item.tanggalKembali!)
                            : '-',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      if (item.isLate)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            'Telat ${item.keterlambatanHari} hari',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFFFF5252),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.assignment_turned_in_rounded,
              'Kondisi',
              item.kondisiAlat?.toUpperCase() ?? '-',
            ),

            Divider(height: 20, color: Colors.grey.shade100),

            // Bottom: Financials & View
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
                          color: Colors.grey.shade600,
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
                OutlinedButton.icon(
                  onPressed: () => _showDetailDialog(item),
                  icon: Icon(Icons.visibility_outlined, size: 14),
                  label: const Text('Lihat'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms, delay: (index * 50).ms).scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade500),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Text(
        text[0].toUpperCase() + text.substring(1),
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w700,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildPaymentStatusBadge(String? status) {
    final isPaid = status?.toLowerCase() == 'lunas';
    final isFree = status == null;

    Color bg;
    Color textColor;
    String label;

    if (isPaid) {
      bg = const Color(0xFF4CAF50);
      textColor = const Color(0xFF4CAF50);
      label = 'Lunas';
    } else if (isFree) {
      return Text(
        '-',
        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
      );
    } else {
      bg = const Color(0xFFFF5252);
      textColor = const Color(0xFFFF5252);
      label = 'Belum Lunas';
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
          color: textColor,
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
                _buildDetailRow(
                  'Judul Buku',
                  item.peminjaman?.alat?.namaAlat ?? '-',
                ),
                _buildDetailRow(
                  'Kode Buku',
                  item.peminjaman?.alat?.kodeAlat ?? '-',
                ),
                _buildDetailRow(
                  'Kondisi Buku',
                  item.kondisiAlat?.toUpperCase() ?? '-',
                ),
                _buildDetailRow(
                  'Jumlah Kembali',
                  '${item.jumlahKembali} buku',
                ),
                _buildDetailRow(
                  'Tgl Kembali',
                  item.tanggalKembali != null
                      ? DateFormat(
                          'dd MMMM yyyy, HH:mm',
                        ).format(item.tanggalKembali!)
                      : '-',
                ),
                _buildDetailRow(
                  'Petugas',
                  item.petugas?.namaLengkap ?? '-',
                ),

                if (item.catatan != null && item.catatan!.isNotEmpty)
                  _buildDetailRow('Catatan', item.catatan!),

                const SizedBox(height: 12),
                Divider(color: Colors.grey.shade200),
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
                  (item.totalPembayaran ?? 0) > 0
                      ? currencyFormat.format(item.totalPembayaran)
                      : 'Gratis',
                ),
                _buildDetailRow(
                  'Status Pembayaran',
                  item.statusPembayaran?.toUpperCase() ?? 'LUNAS',
                ),

                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppTheme.primaryColor,
                      elevation: 0,
                      side: BorderSide(color: Colors.grey.shade300),
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
                color: Colors.grey.shade600,
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
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.history_toggle_off_rounded,
                size: 48,
                color: Colors.grey.shade400,
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
              _searchQuery.isNotEmpty || _hasActiveFilters()
                  ? 'Coba ubah kata kunci atau filter'
                  : 'Data akan muncul setelah ada pengembalian',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            if (_hasActiveFilters())
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: ElevatedButton(
                  onPressed: _clearAllFilters,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppTheme.primaryColor,
                    elevation: 0,
                    side: BorderSide(color: Colors.grey.shade300),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  child: const Text('Hapus Filter'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(10),
      ),
      height: 400,
    )
        .animate(onPlay: (controller) => controller.repeat())
        .shimmer(duration: 1200.ms);
  }
}