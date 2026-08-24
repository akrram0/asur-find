// Mock data & domain models for the asur-find dashboard.

// Scoped so this stays a pure data module while resolving palette colors.
import 'package:flutter/cupertino.dart' show Color;

/// Safety semantics for cleanup candidates.
enum SafetyLevel { safe, review, locked }

class CleanupItem {
  const CleanupItem({
    required this.name,
    required this.path,
    required this.size,
    required this.safety,
    required this.action,
  });

  final String name;
  final String path;
  final String size;
  final SafetyLevel safety;
  final String? action; // null when locked
}

const List<CleanupItem> kCleanupItems = [
  CleanupItem(
    name: 'node_modules/',
    path: r'C:\Projects\api-server',
    size: '6.2 GB',
    safety: SafetyLevel.safe,
    action: 'Clean',
  ),
  CleanupItem(
    name: 'target/',
    path: r'C:\Projects\asur-find\src-tauri',
    size: '4.7 GB',
    safety: SafetyLevel.safe,
    action: 'Clean',
  ),
  CleanupItem(
    name: 'Temp Files',
    path: r'%LOCALAPPDATA%\Temp',
    size: '2.9 GB',
    safety: SafetyLevel.review,
    action: 'Review',
  ),
  CleanupItem(
    name: 'Old Installers',
    path: r'C:\Users\Neweye\Downloads',
    size: '12.4 GB',
    safety: SafetyLevel.review,
    action: 'Archive',
  ),
  CleanupItem(
    name: 'Windows Component Store',
    path: r'C:\Windows\WinSxS',
    size: '9.1 GB',
    safety: SafetyLevel.locked,
    action: null,
  ),
];

// Swiss palette — solid fills, no gradients.
const Color kOrange = Color(0xFFF79009); // needs review
const Color kBlue = Color(0xFF1570EF); // actionable / accent
const Color kGreen = Color(0xFF12B76A); // safe to clean
const Color kGrayDark = Color(0xFF98A2B3);
const Color kGrayMid = Color(0xFFD0D5DD);
const Color kGrayLight = Color(0xFFEAECF0);
const Color kInkSubtle = Color(0xFF344054);

// ---------------------------------------------------------------------------
// Dev Clutter view
// ---------------------------------------------------------------------------

/// Rebuildable dev artifacts reuse [CleanupItem] — identical shape.
const List<CleanupItem> kDevClutterCategories = [
  CleanupItem(
    name: 'node_modules/',
    path: r'C:\Projects\api-server',
    size: '6.2 GB',
    safety: SafetyLevel.safe,
    action: 'Clean',
  ),
  CleanupItem(
    name: 'target/',
    path: r'C:\Projects\asur-find\src-tauri',
    size: '4.7 GB',
    safety: SafetyLevel.safe,
    action: 'Clean',
  ),
  CleanupItem(
    name: '.next/',
    path: r'C:\Projects\dashboard-web',
    size: '1.8 GB',
    safety: SafetyLevel.safe,
    action: 'Clean',
  ),
  CleanupItem(
    name: 'dist/',
    path: r'C:\Projects\sdk-js',
    size: '312 MB',
    safety: SafetyLevel.safe,
    action: 'Clean',
  ),
  CleanupItem(
    name: 'Cargo build cache',
    path: r'%USERPROFILE%\.cargo\registry',
    size: '8.9 GB',
    safety: SafetyLevel.review,
    action: 'Review',
  ),
];

// ---------------------------------------------------------------------------
// Large Files view
// ---------------------------------------------------------------------------

class LargeFile {
  const LargeFile({
    required this.name,
    required this.path,
    required this.size,
    required this.safety,
    required this.action,
  });

  final String name;
  final String path;
  final String size;
  final SafetyLevel safety;
  final String? action; // null when locked
}

const List<LargeFile> kLargeFiles = [
  LargeFile(
    name: 'windows11_24h2.iso',
    path: r'C:\Users\Neweye\Downloads',
    size: '5.7 GB',
    safety: SafetyLevel.review,
    action: 'Archive',
  ),
  LargeFile(
    name: 'backup_2026-07.pst',
    path: r'C:\Users\Neweye\Documents\Outlook Files',
    size: '3.4 GB',
    safety: SafetyLevel.review,
    action: 'Review',
  ),
  LargeFile(
    name: 'docker_desktop_data.vhdx',
    path: r'%LOCALAPPDATA%\Docker\wsl\data\ext4.vhdx',
    size: '18.2 GB',
    safety: SafetyLevel.review,
    action: 'Review',
  ),
  LargeFile(
    name: 'pagefile.sys',
    path: r'C:\',
    size: '8.0 GB',
    safety: SafetyLevel.locked,
    action: null,
  ),
];

// ---------------------------------------------------------------------------
// Settings view
// ---------------------------------------------------------------------------

class SettingsToggle {
  const SettingsToggle({
    required this.label,
    required this.description,
    this.defaultValue = false,
  });

  final String label;
  final String description;
  final bool defaultValue;
}

const List<SettingsToggle> kScanningSettings = [
  SettingsToggle(
    label: 'Rescan on launch',
    description: 'Index storage automatically when the app opens.',
    defaultValue: true,
  ),
  SettingsToggle(
    label: 'Watch dev folders',
    description: 'Live-track node_modules and target/ directories.',
  ),
];

const List<SettingsToggle> kSafetySettings = [
  SettingsToggle(
    label: 'Confirm destructive actions',
    description: 'Ask before emptying the recycle bin.',
    defaultValue: true,
  ),
  SettingsToggle(
    label: 'Exclude system paths',
    description: r'Never propose cleaning inside C:\Windows.',
    defaultValue: true,
  ),
];

const String kAppVersion = '0.1.0';
