// lib/screens/admin/data_management/kategori_management.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:paket_3_training/core/design_system/app_color.dart';
import 'package:paket_3_training/widgets/admin_sidebar.dart';
import 'package:paket_3_training/providers/kategori_provider.dart';
import 'package:paket_3_training/providers/alat_provider.dart';
import 'package:paket_3_training/providers/auth_provider.dart';
import 'package:paket_3_training/models/kategori_model.dart';

class KategoriManagement extends ConsumerStatefulWidget {
  const KategoriManagement({Key? key}) : super(key: key);

  @override
  ConsumerState<KategoriManagement> createState() => _KategoriManagementState();
}

class _KategoriManagementState extends ConsumerState<KategoriManagement> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool get _isDesktop => MediaQuery.of(context).size.width >= 900;
  bool get _isTablet =>
      MediaQuery.of(context).size.width >= 600 &&
      MediaQuery.of(context).size.width < 900;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(kategoriProvider.notifier).ensureInitialized();
      ref.read(alatProvider.notifier).ensureInitialized();
    });
  }

  @override
  Widget build(BuildContext context) {
    final kategoriState = ref.watch(kategoriProvider);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildAppBar(),
      drawer: _isDesktop ? null : AdminSidebar(currentRoute: '/admin/kategori'),
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
              child: AdminSidebar(currentRoute: '/admin/kategori'),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.read(kategoriProvider.notifier).refresh(),
              color: AppTheme.primaryColor,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(_isDesktop ? 24 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 20),
                    if (kategoriState.isLoading &&
                        kategoriState.kategoris.isEmpty)
                      _buildLoadingSkeleton()
                    else if (kategoriState.kategoris.isEmpty)
                      _buildEmptyState()
                    else
                      _buildKategoriGrid(kategoriState.kategoris),
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
    final user = ref.watch(authProvider).user;
    final userName = user?.namaLengkap ?? 'Admin';
    
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
        'Kelola Kategori',
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
  // HEADER
  // ============================================================================
  Widget _buildHeader() {
    final kategoriCount = ref.watch(kategoriProvider).kategoris.length;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Manajemen Kategori',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$kategoriCount kategori terdaftar',
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
  // KATEGORI GRID
  // ============================================================================
  Widget _buildKategoriGrid(List<KategoriModel> kategoris) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = _isDesktop ? 3 : (_isTablet ? 2 : 1);

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: _isDesktop ? 2.5 : (_isTablet ? 2.2 : 3),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: kategoris.length,
          itemBuilder: (context, index) =>
              _buildKategoriCard(kategoris[index], index),
        );
      },
    );
  }

  Widget _buildKategoriCard(KategoriModel kategori, int index) {
    final alats = ref.watch(alatProvider).alats;
    final jumlahAlat = alats
        .where((a) => a.kategoriId == kategori.kategoriId)
        .length;

    return Container(
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
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.category_outlined,
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
                          kategori.namaKategori,
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
                          '$jumlahAlat alat',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton(
                    icon: Icon(
                      Icons.more_vert_rounded,
                      size: 18,
                      color: Colors.grey.shade600,
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
                              Icons.edit_outlined,
                              size: 16,
                              color: Colors.grey.shade700,
                            ),
                            const SizedBox(width: 8),
                            const Text('Edit', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                        onTap: () => Future.delayed(
                          Duration.zero,
                          () => _showFormDialog(kategori: kategori),
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
                          () => _confirmDelete(kategori),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (kategori.deskripsi != null &&
                  kategori.deskripsi!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  kategori.deskripsi!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
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
                Icons.category_outlined,
                size: 48,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Belum ada kategori',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tambahkan kategori pertama Anda',
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
        crossAxisCount: _isDesktop ? 3 : 1,
        childAspectRatio: _isDesktop ? 2.5 : 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: 6,
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
  // FORM DIALOG
  // ============================================================================
  void _showFormDialog({KategoriModel? kategori}) {
    showDialog(
      context: context,
      builder: (context) => _KategoriFormDialog(kategori: kategori),
    );
  }

  // ============================================================================
  // DELETE CONFIRMATION
  // ============================================================================
  void _confirmDelete(KategoriModel kategori) {
    final alats = ref.read(alatProvider).alats;
    final jumlahAlat = alats
        .where((a) => a.kategoriId == kategori.kategoriId)
        .length;

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
              'Hapus Kategori?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              jumlahAlat > 0
                  ? 'Kategori "${kategori.namaKategori}" memiliki $jumlahAlat alat. Yakin ingin menghapus?'
                  : 'Apakah Anda yakin ingin menghapus "${kategori.namaKategori}"?',
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
                          .read(kategoriProvider.notifier)
                          .deleteKategori(kategori.kategoriId);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              success
                                  ? 'Kategori berhasil dihapus'
                                  : 'Gagal menghapus kategori',
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
class _KategoriFormDialog extends ConsumerStatefulWidget {
  final KategoriModel? kategori;

  const _KategoriFormDialog({this.kategori});

  @override
  ConsumerState<_KategoriFormDialog> createState() =>
      _KategoriFormDialogState();
}

class _KategoriFormDialogState extends ConsumerState<_KategoriFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _namaController;
  late TextEditingController _deskripsiController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _namaController = TextEditingController(
      text: widget.kategori?.namaKategori ?? '',
    );
    _deskripsiController = TextEditingController(
      text: widget.kategori?.deskripsi ?? '',
    );
  }

  @override
  void dispose() {
    _namaController.dispose();
    _deskripsiController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final kategori = KategoriModel(
      kategoriId: widget.kategori?.kategoriId ?? 0,
      namaKategori: _namaController.text.trim(),
      deskripsi: _deskripsiController.text.trim().isEmpty
          ? null
          : _deskripsiController.text.trim(),
    );

    final success = widget.kategori == null
        ? await ref.read(kategoriProvider.notifier).createKategori(kategori)
        : await ref.read(kategoriProvider.notifier).updateKategori(kategori);

    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? '${widget.kategori == null ? "Kategori berhasil ditambahkan" : "Kategori berhasil diperbarui"}'
                : 'Gagal menyimpan kategori',
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
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 450),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                        Icons.category_outlined,
                        color: AppTheme.primaryColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.kategori == null
                            ? 'Tambah Kategori'
                            : 'Edit Kategori',
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
                const SizedBox(height: 20),
                _buildTextField(
                  'Nama Kategori',
                  _namaController,
                  'Masukkan nama kategori',
                  required: true,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  'Deskripsi',
                  _deskripsiController,
                  'Masukkan deskripsi (opsional)',
                  maxLines: 3,
                ),
                const SizedBox(height: 20),
                Row(
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    String hint, {
    bool required = false,
    int maxLines = 1,
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
          maxLines: maxLines,
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
}
