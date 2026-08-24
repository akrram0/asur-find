// Global app state: real scan results + safe (recycle-bin) actions.

import 'package:flutter/foundation.dart';

import 'data.dart';
import 'scanner.dart';

class AppState extends ChangeNotifier {
  List<CleanupItem> cleanupItems = const [];
  List<CleanupItem> devClutterItems = const [];
  List<LargeFile> largeFiles = const [];

  int usedBytes = 0;
  int totalBytes = 0;
  bool scanning = false;
  bool scannedOnce = false;
  String? lastScanError;

  String get usedLabel => StorageScanner.formatBytes(usedBytes);
  String get totalLabel => StorageScanner.formatBytes(totalBytes);
  int get usedPercent =>
      totalBytes <= 0 ? 0 : ((usedBytes / totalBytes) * 100).round();

  /// Full rescan of disk usage + all categories.
  Future<void> rescanAll() async {
    if (scanning) return;
    scanning = true;
    notifyListeners();
    try {
      final usage = await StorageScanner.diskUsage();
      usedBytes = usage?.used ?? 0;
      totalBytes = usage?.total ?? 0;
      cleanupItems = await StorageScanner.scanCleanupCandidates();
      devClutterItems = await StorageScanner.scanDevClutter();
      largeFiles = await StorageScanner.scanLargeFiles();
      lastScanError = null;
    } catch (e) {
      lastScanError = e.toString();
    }
    scanning = false;
    scannedOnce = true;
    notifyListeners();
  }

  /// SAFE delete: moves to the Windows Recycle Bin, then refreshes state.
  Future<void> clean(CleanupItem item) async {
    await StorageScanner.recyclePath(item.path);
    cleanupItems = _without(cleanupItems, item);
    devClutterItems = _without(devClutterItems, item);
    // Rescan usage in the background so the meter stays honest.
    final usage = await StorageScanner.diskUsage();
    if (usage != null) {
      usedBytes = usage.used;
      totalBytes = usage.total;
    }
    notifyListeners();
  }

  /// Archive = same safe recycle-bin treatment for large files.
  Future<void> archive(LargeFile file) async {
    await StorageScanner.recyclePath(file.path);
    largeFiles = [...largeFiles]..remove(file);
    notifyListeners();
  }

  static List<T> _without<T>(List<T> list, T item) =>
      [...list]..remove(item);
}

/// Single global instance — simple and sufficient for this utility.
final AppState appState = AppState();
