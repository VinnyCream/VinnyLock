import 'package:flutter/material.dart';
import 'package:vinnylock/domain/entities/device_state.dart';
import 'package:vinnylock/l10n/ltext.dart';
import 'package:vinnylock/l10n/tx.dart';

/// Hỏi người dùng muốn đặt PIN hay hình vẽ. Trả null nếu đóng hộp thoại.
Future<CodeKind?> pickCodeKind(BuildContext context) {
  return showDialog<CodeKind>(
    context: context,
    builder: (BuildContext context) {
      return SimpleDialog(
        title: Text(context.tr(Tx.pickCodeKindTitle)),
        children: <Widget>[
          ListTile(
            leading: const Icon(Icons.pin_outlined),
            title: Text(context.tr(Tx.codePin)),
            onTap: () => Navigator.of(context).pop(CodeKind.pin),
          ),
          ListTile(
            leading: const Icon(Icons.pattern),
            title: Text(context.tr(Tx.codePattern)),
            onTap: () => Navigator.of(context).pop(CodeKind.pattern),
          ),
        ],
      );
    },
  );
}
