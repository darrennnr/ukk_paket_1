// lib/screens/petugas/transaksi/peminjaman_management.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:paket_3_training/core/design_system/app_color.dart';
import 'package:paket_3_training/widgets/petugas_sidebar.dart';
import 'package:paket_3_training/providers/peminjaman_provider.dart';
import 'package:paket_3_training/providers/auth_provider.dart';
import 'package:paket_3_training/models/peminjaman_model.dart';

class PetugasPeminjamanManagement extends ConsumerStatefulWidget {
  const PetugasPeminjamanManagement({Key? key}) : super(key: key);

  @override
  ConsumerState<PetugasPeminjamanManagement> createState() =>
      _PetugasPeminjamanManagementState();
}

class _PetugasPeminjamanManagementState
    extends ConsumerState<PetugasPeminjamanManagement>
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
    _tabController = TabController(length: 2, vsync: this);
    Future.microtask(() {
      ref.read(peminjamanMenungguProvider.notifier).refresh();
      ref.read(peminjamanAktifProvider.notifier).refresh();
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
          : PetugasSidebar(currentRoute: '/petugas/approval'),
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
              child: PetugasSidebar(currentRoute: '/petugas/approval'),
            ),
          Expanded(
            child: Column(
              children: [
                _buildTabBar(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
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
        'Approval Peminjaman',
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
  // TAB BAR
  // ============================================================================
  Widget _buildTabBar() {
    final pendingCount = ref.watch(peminjamanMenungguCountProvider);
    final activeCount = ref.watch(peminjamanAktifCountProvider);

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
            tabs: [
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Menunggu'),
                    const SizedBox(width: 6),
                    _buildCountBadge(pendingCount, _tabController.index == 0),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Aktif'),
                    const SizedBox(width: 6),
                    _buildCountBadge(activeCount, _tabController.index == 1),
                  ],
                ),
              ),
            ],
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          if (_isDesktop || _isTablet) const SizedBox(height: 12),
          if (_isDesktop || _isTablet)
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: _isDesktop ? 24 : 16,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildSearchField(),
                  ),
                  const SizedBox(width: 12),
                  _buildStatusFilter(),
                ],
              ),
            ),
          if (_isDesktop || _isTablet) const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildCountBadge(int count, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isActive ? AppTheme.primaryColor : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: isActive ? Colors.white : Colors.grey.shade700,
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
            if (!_isDesktop && !_isTablet) ...[
              _buildHeader(
                'Peminjaman Menunggu',
                peminjamanState.peminjamans.length,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildSearchField()),
                  const SizedBox(width: 12),
                  _buildStatusFilter(),
                ],
              ),
              const SizedBox(height: 20),
            ],
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
            if (!_isDesktop && !_isTablet) ...[
              _buildHeader(
                'Peminjaman Aktif',
                peminjamanState.peminjamans.length,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildSearchField()),
                  const SizedBox(width: 12),
                  _buildStatusFilter(),
                ],
              ),
              const SizedBox(height: 20),
            ],
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
                showActions: false,
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
    return Column(
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
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0);
  }

  // ============================================================================
  // SEARCH FIELD
  // ============================================================================
  Widget _buildSearchField() {
    return Container(
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
          hintText: 'Cari kode, nama peminjam, atau alat...',
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
        onChanged: (value) {
          setState(() => _searchQuery = value.toLowerCase());
        },
      ),
    );
  }

  // ============================================================================
  // STATUS FILTER
  // ============================================================================
  Widget _buildStatusFilter() {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          value: _selectedStatusFilter,
          hint: Text(
            'Status',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          icon: Icon(
            Icons.arrow_drop_down_rounded,
            size: 20,
            color: Colors.grey.shade600,
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
          onChanged: (value) => setState(() => _selectedStatusFilter = value),
        ),
      ),
    );
  }

  // ============================================================================
  // FILTERED PEMINJAMAN
  // ============================================================================
  List<PeminjamanModel> _getFilteredPeminjaman(
    List<PeminjamanModel> peminjamans,
  ) {
    var filtered = peminjamans;

    // Filter by status (hanya untuk tab semua di mobile/tablet)
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: Column(
        children: [
          // Table Header
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
          Divider(height: 1, color: Colors.grey.shade200),
          // Table Body
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: peminjamans.length,
            separatorBuilder: (_, __) =>
                Divider(height: 1, color: Colors.grey.shade100),
            itemBuilder: (context, index) => _buildPeminjamanRow(
              peminjamans[index],
              index,
              showActions: showActions,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 150.ms);
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
                      color: Colors.grey.shade600,
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
            // Tanggal
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    peminjaman.tanggalPinjam != null
                        ? DateFormat('dd MMM yyyy')
                            .format(peminjaman.tanggalPinjam!)
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
                      color: Colors.grey.shade600,
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
                        _buildActionButton(
                          icon: Icons.visibility_outlined,
                          color: AppTheme.primaryColor,
                          onTap: () => _showDetailDialog(peminjaman),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms, delay: (150 + index * 30).ms);
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    peminjaman.kodePeminjaman,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
                  ? DateFormat('dd MMM yyyy').format(peminjaman.tanggalPinjam!)
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
                        foregroundColor: Colors.white,
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
    ).animate().fadeIn(duration: 400.ms, delay: (index * 50).ms);
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
        color = Colors.grey;
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
                      ? DateFormat('dd MMMM yyyy, HH:mm')
                          .format(peminjaman.tanggalPengajuan!)
                      : '-',
                ),
                _buildDetailRow(
                  'Tanggal Pinjam',
                  peminjaman.tanggalPinjam != null
                      ? DateFormat('dd MMMM yyyy').format(peminjaman.tanggalPinjam!)
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
  // APPROVE DIALOG
  // ============================================================================
  void _approveDialog(PeminjamanModel peminjaman) {
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
              'Peminjaman "${peminjaman.kodePeminjaman}" akan disetujui dan stok alat akan dikurangi.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
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
                      side: BorderSide(color: Colors.grey.shade300),
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
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: catatanController,
              maxLines: 3,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Masukkan alasan penolakan...',
                hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                filled: true,
                fillColor: Colors.grey.shade50,
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade200),
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
                      side: BorderSide(color: Colors.grey.shade300),
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
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.assignment_outlined,
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
            ),
            const SizedBox(height: 4),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Coba kata kunci lain'
                  : 'Belum ada data',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
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
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(10),
          ),
          height: 400,
        )
        .animate(onPlay: (controller) => controller.repeat())
        .shimmer(duration: 1200.ms);
  }
}