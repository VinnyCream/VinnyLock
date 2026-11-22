import 'package:flutter/material.dart';
import 'package:vinnylock/app/theme/tokens.dart';
import 'package:vinnylock/l10n/ltext.dart';
import 'package:vinnylock/l10n/tx.dart';
import 'package:vinnylock/presentation/settings/settings_registry.dart';
import 'package:vinnylock/presentation/shell/session_view_model.dart';

/// Vẽ một mục cài đặt theo loại điều khiển của nó.
class SettingTile extends StatelessWidget {
  const SettingTile({
    super.key,
    required this.def,
    required this.session,
    required this.onAction,
  });

  final SettingDef def;
  final SessionViewModel session;
  final ValueChanged<SettingAction> onAction;

  @override
  Widget build(BuildContext context) {
    final config = session.config;
    final title = Text(context.tr(def.title));
    final subtitle = Text(context.tr(def.summary));
    switch (def.control) {
      case final ToggleControl control:
        return SwitchListTile(
          title: title,
          subtitle: subtitle,
          value: control.read(config),
          onChanged: (bool v) => session.update((c) => control.write(c, v)),
        );
      case final ChoiceControl control:
        final current = control.read(config);
        final selected = control.options.firstWhere(
          (ChoiceOption o) => o.id == current,
          orElse: () => control.options.first,
        );
        return ListTile(
          title: title,
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              subtitle,
              const SizedBox(height: Space.xs),
              Text(
                context.tr(selected.label, selected.args),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(color: context.palette.brand),
              ),
            ],
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _pickChoice(context, control, current),
        );
      case final StepperControl control:
        final value = control.read(config);
        return ListTile(
          title: title,
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              subtitle,
              const SizedBox(height: Space.sm),
              Row(
                children: <Widget>[
                  IconButton.outlined(
                    tooltip: context.tr(Tx.decrease),
                    icon: const Icon(Icons.remove),
                    onPressed: value > control.min
                        ? () => session.update((c) => control.write(c, value - 1))
                        : null,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Space.lg),
                    child: Text(
                      context.tr(control.unit, <String, Object>{'n': value}),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  IconButton.outlined(
                    tooltip: context.tr(Tx.increase),
                    icon: const Icon(Icons.add),
                    onPressed: value < control.max
                        ? () => session.update((c) => control.write(c, value + 1))
                        : null,
                  ),
                ],
              ),
            ],
          ),
        );
      case final ActionControl control:
        return ListTile(
          title: title,
          subtitle: subtitle,
          trailing: const Icon(Icons.chevron_right),
          onTap: () => onAction(control.action),
        );
    }
  }

  Future<void> _pickChoice(BuildContext context, ChoiceControl control, String current) async {
    final picked = await showDialog<ChoiceOption>(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: Text(context.tr(def.title)),
          children: <Widget>[
            for (final option in control.options)
              ListTile(
                title: Text(context.tr(option.label, option.args)),
                trailing: option.id == current
                    ? Icon(Icons.check, color: context.palette.brand)
                    : null,
                onTap: () => Navigator.of(context).pop(option),
              ),
          ],
        );
      },
    );
    if (picked == null || picked.id == current || !context.mounted) return;

    final confirm = picked.confirm;
    if (confirm != null) {
      final accepted = await _confirm(context, confirm);
      if (!accepted) return;
    }
    await session.update((c) => control.write(c, picked.id));
  }

  Future<bool> _confirm(BuildContext context, ConfirmSpec spec) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(context.tr(spec.title)),
          content: Text(context.tr(spec.body)),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(context.tr(Tx.cancel)),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(context.tr(spec.action)),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }
}
