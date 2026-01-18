// lib/screens/admin/transaksi/pengembalian_management.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:paket_3_training/core/design_system/app_color.dart';
import 'package:paket_3_training/widgets/admin_sidebar.dart';
import 'package:paket_3_training/providers/pengembalian_provider.dart';
import 'package:paket_3_training/providers/auth_provider.dart';
import 'package:paket_3_training/models/pengembalian_model.dart';

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
                color: Colors.white,
                border: Border(
                  right: BorderSide(color: Colors.grey.shade200, width: 1),
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
        'Riwayat Pengembalian',
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

  Widget _buildSearchAndFilter() {
    return Row(
      children: [
        Expanded(
          child: Container(
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
                hintText: 'Cari kode peminjaman, nama peminjam...',
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
        ),
        const SizedBox(width: 12),
        // Filter Status Pembayaran
        Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200, width: 1),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              value: _selectedPaymentStatus,
              hint: Text(
                'Status Bayar',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              icon: Icon(
                Icons.arrow_drop_down_rounded,
                size: 20,
                color: Colors.grey.shade600,
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
          Divider(height: 1, color: Colors.grey.shade200),
          // Rows
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: list.length,
            separatorBuilder: (_, __) =>
                Divider(height: 1, color: Colors.grey.shade100),
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
            // Actions
            SizedBox(
              width: isActionTab ? 100 : 50,
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
                        style: TextStyle(fontSize: 11, color: Colors.white),
                      ),
                    )
                  : IconButton(
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

                Divider(height: 24, color: Colors.grey.shade100),

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
                          style: TextStyle(fontSize: 12, color: Colors.white),
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
      bg = Colors.grey;
      text = Colors.grey.shade600;
      label = '-';
    } else {
      bg = const Color(0xFFFF5252);
      text = const Color(0xFFFF5252);
      label = 'Belum Lunas';
    }

    if (isFree) {
      return Text(
        '-',
        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
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
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
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
            ),
            const SizedBox(height: 4),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Coba kata kunci lain'
                  : 'Data akan muncul setelah transaksi',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
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
