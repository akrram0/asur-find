// Dev Clutter view — rebuildable development artifacts.

import 'package:flutter/cupertino.dart';
import 'package:macos_ui/macos_ui.dart';

import 'data.dart';

class DevClutterView extends StatelessWidget {
  const DevClutterView({super.key, required this.scrollController});

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final typography = MacosTheme.of(context).typography;

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      children: [
        Text('Dev Clutter', style: typography.title2),
        const SizedBox(height: 2),
        Text(
          'Build artifacts that can be regenerated on demand',
          style: typography.body.copyWith(color: CupertinoColors.systemGrey),
        ),

        const SizedBox(height: 24),

        const _SectionLabel('REBUILDABLE ARTIFACTS'),
        const SizedBox(height: 8),
        ...kDevClutterCategories.map(_ClutterRow.new),
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

class _ClutterRow extends StatelessWidget {
  const _ClutterRow(this.item);

  final CleanupItem item;

  Color get _dotColor => switch (item.safety) {
        SafetyLevel.safe => kGreen,
        SafetyLevel.review => kOrange,
        SafetyLevel.locked => kGrayMid,
      };

  @override
  Widget build(BuildContext context) {
    final typography = MacosTheme.of(context).typography;

    return Container(
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
          PushButton(
            controlSize: ControlSize.small,
            color: kBlue,
            onPressed: () {}, // TODO: invoke backend clean
            child: Text(
              item.action!,
              style: typography.caption1.copyWith(color: CupertinoColors.white),
            ),
          ),
        ],
      ),
    );
  }
}
