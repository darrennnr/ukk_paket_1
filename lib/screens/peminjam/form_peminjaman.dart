// lib/screens/peminjam/form_peminjaman.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:paket_3_training/core/design_system/app_color.dart';
import 'package:paket_3_training/widgets/pengguna_sidebar.dart';
import '../../providers/alat_provider.dart';
import '../../providers/peminjaman_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/alat_model.dart';
import '../../models/peminjaman_model.dart';

class FormPeminjamanScreen extends ConsumerStatefulWidget {
  final String? bookId;

  const FormPeminjamanScreen({Key? key, this.bookId}) : super(key: key);

  @override
  ConsumerState<FormPeminjamanScreen> createState() => _FormPeminjamanScreenState();
}

class _FormPeminjamanScreenState extends ConsumerState<FormPeminjamanScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();

  // Form fields
  int? _selectedBukuId;
  final TextEditingController _jumlahController = TextEditingController(text: '1');
  DateTime? _tanggalBerakhir;
  final TextEditingController _keperluanController = TextEditingController();

  bool _isSubmitting = false;
  bool _hasInitializedProviders = false;

  bool get _isDesktop => MediaQuery.of(context).size.width >= 900;

  @override
  void initState() {
    super.initState();
    // Set selected book if bookId is provided from URL query parameter
    if (widget.bookId != null) {
      final bookIdInt = int.tryParse(widget.bookId!);
      if (bookIdInt != null) {
        _selectedBukuId = bookIdInt;
      }
    }
    // Provider initialization is now done in build method when auth is ready
  }

  void _initializeProviders() {
    if (!_hasInitializedProviders) {
      _hasInitializedProviders = true;
      ref.read(alatTersediaProvider.notifier).refresh();
    }
  }

  @override
  void dispose() {
    _jumlahController.dispose();
    _keperluanController.dispose();
    super.dispose();
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

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildAppBar(context, user?.namaLengkap ?? 'Peminjam'),
      drawer: _isDesktop ? null : PenggunaSidebar(currentRoute: '/peminjam/ajukan'),
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
              child: PenggunaSidebar(currentRoute: '/peminjam/ajukan'),
            ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(_isDesktop ? 24 : 16),
              child: Center(
                child: Container(
                  constraints: BoxConstraints(maxWidth: _isDesktop ? 700 : double.infinity),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPageHeader(),
                      const SizedBox(height: 24),
                      _buildFormCard(alatState),
                    ],
                  ),
                ),
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
        'Ajukan Peminjaman',
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
                Icons.add_circle_outline_rounded,
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
                    'Form Peminjaman Buku',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Lengkapi formulir di bawah untuk mengajukan peminjaman',
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
  // FORM CARD
  // ============================================================================
  Widget _buildFormCard(AlatState alatState) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Form Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.05),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.edit_note_rounded,
                    color: AppTheme.primaryColor,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Detail Peminjaman',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                      letterSpacing: -0.1,
                    ),
                  ),
                ],
              ),
            ),

            // Form Body
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pilih Buku
                  _buildFieldLabel('Pilih Buku', isRequired: true),
                  const SizedBox(height: 8),
                  _buildBookDropdown(alatState.alats),
                  const SizedBox(height: 20),

                  // Selected Book Preview
                  if (_selectedBukuId != null) ...[
                    _buildSelectedBookPreview(alatState.alats),
                    const SizedBox(height: 20),
                  ],

                  // Jumlah Buku
                  _buildFieldLabel('Jumlah Buku', isRequired: true),
                  const SizedBox(height: 8),
                  _buildJumlahField(alatState.alats),
                  const SizedBox(height: 20),

                  // Tanggal Pengembalian
                  _buildFieldLabel('Tanggal Pengembalian', isRequired: true),
                  const SizedBox(height: 8),
                  _buildDatePicker(),
                  const SizedBox(height: 20),

                  // Keperluan
                  _buildFieldLabel('Keperluan Peminjaman', isRequired: true),
                  const SizedBox(height: 8),
                  _buildKeperluanField(),
                  const SizedBox(height: 32),

                  // Submit Button
                  _buildSubmitButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 100.ms);
  }

  Widget _buildFieldLabel(String label, {bool isRequired = false}) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
            letterSpacing: -0.1,
          ),
        ),
        if (isRequired) ...[
          const SizedBox(width: 4),
          const Text(
            '*',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFFFF5252),
            ),
          ),
        ],
      ],
    );
  }

  // ============================================================================
  // BOOK DROPDOWN
  // ============================================================================
  Widget _buildBookDropdown(List<AlatModel> books) {
    final availableBooks = books.where((b) => b.jumlahTersedia > 0).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: DropdownButtonFormField<int>(
        value: _selectedBukuId,
        decoration: InputDecoration(
          hintText: 'Pilih buku yang ingin dipinjam',
          hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 10),
          prefixIcon: Icon(
            Icons.menu_book_rounded,
            size: 18,
            color: Colors.grey.shade600,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        style: const TextStyle(fontSize: 13, color: Color(0xFF1A1A1A)),
        dropdownColor: Colors.white,
        icon: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey.shade600),
        isExpanded: true,
        validator: (value) {
          if (value == null) {
            return 'Harap pilih buku terlebih dahulu';
          }
          return null;
        },
        items: availableBooks.map((book) {
          return DropdownMenuItem<int>(
            value: book.alatId,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  book.namaAlat,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1A1A1A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedBukuId = value;
            _jumlahController.text = '1'; // Reset jumlah
          });
        },
      ),
    );
  }

  // ============================================================================
  // SELECTED BOOK PREVIEW
  // ============================================================================
  Widget _buildSelectedBookPreview(List<AlatModel> books) {
    final selectedBook = books.firstWhere(
      (b) => b.alatId == _selectedBukuId,
      orElse: () => AlatModel(
        alatId: 0,
        kodeAlat: '',
        namaAlat: '',
        jumlahTotal: 0,
        jumlahTersedia: 0,
      ),
    );

    if (selectedBook.alatId == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              Icons.menu_book_rounded,
              size: 28,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selectedBook.namaAlat,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                if (selectedBook.kategori != null)
                  Text(
                    selectedBook.kategori!.namaKategori,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 12,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Tersedia: ${selectedBook.jumlahTersedia}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.attach_money_rounded,
                      size: 12,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      selectedBook.hargaPerhari != null
                          ? 'Rp ${selectedBook.hargaPerhari!.toStringAsFixed(0)}/hari'
                          : 'Gratis',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1));
  }

  // ============================================================================
  // JUMLAH FIELD
  // ============================================================================
  Widget _buildJumlahField(List<AlatModel> books) {
    return Row(
      children: [
        // Decrease Button
        Container(
          width: 44,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300, width: 1),
          ),
          child: IconButton(
            icon: Icon(Icons.remove_rounded, size: 18, color: Colors.grey.shade700),
            onPressed: () {
              final currentValue = int.tryParse(_jumlahController.text) ?? 1;
              if (currentValue > 1) {
                setState(() {
                  _jumlahController.text = (currentValue - 1).toString();
                });
              }
            },
          ),
        ),
        const SizedBox(width: 12),

        // Input Field
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300, width: 1),
            ),
            child: TextFormField(
              controller: _jumlahController,
              decoration: InputDecoration(
                hintText: 'Jumlah',
                hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Jumlah harus diisi';
                }
                final intVal = int.tryParse(value);
                if (intVal == null || intVal <= 0) {
                  return 'Jumlah harus lebih dari 0';
                }
                if (_selectedBukuId != null) {
                  final book = books.firstWhere(
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
                    return 'Maksimal ${book.jumlahTersedia}';
                  }
                }
                return null;
              },
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Increase Button
        Container(
          width: 44,
          height: 48,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppTheme.primaryColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: IconButton(
            icon: Icon(Icons.add_rounded, size: 18, color: AppTheme.primaryColor),
            onPressed: () {
              if (_selectedBukuId != null) {
                final book = books.firstWhere(
                  (b) => b.alatId == _selectedBukuId,
                  orElse: () => AlatModel(
                    alatId: 0,
                    kodeAlat: '',
                    namaAlat: '',
                    jumlahTotal: 0,
                    jumlahTersedia: 0,
                  ),
                );
                final currentValue = int.tryParse(_jumlahController.text) ?? 1;
                if (currentValue < book.jumlahTersedia) {
                  setState(() {
                    _jumlahController.text = (currentValue + 1).toString();
                  });
                }
              }
            },
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // DATE PICKER
  // ============================================================================
  Widget _buildDatePicker() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: DateTime.now().add(const Duration(days: 7)),
            firstDate: DateTime.now(),
            lastDate: DateTime(DateTime.now().year + 1),
            builder: (context, child) {
              return Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: ColorScheme.light(
                    primary: AppTheme.primaryColor,
                    onPrimary: Colors.white,
                    surface: Colors.white,
                    onSurface: Colors.black,
                  ),
                ),
                child: child!,
              );
            },
          );
          if (picked != null) {
            setState(() {
              _tanggalBerakhir = picked;
            });
          }
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _tanggalBerakhir != null
                  ? AppTheme.primaryColor.withOpacity(0.3)
                  : Colors.grey.shade300,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 18,
                color: _tanggalBerakhir != null
                    ? AppTheme.primaryColor
                    : Colors.grey.shade600,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _tanggalBerakhir != null
                      ? DateFormat('dd MMMM yyyy', 'id_ID').format(_tanggalBerakhir!)
                      : 'Pilih tanggal pengembalian',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: _tanggalBerakhir != null ? FontWeight.w500 : FontWeight.w400,
                    color: _tanggalBerakhir != null
                        ? const Color(0xFF1A1A1A)
                        : Colors.grey.shade500,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_drop_down_rounded,
                size: 20,
                color: Colors.grey.shade600,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // KEPERLUAN FIELD
  // ============================================================================
  Widget _buildKeperluanField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: TextFormField(
        controller: _keperluanController,
        decoration: InputDecoration(
          hintText: 'Jelaskan tujuan peminjaman buku ini...',
          hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        style: const TextStyle(fontSize: 13, color: Color(0xFF1A1A1A)),
        maxLines: 4,
        minLines: 4,
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Keperluan harus diisi';
          }
          if (value.trim().length < 5) {
            return 'Keperluan minimal 5 karakter';
          }
          return null;
        },
      ),
    );
  }

  // ============================================================================
  // SUBMIT BUTTON
  // ============================================================================
  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _handleSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          disabledBackgroundColor: Colors.grey.shade300,
        ),
        child: _isSubmitting
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.grey.shade600),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Memproses...',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.send_rounded, size: 18),
                  const SizedBox(width: 10),
                  const Text(
                    'Ajukan Peminjaman',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ============================================================================
  // SUBMIT HANDLER
  // ============================================================================
  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_tanggalBerakhir == null) {
      _showErrorSnackbar('Harap pilih tanggal pengembalian');
      return;
    }

    final user = ref.read(authProvider).user;
    if (user == null) {
      _showErrorSnackbar('User tidak ditemukan');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Generate kode peminjaman
      final kode = 'PJN-${DateTime.now().millisecondsSinceEpoch}';

      final peminjaman = PeminjamanModel(
        peminjamanId: 0,
        peminjamId: user.userId,
        alatId: _selectedBukuId!,
        kodePeminjaman: kode,
        jumlahPinjam: int.parse(_jumlahController.text),
        tanggalBerakhir: _tanggalBerakhir!,
        keperluan: _keperluanController.text.trim(),
      );

      final success = await ref
          .read(myPeminjamanProvider.notifier)
          .ajukanPeminjaman(peminjaman);

      if (success && mounted) {
        _showSuccessDialog();
      } else if (mounted) {
        _showErrorSnackbar('Gagal mengajukan peminjaman');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar('Terjadi kesalahan: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_rounded,
                color: const Color(0xFF4CAF50),
                size: 56,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Berhasil!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Peminjaman Anda telah diajukan dan menunggu persetujuan petugas',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.go('/peminjam/dashboard');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  'Kembali ke Dashboard',
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
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFFF5252),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
