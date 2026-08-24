// Cleanup candidates list — REAL scanned data + safe confirmation flow.

import 'package:flutter/cupertino.dart';
import 'package:macos_ui/macos_ui.dart';

import 'app_state.dart';
import 'confirm.dart';
import 'data.dart';
import 'scanner.dart';

class CleanupDetailsList extends StatelessWidget {
  const CleanupDetailsList({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        if (appState.scanning) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                CupertinoActivityIndicator(),
                SizedBox(width: 8),
                Text('Scanning…'),
              ],
            ),
          );
        }
        if (appState.cleanupItems.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('Nothing to clean found.'),
          );
        }
        return Column(
          children: [
            for (final item in appState.cleanupItems) _CleanupRow(item: item),
          ],
        );
      },
    );
  }
}

class _CleanupRow extends StatelessWidget {
  const _CleanupRow({required this.item});

  final CleanupItem item;

  Color get _dotColor => switch (item.safety) {
        SafetyLevel.safe => kGreen,
        SafetyLevel.review => kOrange,
        SafetyLevel.locked => kGrayMid,
      };

  Future<void> _onPressed(BuildContext context) async {
    if (item.action == 'Clean') {
      final confirmed = await confirmAction(
        context,
        title: 'Move to Recycle Bin?',
        message:
            '${item.name} (${item.size}) will be moved to the Recycle Bin. '
            'You can restore it later.',
        confirmLabel: 'Clean',
        confirmColor: kGreen,
      );
      if (confirmed) await appState.clean(item);
    } else if (item.action == 'Review') {
      // Non-destructive: just reveal the folder in Explorer.
      await StorageScanner.revealInExplorer(item.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final typography = MacosTheme.of(context).typography;
    final isLocked = item.safety == SafetyLevel.locked;

    return Opacity(
      opacity: isLocked ? 0.55 : 1,
      child: Container(
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: kGrayLight)),
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: _dotColor,
                shape: BoxShape.circle,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name, style: typography.body),
                    const SizedBox(height: 2),
                    Text(
                      item.path,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: typography.caption1.copyWith(
                        color: CupertinoColors.systemGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                item.size,
                style: typography.body.copyWith(
                  color: CupertinoColors.systemGrey,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            if (isLocked)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Row(
                  children: [
                    const MacosIcon(CupertinoIcons.lock, size: 12),
                    const SizedBox(width: 4),
                    Text('Protected', style: typography.caption1),
                  ],
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: PushButton(
                  controlSize: ControlSize.small,
                  color: item.action == 'Clean' ? kGreen : kBlue,
                  onPressed: () => _onPressed(context),
                  child: Text(
                    item.action!,
                    style: typography.caption1.copyWith(
                      color: CupertinoColors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

