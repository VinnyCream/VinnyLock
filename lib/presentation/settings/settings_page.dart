import 'package:flutter/material.dart';
import 'package:vinnylock/app/theme/tokens.dart';
import 'package:vinnylock/domain/usecases/presets.dart';
import 'package:vinnylock/l10n/ltext.dart';
import 'package:vinnylock/l10n/tx.dart';
import 'package:vinnylock/presentation/common/content_width.dart';
import 'package:vinnylock/presentation/common/state_views.dart';
import 'package:vinnylock/presentation/settings/setting_actions.dart';
import 'package:vinnylock/presentation/settings/setting_tile.dart';
import 'package:vinnylock/presentation/settings/settings_registry.dart';
import 'package:vinnylock/presentation/shell/session_view_model.dart';

/// Chiều rộng tối thiểu để chia hai khung (danh sách nhóm bên trái, chi tiết bên phải).
const double _twoPaneMinWidth = 720;

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.session});

  final SessionViewModel session;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _query = '';
  SettingGroup _selected = SettingGroup.lock;

  SessionViewModel get _session => widget.session;

  void _onAction(SettingAction action) => runSettingAction(context, _session, action);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _session,
      builder: (BuildContext context, Widget? _) {
        return Scaffold(
          appBar: AppBar(title: Text(context.tr(Tx.settingsTitle))),
          body: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              if (constraints.maxWidth >= _twoPaneMinWidth) return _twoPane(context);
              return _singlePane(context);
            },
          ),
        );
      },
    );
  }

  Widget _singlePane(BuildContext context) {
    return ContentWidth(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(Space.lg, 0, Space.lg, Space.xl),
        children: <Widget>[
          _SearchBox(onChanged: (String v) => setState(() => _query = v)),
          const SizedBox(height: Space.lg),
          if (_query.trim().isEmpty) ...<Widget>[
            _CodeHero(session: _session, onAction: _onAction),
            const SizedBox(height: Space.lg),
            _PresetCard(session: _session),
            const SizedBox(height: Space.lg),
            for (final group in SettingGroup.values) ...<Widget>[
              _GroupTile(
                group: group,
                selected: false,
                onTap: () => Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (BuildContext c) => _GroupPage(
                      session: _session,
                      group: group,
                      onAction: (SettingAction a) => runSettingAction(c, _session, a),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: Space.sm),
            ],
          ] else
            ..._results(context),
        ],
      ),
    );
  }

  Widget _twoPane(BuildContext context) {
    return Row(
      children: <Widget>[
        SizedBox(
          width: 340,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(Space.lg, 0, Space.lg, Space.xl),
            children: <Widget>[
              _SearchBox(onChanged: (String v) => setState(() => _query = v)),
              const SizedBox(height: Space.lg),
              for (final group in SettingGroup.values) ...<Widget>[
                _GroupTile(
                  group: group,
                  selected: _query.trim().isEmpty && group == _selected,
                  onTap: () => setState(() {
                    _selected = group;
                    _query = '';
                  }),
                ),
                const SizedBox(height: Space.sm),
              ],
            ],
          ),
        ),
        const VerticalDivider(),
        Expanded(
          child: ContentWidth(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(Space.lg, 0, Space.lg, Space.xl),
              children: _query.trim().isEmpty
                  ? <Widget>[
                      if (_selected == SettingGroup.lock) ...<Widget>[
                        _CodeHero(session: _session, onAction: _onAction),
                        const SizedBox(height: Space.lg),
                        _PresetCard(session: _session),
                        const SizedBox(height: Space.lg),
                      ],
                      _GroupBody(session: _session, group: _selected, onAction: _onAction),
                    ]
                  : _results(context),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _results(BuildContext context) {
    final found = searchSettings(kSettings, _query)
        .where((SettingDef d) => d.isVisible(_session.config))
        .toList();
    if (found.isEmpty) {
      return <Widget>[
        SizedBox(height: 240, child: EmptyView(message: context.tr(Tx.noSettingResults))),
      ];
    }
    return <Widget>[
      _Surface(
        children: <Widget>[
          for (final def in found)
            SettingTile(
              key: ValueKey<String>(def.id),
              def: def,
              session: _session,
              onAction: _onAction,
            ),
        ],
      ),
    ];
  }
}

class _SearchBox extends StatelessWidget {
  const _SearchBox({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: context.tr(Tx.searchSettings),
        prefixIcon: const Icon(Icons.search),
      ),
    );
  }
}

class _GroupTile extends StatelessWidget {
  const _GroupTile({required this.group, required this.selected, required this.onTap});

  final SettingGroup group;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final info = kGroupInfo[group]!;
    final p = context.palette;
    return Material(
      color: selected ? p.brandContainer : p.surface,
      borderRadius: BorderRadius.circular(Corner.large),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        selected: selected,
        selectedColor: p.onBrandContainer,
        minVerticalPadding: Space.md,
        leading: DecoratedBox(
          decoration: BoxDecoration(
            color: selected ? p.surface : p.brandContainer,
            borderRadius: BorderRadius.circular(Corner.medium),
          ),
          child: SizedBox.square(
            dimension: 44,
            child: Icon(info.icon, color: p.onBrandContainer),
          ),
        ),
        title: Text(context.tr(info.title)),
        subtitle: Text(context.tr(info.subtitle)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _GroupPage extends StatelessWidget {
  const _GroupPage({required this.session, required this.group, required this.onAction});

  final SessionViewModel session;
  final SettingGroup group;
  final ValueChanged<SettingAction> onAction;

  @override
  Widget build(BuildContext context) {
    final info = kGroupInfo[group]!;
    return Scaffold(
      appBar: AppBar(title: Text(context.tr(info.title))),
      body: ContentWidth(
        child: ListenableBuilder(
          listenable: session,
          builder: (BuildContext context, Widget? _) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(Space.lg, 0, Space.lg, Space.xl),
              children: <Widget>[_GroupBody(session: session, group: group, onAction: onAction)],
            );
          },
        ),
      ),
    );
  }
}

class _GroupBody extends StatelessWidget {
  const _GroupBody({required this.session, required this.group, required this.onAction});

  final SessionViewModel session;
  final SettingGroup group;
  final ValueChanged<SettingAction> onAction;

  @override
  Widget build(BuildContext context) {
    final defs = kSettings
        .where((SettingDef d) => d.group == group && d.isVisible(session.config))
        .toList();
    return _Surface(
      children: <Widget>[
        for (final def in defs)
          SettingTile(key: ValueKey<String>(def.id), def: def, session: session, onAction: onAction),
      ],
    );
  }
}

/// Khối nền cho một nhóm mục, ngăn cách bằng đường kẻ mảnh thay vì thẻ lồng thẻ.
class _Surface extends StatelessWidget {
  const _Surface({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.palette.surface,
      borderRadius: BorderRadius.circular(Corner.large),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: <Widget>[
          for (var i = 0; i < children.length; i++) ...<Widget>[
            if (i > 0) const Divider(indent: Space.lg, endIndent: Space.lg),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _PresetCard extends StatelessWidget {
  const _PresetCard({required this.session});

  final SessionViewModel session;

  static const List<(SecurityPreset, LText, LText)> _items = <(SecurityPreset, LText, LText)>[
    (SecurityPreset.light, Tx.presetLight, Tx.presetLightDesc),
    (SecurityPreset.balanced, Tx.presetBalanced, Tx.presetBalancedDesc),
    (SecurityPreset.strong, Tx.presetStrong, Tx.presetStrongDesc),
  ];

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Material(
      color: context.palette.surface,
      borderRadius: BorderRadius.circular(Corner.large),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Space.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(context.tr(Tx.presetsTitle), style: text.titleMedium),
                  const SizedBox(height: Space.xs),
                  Text(
                    context.tr(Tx.presetsBody),
                    style: text.bodyMedium?.copyWith(color: context.palette.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Space.sm),
            for (final (SecurityPreset preset, LText name, LText desc) in _items)
              ListTile(
                title: Text(context.tr(name)),
                subtitle: Text(context.tr(desc)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  await session.update((c) => applyPreset(c, preset));
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(context.tr(Tx.presetApplied))),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

/// Thẻ nổi đầu trang Cài đặt: hành động quan trọng nhất là đổi hoặc đặt mã chung.
class _CodeHero extends StatelessWidget {
  const _CodeHero({required this.session, required this.onAction});

  final SessionViewModel session;
  final ValueChanged<SettingAction> onAction;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final has = session.device.hasMainCode;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: p.brand,
        borderRadius: BorderRadius.circular(Corner.large),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Space.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(Icons.lock_outline, color: p.onBrand, size: 32),
            const SizedBox(height: Space.md),
            Text(
              context.tr(has ? Tx.settingsHeroTitle : Tx.riskNoCodeTitle),
              style: text.titleLarge?.copyWith(color: p.onBrand),
            ),
            const SizedBox(height: Space.xs),
            Text(
              context.tr(has ? Tx.settingsHeroBody : Tx.riskNoCodeBody),
              style: text.bodyMedium?.copyWith(color: p.onBrand),
            ),
            const SizedBox(height: Space.lg),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: p.onBrand,
                foregroundColor: p.brand,
                shape: const StadiumBorder(),
              ),
              onPressed: () => onAction(SettingAction.changeMainCode),
              child: Text(context.tr(has ? Tx.settingsHeroAction : Tx.riskNoCodeAction)),
            ),
          ],
        ),
      ),
    );
  }
}
