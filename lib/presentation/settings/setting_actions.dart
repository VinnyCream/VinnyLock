import 'package:flutter/material.dart';
import 'package:vinnylock/app/theme/tokens.dart';
import 'package:vinnylock/l10n/ltext.dart';
import 'package:vinnylock/l10n/tx.dart';
import 'package:vinnylock/presentation/common/code_kind_picker.dart';
import 'package:vinnylock/presentation/settings/permissions_page.dart';
import 'package:vinnylock/presentation/settings/recovery_form.dart';
import 'package:vinnylock/presentation/settings/settings_registry.dart';
import 'package:vinnylock/presentation/shell/session_view_model.dart';

/// Xử lý các mục cài đặt dạng hành động (mở hộp thoại, mở trang, gọi Android).
Future<void> runSettingAction(
  BuildContext context,
  SessionViewModel session,
  SettingAction action,
) async {
  switch (action) {
    case SettingAction.changeMainCode:
      final kind = await pickCodeKind(context);
      if (kind == null || !context.mounted) return;
      final ok = await session.setMainCode(kind);
      if (!context.mounted) return;
      _snack(context, ok ? Tx.mainCodeChanged : Tx.codeCancelled);
    case SettingAction.editRecovery:
      await _showRecoveryDialog(context, session);
    case SettingAction.permissions:
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(builder: (BuildContext c) => PermissionsPage(session: session)),
      );
    case SettingAction.openAccessibility:
      await session.openAccessibilitySettings();
    case SettingAction.openAppInfo:
      await session.openAppInfo();
    case SettingAction.resetAll:
      await _confirmReset(context, session);
  }
}

void _snack(BuildContext context, LText message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr(message))));
}

Future<void> _showRecoveryDialog(BuildContext context, SessionViewModel session) {
  return showDialog<void>(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: Text(dialogContext.tr(Tx.recoveryDialogTitle)),
        scrollable: true,
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: RecoveryForm(
            initialQuestion: session.device.recoveryQuestion,
            submitLabel: Tx.save,
            onSubmit: (String question, String answer) async {
              final ok = await session.setRecovery(question: question, answer: answer);
              if (ok && dialogContext.mounted) {
                Navigator.of(dialogContext).pop();
                if (context.mounted) _snack(context, Tx.recoverySaved);
              }
              return ok;
            },
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(dialogContext.tr(Tx.cancel)),
          ),
        ],
        insetPadding: const EdgeInsets.all(Space.lg),
      );
    },
  );
}

Future<void> _confirmReset(BuildContext context, SessionViewModel session) async {
  final accepted = await showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(context.tr(Tx.resetConfirmTitle)),
        content: Text(context.tr(Tx.resetConfirmBody)),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.tr(Tx.cancel)),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.tr(Tx.resetConfirmAction)),
          ),
        ],
      );
    },
  );
  if (accepted == true) await session.resetGeneralSettings();
}
