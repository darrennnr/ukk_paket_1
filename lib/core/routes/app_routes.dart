// lib/core/routes/app_routes.dart
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:paket_3_training/providers/auth_provider.dart';
import 'package:paket_3_training/screens/admin/dashboard_admin.dart';
import 'package:paket_3_training/screens/admin/laporan&activity/log_activity.dart';
import 'package:paket_3_training/screens/admin/laporan&activity/laporan_page.dart';
import 'package:paket_3_training/screens/admin/transaksi/peminjaman_management.dart';
import 'package:paket_3_training/screens/admin/transaksi/pengembalian_management.dart';
import 'package:paket_3_training/screens/auth/login_page.dart';
import 'package:paket_3_training/screens/peminjam/dashboard_pengguna.dart';
import 'package:paket_3_training/screens/petugas/dashboard_petugas.dart';
import 'package:paket_3_training/screens/admin/data_management/user_management.dart';
import 'package:paket_3_training/screens/admin/data_management/alat_management.dart';
import 'package:paket_3_training/screens/admin/data_management/kategori_management.dart';
import 'package:paket_3_training/screens/petugas/transaksi/peminjaman_management.dart';
import 'package:paket_3_training/screens/petugas/transaksi/pengembalian_management.dart';
import 'package:paket_3_training/screens/peminjam/daftar_buku.dart';
import 'package:paket_3_training/screens/peminjam/form_peminjaman.dart';
import 'package:paket_3_training/screens/peminjam/history.dart';
import 'package:paket_3_training/screens/peminjam/kembalikan_buku.dart';
import 'package:paket_3_training/screens/petugas/laporan.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = ref.watch(authProvider.notifier);
  
  return GoRouter(
    initialLocation: '/login',
    refreshListenable: authNotifier, // Listen to auth state changes
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final isAuthenticated = authState.isAuthenticated;
      final isLoading = authState.isLoading;
      final user = authState.user;
      final currentPath = state.matchedLocation;

      // Wait for auth check to complete
      if (isLoading) {
        return null;
      }

      // If not authenticated and not on login page, redirect to login
      if (!isAuthenticated && currentPath != '/login') {
        return '/login';
      }

      // If authenticated and on login page, redirect to appropriate dashboard
      if (isAuthenticated && currentPath == '/login') {
        final role = user?.role?.role?.toLowerCase() ?? '';
        return _getDashboardByRole(role);
      }

      // Role-based access control
      if (isAuthenticated && user != null) {
        final role = user.role?.role?.toLowerCase() ?? '';
        
        // Admin routes
        if (currentPath.startsWith('/admin/') && role != 'admin') {
          return _getDashboardByRole(role);
        }
        
        // Petugas routes
        if (currentPath.startsWith('/petugas/') && role != 'petugas') {
          return _getDashboardByRole(role);
        }
        
        // Peminjam routes
        if (currentPath.startsWith('/peminjam/') && role != 'peminjam') {
          return _getDashboardByRole(role);
        }
      }

      return null; // No redirect needed
    },
    routes: [
      // Auth Routes
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),

      // Admin Routes
      GoRoute(
        path: '/admin/dashboard',
        builder: (context, state) => const DashboardAdmin(),
      ),
      GoRoute(
        path: '/admin/users',
        builder: (context, state) => const UserManagement(),
      ),
      GoRoute(
        path: '/admin/alat',
        builder: (context, state) => const AlatManagement(),
      ),
      GoRoute(
        path: '/admin/kategori',
        builder: (context, state) => const KategoriManagement(),
      ),

      // Transaction Routes
      GoRoute(
        path: '/admin/peminjaman',
        builder: (context, state) => const PeminjamanManagement(),
      ),
      GoRoute(
        path: '/admin/pengembalian',
        builder: (context, state) => const PengembalianManagement(),
      ),

      // Report & Activity Routes
      GoRoute(
        path: '/admin/laporan',
        builder: (context, state) => const LaporanPage(),
      ),
      GoRoute(
        path: '/admin/log-aktivitas',
        builder: (context, state) => const LogActivityScreen(),
      ),

      GoRoute(
        path: '/admin/settings',
        builder: (context, state) =>
            const _PlaceholderPage(title: 'Pengaturan'),
      ),

      // Petugas Routes
      GoRoute(
        path: '/petugas/dashboard',
        builder: (context, state) => const DashboardPetugas(),
      ),

      GoRoute(
        path: '/petugas/approval',
        builder: (context, state) => const PetugasPeminjamanManagement(),
      ),

      GoRoute(
        path: '/petugas/pengembalian',
        builder: (context, state) => const PetugasPengembalianManagement(),
      ),

      GoRoute(
        path: '/petugas/laporan',
        builder: (context, state) => const LaporanPetugas(),
      ),

      // Peminjam Routes
      GoRoute(
        path: '/peminjam/dashboard',
        builder: (context, state) => const DashboardPeminjam(),
      ),
      GoRoute(
        path: '/peminjam/buku',
        builder: (context, state) => const DaftarBukuScreen(),
      ),
      GoRoute(
        path: '/peminjam/ajukan',
        builder: (context, state) {
          // Use query parameter instead of extra for web compatibility
          final bookId = state.uri.queryParameters['bookId'];
          return FormPeminjamanScreen(bookId: bookId);
        },
      ),
      GoRoute(
        path: '/peminjam/history',
        builder: (context, state) => const HistoryPeminjamanScreen(),
      ),
      GoRoute(
        path: '/peminjam/kembalikan',
        builder: (context, state) => const KembalikanBukuScreen(),
      ),

      // Backward compatibility (redirect old routes)
      GoRoute(
        path: '/dashboard-admin',
        redirect: (context, state) => '/admin/dashboard',
      ),
      GoRoute(
        path: '/dashboard-petugas',
        redirect: (context, state) => '/petugas/dashboard',
      ),
      GoRoute(
        path: '/dashboard-peminjam',
        redirect: (context, state) => '/peminjam/dashboard',
      ),
    ],
  );
});

// Helper function to get dashboard route by role
String _getDashboardByRole(String role) {
  switch (role) {
    case 'admin':
      return '/admin/dashboard';
    case 'petugas':
      return '/petugas/dashboard';
    case 'peminjam':
      return '/peminjam/dashboard';
    default:
      return '/login';
  }
}

// Placeholder widget untuk halaman yang belum dibuat
class _PlaceholderPage extends StatelessWidget {
  final String title;

  const _PlaceholderPage({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/admin/dashboard'),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.construction_rounded,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Halaman "$title"',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Sedang dalam pengembangan',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.go('/admin/dashboard'),
              icon: const Icon(Icons.home_rounded, size: 18),
              label: const Text('Kembali ke Dashboard'),
            ),
          ],
        ),
      ),
    );
  }
}
