// Dashboard view: header, treemap visualization, cleanup details list.

import 'package:flutter/cupertino.dart';
import 'package:macos_ui/macos_ui.dart';

import 'data.dart';
import 'details_list.dart';
import 'treemap.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key, required this.scrollController});

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final typography = MacosTheme.of(context).typography;

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      children: [
        // ---- Header ----
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Dashboard', style: typography.title2),
                const SizedBox(height: 2),
                Text(
                  'Storage overview for this PC',
                  style: typography.body.copyWith(
                    color: CupertinoColors.systemGrey,
                  ),
                ),
              ],
            ),
            PushButton(
              controlSize: ControlSize.large,
              color: kBlue,
              onPressed: () {}, // TODO: invoke backend rescan
              child: Text(
                'Rescan',
                style: typography.body.copyWith(color: CupertinoColors.white),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // ---- Storage composition treemap ----
        const _SectionLabel('STORAGE COMPOSITION'),
        const SizedBox(height: 8),
        const StorageTreemap(),

        const SizedBox(height: 24),

        // ---- Details list ----
        const _SectionLabel('DETAILS'),
        const SizedBox(height: 8),
        const CleanupDetailsList(),
      ],
    );
  }
}

/// Swiss micro-label: uppercase, wide tracking, muted.
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
