import 'package:flutter/material.dart';
import 'package:vinnylock/app/theme/tokens.dart';
import 'package:vinnylock/domain/entities/app_entry.dart';
import 'package:vinnylock/l10n/ltext.dart';
import 'package:vinnylock/l10n/tx.dart';
import 'package:vinnylock/presentation/apps/app_icon.dart';
import 'package:vinnylock/presentation/common/status_ui.dart';

/// Một dòng ứng dụng: icon, tên, trạng thái và công tắc khóa.
class AppTile extends StatelessWidget {
  const AppTile({
    super.key,
    required this.entry,
    required this.iconLoader,
    required this.onToggle,
    required this.onOpen,
  });

  final AppEntry entry;
  final IconLoader iconLoader;
  final ValueChanged<bool> onToggle;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final name = entry.app.label;
    return Material(
      color: context.palette.surface,
      borderRadius: BorderRadius.circular(Corner.medium),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 72),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.lg, vertical: Space.sm),
            child: Row(
              children: <Widget>[
                AppIcon(package: entry.app.package, label: name, loader: iconLoader),
                const SizedBox(width: Space.lg),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: Space.xs),
                      StatusLabel(status: entry.status),
                    ],
                  ),
                ),
                const SizedBox(width: Space.sm),
                Semantics(
                  label: context.tr(Tx.toggleLock, <String, Object>{'name': name}),
                  child: Switch(value: entry.enabled, onChanged: onToggle),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
