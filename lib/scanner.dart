// Real disk scanning engine â€” pure dart:io + PowerShell interop.
// No native plugins required; works on Windows out of the box.

import 'dart:io';

import 'data.dart';

class DiskUsage {
  const DiskUsage({required this.used, required this.total});
  final int used;
  final int total;
}

class StorageScanner {
  StorageScanner._();

  /// Folder names that are rebuildable dev artifacts.
  static const _artifactNames = {
    'node_modules', 'target', '.next', '.nuxt', 'dist', 'build',
    '.dart_tool', '.gradle', '__pycache__', '.venv',
  };

  /// Roots searched for dev projects.
  static const _devRootCandidates = [
    r'C:\Projects', r'C:\code', r'C:\src', r'C:\dev', r'C:\work',
  ];

  static const _largeFileThreshold = 100 * 1024 * 1024; // 100 MB

  // -------------------------------------------------------------------
  // Disk usage (C:) via PowerShell/CIM
  // -------------------------------------------------------------------

  static Future<DiskUsage?> diskUsage() async {
    try {
      final res = await Process.run(
        'powershell',
        [
          '-NoProfile',
          '-Command',
          r'''$d = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"; "{0}|{1}" -f $d.Size, $d.FreeSpace''',
        ],
        runInShell: true,
      );
      final parts = res.stdout.toString().trim().split('|');
      if (parts.length != 2) return null;
      final total = int.tryParse(parts[0].trim()) ?? 0;
      final free = int.tryParse(parts[1].trim()) ?? 0;
      if (total <= 0) return null;
      return DiskUsage(used: total - free, total: total);
    } catch (_) {
      return null;
    }
  }

  // -------------------------------------------------------------------
  // Dev clutter: rebuildable artifact folders under known dev roots
  // -------------------------------------------------------------------

  static Future<List<CleanupItem>> scanDevClutter() async {
    final roots =
        _devRootCandidates.where((p) => Directory(p).existsSync()).toList();
    final found = <CleanupItem>[];
    for (final root in roots) {
      await _findArtifacts(Directory(root), 6, found);
    }
    return found;
  }

  static Future<void> _findArtifacts(
    Directory dir,
    int depth,
    List<CleanupItem> out,
  ) async {
    if (depth <= 0) return;
    Stream<FileSystemEntity> entities;
    try {
      entities = dir.list(followLinks: false);
    } catch (_) {
      return; // access denied etc.
    }
    await for (final e in entities) {
      if (e is! Directory) continue;
      final name =
          e.uri.pathSegments.where((s) => s.isNotEmpty).last.toLowerCase();
      if (_artifactNames.contains(name)) {
        final size = await directorySize(e.path);
        out.add(CleanupItem(
          name: '$name/',
          path: e.path,
          size: formatBytes(size),
          safety: SafetyLevel.safe,
          action: 'Clean',
        ));
        continue; // do not descend into an artifact folder
      }
      await _findArtifacts(e, depth - 1, out);
    }
  }

  // -------------------------------------------------------------------
  // Cleanup candidates for the Dashboard (temp + downloads)
  // -------------------------------------------------------------------

  static Future<List<CleanupItem>> scanCleanupCandidates() async {
    final items = <CleanupItem>[];
    final localAppData = Platform.environment['LOCALAPPDATA'];
    final userProfile = Platform.environment['USERPROFILE'];

    if (localAppData != null) {
      final temp = Directory(join(localAppData, 'Temp'));
      if (temp.existsSync()) {
        final size = await directorySize(temp.path);
        items.add(CleanupItem(
          name: 'Temp Files',
          path: temp.path,
          size: formatBytes(size),
          safety: SafetyLevel.review,
          action: 'Review',
        ));
      }
    }
    if (userProfile != null) {
      final downloads = Directory(join(userProfile, 'Downloads'));
      if (downloads.existsSync()) {
        final size = await directorySize(downloads.path);
        items.add(CleanupItem(
          name: 'Downloads Folder',
          path: downloads.path,
          size: formatBytes(size),
          safety: SafetyLevel.review,
          action: 'Review',
        ));
      }
    }
    // System-protected store: always present, never actionable.
    items.add(const CleanupItem(
      name: 'Windows Component Store',
      path: r'C:\Windows\WinSxS',
      size: 'â€”',
      safety: SafetyLevel.locked,
      action: null,
    ));
    return items;
  }

