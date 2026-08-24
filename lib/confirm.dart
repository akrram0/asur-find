// Safe confirmation dialog — native macOS alert before destructive actions.

import 'package:flutter/cupertino.dart';
import 'package:macos_ui/macos_ui.dart';

/// Shows a native macOS alert and returns true if the user confirmed.
Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  required Color confirmColor,
}) async {
  final res = await showMacosAlertDialog<bool>(
    context: context,
    builder: (context) => MacosAlertDialog(
      appIcon: const MacosIcon(
        CupertinoIcons.exclamationmark_shield,
        size: 40,
      ),
      title: Text(title, style: MacosTheme.of(context).typography.headline),
      message: Text(
        message,
        textAlign: TextAlign.center,
        style: MacosTheme.of(context).typography.body.copyWith(
              color: CupertinoColors.systemGrey,
            ),
      ),
      primaryButton: PushButton(
        controlSize: ControlSize.large,
        color: confirmColor,
        onPressed: () => Navigator.of(context).pop(true),
        child: Text(
          confirmLabel,
          style: const TextStyle(color: CupertinoColors.white),
        ),
      ),
      secondaryButton: PushButton(
        controlSize: ControlSize.large,
        onPressed: () => Navigator.of(context).pop(false),
        child: const Text('Cancel'),
      ),
    ),
  );
  return res ?? false;
}
