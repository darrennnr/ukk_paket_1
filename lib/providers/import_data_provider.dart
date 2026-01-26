// lib/providers/import_data_provider.dart
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paket_3_training/services/import_data_service.dart';

// ============================================================================
// IMPORT DATA STATE
// ============================================================================
class ImportDataState {
  final bool isLoading;
  final bool isImporting;
  final double progress;
  final int totalRows;
  final int processedRows;
  final String? selectedTable;
  final PlatformFile? selectedFile;
  final List<Map<String, dynamic>>? previewData;
  final ImportResult? result;
  final String? errorMessage;
  final DuplicateHandling duplicateHandling;
  final bool stopOnError;

  const ImportDataState({
    this.isLoading = false,
    this.isImporting = false,
    this.progress = 0.0,
    this.totalRows = 0,
    this.processedRows = 0,
    this.selectedTable,
    this.selectedFile,
    this.previewData,
    this.result,
    this.errorMessage,
    this.duplicateHandling = DuplicateHandling.skip,
    this.stopOnError = false,
  });

  ImportDataState copyWith({
    bool? isLoading,
    bool? isImporting,
    double? progress,
    int? totalRows,
    int? processedRows,
    String? selectedTable,
    PlatformFile? selectedFile,
    List<Map<String, dynamic>>? previewData,
    ImportResult? result,
    String? errorMessage,
    DuplicateHandling? duplicateHandling,
    bool? stopOnError,
    bool clearFile = false,
    bool clearPreview = false,
    bool clearResult = false,
    bool clearError = false,
  }) {
    return ImportDataState(
      isLoading: isLoading ?? this.isLoading,
      isImporting: isImporting ?? this.isImporting,
      progress: progress ?? this.progress,
      totalRows: totalRows ?? this.totalRows,
      processedRows: processedRows ?? this.processedRows,
      selectedTable: selectedTable ?? this.selectedTable,
      selectedFile: clearFile ? null : (selectedFile ?? this.selectedFile),
      previewData: clearPreview ? null : (previewData ?? this.previewData),
      result: clearResult ? null : (result ?? this.result),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      duplicateHandling: duplicateHandling ?? this.duplicateHandling,
      stopOnError: stopOnError ?? this.stopOnError,
    );
  }

  bool get hasFile => selectedFile != null;
  bool get hasPreview => previewData != null && previewData!.isNotEmpty;
  bool get hasResult => result != null;
  bool get canImport => hasFile && hasPreview && selectedTable != null && !isImporting;
}

// ============================================================================
// IMPORT DATA NOTIFIER
// ============================================================================
class ImportDataNotifier extends Notifier<ImportDataState> {
  late final ImportDataService _service;

  @override
  ImportDataState build() {
    _service = ImportDataService();
    return const ImportDataState();
  }

  /// Get daftar tabel yang bisa diimport
  List<String> get importableTables => _service.getImportableTables();

  /// Get dependencies untuk sebuah tabel
  List<String> getTableDependencies(String tableName) {
    return _service.getTableDependencies(tableName);
  }

  /// Set tabel yang dipilih
  void setSelectedTable(String? tableName) {
    state = state.copyWith(
      selectedTable: tableName,
      clearFile: true,
      clearPreview: true,
      clearResult: true,
      clearError: true,
    );
  }

  /// Set duplicate handling option
  void setDuplicateHandling(DuplicateHandling handling) {
    state = state.copyWith(duplicateHandling: handling);
  }

  /// Set stop on error option
  void setStopOnError(bool value) {
    state = state.copyWith(stopOnError: value);
  }

  /// Pick and parse file
  Future<void> pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'json', 'xlsx', 'xls'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      state = state.copyWith(
        selectedFile: file,
        isLoading: true,
        clearPreview: true,
        clearResult: true,
        clearError: true,
      );

      // Parse file
      final rows = await _service.parseFile(file);
      
      // Take first 10 rows for preview
      final preview = rows.take(10).toList();
      
      state = state.copyWith(
        isLoading: false,
        previewData: preview,
        totalRows: rows.length,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal membaca file: ${e.toString()}',
      );
    }
  }

  /// Set file directly (untuk drag & drop)
  Future<void> setFile(PlatformFile file) async {
    try {
      state = state.copyWith(
        selectedFile: file,
        isLoading: true,
        clearPreview: true,
        clearResult: true,
        clearError: true,
      );

      final rows = await _service.parseFile(file);
      final preview = rows.take(10).toList();
      
      state = state.copyWith(
        isLoading: false,
        previewData: preview,
        totalRows: rows.length,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal membaca file: ${e.toString()}',
      );
    }
  }

  /// Clear file selection
  void clearFile() {
    state = state.copyWith(
      clearFile: true,
      clearPreview: true,
      clearResult: true,
      clearError: true,
      totalRows: 0,
      processedRows: 0,
      progress: 0.0,
    );
  }

  /// Start import process
  Future<void> startImport() async {
    if (!state.canImport) return;
    
    try {
      state = state.copyWith(
        isImporting: true,
        progress: 0.0,
        processedRows: 0,
        clearResult: true,
        clearError: true,
      );

      // Re-parse file to get all rows
      final rows = await _service.parseFile(state.selectedFile!);
      
      state = state.copyWith(totalRows: rows.length);

      // Run import
      final result = await _service.importData(
        rows: rows,
        tableName: state.selectedTable!,
        options: ImportOptions(
          duplicateHandling: state.duplicateHandling,
          stopOnError: state.stopOnError,
        ),
        onProgress: (processed, total) {
          state = state.copyWith(
            processedRows: processed,
            progress: total > 0 ? processed / total : 0.0,
          );
        },
      );

      state = state.copyWith(
        isImporting: false,
        result: result,
        progress: 1.0,
        processedRows: rows.length,
      );
    } catch (e) {
      state = state.copyWith(
        isImporting: false,
        errorMessage: 'Gagal melakukan import: ${e.toString()}',
      );
    }
  }

  /// Generate and get template CSV content
  String getTemplateCsv() {
    if (state.selectedTable == null) return '';
    
    final headers = _service.getTemplateHeaders(state.selectedTable!);
    final example = _service.getTemplateExampleRow(state.selectedTable!);
    
    final buffer = StringBuffer();
    buffer.writeln(headers.join(','));
    if (example.isNotEmpty) {
      buffer.writeln(example.join(','));
    }
    
    return buffer.toString();
  }

  /// Get template headers untuk display
  List<String> getTemplateHeaders() {
    if (state.selectedTable == null) return [];
    return _service.getTemplateHeaders(state.selectedTable!);
  }

  /// Reset state
  void reset() {
    state = const ImportDataState();
  }
}

// ============================================================================
// PROVIDER
// ============================================================================
final importDataProvider = NotifierProvider<ImportDataNotifier, ImportDataState>(() {
  return ImportDataNotifier();
});
