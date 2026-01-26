// lib/widgets/admin_sidebar.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:paket_3_training/core/design_system/app_color.dart';
import 'package:paket_3_training/core/design_system/app_design_system.dart' hide AppTheme;
import '../providers/auth_provider.dart';

class AdminSidebar extends ConsumerWidget {
  final String currentRoute;

  const AdminSidebar({Key? key, required this.currentRoute}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final isAuthLoading = authState.isLoading;
    // During loading, show all menus (optimistic rendering) to prevent disappearing menus
    final roleName = isAuthLoading ? 'admin' : (user?.role?.role?.toLowerCase() ?? '');
    final isDrawerMode = Scaffold.maybeOf(context) != null;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Sidebar content
        Widget sidebarContent = Container(
          width: isDrawerMode ? null : 260,
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: isDrawerMode
                ? null
                : Border(
                    right: BorderSide(color: AppColors.borderMedium, width: 1),
                  ),
          ),
          child: Column(
            children: [
              // Header - Profile at TOP (consistent with pengguna_sidebar)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppColors.borderMedium, width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          (user?.namaLengkap ?? 'A')[0].toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.textInverse,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            user?.namaLengkap ?? 'Admin',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            roleName == 'petugas' ? 'Petugas' : 'Administrator',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                              letterSpacing: 0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Menu Items
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 8,
                  ),
                  children: [
                    // Dashboard
                    _buildMenuItem(
                      context,
                      icon: Icons.dashboard_rounded,
                      title: 'Dashboard',
                      route: '/admin/dashboard',
                      isActive: currentRoute == '/admin/dashboard',
                    ),

                    const SizedBox(height: 4),

                    // Admin Only Sections
                    if (roleName == 'admin') ...[
                      const SizedBox(height: 12),
                      _buildSectionHeader('Manajemen Data'),
                      const SizedBox(height: 4),

                      _buildMenuItem(
                        context,
                        icon: Icons.people_outline_rounded,
                        title: 'Kelola Pengguna',
                        route: '/admin/users',
                        isActive: currentRoute == '/admin/users',
                      ),

                      _buildMenuItem(
                        context,
                        icon: Icons.inventory_2_outlined,
                        title: 'Kelola Alat',
                        route: '/admin/alat',
                        isActive: currentRoute == '/admin/alat',
                      ),

                      _buildMenuItem(
                        context,
                        icon: Icons.category_outlined,
                        title: 'Kelola Kategori',
                        route: '/admin/kategori',
                        isActive: currentRoute == '/admin/kategori',
                      ),
                    ],

                    // Peminjaman & Pengembalian (Admin & Petugas)
                    if (roleName == 'admin' || roleName == 'petugas') ...[
                      const SizedBox(height: 12),
                      _buildSectionHeader('Transaksi'),
                      const SizedBox(height: 4),

                      _buildMenuItem(
                        context,
                        icon: Icons.assignment_outlined,
                        title: 'Kelola Peminjaman',
                        route: '/admin/peminjaman',
                        isActive: currentRoute == '/admin/peminjaman',
                      ),

                      _buildMenuItem(
                        context,
                        icon: Icons.assignment_return_outlined,
                        title: 'Kelola Pengembalian',
                        route: '/admin/pengembalian',
                        isActive: currentRoute == '/admin/pengembalian',
                      ),
                    ],

                    // Laporan & Log (Admin Only)
                    if (roleName == 'admin') ...[
                      const SizedBox(height: 12),
                      _buildSectionHeader('Log Aktivitas'),
                      const SizedBox(height: 4),

                      // _buildMenuItem(
                      //   context,
                      //   icon: Icons.bar_chart_rounded,
                      //   title: 'Laporan',
                      //   route: '/admin/laporan',
                      //   isActive: currentRoute == '/admin/laporan',
                      // ),

                      _buildMenuItem(
                        context,
                        icon: Icons.history_rounded,
                        title: 'Log Aktivitas',
                        route: '/admin/log-aktivitas',
                        isActive: currentRoute == '/admin/log-aktivitas',
                      ),

                      const SizedBox(height: 12),
                      _buildSectionHeader('Alat Bantu'),
                      const SizedBox(height: 4),

                      _buildMenuItem(
                        context,
                        icon: Icons.upload_file_rounded,
                        title: 'Impor Data',
                        route: '/admin/import-data',
                        isActive: currentRoute == '/admin/import-data',
                      ),
                    ],
                  ],
                ),
              ),

              // Logout Button
              _buildLogoutButton(context, ref, isDrawerMode),
              const SizedBox(height: 12),
            ],
          ),
        );

        // Return Drawer for mobile, Container for desktop
        return isDrawerMode
            ? Drawer(
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
                child: sidebarContent,
              )
            : sidebarContent;
      },
    );
  }

  // ============================================================================
  // SECTION HEADER - Ultra Compact
  // ============================================================================
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: AppColors.textTertiary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  // ============================================================================
  // MENU ITEM - Minimalis & Structured
  // ============================================================================
  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String route,
    bool isActive = false,
  }) {
    final isDrawerMode = Scaffold.maybeOf(context) != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () {
            // If already on this route, just close drawer if open and return
            if (currentRoute == route) {
              if (isDrawerMode) {
                Navigator.pop(context);
              }
              return;
            }
            // Navigate to new route
            context.go(route);
            if (isDrawerMode) {
              Navigator.pop(context);
            }
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isActive
                  ? AppTheme.primaryColor.withOpacity(0.08)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: isActive
                  ? Border.all(
                      color: AppTheme.primaryColor.withOpacity(0.2),
                      width: 1,
                    )
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isActive
                      ? AppTheme.primaryColor
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                      color: isActive
                          ? AppTheme.primaryColor
                          : AppColors.textPrimary,
                      letterSpacing: -0.1,
                    ),
                  ),
                ),
                if (isActive)
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // LOGOUT BUTTON - Minimalis
  // ============================================================================
  Widget _buildLogoutButton(
    BuildContext context,
    WidgetRef ref,
    bool isDrawerMode,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () {
            _handleLogout(context, ref);
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.borderMedium, width: 1),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.logout_rounded,
                  size: 18,
                  color: Color(0xFFFF5252),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Keluar',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFFF5252),
                    letterSpacing: -0.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // LOGOUT HANDLER - Minimalis Dialog
  // ============================================================================
  void _handleLogout(BuildContext context, WidgetRef ref) {
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
                    Icons.logout_rounded,
                    color: Color(0xFFFF5252),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Konfirmasi Keluar',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Apakah Anda yakin ingin keluar dari sistem?',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                  child: const Text(
                    'Batal',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ref.read(authProvider.notifier).logout();
                    context.go('/login');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF5252),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                  ),
                  child: const Text(
                    'Keluar',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textInverse,
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
