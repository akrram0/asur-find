// Cleanup candidates list: safety dot, name, Windows path, size,
// native macOS PushButton per safety level.

import 'package:flutter/cupertino.dart';
import 'package:macos_ui/macos_ui.dart';

import 'data.dart';

class CleanupDetailsList extends StatelessWidget {
  const CleanupDetailsList({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: kCleanupItems.map(_CleanupRow.new).toList(),
    );
  }
}

class _CleanupRow extends StatelessWidget {
  const _CleanupRow(this.item);

  final CleanupItem item;

  Color get _dotColor {
    switch (item.safety) {
      case SafetyLevel.safe:
        return kGreen;
      case SafetyLevel.review:
        return kOrange;
      case SafetyLevel.locked:
        return kGrayMid;
    }
  }

  Color get _actionColor {
    switch (item.safety) {
      case SafetyLevel.safe:
        return kGreen;
      case SafetyLevel.review:
        return kOrange;
      case SafetyLevel.locked:
        throw StateError('Locked items render no button');
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
            // Safety level dot
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: _dotColor,
                shape: BoxShape.circle,
              ),
            ),

            // Name + strict Windows path
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

            // Size — tabular figures
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

            // Contextual action — native PushButton or disabled Protected state
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
                  color: _actionColor,
                  onPressed: () {}, // TODO: invoke backend clean/archive
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
