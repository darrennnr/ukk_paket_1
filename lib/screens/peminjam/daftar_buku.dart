// lib/screens/peminjam/daftar_buku.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:paket_3_training/core/design_system/app_color.dart';
import 'package:paket_3_training/widgets/pengguna_sidebar.dart';
import '../../providers/alat_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/alat_model.dart';

class DaftarBukuScreen extends ConsumerStatefulWidget {
  const DaftarBukuScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<DaftarBukuScreen> createState() => _DaftarBukuScreenState();
}

class _DaftarBukuScreenState extends ConsumerState<DaftarBukuScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _searchQuery = '';
  int? _selectedKategoriId;
  bool _hasInitializedProviders = false;

  bool get _isDesktop => MediaQuery.of(context).size.width >= 900;
  bool get _isTablet => MediaQuery.of(context).size.width >= 600 && MediaQuery.of(context).size.width < 900;

  @override
  void initState() {
    super.initState();
    // Provider initialization is now done in build method when auth is ready
  }

  void _initializeProviders() {
    if (!_hasInitializedProviders) {
      _hasInitializedProviders = true;
      ref.read(alatTersediaProvider.notifier).ensureInitialized();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final alatState = ref.watch(alatTersediaProvider);
    final user = authState.user;

    // Wait for auth to complete before initializing providers
    if (!authState.isLoading && authState.isAuthenticated && !_hasInitializedProviders) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initializeProviders();
      });
    }

    // Filter buku berdasarkan search dan kategori
    final filteredBooks = alatState.alats.where((book) {
      final matchesSearch = _searchQuery.isEmpty ||
          book.namaAlat.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (book.kategori?.namaKategori.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      
      final matchesKategori = _selectedKategoriId == null || book.kategoriId == _selectedKategoriId;
      
      return matchesSearch && matchesKategori;
    }).toList();

    // Ambil daftar kategori unik
    final categories = <int, String>{};
    for (var book in alatState.alats) {
      if (book.kategoriId != null && book.kategori != null) {
        categories[book.kategoriId!] = book.kategori!.namaKategori;
      }
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildAppBar(context, user?.namaLengkap ?? 'Peminjam'),
      drawer: _isDesktop ? null : PenggunaSidebar(currentRoute: '/peminjam/buku'),
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
              child: PenggunaSidebar(currentRoute: '/peminjam/buku'),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.read(alatTersediaProvider.notifier).refresh(),
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
                          _buildSearchBar(),
                          const SizedBox(height: 16),
                          _buildCategoryFilter(categories),
                          const SizedBox(height: 20),
                          _buildResultsHeader(filteredBooks.length),
                        ],
                      ),
                    ),
                  ),

                  // Book Grid
                  if (alatState.isLoading)
                    SliverFillRemaining(
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.primaryColor,
                          strokeWidth: 2,
                        ),
                      ),
                    )
                  else if (filteredBooks.isEmpty)
                    SliverFillRemaining(
                      child: _buildEmptyState(),
                    )
                  else
                    SliverPadding(
                      padding: EdgeInsets.symmetric(
                        horizontal: _isDesktop ? 24 : 16,
                        vertical: 0,
                      ),
                      sliver: SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: _isDesktop ? 4 : (_isTablet ? 3 : 2),
                          mainAxisSpacing: _isDesktop ? 20 : 16,
                          crossAxisSpacing: _isDesktop ? 20 : 16,
                          childAspectRatio: 0.68,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final book = filteredBooks[index];
                            return _buildBookCard(book, index);
                          },
                          childCount: filteredBooks.length,
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
        'Daftar Buku',
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
              Icon(Icons.dashboard_rounded, size: 18, color: Colors.grey.shade700),
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
                Icons.menu_book_rounded,
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
                    'Katalog Buku',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Temukan dan pinjam buku yang Anda butuhkan',
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
          hintText: 'Cari judul buku atau kategori...',
          hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          prefixIcon: Icon(
            Icons.search_rounded,
            size: 20,
            color: Colors.grey.shade500,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear_rounded, size: 18, color: Colors.grey.shade500),
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
    ).animate().fadeIn(duration: 400.ms, delay: 100.ms);
  }

  // ============================================================================
  // CATEGORY FILTER
  // ============================================================================
  Widget _buildCategoryFilter(Map<int, String> categories) {
    if (categories.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kategori',
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
            children: [
              _buildCategoryChip(
                label: 'Semua',
                isSelected: _selectedKategoriId == null,
                onTap: () {
                  setState(() {
                    _selectedKategoriId = null;
                  });
                },
              ),
              const SizedBox(width: 8),
              ...categories.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildCategoryChip(
                    label: entry.value,
                    isSelected: _selectedKategoriId == entry.key,
                    onTap: () {
                      setState(() {
                        _selectedKategoriId = entry.key;
                      });
                    },
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms, delay: 150.ms);
  }

  Widget _buildCategoryChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryColor
                : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? AppTheme.primaryColor
                  : Colors.grey.shade300,
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? Colors.white : Colors.grey.shade700,
              letterSpacing: -0.1,
            ),
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
  Widget _buildBookCard(AlatModel book, int index) {
    final isAvailable = book.jumlahTersedia > 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (isAvailable) {
            context.go('/peminjam/ajukan?bookId=${book.alatId}');
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Buku tidak tersedia'),
                backgroundColor: Colors.orange.shade600,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                margin: const EdgeInsets.all(16),
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isAvailable
                  ? Colors.grey.shade200
                  : Colors.grey.shade300,
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Book Image
              Stack(
                children: [
                  Container(
                    height: 140,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.menu_book_rounded,
                        size: 56,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ),
                  // Availability Badge
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isAvailable
                            ? const Color(0xFF4CAF50)
                            : Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isAvailable ? 'Tersedia' : 'Habis',
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Book Info
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        book.namaAlat,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                          height: 1.3,
                          letterSpacing: -0.1,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),

                      // Category
                      if (book.kategori != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            book.kategori!.namaKategori,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryColor,
                              letterSpacing: 0.1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                      const Spacer(),

                      // Stock & Price Info
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.inventory_2_outlined,
                                size: 12,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Stok: ${book.jumlahTersedia}/${book.jumlahTotal}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.attach_money_rounded,
                                size: 12,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  book.hargaPerhari != null
                                      ? 'Rp ${book.hargaPerhari!.toStringAsFixed(0)}/hari'
                                      : 'Gratis',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Action Button
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isAvailable
                              ? AppTheme.primaryColor
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isAvailable ? Icons.add_circle_outline_rounded : Icons.block_rounded,
                              size: 14,
                              color: isAvailable ? Colors.white : Colors.grey.shade600,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isAvailable ? 'PINJAM BUKU' : 'TIDAK TERSEDIA',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isAvailable ? Colors.white : Colors.grey.shade600,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
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
              Icons.search_off_rounded,
              size: 56,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Buku Tidak Ditemukan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Coba gunakan kata kunci lain',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
