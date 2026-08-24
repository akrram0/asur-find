// Treemap visualization: solid blocks, no gaps, text anchored top-left.

import 'package:flutter/cupertino.dart';
import 'package:macos_ui/macos_ui.dart';

import 'data.dart';

class StorageTreemap extends StatelessWidget {
  const StorageTreemap({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: 240,
        // Nested Expanded flex ratios approximate a squarified treemap.
        child: Column(
          children: [
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      color: kOrange,
                      child: const _BlockLabel(
                        label: 'Dev Clutter',
                        size: '42.8 GB',
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Expanded(
                          child: Container(
                            color: kBlue,
                            child: const _BlockLabel(
                              label: 'Large Files',
                              size: '24.1 GB',
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            color: kGrayDark,
                            child: const _BlockLabel(
                              label: 'Build Caches',
                              size: '18.4 GB',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Container(
                      color: kGrayMid,
                      child: const _BlockLabel(
                        label: 'System & Apps',
                        size: '186.0 GB',
                        darkText: true,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      color: kGrayLight,
                      child: const _BlockLabel(
                        label: 'Other',
                        size: '92.0 GB',
                        darkText: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Label anchored to the top-left of a solid block.
class _BlockLabel extends StatelessWidget {
  const _BlockLabel({
    required this.label,
    required this.size,
    this.darkText = false,
  });

  final String label;
  final String size;
  final bool darkText;

  @override
  Widget build(BuildContext context) {
    final color = darkText ? kInkSubtle : CupertinoColors.white;
    final typography = MacosTheme.of(context).typography;

    return Align(
      alignment: Alignment.topLeft,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: typography.caption1.copyWith(
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(size, style: typography.body.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}