  // -------------------------------------------------------------------
  // Large files (>100 MB) in user folders
  // -------------------------------------------------------------------

  static Future<List<LargeFile>> scanLargeFiles() async {
    final userProfile = Platform.environment['USERPROFILE'];
    if (userProfile == null) return const [];
    final roots = ['Downloads', 'Documents', 'Desktop', 'Videos']
        .map((d) => Directory(join(userProfile, d)))
        .where((d) => d.existsSync())
        .toList();

    final found = <LargeFile>[];
    for (final root in roots) {
      await _findLargeFiles(root, 4, found);
    }
    found.sort((a, b) => _bytesOf(b.size).compareTo(_bytesOf(a.size)));
    return found;
  }

  static Future<void> _findLargeFiles(
    Directory dir,
    int depth,
    List<LargeFile> out,
  ) async {
    if (depth <= 0) return;
    Stream<FileSystemEntity> entities;
    try {
      entities = dir.list(followLinks: false);
    } catch (_) {
      return;
    }
    await for (final e in entities) {
      try {
        if (e is Directory) {
          await _findLargeFiles(e, depth - 1, out);
        } else if (e is File) {
          final len = e.lengthSync();
          if (len >= _largeFileThreshold) {
            out.add(LargeFile(
              name: e.uri.pathSegments.where((s) => s.isNotEmpty).last,
              path: e.path,
              size: formatBytes(len),
              safety: SafetyLevel.review,
              action: 'Archive',
            ));
          }
        }
      } catch (_) {/* locked / access denied â€” skip */}
    }
  }

  // -------------------------------------------------------------------
  // Actions â€” Recycle Bin (safe & reversible) / Explorer reveal
  // -------------------------------------------------------------------

  static Future<void> recyclePath(String path) async {
    try {
      final isDir = FileSystemEntity.isDirectorySync(path);
      final escaped = path.replaceAll("'", "''");
      final method = isDir ? 'DeleteDirectory' : 'DeleteFile';
      final cmd = "Add-Type -AssemblyName Microsoft.VisualBasic; "
          "[Microsoft.VisualBasic.FileIO.FileSystem]::$method("
          "'$escaped', 'OnlyErrorDialogs', 'SendToRecycleBin')";
      await Process.run(
        'powershell',
        ['-NoProfile', '-Command', cmd],
        runInShell: true,
      );
    } catch (_) {/* best-effort */}
  }

  static Future<void> revealInExplorer(String path) async {
    try {
      final target = FileSystemEntity.isDirectorySync(path)
          ? path
          : Directory(path).parent.path;
      await Process.run('explorer', [target], runInShell: true);
    } catch (_) {}
  }

  // -------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------

  /// `path.join` equivalent without pulling in package:path.
  static String join(String a, String b) =>
      a.endsWith('\\') ? '$a$b' : '$a\\$b';

  static Future<int> directorySize(String path) async {
    var total = 0;
    Stream<FileSystemEntity> entities;
    try {
      entities = Directory(path).list(recursive: true, followLinks: false);
    } catch (_) {
      return 0;
    }
    await for (final e in entities) {
      try {
        if (e is File) total += e.lengthSync();
      } catch (_) {}
    }
    return total;
  }

  static String formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = 0;
    var v = bytes.toDouble();
    while (v >= 1024 && i < units.length - 1) {
      v /= 1024;
      i++;
    }
    return i >= 3
        ? '${v.toStringAsFixed(1)} ${units[i]}'
        : '${v.round()} ${units[i]}';
  }

  static int _bytesOf(String human) {
    final parts = human.split(' ');
    if (parts.length != 2) return 0;
    const order = {'B': 0, 'KB': 1, 'MB': 2, 'GB': 3, 'TB': 4};
    var v = double.tryParse(parts[0]) ?? 0;
    for (var i = 0; i < (order[parts[1]] ?? 0); i++) {
      v *= 1024;
    }
    return v.round();
  }
}
