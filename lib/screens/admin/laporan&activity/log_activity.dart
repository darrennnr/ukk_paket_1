// lib/screens/admin/laporan&activity/log_activity.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:paket_3_training/core/design_system/app_color.dart';
import 'package:paket_3_training/core/design_system/app_design_system.dart'
    hide AppTheme;
import 'package:paket_3_training/widgets/admin_sidebar.dart';
import 'package:paket_3_training/providers/log_aktivitas_provider.dart';
import 'package:paket_3_training/providers/auth_provider.dart';
import 'package:paket_3_training/models/log_aktivitas_model.dart';

class LogActivityScreen extends ConsumerStatefulWidget {
  const LogActivityScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LogActivityScreen> createState() => _LogActivityScreenState();
}

class _LogActivityScreenState extends ConsumerState<LogActivityScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  String? _selectedTypeFilter;
  String? _selectedDateFilter = 'all'; // all, today, week, month

  bool get _isDesktop => MediaQuery.of(context).size.width >= 900;
  bool get _isTablet =>
      MediaQuery.of(context).size.width >= 600 &&
      MediaQuery.of(context).size.width < 900;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(logAktivitasProvider.notifier).loadLogs());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final logState = ref.watch(logAktivitasProvider);
    final filteredLogs = _getFilteredLogs();

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildAppBar(),
      drawer: _isDesktop
          ? null
          : AdminSidebar(currentRoute: '/admin/log-aktivitas'),
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
              child: AdminSidebar(currentRoute: '/admin/log-aktivitas'),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () =>
                  ref.read(logAktivitasProvider.notifier).refresh(),
              color: AppTheme.primaryColor,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(_isDesktop ? 24 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 20),
                    _buildStatsCards(),
                    const SizedBox(height: 20),
                    _buildFilters(),
                    const SizedBox(height: 20),
                    if (logState.isLoading && logState.logs.isEmpty)
                      _buildLoadingSkeleton()
                    else if (filteredLogs.isEmpty)
                      _buildEmptyState()
                    else
                      _buildLogList(filteredLogs),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<LogAktivitasModel> _getFilteredLogs() {
    var logs = ref.watch(filteredLogsProvider);

    // Filter by type
    if (_selectedTypeFilter != null && _selectedTypeFilter != 'all') {
      logs = logs.where((log) {
        switch (_selectedTypeFilter) {
          case 'login':
            return log.isLogin;
          case 'logout':
            return log.isLogout;
          case 'create':
            return log.isCreate;
          case 'update':
            return log.isUpdate;
          case 'delete':
            return log.isDelete;
          case 'approval':
            return log.isApproval;
          default:
            return true;
        }
      }).toList();
    }

    // Filter by date
    if (_selectedDateFilter != null && _selectedDateFilter != 'all') {
      final now = DateTime.now();
      logs = logs.where((log) {
        if (log.createdAt == null) return false;

        switch (_selectedDateFilter) {
          case 'today':
            return log.createdAt!.year == now.year &&
                log.createdAt!.month == now.month &&
                log.createdAt!.day == now.day;
          case 'week':
            final weekAgo = now.subtract(const Duration(days: 7));
            return log.createdAt!.isAfter(weekAgo);
          case 'month':
            final monthAgo = now.subtract(const Duration(days: 30));
            return log.createdAt!.isAfter(monthAgo);
          default:
            return true;
        }
      }).toList();
    }

    // Search filter
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      logs = logs.where((log) {
        final namaMatch =
            log.user?.namaLengkap.toLowerCase().contains(query) ?? false;
        final usernameMatch =
            log.user?.username.toLowerCase().contains(query) ?? false;
        final deskripsiMatch =
            log.deskripsi?.toLowerCase().contains(query) ?? false;

        return log.aktivitas.toLowerCase().contains(query) ||
            namaMatch ||
            usernameMatch ||
            deskripsiMatch;
      }).toList();
    }

    return logs;
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
        'Log Aktivitas',
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
    final totalLogs = ref.watch(logAktivitasProvider).logs.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Log Aktivitas Sistem',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Total $totalLogs aktivitas tercatat',
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
        ),
      ],
    ).animate().fadeIn(duration: 150.ms).slideY(begin: -0.1, end: 0);
  }

  // ============================================================================
  // STATS CARDS
  // ============================================================================
  Widget _buildStatsCards() {
    final logCounts = ref.watch(logCountByTypeProvider);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildStatCard(
          'Login',
          logCounts['login'] ?? 0,
          Icons.login_rounded,
          const Color(0xFF4CAF50),
        ),
        _buildStatCard(
          'Logout',
          logCounts['logout'] ?? 0,
          Icons.logout_rounded,
          const Color(0xFF9E9E9E),
        ),
        _buildStatCard(
          'Tambah',
          logCounts['create'] ?? 0,
          Icons.add_circle_outline_rounded,
          const Color(0xFF2196F3),
        ),
        _buildStatCard(
          'Ubah',
          logCounts['update'] ?? 0,
          Icons.edit_outlined,
          const Color(0xFFFF9800),
        ),
        _buildStatCard(
          'Hapus',
          logCounts['delete'] ?? 0,
          Icons.delete_outline_rounded,
          const Color(0xFFFF5252),
        ),
        _buildStatCard(
          'Approval',
          logCounts['approval'] ?? 0,
          Icons.check_circle_outline_rounded,
          const Color(0xFF9C27B0),
        ),
      ],
    ).animate().fadeIn(duration: 150.ms, delay: 100.ms);
  }

  Widget _buildStatCard(String label, int count, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderMedium, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$count',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // FILTERS
  // ============================================================================
  Widget _buildFilters() {
    return Column(
      children: [
        // Search Bar
        Container(
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
              hintText: 'Cari aktivitas, user, atau deskripsi...',
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
                        setState(() {});
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
            onChanged: (value) => setState(() {}),
          ),
        ),
        const SizedBox(height: 12),
        // Filter Row
        Row(
          children: [
            Expanded(
              child: Container(
                height: 42,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.borderMedium, width: 1),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    value: _selectedTypeFilter,
                    hint: Text(
                      'Tipe Aktivitas',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    icon: Icon(
                      Icons.arrow_drop_down_rounded,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                    isExpanded: true,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF1A1A1A),
                    ),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Semua Tipe')),
                      DropdownMenuItem(value: 'login', child: Text('Login')),
                      DropdownMenuItem(value: 'logout', child: Text('Logout')),
                      DropdownMenuItem(value: 'create', child: Text('Tambah')),
                      DropdownMenuItem(value: 'update', child: Text('Ubah')),
                      DropdownMenuItem(value: 'delete', child: Text('Hapus')),
                      DropdownMenuItem(
                        value: 'approval',
                        child: Text('Approval'),
                      ),
                    ],
                    onChanged: (value) =>
                        setState(() => _selectedTypeFilter = value),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                height: 42,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.borderMedium, width: 1),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedDateFilter,
                    icon: Icon(
                      Icons.arrow_drop_down_rounded,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                    isExpanded: true,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF1A1A1A),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'all',
                        child: Text('Semua Waktu'),
                      ),
                      DropdownMenuItem(value: 'today', child: Text('Hari Ini')),
                      DropdownMenuItem(
                        value: 'week',
                        child: Text('7 Hari Terakhir'),
                      ),
                      DropdownMenuItem(
                        value: 'month',
                        child: Text('30 Hari Terakhir'),
                      ),
                    ],
                    onChanged: (value) =>
                        setState(() => _selectedDateFilter = value),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================================
  // LOG LIST
  // ============================================================================
  Widget _buildLogList(List<LogAktivitasModel> logs) {
    if (_isDesktop || _isTablet) {
      return _buildDesktopTable(logs);
    }
    return _buildMobileList(logs);
  }

  Widget _buildDesktopTable(List<LogAktivitasModel> logs) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderMedium, width: 1),
      ),
      child: Column(
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(10),
              ),
            ),
            child: Row(
              children: [
                const Expanded(
                  flex: 2,
                  child: Text(
                    'Pengguna',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
                const Expanded(
                  flex: 2,
                  child: Text(
                    'Aktivitas',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
                if (_isDesktop)
                  const Expanded(
                    flex: 3,
                    child: Text(
                      'Deskripsi',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const Expanded(
                  flex: 2,
                  child: Text(
                    'Waktu',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 40),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.borderMedium),
          // Table Body
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: logs.length,
            separatorBuilder: (_, __) =>
                Divider(height: 1, color: AppColors.surfaceContainerLow),
            itemBuilder: (context, index) => _buildLogRow(logs[index], index),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 150.ms, delay: 150.ms);
  }

  Widget _buildLogRow(LogAktivitasModel log, int index) {
    final typeInfo = _getLogTypeInfo(log);

    return InkWell(
          onTap: () => _showDetailDialog(log),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // User Info
                Expanded(
                  flex: 2,
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            (log.user?.namaLengkap ?? 'U')[0].toUpperCase(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              log.user?.namaLengkap ?? 'Unknown',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A1A1A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '@${log.user?.username ?? 'unknown'}',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Activity Type
                Expanded(
                  flex: 2,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: typeInfo['color'].withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          typeInfo['icon'],
                          size: 14,
                          color: typeInfo['color'],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          log.aktivitas,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF1A1A1A),
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                // Description
                if (_isDesktop)
                  Expanded(
                    flex: 3,
                    child: Text(
                      log.deskripsi ?? '-',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                // Time
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        log.createdAt != null
                            ? DateFormat('dd MMM yyyy').format(log.createdAt!)
                            : '-',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF1A1A1A),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        log.createdAt != null
                            ? DateFormat('HH:mm:ss').format(log.createdAt!)
                            : '-',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Action
                SizedBox(
                  width: 40,
                  child: IconButton(
                    icon: Icon(
                      Icons.visibility_outlined,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () => _showDetailDialog(log),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 150.ms, delay: (150 + index * 30).ms)
        .slideX(begin: 0.03, end: 0);
  }

  Widget _buildMobileList(List<LogAktivitasModel> logs) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: logs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _buildMobileCard(logs[index], index),
    );
  }

  Widget _buildMobileCard(LogAktivitasModel log, int index) {
    final typeInfo = _getLogTypeInfo(log);

    return InkWell(
          onTap: () => _showDetailDialog(log),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderMedium, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          (log.user?.namaLengkap ?? 'U')[0].toUpperCase(),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            log.user?.namaLengkap ?? 'Unknown',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A1A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '@${log.user?.username ?? 'unknown'}',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: typeInfo['color'].withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        typeInfo['icon'],
                        size: 14,
                        color: typeInfo['color'],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.borderMedium, width: 1),
                  ),
                  child: Text(
                    log.aktivitas,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ),
                if (log.deskripsi != null && log.deskripsi!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    log.deskripsi!,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 12,
                      color: AppColors.textTertiary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      log.createdAt != null
                          ? DateFormat(
                              'dd MMM yyyy, HH:mm',
                            ).format(log.createdAt!)
                          : '-',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 150.ms, delay: (index * 50).ms)
        .scale(begin: const Offset(0.95, 0.95));
  }

  Map<String, dynamic> _getLogTypeInfo(LogAktivitasModel log) {
    if (log.isLogin) {
      return {
        'icon': Icons.login_rounded,
        'color': const Color(0xFF4CAF50),
        'label': 'Login',
      };
    } else if (log.isLogout) {
      return {
        'icon': Icons.logout_rounded,
        'color': const Color(0xFF9E9E9E),
        'label': 'Logout',
      };
    } else if (log.isCreate) {
      return {
        'icon': Icons.add_circle_outline_rounded,
        'color': const Color(0xFF2196F3),
        'label': 'Tambah',
      };
    } else if (log.isUpdate) {
      return {
        'icon': Icons.edit_outlined,
        'color': const Color(0xFFFF9800),
        'label': 'Ubah',
      };
    } else if (log.isDelete) {
      return {
        'icon': Icons.delete_outline_rounded,
        'color': const Color(0xFFFF5252),
        'label': 'Hapus',
      };
    } else if (log.isApproval) {
      return {
        'icon': Icons.check_circle_outline_rounded,
        'color': const Color(0xFF9C27B0),
        'label': 'Approval',
      };
    }
    return {
      'icon': Icons.info_outline_rounded,
      'color': AppColors.textDisabled,
      'label': 'Lainnya',
    };
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
                Icons.history_rounded,
                size: 48,
                color: AppColors.textHint,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Tidak ada log aktivitas',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _searchController.text.isNotEmpty ||
                      _selectedTypeFilter != null ||
                      _selectedDateFilter != 'all'
                  ? 'Coba ubah filter pencarian'
                  : 'Belum ada aktivitas yang tercatat',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
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
    return Container(
          decoration: BoxDecoration(
            color: AppColors.borderMedium,
            borderRadius: BorderRadius.circular(10),
          ),
          height: 400,
        )
        .animate(onPlay: (controller) => controller.repeat())
        .shimmer(duration: 1200.ms);
  }

  // ============================================================================
  // DETAIL DIALOG
  // ============================================================================
  void _showDetailDialog(LogAktivitasModel log) {
    final typeInfo = _getLogTypeInfo(log);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: AppColors.surface,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: _isDesktop ? 500 : double.infinity,
            maxHeight: 600,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: typeInfo['color'].withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        typeInfo['icon'],
                        color: typeInfo['color'],
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Detail Log Aktivitas',
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
              ),
              Divider(height: 1, color: AppColors.borderMedium),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // User Section
                      _buildDetailSection('Informasi Pengguna', [
                        _buildDetailRow(
                          'Nama Lengkap',
                          log.user?.namaLengkap ?? '-',
                        ),
                        _buildDetailRow('Username', log.user?.username ?? '-'),
                        _buildDetailRow('Email', log.user?.email ?? '-'),
                      ]),
                      const SizedBox(height: 16),
                      // Activity Section
                      _buildDetailSection('Detail Aktivitas', [
                        _buildDetailRow('Aktivitas', log.aktivitas),
                        _buildDetailRow(
                          'Tipe',
                          typeInfo['label'],
                          valueColor: typeInfo['color'],
                        ),
                        if (log.tabelTerkait != null)
                          _buildDetailRow('Tabel', log.tabelTerkait!),
                        if (log.idTerkait != null)
                          _buildDetailRow('ID Terkait', '${log.idTerkait}'),
                      ]),
                      if (log.deskripsi != null &&
                          log.deskripsi!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _buildDetailSection('Deskripsi', [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLowest,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.borderMedium,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              log.deskripsi!,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textDisabled,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ]),
                      ],
                      const SizedBox(height: 16),
                      // Timestamp Section
                      _buildDetailSection('Informasi Waktu', [
                        _buildDetailRow(
                          'Tanggal',
                          log.createdAt != null
                              ? DateFormat(
                                  'EEEE, dd MMMM yyyy',
                                  'id_ID',
                                ).format(log.createdAt!)
                              : '-',
                        ),
                        _buildDetailRow(
                          'Waktu',
                          log.createdAt != null
                              ? DateFormat('HH:mm:ss').format(log.createdAt!)
                              : '-',
                        ),
                      ]),
                      if (log.userAgent != null &&
                          log.userAgent!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _buildDetailSection('User Agent', [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLowest,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.borderMedium,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              log.userAgent!,
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textPrimary,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                        ]),
                      ],
                    ],
                  ),
                ),
              ),
              Divider(height: 1, color: AppColors.borderMedium),
              // Footer
              Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Tutup',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.borderMedium, width: 1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
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
              style: TextStyle(
                fontSize: 12,
                color: valueColor ?? const Color(0xFF1A1A1A),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
