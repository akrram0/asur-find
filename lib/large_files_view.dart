// Large Files view — files above the size threshold.

import 'package:flutter/cupertino.dart';
import 'package:macos_ui/macos_ui.dart';

import 'data.dart';

class LargeFilesView extends StatelessWidget {
  const LargeFilesView({super.key, required this.scrollController});

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final typography = MacosTheme.of(context).typography;

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      children: [
        Text('Large Files', style: typography.title2),
        const SizedBox(height: 2),
        Text(
          'Files larger than 100 MB found on this PC',
          style: typography.body.copyWith(color: CupertinoColors.systemGrey),
        ),

        const SizedBox(height: 24),

        const _SectionLabel('TOP CONSUMERS'),
        const SizedBox(height: 8),
        ...kLargeFiles.map(_LargeFileRow.new),
      ],
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

class _LargeFileRow extends StatelessWidget {
  const _LargeFileRow(this.file);

  final LargeFile file;

  Color get _dotColor => switch (file.safety) {
        SafetyLevel.safe => kGreen,
        SafetyLevel.review => kOrange,
        SafetyLevel.locked => kGrayMid,
      };

  @override
  Widget build(BuildContext context) {
    final typography = MacosTheme.of(context).typography;
    final isLocked = file.safety == SafetyLevel.locked;

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
                    Text(file.name, style: typography.body),
                    const SizedBox(height: 2),
                    Text(
                      file.path,
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

            // Size — right-aligned fixed column for visual columnarity
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 72),
              child: Text(
                file.size,
                textAlign: TextAlign.right,
                style: typography.body.copyWith(
                  color: CupertinoColors.systemGrey,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),

            // Contextual action
            if (isLocked)
              Padding(
                padding: const EdgeInsets.only(left: 20, right: 8),
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
                padding: const EdgeInsets.only(left: 20),
                child: PushButton(
                  controlSize: ControlSize.small,
                  color: file.action == 'Archive' ? kOrange : kBlue,
                  onPressed: () {}, // TODO: invoke backend archive/review
                  child: Text(
                    file.action!,
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
