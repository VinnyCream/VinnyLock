import 'package:flutter/material.dart';
import 'package:vinnylock/app/theme/tokens.dart';
import 'package:vinnylock/domain/entities/app_entry.dart';
import 'package:vinnylock/domain/entities/device_state.dart';
import 'package:vinnylock/domain/entities/lock_config.dart';
import 'package:vinnylock/l10n/ltext.dart';
import 'package:vinnylock/l10n/tx.dart';
import 'package:vinnylock/presentation/apps/app_icon.dart';
import 'package:vinnylock/presentation/apps/apps_view_model.dart';
import 'package:vinnylock/presentation/common/choice_labels.dart';
import 'package:vinnylock/presentation/common/status_ui.dart';

/// Mở bảng chỉnh riêng một ứng dụng: bottom sheet trên màn hình hẹp, hộp thoại trên màn hình rộng.
Future<void> showAppPolicy(
  BuildContext context, {
  required AppsViewModel viewModel,
  required String package,
}) {
  final wide = MediaQuery.sizeOf(context).width >= Layout.compactMax;
  Widget content() => AppPolicyContent(viewModel: viewModel, package: package);
  if (wide) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480, maxHeight: 640),
            child: content(),
          ),
        );
      },
    );
  }
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (BuildContext context) => content(),
  );
}

class AppPolicyContent extends StatelessWidget {
  const AppPolicyContent({super.key, required this.viewModel, required this.package});

