// lib/screens/admin/data_management/alat_management.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:paket_3_training/core/design_system/app_color.dart';
import 'package:paket_3_training/core/design_system/app_design_system.dart'
    hide AppTheme;
import 'package:paket_3_training/services/storage_services.dart';
import 'package:paket_3_training/widgets/admin_sidebar.dart';
import 'package:paket_3_training/providers/alat_provider.dart';
import 'package:paket_3_training/providers/kategori_provider.dart';
import 'package:paket_3_training/providers/auth_provider.dart';
import 'package:paket_3_training/models/alat_model.dart';
import 'dart:typed_data';

class AlatManagement extends ConsumerStatefulWidget {
  const AlatManagement({Key? key}) : super(key: key);

  @override
  ConsumerState<AlatManagement> createState() => _AlatManagementState();
}

class _AlatManagementState extends ConsumerState<AlatManagement> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  int? _selectedKategoriFilter;

  bool get _isDesktop => MediaQuery.of(context).size.width >= 900;
  bool get _isTablet =>
      MediaQuery.of(context).size.width >= 600 &&
      MediaQuery.of(context).size.width < 900;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // GUNAKAN FUNGSI BARU: ensureInitializedPaginated()
      ref.read(alatProvider.notifier).ensureInitializedPaginated();
      ref.read(kategoriProvider.notifier).ensureInitialized();
    });

    // Setup scroll listener for pagination
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // Load more when near bottom - GUNAKAN FUNGSI BARU
      ref.read(alatProvider.notifier).loadMoreAlats();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final alatState = ref.watch(alatProvider);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildAppBar(),
      drawer: _isDesktop ? null : AdminSidebar(currentRoute: '/admin/alat'),
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
              child: AdminSidebar(currentRoute: '/admin/alat'),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () =>
                  ref.read(alatProvider.notifier).refreshPaginated(),
              color: AppTheme.primaryColor,
              child: CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: EdgeInsets.all(_isDesktop ? 24 : 16),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _buildHeader(),
                        const SizedBox(height: 20),
                        _buildSearchAndFilter(),
                        const SizedBox(height: 20),
                      ]),
                    ),
                  ),
                  if (alatState.isLoading && alatState.displayedAlats.isEmpty)
                    SliverPadding(
                      padding: EdgeInsets.symmetric(
                        horizontal: _isDesktop ? 24 : 16,
                      ),
                      sliver: _buildLoadingSkeletonSliver(),
                    )
                  else if (alatState.displayedAlats.isEmpty)
                    SliverPadding(
                      padding: EdgeInsets.all(_isDesktop ? 24 : 16),
                      sliver: SliverToBoxAdapter(child: _buildEmptyState()),
                    )
                  else
                    SliverPadding(
                      padding: EdgeInsets.symmetric(
                        horizontal: _isDesktop ? 24 : 16,
                      ),
                      sliver: _buildAlatGridSliver(alatState.displayedAlats),
                    ),
                  // Loading indicator for pagination
                  if (alatState.isLoadingMore)
                    SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverToBoxAdapter(
                        child: Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                  // Bottom spacing
                  const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFAB(),
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
        'Kelola Alat',
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
    final alatState = ref.watch(alatProvider);
    final totalCount = alatState.totalCount;
    final tersediaCount = alatState.displayedAlats
        .where((a) => a.isAvailable)
        .length;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Manajemen Alat',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$totalCount total alat • $tersediaCount tersedia',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(duration: 150.ms).slideY(begin: -0.1, end: 0);
  }

  // ============================================================================
  // SEARCH & FILTER
  // ============================================================================
  Widget _buildSearchAndFilter() {
    final kategoris = ref.watch(kategoriProvider).kategoris;

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
                hintText: 'Cari alat...',
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
                          _searchController.clear();
                          // GUNAKAN FUNGSI BARU
                          ref
                              .read(alatProvider.notifier)
                              .searchAlatsPaginated('');
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
                setState(() {});
                // GUNAKAN FUNGSI BARU: searchAlatsPaginated()
                ref.read(alatProvider.notifier).searchAlatsPaginated(value);
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
              value: _selectedKategoriFilter,
              hint: Text(
                'Kategori',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              icon: Icon(
                Icons.arrow_drop_down_rounded,
                size: 20,
                color: AppColors.textSecondary,
              ),
              style: const TextStyle(fontSize: 13, color: Color(0xFF1A1A1A)),
              items: [
                DropdownMenuItem<int?>(
                  value: null,
                  child: Text(
                    'Semua Kategori',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                ...kategoris.map(
                  (k) => DropdownMenuItem<int?>(
                    value: k.kategoriId,
                    child: Text(
                      k.namaKategori,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() => _selectedKategoriFilter = value);
                // GUNAKAN FUNGSI BARU: filterByKategoriPaginated()
                ref
                    .read(alatProvider.notifier)
                    .filterByKategoriPaginated(value);
              },
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // ALAT GRID (SLIVER VERSION)
  // ============================================================================
  Widget _buildAlatGridSliver(List<AlatModel> alats) {
    int crossAxisCount = _isDesktop ? 5 : (_isTablet ? 4 : 2);

    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: _isDesktop ? 0.68 : (_isTablet ? 0.65 : 0.62),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) => _buildAlatCard(alats[index], index),
        childCount: alats.length,
      ),
    );
  }

  Widget _buildAlatCard(AlatModel alat, int index) {
    final kategoriName = alat.kategori?.namaKategori ?? 'Tanpa Kategori';
    final isAvailable = alat.isAvailable;

    return InkWell(
          onTap: () => _showDetailDialog(alat),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderMedium, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Container - Portrait 3:4 ratio (SMALLER SIZE)
                Expanded(
                  flex: 5, // Reduced from full AspectRatio to flex ratio
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(10),
                      ),
                    ),
                    child: Stack(
                      children: [
                        if (alat.fotoAlat != null && alat.fotoAlat!.isNotEmpty)
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(10),
                            ),
                            child: Image.network(
                              alat.fotoAlat!,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                              headers: kIsWeb
                                  ? {'Cache-Control': 'no-cache'}
                                  : null,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Center(
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          value:
                                              loadingProgress
                                                      .expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                        .cumulativeBytesLoaded /
                                                    loadingProgress
                                                        .expectedTotalBytes!
                                              : null,
                                          color: AppTheme.primaryColor,
                                        ),
                                      ),
                                    );
                                  },
                              errorBuilder: (context, error, stackTrace) {
                                if (kDebugMode) {
                                  print('❌ Image load error: $error');
                                }
                                return Center(
                                  child: Icon(
                                    Icons.inventory_2_outlined,
                                    size: 32,
                                    color: AppColors.textHint,
                                  ),
                                );
                              },
                            ),
                          )
                        else
                          Center(
                            child: Icon(
                              Icons.inventory_2_outlined,
                              size: 32,
                              color: AppColors.textHint,
                            ),
                          ),
                        // Status Badge
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: isAvailable
                                  ? const Color(0xFF4CAF50)
                                  : const Color(0xFFFF5252),
                              borderRadius: BorderRadius.circular(5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 3,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Text(
                              isAvailable ? 'Tersedia' : 'Habis',
                              style: const TextStyle(
                                fontSize: 9,
                                color: AppColors.surface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Content - Compact version
                Expanded(
                  flex: 3, // Reduced content area
                  child: Padding(
                    padding: const EdgeInsets.all(7),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              alat.namaAlat,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A1A1A),
                                letterSpacing: -0.1,
                                height: 1,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              kategoriName,
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.textSecondary,
                                height: 1,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                Icon(
                                  Icons.qr_code_2_rounded,
                                  size: 9,
                                  color: AppColors.textTertiary,
                                ),
                                const SizedBox(width: 3),
                                Expanded(
                                  child: Text(
                                    alat.kodeAlat,
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w500,
                                      height: 1,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Stok: ${alat.jumlahTersedia}/${alat.jumlahTotal}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: alat.jumlahTersedia > 0
                                      ? const Color(0xFF4CAF50)
                                      : const Color(0xFFFF5252),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            PopupMenuButton(
                              icon: Icon(
                                Icons.more_vert_rounded,
                                size: 14,
                                color: AppColors.textSecondary,
                              ),
                              color: AppColors.surface,
                              offset: const Offset(0, 25),
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  height: 34,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.visibility_outlined,
                                        size: 15,
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
                                    () => _showDetailDialog(alat),
                                  ),
                                ),
                                PopupMenuItem(
                                  height: 34,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.edit_outlined,
                                        size: 15,
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
                                    () => _showFormDialog(alat: alat),
                                  ),
                                ),
                                PopupMenuItem(
                                  height: 34,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(
                                        Icons.delete_outline_rounded,
                                        size: 15,
                                        color: Color(0xFFFF5252),
                                      ),
                                      SizedBox(width: 8),
                                      Text(
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
                                    () => _confirmDelete(alat),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 150.ms, delay: (index * 50).ms)
        .scale(begin: const Offset(0.95, 0.95));
  }

  // ============================================================================
  // EMPTY STATE
  // ============================================================================
  Widget _buildEmptyState() {
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
                Icons.inventory_2_outlined,
                size: 48,
                color: AppColors.textHint,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Belum ada data alat',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tambahkan alat pertama Anda',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // LOADING SKELETON (SLIVER VERSION)
  // ============================================================================
  Widget _buildLoadingSkeletonSliver() {
    int crossAxisCount = _isDesktop ? 5 : (_isTablet ? 4 : 2);

    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: _isDesktop ? 0.68 : (_isTablet ? 0.65 : 0.62),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) =>
            Container(
                  decoration: BoxDecoration(
                    color: AppColors.borderMedium,
                    borderRadius: BorderRadius.circular(10),
                  ),
                )
                .animate(onPlay: (controller) => controller.repeat())
                .shimmer(duration: 1200.ms),
        childCount: 16,
      ),
    );
  }

  // ============================================================================
  // FAB
  // ============================================================================
  Widget _buildFAB() {
    return FloatingActionButton(
      onPressed: () => _showFormDialog(),
      backgroundColor: AppTheme.primaryColor,
      elevation: 2,
      child: const Icon(Icons.add_rounded, color: AppColors.surface, size: 24),
    );
  }

  // ============================================================================
  // DETAIL DIALOG
  // ============================================================================
  void _showDetailDialog(AlatModel alat) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: AppColors.surface,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: _isDesktop ? 450 : double.infinity,
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: SingleChildScrollView(
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
                          Icons.inventory_2_outlined,
                          color: AppTheme.primaryColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Detail Alat',
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
                  const SizedBox(height: 16),
                  // Smaller detail image - 3:4 ratio
                  if (alat.fotoAlat != null && alat.fotoAlat!.isNotEmpty)
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 250),
                        child: AspectRatio(
                          aspectRatio: 3 / 4,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              alat.fotoAlat!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: AppColors.surfaceContainerLow,
                                child: Center(
                                  child: Icon(
                                    Icons.inventory_2_outlined,
                                    size: 40,
                                    color: AppColors.textHint,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (alat.fotoAlat != null && alat.fotoAlat!.isNotEmpty)
                    const SizedBox(height: 16),
                  _buildDetailRow('Nama Alat', alat.namaAlat),
                  _buildDetailRow('Kode Alat', alat.kodeAlat),
                  _buildDetailRow(
                    'Kategori',
                    alat.kategori?.namaKategori ?? '-',
                  ),
                  _buildDetailRow('Kondisi', alat.kondisi ?? 'Baik'),
                  _buildDetailRow('Jumlah Total', '${alat.jumlahTotal} unit'),
                  _buildDetailRow(
                    'Jumlah Tersedia',
                    '${alat.jumlahTersedia} unit',
                  ),
                  if (alat.hargaPerhari != null)
                    _buildDetailRow(
                      'Harga/Hari',
                      NumberFormat.currency(
                        locale: 'id_ID',
                        symbol: 'Rp ',
                        decimalDigits: 0,
                      ).format(alat.hargaPerhari),
                    ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 42,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _showFormDialog(alat: alat);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Edit Alat',
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
            width: 120,
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
  // FORM DIALOG (Add/Edit)
  // ============================================================================
  void _showFormDialog({AlatModel? alat}) {
    showDialog(
      context: context,
      builder: (context) => _AlatFormDialog(alat: alat),
    );
  }

  // ============================================================================
  // DELETE CONFIRMATION
  // ============================================================================
  void _confirmDelete(AlatModel alat) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing while deleting
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          bool isDeleting = false;

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
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
                    Icons.warning_rounded,
                    color: Color(0xFFFF5252),
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Hapus Alat?',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  'Apakah Anda yakin ingin menghapus "${alat.namaAlat}"?',
                  style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: isDeleting
                            ? null
                            : () => Navigator.pop(dialogContext),
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
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isDeleting
                            ? null
                            : () async {
                                // Set loading state
                                setState(() => isDeleting = true);

                                try {
                                  // Perform delete operation
                                  final success = await ref
                                      .read(alatProvider.notifier)
                                      .deleteAlatPaginated(alat.alatId);

                                  // Close dialog after operation completes
                                  if (dialogContext.mounted) {
                                    Navigator.pop(dialogContext);
                                  }

                                  // Show feedback in parent context
                                  if (mounted) {
                                    ScaffoldMessenger.of(
                                      this.context,
                                    ).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          success
                                              ? 'Alat berhasil dihapus'
                                              : 'Gagal menghapus alat',
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                        backgroundColor: success
                                            ? const Color(0xFF4CAF50)
                                            : const Color(0xFFFF5252),
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  // Handle error
                                  setState(() => isDeleting = false);

                                  if (mounted) {
                                    ScaffoldMessenger.of(
                                      this.context,
                                    ).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Error: ${e.toString()}',
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                        backgroundColor: const Color(
                                          0xFFFF5252,
                                        ),
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                    );
                                  }
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
                        child: isDeleting
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Hapus',
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
              ],
            ),
          );
        },
      ),
    );
  }
}

// ============================================================================
// FORM DIALOG WIDGET (Unchanged - keeping compact preview)
// ============================================================================
class _AlatFormDialog extends ConsumerStatefulWidget {
  final AlatModel? alat;

  const _AlatFormDialog({this.alat});

  @override
  ConsumerState<_AlatFormDialog> createState() => _AlatFormDialogState();
}

class _AlatFormDialogState extends ConsumerState<_AlatFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _kodeController;
  late TextEditingController _namaController;
  late TextEditingController _jumlahTotalController;
  late TextEditingController _jumlahTersediaController;
  late TextEditingController _hargaController;
  late TextEditingController _fotoUrlController;
  int? _selectedKategoriId;
  String _selectedKondisi = 'baik';
  bool _isLoading = false;

  Uint8List? _selectedImageBytes;
  String? _selectedImageName;
  bool _useFileUpload = false;
  final StorageService _storageService = StorageService();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _kodeController = TextEditingController(text: widget.alat?.kodeAlat ?? '');
    _namaController = TextEditingController(text: widget.alat?.namaAlat ?? '');
    _jumlahTotalController = TextEditingController(
      text: widget.alat?.jumlahTotal.toString() ?? '0',
    );
    _jumlahTersediaController = TextEditingController(
      text: widget.alat?.jumlahTersedia.toString() ?? '0',
    );
    _hargaController = TextEditingController(
      text: widget.alat?.hargaPerhari?.toString() ?? '',
    );
    _fotoUrlController = TextEditingController(
      text: widget.alat?.fotoAlat ?? '',
    );
    _selectedKategoriId = widget.alat?.kategoriId;

    // FIX: Normalize kondisi value dan fallback ke 'baik' jika tidak valid
    final rawKondisi = (widget.alat?.kondisi ?? 'baik').toLowerCase().trim();
    final validKondisi = ['baik', 'rusak ringan', 'rusak berat'];
    _selectedKondisi = validKondisi.contains(rawKondisi) ? rawKondisi : 'baik';
  }

  @override
  void dispose() {
    _kodeController.dispose();
    _namaController.dispose();
    _jumlahTotalController.dispose();
    _jumlahTersediaController.dispose();
    _hargaController.dispose();
    _fotoUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _selectedImageBytes = bytes;
          _selectedImageName = pickedFile.name;
          _useFileUpload = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memilih gambar: ${e.toString()}'),
            backgroundColor: const Color(0xFFFF5252),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _clearImage() {
    setState(() {
      _selectedImageBytes = null;
      _selectedImageName = null;
      _useFileUpload = false;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String? imageUrl;

      if (_useFileUpload &&
          _selectedImageBytes != null &&
          _selectedImageName != null) {
        imageUrl = await _storageService.uploadImage(
          fileBytes: _selectedImageBytes!,
          fileName: _selectedImageName!,
        );
      } else if (!_useFileUpload && _fotoUrlController.text.trim().isNotEmpty) {
        imageUrl = _fotoUrlController.text.trim();
      }

      final alat = AlatModel(
        alatId: widget.alat?.alatId ?? 0,
        kodeAlat: _kodeController.text.trim(),
        namaAlat: _namaController.text.trim(),
        kategoriId: _selectedKategoriId,
        kondisi: _selectedKondisi,
        jumlahTotal: int.tryParse(_jumlahTotalController.text) ?? 0,
        jumlahTersedia: int.tryParse(_jumlahTersediaController.text) ?? 0,
        hargaPerhari: _hargaController.text.isNotEmpty
            ? double.tryParse(_hargaController.text)
            : null,
        fotoAlat: imageUrl,
      );

      // GUNAKAN FUNGSI BARU: createAlatPaginated()
      final success = widget.alat == null
          ? await ref.read(alatProvider.notifier).createAlatPaginated(alat)
          : await ref
                .read(alatProvider.notifier)
                .updateAlatPaginated(alat, oldFotoUrl: widget.alat?.fotoAlat);

      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? '${widget.alat == null ? "Alat berhasil ditambahkan" : "Alat berhasil diperbarui"}'
                  : 'Gagal menyimpan alat',
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
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: const Color(0xFFFF5252),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final kategoris = ref.watch(kategoriProvider).kategoris;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: AppColors.surface,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 650),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.inventory_2_outlined,
                      color: AppTheme.primaryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.alat == null ? 'Tambah Alat' : 'Edit Alat',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                        color: Colors.white,
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
            ),
            Divider(height: 1, color: AppColors.borderMedium),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTextField(
                        'Kode Alat',
                        _kodeController,
                        'Masukkan kode alat',
                        required: true,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        'Nama Alat',
                        _namaController,
                        'Masukkan nama alat',
                        required: true,
                      ),
                      const SizedBox(height: 16),
                      _buildDropdown('Kategori', kategoris),
                      const SizedBox(height: 16),
                      _buildKondisiDropdown(),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              'Jumlah Total',
                              _jumlahTotalController,
                              '0',
                              isNumber: true,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTextField(
                              'Tersedia',
                              _jumlahTersediaController,
                              '0',
                              isNumber: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        'Harga/Hari (Rp)',
                        _hargaController,
                        'Opsional',
                        isNumber: true,
                      ),
                      const SizedBox(height: 16),
                      _buildImageSection(),
                    ],
                  ),
                ),
              ),
            ),
            Divider(height: 1, color: AppColors.borderMedium),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.pop(context),
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
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.surface,
                              ),
                            )
                          : const Text(
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
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Foto Alat',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Text(
                  _useFileUpload ? 'Upload File' : 'URL',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 4),
                Switch(
                  value: _useFileUpload,
                  onChanged: (value) {
                    setState(() {
                      _useFileUpload = value;
                      if (!value) _clearImage();
                    });
                  },
                  activeColor: AppTheme.primaryColor,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_useFileUpload) ...[
          InkWell(
            onTap: _pickImage,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.borderMedium),
              ),
              child: Column(
                children: [
                  if (_selectedImageBytes != null) ...[
                    // Smaller preview in form - max 200px wide
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 200),
                      child: AspectRatio(
                        aspectRatio: 3 / 4,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            _selectedImageBytes!,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _selectedImageName ?? '',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _clearImage,
                      icon: const Icon(Icons.close_rounded, size: 16),
                      label: const Text('Hapus'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFFF5252),
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ] else ...[
                    Icon(
                      Icons.cloud_upload_outlined,
                      size: 40,
                      color: AppColors.textHint,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Klik untuk upload foto',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'PNG, JPG (max. 5MB)',
                      style: TextStyle(fontSize: 11, color: AppColors.textHint),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ] else ...[
          TextFormField(
            controller: _fotoUrlController,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'https://... (opsional)',
              hintStyle: TextStyle(fontSize: 13, color: AppColors.textHint),
              filled: true,
              fillColor: AppColors.surfaceContainerLowest,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
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
          if (_fotoUrlController.text.isNotEmpty) ...[
            const SizedBox(height: 8),
            // Smaller URL preview
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 200),
                child: AspectRatio(
                  aspectRatio: 3 / 4,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      _fotoUrlController.text,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppColors.surfaceContainerLow,
                        child: Center(
                          child: Icon(
                            Icons.broken_image_outlined,
                            size: 32,
                            color: AppColors.textHint,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    String hint, {
    bool required = false,
    bool isNumber = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          inputFormatters: isNumber
              ? [FilteringTextInputFormatter.digitsOnly]
              : null,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(fontSize: 13, color: AppColors.textHint),
            filled: true,
            fillColor: AppColors.surfaceContainerLowest,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
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
            errorStyle: const TextStyle(fontSize: 11),
          ),
          validator: required
              ? (value) {
                  if (value == null || value.isEmpty)
                    return '$label wajib diisi';
                  return null;
                }
              : null,
        ),
      ],
    );
  }

  Widget _buildDropdown(String label, List kategoris) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<int?>(
          value: _selectedKategoriId,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surfaceContainerLowest,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.borderMedium),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.borderMedium),
            ),
          ),
          items: [
            const DropdownMenuItem(
              value: null,
              child: Text('Pilih Kategori', style: TextStyle(fontSize: 13)),
            ),
            ...kategoris.map(
              (k) => DropdownMenuItem(
                value: k.kategoriId,
                child: Text(
                  k.namaKategori,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ),
          ],
          onChanged: (value) => setState(() => _selectedKategoriId = value),
        ),
      ],
    );
  }

  Widget _buildKondisiDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Kondisi',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedKondisi, // Langsung gunakan tanpa normalisasi lagi
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surfaceContainerLowest,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.borderMedium),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.borderMedium),
            ),
          ),
          items: const [
            DropdownMenuItem(
              value: 'baik',
              child: Text('Baik', style: TextStyle(fontSize: 13)),
            ),
            DropdownMenuItem(
              value: 'rusak ringan',
              child: Text('Rusak Ringan', style: TextStyle(fontSize: 13)),
            ),
            DropdownMenuItem(
              value: 'rusak berat',
              child: Text('Rusak Berat', style: TextStyle(fontSize: 13)),
            ),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() => _selectedKondisi = value);
            }
          },
        ),
      ],
    );
  }
}
