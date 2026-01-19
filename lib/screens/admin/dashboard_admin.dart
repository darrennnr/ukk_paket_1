// lib/screens/admin/dashboard_admin.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:paket_3_training/core/design_system/app_color.dart';
import 'package:paket_3_training/widgets/admin_sidebar.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/auth_provider.dart';

class DashboardAdmin extends ConsumerStatefulWidget {
  const DashboardAdmin({Key? key}) : super(key: key);

  @override
  ConsumerState<DashboardAdmin> createState() => _DashboardAdminState();
}

class _DashboardAdminState extends ConsumerState<DashboardAdmin> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool get _isDesktop => MediaQuery.of(context).size.width >= 900;
  bool _hasInitializedProviders = false;

  @override
  void initState() {
    super.initState();
    // Provider initialization is now done in build method when auth is ready
  }

  void _initializeProviders() {
    if (!_hasInitializedProviders) {
      _hasInitializedProviders = true;
      ref.read(dashboardProvider.notifier).ensureInitialized();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final dashboardState = ref.watch(dashboardProvider);
    final user = authState.user;

    // Wait for auth to complete before initializing providers
    if (!authState.isLoading && authState.isAuthenticated && !_hasInitializedProviders) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initializeProviders();
      });
    }

    // Show loading skeleton while auth is loading
    final showLoading = authState.isLoading || 
        (dashboardState.isLoading && dashboardState.statistics.isEmpty);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildAppBar(context, user?.namaLengkap ?? 'Admin'),
      drawer: _isDesktop
          ? null
          : AdminSidebar(currentRoute: '/admin/dashboard'),
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
              child: AdminSidebar(currentRoute: '/admin/dashboard'),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.read(dashboardProvider.notifier).refresh(),
              color: AppTheme.primaryColor,
              child: showLoading
                  ? _buildLoadingSkeleton()
                  : SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.all(_isDesktop ? 24 : 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildWelcomeHeader(user?.namaLengkap ?? 'Admin'),
                          const SizedBox(height: 24),
                          _buildStatisticsGrid(dashboardState.statistics),
                          const SizedBox(height: 24),
                          _buildChartSection(dashboardState.statistics),
                          const SizedBox(height: 24),
                          _buildRecentActivitySection(
                            dashboardState.recentActivities,
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // WELCOME HEADER - Minimalis & Compact
  // ============================================================================
  Widget _buildWelcomeHeader(String userName) {
    final hour = DateTime.now().hour;
    String greeting = hour < 12
        ? 'Selamat Pagi'
        : hour < 18
        ? 'Selamat Siang'
        : 'Selamat Malam';

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                userName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0);
  }

  // ============================================================================
  // APP BAR - Ultra Minimalis
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
        'Dashboard',
        style: TextStyle(
          color: const Color(0xFF1A1A1A),
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
      ),
      actions: [
        if (_isDesktop) ...[
          _buildIconButton(Icons.notifications_outlined, () {}, badge: '3'),
          const SizedBox(width: 4),
        ],
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

  Widget _buildIconButton(IconData icon, VoidCallback onTap, {String? badge}) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: Icon(icon, color: Colors.grey.shade700, size: 20),
          onPressed: onTap,
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        ),
        if (badge != null)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: const Color(0xFFFF5252),
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
              child: Text(
                badge,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
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
              Icon(
                Icons.person_outline_rounded,
                size: 18,
                color: Colors.grey.shade700,
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

  // ============================================================================
  // STATISTICS GRID - Compact & Clean
  // ============================================================================
  Widget _buildStatisticsGrid(Map<String, dynamic> statistics) {
    final stats = [
      _StatCard(
        title: 'Pengguna',
        value: statistics['total_users']?.toString() ?? '0',
        icon: Icons.people_outline_rounded,
        color: const Color(0xFF4CAF50),
      ),
      _StatCard(
        title: 'Total Alat',
        value: statistics['total_alat']?.toString() ?? '0',
        icon: Icons.inventory_2_outlined,
        color: const Color(0xFF2196F3),
      ),
      _StatCard(
        title: 'Kategori',
        value: statistics['total_kategori']?.toString() ?? '0',
        icon: Icons.category_outlined,
        color: const Color(0xFF9C27B0),
      ),
      _StatCard(
        title: 'Pending',
        value: statistics['peminjaman_pending']?.toString() ?? '0',
        icon: Icons.pending_actions_outlined,
        color: const Color(0xFFFF9800),
      ),
      _StatCard(
        title: 'Aktif',
        value: statistics['peminjaman_aktif']?.toString() ?? '0',
        icon: Icons.assignment_turned_in_outlined,
        color: const Color(0xFF00BCD4),
      ),
      _StatCard(
        title: 'Tersedia',
        value: statistics['alat_tersedia']?.toString() ?? '0',
        icon: Icons.check_circle_outline_rounded,
        color: const Color(0xFF66BB6A),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = constraints.maxWidth > 1200
            ? 6
            : constraints.maxWidth > 900
            ? 3
            : 2;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 1.4,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: stats.length,
          itemBuilder: (context, index) => _buildStatCard(stats[index], index),
        );
      },
    );
  }

  Widget _buildStatCard(_StatCard stat, int index) {
    return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade200, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: stat.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(stat.icon, color: stat.color, size: 20),
              ),
              const SizedBox(height: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stat.value,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    stat.title,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 400.ms, delay: (index * 50).ms)
        .scale(begin: const Offset(0.95, 0.95));
  }

  // ============================================================================
  // CHART SECTION - Minimalis & Structured
  // ============================================================================
  Widget _buildChartSection(Map<String, dynamic> statistics) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 900;

        if (isDesktop) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: _buildPeminjamanChart(statistics)),
              const SizedBox(width: 12),
              Expanded(flex: 2, child: _buildAlatStatusChart(statistics)),
            ],
          );
        } else {
          return Column(
            children: [
              _buildPeminjamanChart(statistics),
              const SizedBox(height: 12),
              _buildAlatStatusChart(statistics),
            ],
          );
        }
      },
    );
  }

  Widget _buildPeminjamanChart(Map<String, dynamic> statistics) {
    final pending = (statistics['peminjaman_pending'] ?? 0).toDouble();
    final aktif = (statistics['peminjaman_aktif'] ?? 0).toDouble();

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
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.bar_chart_rounded,
                  size: 16,
                  color: Color(0xFF666666),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Status Peminjaman',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: (pending > aktif ? pending : aktif) * 1.2,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (group) => const Color(0xFF1A1A1A),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${rod.toY.toInt()}',
                        const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            value.toInt() == 0 ? 'Pending' : 'Aktif',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: [
                  BarChartGroupData(
                    x: 0,
                    barRods: [
                      BarChartRodData(
                        toY: pending,
                        color: const Color(0xFFFF9800),
                        width: 32,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6),
                        ),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 1,
                    barRods: [
                      BarChartRodData(
                        toY: aktif,
                        color: const Color(0xFF00BCD4),
                        width: 32,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 200.ms);
  }

  Widget _buildAlatStatusChart(Map<String, dynamic> statistics) {
    final total = (statistics['total_alat'] ?? 0).toDouble();
    final tersedia = (statistics['alat_tersedia'] ?? 0).toDouble();
    final dipinjam = total - tersedia;

    if (total == 0) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200, width: 1),
        ),
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(40),
            child: Text(
              'Tidak ada data',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        ),
      );
    }

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
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.donut_small_rounded,
                  size: 16,
                  color: Color(0xFF666666),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Status Alat',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 140,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: [
                  PieChartSectionData(
                    value: tersedia,
                    title: '${tersedia.toInt()}',
                    color: const Color(0xFF4CAF50),
                    radius: 40,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  if (dipinjam > 0)
                    PieChartSectionData(
                      value: dipinjam,
                      title: '${dipinjam.toInt()}',
                      color: const Color(0xFFFF5252),
                      radius: 40,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem('Tersedia', const Color(0xFF4CAF50)),
              const SizedBox(width: 16),
              _buildLegendItem('Dipinjam', const Color(0xFFFF5252)),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 250.ms);
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // RECENT ACTIVITY SECTION - Minimalis & Compact
  // ============================================================================
  Widget _buildRecentActivitySection(List<Map<String, dynamic>> activities) {
    if (activities.isEmpty) {
      return const SizedBox.shrink();
    }

    // Limit to 5 activities
    final displayActivities = activities.take(5).toList();

    return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.history_rounded,
                        size: 14,
                        color: Color(0xFF666666),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Aktivitas Terbaru',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => context.go('/admin/log-aktivitas'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Lihat Semua',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 10,
                        color: AppTheme.primaryColor,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200, width: 1),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: displayActivities.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  thickness: 1,
                  color: Colors.grey.shade100,
                  indent: 50,
                  endIndent: 12,
                ),
                itemBuilder: (context, index) {
                  return _buildActivityItem(displayActivities[index], index);
                },
              ),
            ),
          ],
        )
        .animate()
        .fadeIn(duration: 400.ms, delay: 300.ms)
        .slideY(begin: 0.1, end: 0);
  }

  Widget _buildActivityItem(Map<String, dynamic> activity, int index) {
    // Extract data
    final user = activity['user'];
    final userName = user != null
        ? user['nama_lengkap'] ?? 'Unknown'
        : 'System';
    final aktivitas = activity['aktivitas'] ?? '';
    final deskripsi = activity['deskripsi'] ?? '';
    final createdAt = activity['created_at'] != null
        ? DateTime.parse(activity['created_at'])
        : DateTime.now();

    // Determine icon and color based on activity type
    IconData icon = Icons.info_outline_rounded;
    Color iconColor = const Color(0xFF2196F3);

    if (aktivitas.toLowerCase().contains('tambah') ||
        aktivitas.toLowerCase().contains('create')) {
      icon = Icons.add_circle_outline_rounded;
      iconColor = const Color(0xFF4CAF50);
    } else if (aktivitas.toLowerCase().contains('setujui') ||
        aktivitas.toLowerCase().contains('approve')) {
      icon = Icons.check_circle_outline_rounded;
      iconColor = const Color(0xFF2196F3);
    } else if (aktivitas.toLowerCase().contains('kembali') ||
        aktivitas.toLowerCase().contains('return')) {
      icon = Icons.assignment_return_outlined;
      iconColor = const Color(0xFF9C27B0);
    } else if (aktivitas.toLowerCase().contains('tolak') ||
        aktivitas.toLowerCase().contains('reject')) {
      icon = Icons.cancel_outlined;
      iconColor = const Color(0xFFFF5252);
    } else if (aktivitas.toLowerCase().contains('hapus') ||
        aktivitas.toLowerCase().contains('delete')) {
      icon = Icons.delete_outline_rounded;
      iconColor = const Color(0xFFFF5252);
    } else if (aktivitas.toLowerCase().contains('ubah') ||
        aktivitas.toLowerCase().contains('update')) {
      icon = Icons.edit_outlined;
      iconColor = const Color(0xFFFF9800);
    } else if (aktivitas.toLowerCase().contains('login')) {
      icon = Icons.login_rounded;
      iconColor = AppTheme.primaryColor;
    } else if (aktivitas.toLowerCase().contains('logout')) {
      icon = Icons.logout_rounded;
      iconColor = AppTheme.primaryColor;
    }

    // Format time ago
    final timeAgo = _formatTimeAgo(createdAt);

    return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF1A1A1A),
                          height: 1.4,
                        ),
                        children: [
                          TextSpan(
                            text: userName,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          TextSpan(
                            text: ' $aktivitas',
                            style: const TextStyle(fontWeight: FontWeight.w400),
                          ),
                          if (deskripsi.isNotEmpty)
                            TextSpan(
                              text: ' "$deskripsi"',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: iconColor,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 11,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          timeAgo,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 400.ms, delay: (350 + index * 80).ms)
        .slideX(begin: 0.05, end: 0);
  }

  // Helper: Format time ago
  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return DateFormat('d MMM yyyy').format(dateTime);
    } else if (difference.inDays > 0) {
      return '${difference.inDays} hari lalu';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} jam lalu';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} menit lalu';
    } else {
      return 'Baru saja';
    }
  }

  // ============================================================================
  // LOADING SKELETON
  // ============================================================================
  Widget _buildLoadingSkeleton() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(_isDesktop ? 24 : 16),
      child: Column(
        children: [
          _buildSkeletonBox(height: 60),
          const SizedBox(height: 24),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _isDesktop ? 6 : 2,
              childAspectRatio: 1.4,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: 6,
            itemBuilder: (context, index) => _buildSkeletonBox(),
          ),
          const SizedBox(height: 24),
          _buildSkeletonBox(height: 250),
          const SizedBox(height: 24),
          _buildSkeletonBox(height: 200),
        ],
      ),
    );
  }

  Widget _buildSkeletonBox({double? height}) {
    return Container(
          height: height,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(10),
          ),
        )
        .animate(onPlay: (controller) => controller.repeat())
        .shimmer(duration: 1200.ms);
  }

  // ============================================================================
  // LOGOUT HANDLER
  // ============================================================================
  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Color(0xFFFF5252), size: 20),
            SizedBox(width: 10),
            Text(
              'Konfirmasi Keluar',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        content: const Text(
          'Apakah Anda yakin ingin keluar?',
          style: TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Batal',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(authProvider.notifier).logout();
              context.go('/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5252),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text(
              'Keluar',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// DATA MODELS
// ============================================================================
class _StatCard {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });
}