  final AppsViewModel viewModel;
  final String package;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (BuildContext context, Widget? _) {
        final entry = viewModel.entryOf(package);
        if (entry == null) return const SizedBox.shrink();
        return _Body(viewModel: viewModel, entry: entry);
      },
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.viewModel, required this.entry});

  final AppsViewModel viewModel;
  final AppEntry entry;

  static const List<AuthMode> _modes = <AuthMode>[
    AuthMode.biometricOnly,
    AuthMode.codeOnly,
    AuthMode.both,
    AuthMode.either,
  ];

  @override
  Widget build(BuildContext context) {
    final package = entry.app.package;
    final policy = viewModel.policyOf(package);
    final session = viewModel.session;
    final device = session.device;
    final effective = session.config.effectiveFor(package);
    final text = Theme.of(context).textTheme;
    final usesBiometric = effective.mode != AuthMode.codeOnly;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        Space.xl,
        Space.sm,
        Space.xl,
        Space.xl + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              AppIcon(package: package, label: entry.app.label, loader: viewModel.loadIcon),
              const SizedBox(width: Space.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(entry.app.label, style: text.titleLarge, maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: Space.xs),
                    StatusLabel(status: entry.status),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.lg),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(context.tr(Tx.sheetLockToggle)),
            value: policy.enabled,
            onChanged: (bool value) => _toggle(context, value),
          ),
          const Divider(),
          const SizedBox(height: Space.lg),
          _SectionTitle(context.tr(Tx.unlockMethod)),
          Wrap(
            spacing: Space.sm,
            runSpacing: Space.sm,
            children: <Widget>[
              ChoiceChip(
                label: Text(context.tr(Tx.useDefault)),
                selected: policy.mode == null,
                onSelected: (_) => _setMode(null),
              ),
              for (final mode in _modes)
                ChoiceChip(
                  label: Text(context.tr(authModeLabel(mode))),
                  selected: policy.mode == mode,
                  onSelected: (_) => _setMode(mode),
                ),
            ],
          ),
          if (usesBiometric && !device.biometricAvailable) ...<Widget>[
            const SizedBox(height: Space.sm),
            Text(
              context.tr(Tx.biometricUnavailable),
              style: text.bodySmall?.copyWith(color: context.palette.attention),
            ),
          ],
          if (effective.mode == AuthMode.both) ...<Widget>[
            const SizedBox(height: Space.lg),
            _SectionTitle(context.tr(Tx.orderTitle)),
            Wrap(
              spacing: Space.sm,
              runSpacing: Space.sm,
              children: <Widget>[
                ChoiceChip(
                  label: Text(context.tr(Tx.useDefault)),
                  selected: policy.order == null,
                  onSelected: (_) => _setOrder(null),
                ),
                for (final order in AuthOrder.values)
                  ChoiceChip(
                    label: Text(context.tr(authOrderLabel(order))),
                    selected: policy.order == order,
                    onSelected: (_) => _setOrder(order),
                  ),
              ],
            ),
          ],
          const SizedBox(height: Space.lg),
          _SectionTitle(context.tr(Tx.relockTitle)),
          Wrap(
            spacing: Space.sm,
            runSpacing: Space.sm,
            children: <Widget>[
              ChoiceChip(
                label: Text(context.tr(Tx.useDefault)),
                selected: policy.relock == null,
                onSelected: (_) => _setRelock(null),
              ),
              for (final id in kRelockIds)
                ChoiceChip(
                  label: Text(_relockText(context, id)),
                  selected: policy.relock != null && relockToId(policy.relock!) == id,
                  onSelected: (_) => _setRelock(relockFromId(id)),
                ),
            ],
          ),
          const SizedBox(height: Space.lg),
          _SectionTitle(context.tr(Tx.ownCodeTitle)),
          Text(
            context.tr(device.hasOwnCode(entry.app.package) ? Tx.ownCodeSet : Tx.ownCodeNone),
            style: text.bodyMedium?.copyWith(color: context.palette.muted),
          ),
          const SizedBox(height: Space.sm),
          Wrap(
            spacing: Space.sm,
            runSpacing: Space.sm,
            children: <Widget>[
              OutlinedButton(
                onPressed: () => _setOwnCode(context, CodeKind.pin),
                child: Text(context.tr(Tx.setOwnPin)),
              ),
              OutlinedButton(
                onPressed: () => _setOwnCode(context, CodeKind.pattern),
                child: Text(context.tr(Tx.setOwnPattern)),
              ),
              if (device.hasOwnCode(entry.app.package))
                TextButton(
                  onPressed: () => session.clearAppCode(entry.app.package),
                  child: Text(context.tr(Tx.removeOwnCode)),
                ),
            ],
          ),
          const SizedBox(height: Space.lg),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(context.tr(Tx.allowRecoveryTitle)),
            subtitle: Text(context.tr(Tx.allowRecoveryBody)),
            value: policy.allowRecovery,
            onChanged: (bool value) {
              viewModel.updatePolicy(entry.app.package, (AppPolicy p) => p.copyWith(allowRecovery: value));
            },
          ),
        ],
      ),
    );
  }

  String _relockText(BuildContext context, String id) {
    final (LText label, Map<String, Object>? args) = relockLabel(id);
    return context.tr(label, args);
  }

  Future<void> _toggle(BuildContext context, bool value) async {
    final result = await viewModel.setLocked(entry.app.package, locked: value);
    if (result == ToggleResult.needMainCode && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr(Tx.needMainCode))),
      );
    }
  }

  void _setMode(AuthMode? mode) {
    viewModel.updatePolicy(entry.app.package, (AppPolicy p) => p.copyWith(mode: mode));
  }

  void _setOrder(AuthOrder? order) {
    viewModel.updatePolicy(entry.app.package, (AppPolicy p) => p.copyWith(order: order));
  }

  void _setRelock(RelockRule? rule) {
    viewModel.updatePolicy(entry.app.package, (AppPolicy p) => p.copyWith(relock: rule));
  }

  Future<void> _setOwnCode(BuildContext context, CodeKind kind) async {
    final ok = await viewModel.session.setAppCode(entry.app.package, kind);
    if (!context.mounted) return;
    final message = ok ? Tx.codeSaved : Tx.codeCancelled;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr(message))));
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.sm),
      child: Text(text, style: Theme.of(context).textTheme.labelLarge),
    );
  }
}
