// lib/widgets/petugas_sidebar.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:paket_3_training/core/design_system/app_color.dart';
import '../providers/auth_provider.dart';

class PetugasSidebar extends ConsumerWidget {
  final String currentRoute;

  const PetugasSidebar({Key? key, required this.currentRoute}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final isDrawerMode = Scaffold.maybeOf(context) != null;

    return LayoutBuilder(
      builder: (context, constraints) {
        Widget sidebarContent = Container(
          width: isDrawerMode ? null : 260,
          decoration: BoxDecoration(
            color: Colors.white,
            border: isDrawerMode
                ? null
                : Border(
                    right: BorderSide(color: Colors.grey.shade200, width: 1),
                  ),
          ),
          child: Column(
            children: [
              // Menu Items
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  children: [
                    // Dashboard
                    _buildMenuItem(
                      context,
                      icon: Icons.dashboard_rounded,
                      title: 'Dashboard',
                      route: '/petugas/dashboard',
                      isActive: currentRoute == '/petugas/dashboard',
                    ),

                    const SizedBox(height: 12),
                    _buildSectionHeader('Transaksi'),
                    const SizedBox(height: 4),

                    _buildMenuItem(
                      context,
                      icon: Icons.check_circle_outline_rounded,
                      title: 'Approval Peminjaman',
                      route: '/petugas/approval',
                      isActive: currentRoute == '/petugas/approval',
                    ),

                    _buildMenuItem(
                      context,
                      icon: Icons.assignment_return_outlined,
                      title: 'Pantau Pengembalian',
                      route: '/petugas/pengembalian',
                      isActive: currentRoute == '/petugas/pengembalian',
                    ),

                    const SizedBox(height: 12),
                    _buildSectionHeader('Laporan'),
                    const SizedBox(height: 4),

                    _buildMenuItem(
                      context,
                      icon: Icons.bar_chart_rounded,
                      title: 'Laporan',
                      route: '/petugas/laporan',
                      isActive: currentRoute == '/petugas/laporan',
                    ),
                  ],
                ),
              ),

              // User Profile Section
              _buildUserProfile(context, user?.namaLengkap, user?.email),

              // Logout Button
              _buildLogoutButton(context, ref, isDrawerMode),
              const SizedBox(height: 12),
            ],
          ),
        );

        return isDrawerMode
            ? Drawer(
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                child: sidebarContent,
              )
            : sidebarContent;
      },
    );
  }

  // ============================================================================
  // SECTION HEADER
  // ============================================================================
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade500,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  // ============================================================================
  // MENU ITEM
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
              color: isActive ? AppTheme.primaryColor.withOpacity(0.08) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: isActive
                  ? Border.all(color: AppTheme.primaryColor.withOpacity(0.2), width: 1)
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isActive ? AppTheme.primaryColor : Colors.grey.shade600,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                      color: isActive ? AppTheme.primaryColor : const Color(0xFF1A1A1A),
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
  // USER PROFILE
  // ============================================================================
  Widget _buildUserProfile(BuildContext context, String? nama, String? email) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                (nama ?? 'P')[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  nama ?? 'Petugas',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                    letterSpacing: -0.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (email != null && email.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    email,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                      letterSpacing: 0,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // LOGOUT BUTTON
  // ============================================================================
  Widget _buildLogoutButton(BuildContext context, WidgetRef ref, bool isDrawerMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () {
            if (isDrawerMode) {
              Navigator.pop(context);
            }
            _handleLogout(context, ref);
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200, width: 1),
            ),
            child: Row(
              children: [
                const Icon(Icons.logout_rounded, size: 18, color: Color(0xFFFF5252)),
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
  // LOGOUT HANDLER
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
                  child: const Icon(Icons.logout_rounded, color: Color(0xFFFF5252), size: 20),
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
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.4),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  child: Text(
                    'Batal',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    ref.read(authProvider.notifier).logout();
                    Navigator.pop(context);
                    context.go('/login');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF5252),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  child: const Text(
                    'Keluar',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
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