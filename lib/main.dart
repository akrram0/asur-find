// asur-find — Safe Deep Cleaning Utility
//
// macOS-native dashboard UI (macos_ui) targeting Windows desktop.
// Strict Swiss Brutalism/Minimalism: hairline separators, high contrast,
// uppercase micro-labels, tabular numerals, zero Material widgets.

import 'package:flutter/cupertino.dart';
import 'package:macos_ui/macos_ui.dart';

import 'app_state.dart';
import 'dashboard.dart';
import 'dev_clutter_view.dart';
import 'large_files_view.dart';
import 'settings_view.dart';

void main() {
  runApp(const AsurFindApp());
}

class AsurFindApp extends StatelessWidget {
  const AsurFindApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MacosApp(
      title: 'asur-find',
      debugShowCheckedModeBanner: false,
      theme: MacosThemeData(brightness: Brightness.light),
      home: const AsurFindWindow(),
    );
  }
}

// ---------------------------------------------------------------------------
// MacosWindow shell — translucent sidebar + content area
// ---------------------------------------------------------------------------

class AsurFindWindow extends StatefulWidget {
  const AsurFindWindow({super.key});

  @override
  State<AsurFindWindow> createState() => _AsurFindWindowState();
}

class _AsurFindWindowState extends State<AsurFindWindow> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Kick off the first real disk scan once the shell is on screen.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      appState.rescanAll();
    });
  }

  static const List<({String label, IconData icon})> _navItems = [
    (label: 'Dashboard', icon: CupertinoIcons.square_grid_2x2),
    (label: 'Dev Clutter', icon: CupertinoIcons.cube_box),
    (label: 'Large Files', icon: CupertinoIcons.doc_on_doc),
    (label: 'Settings', icon: CupertinoIcons.gear),
  ];

  @override
  Widget build(BuildContext context) {
    return MacosWindow(
      // The window shell renders the native translucent sidebar vibrancy
      // and manages the titlebar/traffic-light region on macOS chrome.
      sidebar: Sidebar(
        // Leaves room for the native traffic-light controls.
        topOffset: 38,
        minWidth: 220,
        maxWidth: 260,
        builder: (context, scrollController) {
          return Column(
            children: [
              // Real disk usage meter (live from the scanner).
              const Padding(
                padding: EdgeInsets.fromLTRB(12, 8, 12, 4),
                child: _StorageMeter(),
              ),
              Expanded(
                child: SidebarItems(
                  scrollController: scrollController,
                  currentIndex: _selectedIndex,
                  onChanged: (index) => setState(() => _selectedIndex = index),
                  items: [
                    const SidebarItem(label: Text('Library'), section: true),
                    // Explicit label colors — guarantees visibility in both
                    // selected (white on blue) and idle (dark on light) states.
                    for (final (index, (:label, :icon)) in _navItems.indexed)
                      SidebarItem(
                        leading: MacosIcon(icon, size: 16),
                        label: Text(
                          label,
                          style: TextStyle(
                            color: index == _selectedIndex
                                ? CupertinoColors.white
                                : const Color(0xFF3A3A3C),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      child: ContentArea(
        builder: (context, scrollController) => switch (_selectedIndex) {
          0 => DashboardView(scrollController: scrollController),
          1 => DevClutterView(scrollController: scrollController),
          2 => LargeFilesView(scrollController: scrollController),
          _ => SettingsView(scrollController: scrollController),
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sidebar storage meter — live disk usage from the scanner (no Material)
// ---------------------------------------------------------------------------

class _StorageMeter extends StatelessWidget {
  const _StorageMeter();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final typography = MacosTheme.of(context).typography;
        final scanning = appState.scanning;
        final fraction = appState.totalBytes <= 0
            ? 0.0
            : (appState.usedBytes / appState.totalBytes)
                .clamp(0.0, 1.0);

        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFF2F2F7),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                scanning
                    ? 'Scanning drive C:…'
                    : appState.totalBytes > 0
                        ? '${appState.usedLabel} used of ${appState.totalLabel}'
                        : 'Drive C: —',
                style: typography.caption1.copyWith(
                  color: const Color(0xFF3A3A3C),
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 6),
              // Hairline progress bar built from primitives (no Material).
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: SizedBox(
                  height: 4,
                  child: Stack(
                    children: [
                      Container(color: const Color(0xFFD1D1D6)),
                      FractionallySizedBox(
                        widthFactor: fraction,
                        child: Container(color: const Color(0xFF007AFF)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

