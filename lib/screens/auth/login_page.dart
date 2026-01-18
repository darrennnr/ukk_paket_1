// lib/screens/auth/login_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:paket_3_training/core/design_system/app_color.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:paket_3_training/providers/auth_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isMobile = size.width < 600;
    final isTablet = size.width >= 600 && size.width < 1024;
    final isDesktop = size.width >= 1024;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 20 : (isTablet ? 40 : 48),
                vertical: isMobile ? 24 : 32,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isDesktop ? 1100 : (isTablet ? 850 : 450),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Left side - Branding (only on desktop/tablet)
                    if (!isMobile) ...[
                      Expanded(
                        flex: isDesktop ? 5 : 4,
                        child:
                            _BrandingSection(
                                  isDesktop: isDesktop,
                                  isTablet: isTablet,
                                )
                                .animate()
                                .fadeIn(duration: 400.ms)
                                .slideX(begin: -0.1, end: 0),
                      ),
                      SizedBox(width: isDesktop ? 60 : 40),
                    ],
                    // Right side - Login form
                    Expanded(
                      flex: isDesktop ? 4 : (isTablet ? 5 : 1),
                      child:
                          _LoginFormContainer(
                                isMobile: isMobile,
                                isTablet: isTablet,
                                isDesktop: isDesktop,
                              )
                              .animate()
                              .fadeIn(duration: 400.ms, delay: 150.ms)
                              .slideX(begin: 0.1, end: 0),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// BRANDING SECTION - Minimalist & Compact
// ============================================================================
class _BrandingSection extends StatelessWidget {
  final bool isDesktop;
  final bool isTablet;

  const _BrandingSection({required this.isDesktop, required this.isTablet});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Logo - Compact
        Container(
          width: isDesktop ? 54 : 48,
          height: isDesktop ? 54 : 48,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade200, width: 1),
          ),
          child: Icon(
            Icons.menu_book_rounded,
            size: isDesktop ? 28 : 24,
            color: Colors.white,
          ),
        ),
        SizedBox(height: isDesktop ? 24 : 20),
        // Title - Compact
        Text(
          'Sistem Peminjaman\nBuku',
          style: TextStyle(
            fontSize: isDesktop ? 32 : 28,
            fontWeight: FontWeight.w700,
            height: 1.2,
            color: const Color(0xFF1A1A1A),
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: isDesktop ? 12 : 10),
        // Description - Compact
        Text(
          'Kelola peminjaman dan pengembalian buku\ndengan mudah dan efisien.',
          style: TextStyle(
            fontSize: isDesktop ? 13 : 12,
            height: 1.5,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w400,
          ),
        ),
        SizedBox(height: isDesktop ? 32 : 28),
        // Features - Minimalist
        _FeatureItem(
          icon: Icons.library_books_rounded,
          text: 'Akses koleksi buku perpustakaan',
          isDesktop: isDesktop,
        ),
        SizedBox(height: isDesktop ? 12 : 10),
        _FeatureItem(
          icon: Icons.history_rounded,
          text: 'Lacak riwayat peminjaman Anda',
          isDesktop: isDesktop,
        ),
        SizedBox(height: isDesktop ? 12 : 10),
        _FeatureItem(
          icon: Icons.notifications_active_rounded,
          text: 'Notifikasi pengingat pengembalian',
          isDesktop: isDesktop,
        ),
      ],
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isDesktop;

  const _FeatureItem({
    required this.icon,
    required this.text,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: isDesktop ? 34 : 32,
          height: isDesktop ? 34 : 32,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: isDesktop ? 18 : 16,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: isDesktop ? 13 : 12,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.1,
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// LOGIN FORM CONTAINER - Clean & Structured
// ============================================================================
class _LoginFormContainer extends StatelessWidget {
  final bool isMobile;
  final bool isTablet;
  final bool isDesktop;

  const _LoginFormContainer({
    required this.isMobile,
    required this.isTablet,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 24 : (isTablet ? 28 : 32)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Mobile header
          if (isMobile) ...[
            Center(
              child: Column(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.menu_book_rounded,
                      size: 24,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Peminjaman Buku',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A1A1A),
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
          // Title
          Text(
            'Masuk',
            style: TextStyle(
              fontSize: isMobile ? 20 : (isTablet ? 22 : 24),
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1A1A),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Masuk untuk mengakses sistem',
            style: TextStyle(
              fontSize: isMobile ? 12 : 13,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w400,
            ),
          ),
          SizedBox(height: isMobile ? 24 : 28),
          // Form
          LoginForm(
            isMobile: isMobile,
            isTablet: isTablet,
            isDesktop: isDesktop,
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// LOGIN FORM - Minimalist & Clean
// ============================================================================
class LoginForm extends ConsumerStatefulWidget {
  final bool isMobile;
  final bool isTablet;
  final bool isDesktop;

  const LoginForm({
    super.key,
    required this.isMobile,
    required this.isTablet,
    required this.isDesktop,
  });

  @override
  ConsumerState<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends ConsumerState<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() != true) return;

    setState(() => _isLoading = true);

    final success = await ref
        .read(authProvider.notifier)
        .login(_usernameController.text.trim(), _passwordController.text);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      final authState = ref.read(authProvider);
      final user = authState.user;

      if (user == null) return;

      String route = '/';
      if (authState.isAdmin) {
        route = '/dashboard-admin';
      } else if (authState.isPetugas) {
        route = '/dashboard-petugas';
      } else if (authState.isPeminjam) {
        route = '/dashboard-peminjam';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Login berhasil! Selamat datang, ${user.namaLengkap}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
            backgroundColor: AppTheme.primaryColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 2),
          ),
        );
        context.go(route);
      }
    } else {
      final errorMessage = ref.read(authProvider).errorMessage ?? 'Login gagal';

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              errorMessage,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
            backgroundColor: const Color(0xFFFF5252),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final fontSize = widget.isMobile ? 13.0 : 13.0;
    final inputHeight = widget.isMobile ? 44.0 : 46.0;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Username field
          Text(
            'Username',
            style: TextStyle(
              fontSize: fontSize,
              color: const Color(0xFF1A1A1A),
              fontWeight: FontWeight.w600,
              letterSpacing: -0.1,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: inputHeight,
            child: TextFormField(
              controller: _usernameController,
              style: TextStyle(
                fontSize: fontSize,
                color: const Color(0xFF1A1A1A),
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: 'Masukkan username',
                hintStyle: TextStyle(
                  fontSize: fontSize,
                  color: Colors.grey.shade400,
                  fontWeight: FontWeight.w400,
                ),
                prefixIcon: Icon(
                  Icons.person_outline_rounded,
                  size: 18,
                  color: Colors.grey.shade600,
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: AppTheme.primaryColor,
                    width: 1.5,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Color(0xFFFF5252),
                    width: 1,
                  ),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Color(0xFFFF5252),
                    width: 1.5,
                  ),
                ),
                errorStyle: const TextStyle(fontSize: 11, height: 1.2),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Username wajib diisi';
                }
                if (value.length < 3) {
                  return 'Username minimal 3 karakter';
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 18),
          // Password field
          Text(
            'Kata Sandi',
            style: TextStyle(
              fontSize: fontSize,
              color: const Color(0xFF1A1A1A),
              fontWeight: FontWeight.w600,
              letterSpacing: -0.1,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: inputHeight,
            child: TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              style: TextStyle(
                fontSize: fontSize,
                color: const Color(0xFF1A1A1A),
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: 'Masukkan kata sandi',
                hintStyle: TextStyle(
                  fontSize: fontSize,
                  color: Colors.grey.shade400,
                  fontWeight: FontWeight.w400,
                ),
                prefixIcon: Icon(
                  Icons.lock_outline_rounded,
                  size: 18,
                  color: Colors.grey.shade600,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 18,
                    color: Colors.grey.shade500,
                  ),
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: AppTheme.primaryColor,
                    width: 1.5,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Color(0xFFFF5252),
                    width: 1,
                  ),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Color(0xFFFF5252),
                    width: 1.5,
                  ),
                ),
                errorStyle: const TextStyle(fontSize: 11, height: 1.2),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Kata sandi wajib diisi';
                }
                if (value.length < 6) {
                  return 'Minimal 6 karakter';
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 14),
          // Remember me & Forgot password
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: () {
                  setState(() => _rememberMe = !_rememberMe);
                },
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Row(
                    children: [
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: _rememberMe
                              ? AppTheme.primaryColor
                              : Colors.transparent,
                          border: Border.all(
                            color: _rememberMe
                                ? AppTheme.primaryColor
                                : Colors.grey.shade300,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: _rememberMe
                            ? const Icon(
                                Icons.check,
                                size: 12,
                                color: Colors.white,
                              )
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Ingat saya',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  // TODO: Forgot password
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Lupa kata sandi?',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: widget.isMobile ? 22 : 24),
          // Login button
          SizedBox(
            width: double.infinity,
            height: widget.isMobile ? 44 : 46,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                disabledBackgroundColor: AppTheme.primaryColor.withOpacity(0.6),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'Masuk',
                      style: TextStyle(
                        fontSize: fontSize + 1,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
