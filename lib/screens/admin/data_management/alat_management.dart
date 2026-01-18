// lib/screens/admin/data_management/alat_management.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:paket_3_training/core/design_system/app_color.dart';
import 'package:paket_3_training/widgets/admin_sidebar.dart';
import 'package:paket_3_training/providers/alat_provider.dart';
import 'package:paket_3_training/providers/kategori_provider.dart';
import 'package:paket_3_training/models/alat_model.dart';

class AlatManagement extends ConsumerStatefulWidget {
  const AlatManagement({Key? key}) : super(key: key);

  @override
  ConsumerState<AlatManagement> createState() => _AlatManagementState();
}

class _AlatManagementState extends ConsumerState<AlatManagement> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  int? _selectedKategoriFilter;

  bool get _isDesktop => MediaQuery.of(context).size.width >= 900;
  bool get _isTablet =>
      MediaQuery.of(context).size.width >= 600 &&
      MediaQuery.of(context).size.width < 900;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(alatProvider.notifier).refresh();
      ref.read(kategoriProvider.notifier).refresh();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
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
                color: Colors.white,
                border: Border(
                  right: BorderSide(color: Colors.grey.shade200, width: 1),
                ),
              ),
              child: AdminSidebar(currentRoute: '/admin/alat'),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.read(alatProvider.notifier).refresh(),
              color: AppTheme.primaryColor,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(_isDesktop ? 24 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 20),
                    _buildSearchAndFilter(),
                    const SizedBox(height: 20),
                    if (alatState.isLoading && alatState.alats.isEmpty)
                      _buildLoadingSkeleton()
                    else if (alatState.alats.isEmpty)
                      _buildEmptyState()
                    else
                      _buildAlatGrid(alatState.alats),
                  ],
                ),
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
        'Kelola Alat',
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
  // HEADER
  // ============================================================================
  Widget _buildHeader() {
    final alatCount = ref.watch(alatProvider).alats.length;
    final tersediaCount = ref
        .watch(alatProvider)
        .alats
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
                '$alatCount total alat • $tersediaCount tersedia',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0);
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200, width: 1),
            ),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(fontSize: 13, color: Color(0xFF1A1A1A)),
              decoration: InputDecoration(
                hintText: 'Cari alat...',
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
                          _searchController.clear();
                          ref.read(alatProvider.notifier).searchAlats('');
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
                ref.read(alatProvider.notifier).searchAlats(value);
              },
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200, width: 1),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int?>(
              value: _selectedKategoriFilter,
              hint: Text(
                'Kategori',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              icon: Icon(
                Icons.arrow_drop_down_rounded,
                size: 20,
                color: Colors.grey.shade600,
              ),
              style: const TextStyle(fontSize: 13, color: Color(0xFF1A1A1A)),
              items: [
                DropdownMenuItem<int?>(
                  value: null,
                  child: Text(
                    'Semua Kategori',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
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
                ref.read(alatProvider.notifier).filterByKategori(value);
              },
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // ALAT GRID
  // ============================================================================
  Widget _buildAlatGrid(List<AlatModel> alats) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = _isDesktop ? 4 : (_isTablet ? 3 : 2);

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: _isDesktop ? 0.75 : 0.7,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: alats.length,
          itemBuilder: (context, index) => _buildAlatCard(alats[index], index),
        );
      },
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
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
                            height: 120,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Center(
                              child: Icon(
                                Icons.inventory_2_outlined,
                                size: 40,
                                color: Colors.grey.shade400,
                              ),
                            ),
                          ),
                        )
                      else
                        Center(
                          child: Icon(
                            Icons.inventory_2_outlined,
                            size: 40,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      // Status Badge
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isAvailable
                                ? const Color(0xFF4CAF50)
                                : const Color(0xFFFF5252),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isAvailable ? 'Tersedia' : 'Habis',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          alat.namaAlat,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1A1A),
                            letterSpacing: -0.1,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          kategoriName,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            Icon(
                              Icons.qr_code_2_rounded,
                              size: 12,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                alat.kodeAlat,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Stok: ${alat.jumlahTersedia}/${alat.jumlahTotal}',
                                style: TextStyle(
                                  fontSize: 12,
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
                                size: 16,
                                color: Colors.grey.shade600,
                              ),
                              offset: const Offset(0, 30),
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
                                        color: Colors.grey.shade700,
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
                                  height: 36,
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.edit_outlined,
                                        size: 16,
                                        color: Colors.grey.shade700,
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
                                  height: 36,
                                  child: const Row(
                                    children: [
                                      Icon(
                                        Icons.delete_outline_rounded,
                                        size: 16,
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
        .fadeIn(duration: 400.ms, delay: (index * 50).ms)
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
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.inventory_2_outlined,
                size: 48,
                color: Colors.grey.shade400,
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
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _isDesktop ? 4 : 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: 8,
      itemBuilder: (context, index) =>
          Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10),
                ),
              )
              .animate(onPlay: (controller) => controller.repeat())
              .shimmer(duration: 1200.ms),
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
      child: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
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
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: _isDesktop ? 500 : double.infinity,
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
                  const SizedBox(height: 20),
                  if (alat.fotoAlat != null && alat.fotoAlat!.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        alat.fotoAlat!,
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 200,
                          color: Colors.grey.shade100,
                          child: Center(
                            child: Icon(
                              Icons.inventory_2_outlined,
                              size: 48,
                              color: Colors.grey.shade400,
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
                      final success = await ref
                          .read(alatProvider.notifier)
                          .deleteAlat(alat.alatId);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
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
}

// ============================================================================
// FORM DIALOG WIDGET
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
  late TextEditingController _fotoController;
  int? _selectedKategoriId;
  String _selectedKondisi = 'baik';
  bool _isLoading = false;

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
    _fotoController = TextEditingController(text: widget.alat?.fotoAlat ?? '');
    _selectedKategoriId = widget.alat?.kategoriId;
    _selectedKondisi = widget.alat?.kondisi ?? 'baik';
  }

  @override
  void dispose() {
    _kodeController.dispose();
    _namaController.dispose();
    _jumlahTotalController.dispose();
    _jumlahTersediaController.dispose();
    _hargaController.dispose();
    _fotoController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

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
      fotoAlat: _fotoController.text.trim().isEmpty
          ? null
          : _fotoController.text.trim(),
    );

    final success = widget.alat == null
        ? await ref.read(alatProvider.notifier).createAlat(alat)
        : await ref.read(alatProvider.notifier).updateAlat(alat);

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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final kategoris = ref.watch(kategoriProvider).kategoris;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
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
            Divider(height: 1, color: Colors.grey.shade200),
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
                      _buildTextField(
                        'URL Foto',
                        _fotoController,
                        'https://... (opsional)',
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Divider(height: 1, color: Colors.grey.shade200),
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
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Simpan',
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
            hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
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
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade200),
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
          value: _selectedKondisi,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade200),
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
          onChanged: (value) => setState(() => _selectedKondisi = value!),
        ),
      ],
    );
  }
}
