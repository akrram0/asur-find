// asur-find — Safe Deep Cleaning Utility
//
// macOS-native dashboard UI (macos_ui) targeting Windows desktop.
// Strict Swiss Brutalism/Minimalism: hairline separators, high contrast,
// uppercase micro-labels, tabular numerals, zero Material widgets.

import 'package:flutter/cupertino.dart';
import 'package:macos_ui/macos_ui.dart';

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
          return SidebarItems(
            scrollController: scrollController,
            currentIndex: _selectedIndex,
            onChanged: (index) => setState(() => _selectedIndex = index),
            items: [
              const SidebarItem(label: Text('Library'), section: true),
              for (final (:label, :icon) in _navItems)
                SidebarItem(
                  leading: MacosIcon(icon, size: 16),
                  label: Text(label),
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
// (Placeholder views removed — all sidebar destinations are implemented.)
// ---------------------------------------------------------------------------
