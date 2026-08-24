// Large Files view — REAL scanned files >100 MB.

import 'package:flutter/cupertino.dart';
import 'package:macos_ui/macos_ui.dart';

import 'app_state.dart';
import 'confirm.dart';
import 'data.dart';
import 'scanner.dart';

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
          'Files larger than 100 MB in your user folders',
          style: typography.body.copyWith(color: CupertinoColors.systemGrey),
        ),

        const SizedBox(height: 24),

        const _SectionLabel('TOP CONSUMERS'),
        const SizedBox(height: 8),
        ListenableBuilder(
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
            if (appState.largeFiles.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('No files above 100 MB found.'),
              );
            }
            return Column(
              children: [
                for (final file in appState.largeFiles)
                  _LargeFileRow(file: file),
              ],
            );
          },
        ),
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
  const _LargeFileRow({required this.file});

  final LargeFile file;

  Future<void> _archive(BuildContext context) async {
    final confirmed = await confirmAction(
      context,
      title: 'Move to Recycle Bin?',
      message:
          '${file.name} (${file.size}) will be moved to the Recycle Bin. '
          'You can restore it later from there.',
      confirmLabel: 'Archive',
      confirmColor: kOrange,
    );
    if (confirmed) await appState.archive(file);
  }

  @override
  Widget build(BuildContext context) {
    final typography = MacosTheme.of(context).typography;

    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: kGrayLight)),
      ),
      child: Row(
        children: [
          const MacosIcon(CupertinoIcons.doc_text, size: 16),
          const SizedBox(width: 8),
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
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Row(
              children: [
                PushButton(
                  controlSize: ControlSize.small,
                  onPressed: () =>
                      StorageScanner.revealInExplorer(file.path),
                  child: Text('Review', style: typography.caption1),
                ),
                const SizedBox(width: 8),
                PushButton(
                  controlSize: ControlSize.small,
                  color: kOrange,
                  onPressed: () => _archive(context),
                  child: Text(
                    'Archive',
                    style: typography.caption1.copyWith(
                      color: CupertinoColors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

