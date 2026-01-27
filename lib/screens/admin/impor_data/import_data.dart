// lib/screens/admin/impor_data/import_data.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:paket_3_training/core/design_system/app_color.dart';
import 'package:paket_3_training/core/design_system/app_design_system.dart' hide AppTheme;
import 'package:paket_3_training/widgets/admin_sidebar.dart';
import 'package:paket_3_training/providers/auth_provider.dart';
import 'package:paket_3_training/providers/import_data_provider.dart';
import 'package:paket_3_training/services/import_data_service.dart';

class ImportDataPage extends ConsumerStatefulWidget {
  const ImportDataPage({Key? key}) : super(key: key);

  @override
  ConsumerState<ImportDataPage> createState() => _ImportDataPageState();
}

class _ImportDataPageState extends ConsumerState<ImportDataPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool get _isDesktop => MediaQuery.of(context).size.width >= 900;

  @override
  Widget build(BuildContext context) {
    final importState = ref.watch(importDataProvider);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildAppBar(),
      drawer: _isDesktop ? null : AdminSidebar(currentRoute: '/admin/import-data'),
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
              child: AdminSidebar(currentRoute: '/admin/import-data'),
            ),
          Expanded(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(_isDesktop ? 24 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 20),
                  _buildMainContent(importState),
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
        'Impor Data',
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
              Icon(Icons.person_outline_rounded, size: 18, color: AppColors.textPrimary),
              const SizedBox(width: 10),
              const Text('Profil', style: TextStyle(fontSize: 13)),
            ],
          ),
        ),
        const PopupMenuDivider(height: 1),
        PopupMenuItem(
          value: 'logout',
          height: 40,
          child: const Row(
            children: [
              Icon(Icons.logout_rounded, size: 18, color: Color(0xFFFF5252)),
              SizedBox(width: 10),
              Text('Keluar', style: TextStyle(fontSize: 13, color: Color(0xFFFF5252))),
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
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Impor Data',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Import data dari file CSV, JSON, atau Excel',
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
    ).animate().fadeIn(duration: 150.ms).slideY(begin: -0.1, end: 0);
  }

  // ============================================================================
  // MAIN CONTENT
  // ============================================================================
  Widget _buildMainContent(ImportDataState state) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (_isDesktop) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 1, child: _buildLeftPanel(state)),
              const SizedBox(width: 20),
              Expanded(flex: 2, child: _buildRightPanel(state)),
            ],
          );
        }
        
        return Column(
          children: [
            _buildLeftPanel(state),
            const SizedBox(height: 20),
            _buildRightPanel(state),
          ],
        );
      },
    );
  }

  // ============================================================================
  // LEFT PANEL - Configuration
  // ============================================================================
  Widget _buildLeftPanel(ImportDataState state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Konfigurasi Import', Icons.settings_outlined),
          const SizedBox(height: 16),
          _buildTableSelector(state),
          const SizedBox(height: 16),
          _buildFileUpload(state),
          const SizedBox(height: 16),
          _buildImportOptions(state),
          const SizedBox(height: 16),
          _buildTemplateSection(state),
          const SizedBox(height: 20),
          _buildImportButton(state),
        ],
      ),
    ).animate().fadeIn(duration: 150.ms, delay: 100.ms);
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.primaryColor, size: 18),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
        ),
      ],
    );
  }

  Widget _buildTableSelector(ImportDataState state) {
    final tables = ref.read(importDataProvider.notifier).importableTables;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pilih Tabel',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.borderMedium),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: state.selectedTable,
              hint: Text(
                'Pilih tabel target...',
                style: TextStyle(fontSize: 13, color: AppColors.textHint),
              ),
              isExpanded: true,
              icon: Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary),
              items: tables.map((table) {
                final deps = ref.read(importDataProvider.notifier).getTableDependencies(table);
                return DropdownMenuItem<String>(
                  value: table,
                  child: Row(
                    children: [
                      Icon(_getTableIcon(table), size: 16, color: AppTheme.primaryColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _getTableDisplayName(table),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                            if (deps.isNotEmpty)
                              Text(
                                'Depends: ${deps.join(", ")}',
                                style: TextStyle(fontSize: 10, color: AppColors.textTertiary),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: state.isImporting ? null : (value) {
                ref.read(importDataProvider.notifier).setSelectedTable(value);
              },
            ),
          ),
        ),
      ],
    );
  }

  IconData _getTableIcon(String table) {
    switch (table) {
      case 'kategori': return Icons.category_outlined;
      case 'alat': return Icons.build_outlined;
      case 'users': return Icons.people_outlined;
      case 'peminjaman': return Icons.assignment_outlined;
      case 'pengembalian': return Icons.assignment_return_outlined;
      case 'role': return Icons.admin_panel_settings_outlined;
      case 'status_peminjaman': return Icons.flag_outlined;
      default: return Icons.table_chart_outlined;
    }
  }

  String _getTableDisplayName(String table) {
    switch (table) {
      case 'kategori': return 'Kategori';
      case 'alat': return 'Alat';
      case 'users': return 'Users';
      case 'peminjaman': return 'Peminjaman';
      case 'pengembalian': return 'Pengembalian';
      case 'role': return 'Role';
      case 'status_peminjaman': return 'Status Peminjaman';
      default: return table;
    }
  }

  Widget _buildFileUpload(ImportDataState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'File Import',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: state.selectedTable == null || state.isImporting
              ? null
              : () => ref.read(importDataProvider.notifier).pickFile(),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border.all(
                color: state.hasFile ? AppColors.success : AppColors.borderMedium,
                style: state.hasFile ? BorderStyle.solid : BorderStyle.solid,
              ),
              borderRadius: BorderRadius.circular(8),
              color: state.hasFile 
                  ? AppColors.successContainer.withOpacity(0.3) 
                  : AppColors.surfaceContainerLowest,
            ),
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                : Column(
                    children: [
                      Icon(
                        state.hasFile ? Icons.check_circle_outline : Icons.cloud_upload_outlined,
                        size: 32,
                        color: state.hasFile ? AppColors.success : AppColors.textTertiary,
                      ),
                      const SizedBox(height: 8),
                      if (state.hasFile) ...[
                        Text(
                          state.selectedFile!.name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1A1A),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          '${state.totalRows} baris data',
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: state.isImporting
                              ? null
                              : () => ref.read(importDataProvider.notifier).clearFile(),
                          icon: const Icon(Icons.close, size: 14),
                          label: const Text('Hapus', style: TextStyle(fontSize: 12)),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.error,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          ),
                        ),
                      ] else ...[
                        Text(
                          state.selectedTable == null
                              ? 'Pilih tabel terlebih dahulu'
                              : 'Klik untuk pilih file',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'CSV, JSON, XLSX, XLS',
                          style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
                        ),
                      ],
                    ],
                  ),
          ),
        ),
        if (state.errorMessage != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.errorContainer,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, size: 14, color: AppColors.error),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    state.errorMessage!,
                    style: TextStyle(fontSize: 11, color: AppColors.error),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildImportOptions(ImportDataState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Opsi Duplikat',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: DuplicateHandling.values.map((option) {
            final isSelected = state.duplicateHandling == option;
            return ChoiceChip(
              label: Text(_getDuplicateOptionLabel(option)),
              selected: isSelected,
              onSelected: state.isImporting ? null : (selected) {
                if (selected) {
                  ref.read(importDataProvider.notifier).setDuplicateHandling(option);
                }
              },
              selectedColor: AppTheme.primaryColor.withOpacity(0.2),
              checkmarkColor: AppTheme.primaryColor,
              labelStyle: TextStyle(
                fontSize: 11,
                color: isSelected ? AppTheme.primaryColor : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            SizedBox(
              height: 20,
              width: 20,
              child: Checkbox(
                value: state.stopOnError,
                onChanged: state.isImporting ? null : (value) {
                  ref.read(importDataProvider.notifier).setStopOnError(value ?? false);
                },
                activeColor: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Berhenti jika ada error',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ],
    );
  }

  String _getDuplicateOptionLabel(DuplicateHandling option) {
    switch (option) {
      case DuplicateHandling.skip: return 'Lewati';
      case DuplicateHandling.update: return 'Update';
      case DuplicateHandling.error: return 'Error';
    }
  }

  Widget _buildTemplateSection(ImportDataState state) {
    if (state.selectedTable == null) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.infoContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: AppColors.info),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Template ${_getTableDisplayName(state.selectedTable!)}',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                onPressed: () => _showTemplateDialog(state.selectedTable!),
                icon: Icon(Icons.visibility, size: 18, color: AppColors.info),
                tooltip: 'Lihat Template',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Klik ikon mata untuk melihat format template',
            style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  void _showTemplateDialog(String tableName) {
    final csv = ref.read(importDataProvider.notifier).getTemplateCsv();
    final headers = ref.read(importDataProvider.notifier).getTemplateHeaders();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: AppColors.surface,
        title: Row(
          children: [
            Icon(Icons.table_chart, color: AppTheme.primaryColor, size: 20),
            const SizedBox(width: 8),
            Text(
              'Template ${_getTableDisplayName(tableName)}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Kolom yang diperlukan:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: headers.map((h) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(h, style: TextStyle(fontSize: 11, color: AppTheme.primaryColor, fontWeight: FontWeight.w500)),
                )).toList(),
              ),
              const SizedBox(height: 16),
              Text(
                'Format CSV:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.borderMedium),
                ),
                child: SelectableText(
                  csv,
                  style: const TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: csv));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Template berhasil disalin ke clipboard'),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              );
            },
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Salin'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImportButton(ImportDataState state) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: state.canImport
            ? () => ref.read(importDataProvider.notifier).startImport()
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
        child: state.isImporting
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Mengimport... ${(state.progress * 100).toInt()}%',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.upload_file, size: 18),
                  SizedBox(width: 8),
                  Text('Mulai Import', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              ),
      ),
    );
  }

  // ============================================================================
  // RIGHT PANEL - Preview & Results
  // ============================================================================
  Widget _buildRightPanel(ImportDataState state) {
    return Column(
      children: [
        if (state.isImporting || state.hasResult) _buildProgress(state),
        if (state.hasResult) ...[
          const SizedBox(height: 16),
          _buildResultSummary(state.result!),
        ],
        if (state.hasPreview) ...[
          const SizedBox(height: 16),
          _buildDataPreview(state),
        ],
        if (!state.hasPreview && !state.hasResult)
          _buildEmptyState(),
      ],
    );
  }

  Widget _buildProgress(ImportDataState state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                state.isImporting ? Icons.hourglass_top : Icons.check_circle,
                color: state.isImporting ? AppColors.warning : AppColors.success,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                state.isImporting ? 'Proses Import...' : 'Import Selesai',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const Spacer(),
              Text(
                '${state.processedRows}/${state.totalRows}',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: state.progress,
              backgroundColor: AppColors.borderMedium,
              valueColor: AlwaysStoppedAnimation(
                state.isImporting ? AppTheme.primaryColor : AppColors.success,
              ),
              minHeight: 8,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildResultSummary(ImportResult result) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Hasil Import', Icons.summarize_outlined),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildStatCard('Total', result.totalRows, AppColors.info)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard('Berhasil', result.successCount, AppColors.success)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard('Gagal', result.failedCount, AppColors.error)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard('Dilewati', result.skippedCount, AppColors.warning)),
            ],
          ),
          if (result.hasErrors) ...[
            const SizedBox(height: 16),
            _buildErrorList(result.errors),
          ],
          const SizedBox(height: 16),
          Text(
            'Durasi: ${result.duration.inSeconds}.${(result.duration.inMilliseconds % 1000).toString().padLeft(3, '0')} detik',
            style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildStatCard(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorList(List<ImportError> errors) {
    final displayErrors = errors.take(10).toList();
    final hasMore = errors.length > 10;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.errorContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.error),
              const SizedBox(width: 6),
              Text(
                'Error Details (${errors.length})',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.error,
                ),
              ),
              const Spacer(),
              if (errors.isNotEmpty)
                TextButton.icon(
                  onPressed: () => _copyErrorReport(errors),
                  icon: Icon(Icons.copy, size: 14, color: AppColors.error),
                  label: Text('Salin', style: TextStyle(fontSize: 11, color: AppColors.error)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          ...displayErrors.map((error) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              '• Row ${error.rowNumber}: ${error.field} - ${error.message}',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          )),
          if (hasMore)
            Text(
              '... dan ${errors.length - 10} error lainnya',
              style: TextStyle(fontSize: 11, color: AppColors.textTertiary, fontStyle: FontStyle.italic),
            ),
        ],
      ),
    );
  }

  void _copyErrorReport(List<ImportError> errors) {
    final buffer = StringBuffer();
    buffer.writeln('Row,Field,Message,Value');
    for (final error in errors) {
      buffer.writeln('${error.rowNumber},"${error.field}","${error.message}","${error.value ?? ''}"');
    }
    
    Clipboard.setData(ClipboardData(text: buffer.toString()));
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Error report disalin ke clipboard'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildDataPreview(ImportDataState state) {
    final headers = state.previewData!.isNotEmpty 
        ? state.previewData!.first.keys.toList() 
        : <String>[];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildSectionTitle('Preview Data', Icons.preview_outlined),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.infoContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${state.previewData!.length} dari ${state.totalRows} baris',
                    style: TextStyle(fontSize: 10, color: AppColors.info, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(AppColors.surfaceContainerLowest),
              dataRowMinHeight: 36,
              dataRowMaxHeight: 48,
              headingRowHeight: 40,
              columnSpacing: 16,
              horizontalMargin: 16,
              columns: headers.map((h) => DataColumn(
                label: Text(
                  h,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              )).toList(),
              rows: state.previewData!.map((row) => DataRow(
                cells: headers.map((h) => DataCell(
                  Text(
                    row[h]?.toString() ?? '-',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                )).toList(),
              )).toList(),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 150.ms, delay: 200.ms);
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderMedium),
      ),
      child: Center(
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
                Icons.upload_file_outlined,
                size: 48,
                color: AppColors.textHint,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Belum ada data',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Pilih tabel dan upload file untuk memulai import',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _buildFormatChip('CSV', Icons.description_outlined),
                _buildFormatChip('JSON', Icons.data_object),
                _buildFormatChip('XLSX', Icons.table_chart_outlined),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 150.ms, delay: 100.ms);
  }

  Widget _buildFormatChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderMedium),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textTertiary),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
