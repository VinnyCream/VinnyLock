import 'package:flutter/material.dart';
import 'package:vinnylock/app/theme/tokens.dart';
import 'package:vinnylock/domain/entities/app_entry.dart';
import 'package:vinnylock/l10n/ltext.dart';
import 'package:vinnylock/l10n/tx.dart';
import 'package:vinnylock/presentation/common/content_width.dart';
import 'package:vinnylock/presentation/common/state_views.dart';
import 'package:vinnylock/presentation/common/status_ui.dart';
import 'package:vinnylock/presentation/settings/settings_registry.dart';

/// Trang giải thích từng tính năng. Nội dung lấy từ cùng danh mục với trang Cài đặt
/// nên hai nơi không bao giờ lệch nhau.
class GuidePage extends StatefulWidget {
  const GuidePage({super.key});

  @override
  State<GuidePage> createState() => _GuidePageState();
}

class _GuidePageState extends State<GuidePage> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    final found = searchSettings(kSettings, _query);
    final searching = _query.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr(Tx.guideTitle))),
      body: ContentWidth(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(Space.lg, 0, Space.lg, Space.xxl),
          children: <Widget>[
            TextField(
              onChanged: (String v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: context.tr(Tx.guideSearch),
                prefixIcon: const Icon(Icons.search),
              ),
            ),
            const SizedBox(height: Space.lg),
            if (!searching) ...<Widget>[
              Text(
                context.tr(Tx.guideIntro),
                style: text.bodyMedium?.copyWith(color: p.muted),
              ),
              const SizedBox(height: Space.xl),
              Text(context.tr(Tx.legendTitle), style: text.titleLarge),
              const SizedBox(height: Space.sm),
              for (final status in LockStatus.values)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: Space.sm),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(top: Space.xs),
                        child: StatusMark(status: status, size: 16),
                      ),
                      const SizedBox(width: Space.md),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            children: <InlineSpan>[
                              TextSpan(
                                text: '${context.tr(status.label)}. ',
                                style: text.labelLarge,
                              ),
                              TextSpan(text: context.tr(status.description)),
                            ],
                          ),
                          style: text.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: Space.xl),
            ],
            if (searching && found.isEmpty)
              SizedBox(height: 240, child: EmptyView(message: context.tr(Tx.noSettingResults)))
            else
              for (final group in SettingGroup.values)
                ..._section(context, group, found.where((SettingDef d) => d.group == group).toList()),
            if (!searching) ...<Widget>[
              const SizedBox(height: Space.lg),
              Text(context.tr(Tx.guidePrivacyTitle), style: text.titleLarge),
              const SizedBox(height: Space.sm),
              Text(context.tr(Tx.guidePrivacyBody), style: text.bodyLarge),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _section(BuildContext context, SettingGroup group, List<SettingDef> defs) {
    if (defs.isEmpty) return const <Widget>[];
    final text = Theme.of(context).textTheme;
    final info = kGroupInfo[group]!;
    return <Widget>[
      Padding(
        padding: const EdgeInsets.only(top: Space.lg, bottom: Space.sm),
        child: Row(
          children: <Widget>[
            Icon(info.icon, color: context.palette.brand),
            const SizedBox(width: Space.sm),
            Text(context.tr(info.title), style: text.titleLarge),
          ],
        ),
      ),
      for (final def in defs)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: Space.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(context.tr(def.title), style: text.titleMedium),
              const SizedBox(height: Space.xs),
              Text(
                context.tr(def.summary),
                style: text.bodyMedium?.copyWith(color: context.palette.muted),
              ),
            ],
          ),
        ),
    ];
  }
}
