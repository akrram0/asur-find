// Settings view — macOS-native toggles in Swiss-labeled sections.

import 'package:flutter/cupertino.dart';
import 'package:macos_ui/macos_ui.dart';

import 'data.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key, required this.scrollController});

  final ScrollController scrollController;

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  late final Map<String, bool> _toggleState = {
    for (final t in [...kScanningSettings, ...kSafetySettings])
      t.label: t.defaultValue,
    kProtectedSettingLabel: true, // locked, always on
  };

  static const String kProtectedSettingLabel = 'Protect Windows internals';

  @override
  Widget build(BuildContext context) {
    final typography = MacosTheme.of(context).typography;

    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      children: [
        Text('Settings', style: typography.title2),
        const SizedBox(height: 2),
        Text(
          'Scanning and safety preferences',
          style: typography.body.copyWith(color: CupertinoColors.systemGrey),
        ),

        const SizedBox(height: 24),

        const _SectionLabel('SCANNING'),
        const SizedBox(height: 8),
        ...kScanningSettings.map((t) => _buildToggleRow(context, t)),

        const SizedBox(height: 16),

        const _SectionLabel('SAFETY'),
        const SizedBox(height: 8),
        ...kSafetySettings.map((t) => _buildToggleRow(context, t)),

        // Locked system protection — same disabled treatment as protected rows.
        Opacity(
          opacity: 0.55,
          child: IgnorePointer(
            child: _buildToggleRow(
              context,
              const SettingsToggle(
                label: kProtectedSettingLabel,
                description: 'Managed by policy. Always enabled.',
                defaultValue: true,
              ),
              locked: true,
            ),
          ),
        ),

        const SizedBox(height: 16),

        const _SectionLabel('ABOUT'),
        const SizedBox(height: 8),
        Text(
          'asur-find $kAppVersion',
          style: typography.caption1.copyWith(
            color: CupertinoColors.systemGrey,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }

  Widget _buildToggleRow(
    BuildContext context,
    SettingsToggle toggle, {
    bool locked = false,
  }) {
    final typography = MacosTheme.of(context).typography;

    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: kGrayLight)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (locked) ...[
                      const MacosIcon(CupertinoIcons.lock, size: 12),
                      const SizedBox(width: 6),
                    ],
                    Text(toggle.label, style: typography.body),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  toggle.description,
                  style: typography.caption1.copyWith(
                    color: CupertinoColors.systemGrey,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          MacosSwitch(
            value: _toggleState[toggle.label] ?? false,
            onChanged:
                locked ? null : (v) => setState(() => _toggleState[toggle.label] = v),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: MacosTheme.of(context).typography.caption1.copyWith(
            letterSpacing: 1.4,
            fontWeight: FontWeight.w600,
            color: CupertinoColors.systemGrey,
          ),
    );
  }
}
