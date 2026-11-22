import 'package:flutter/material.dart';
import 'package:vinnylock/app/theme/tokens.dart';
import 'package:vinnylock/domain/entities/app_entry.dart';
import 'package:vinnylock/domain/usecases/app_entries.dart';
import 'package:vinnylock/l10n/ltext.dart';
import 'package:vinnylock/l10n/tx.dart';
import 'package:vinnylock/presentation/apps/app_policy_sheet.dart';
import 'package:vinnylock/presentation/apps/app_tile.dart';
import 'package:vinnylock/presentation/apps/apps_view_model.dart';
import 'package:vinnylock/presentation/apps/legend_sheet.dart';
import 'package:vinnylock/presentation/common/content_width.dart';
import 'package:vinnylock/presentation/common/state_views.dart';
import 'package:vinnylock/presentation/shell/session_view_model.dart';

class AppsPage extends StatelessWidget {
  const AppsPage({super.key, required this.viewModel});

  final AppsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (BuildContext context, Widget? _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(context.tr(Tx.navApps)),
            actions: <Widget>[
              TextButton.icon(
                onPressed: () => showLegend(context),
                icon: const Icon(Icons.info_outline),
                label: Text(context.tr(Tx.legendButton)),
              ),
              const SizedBox(width: Space.sm),
            ],
          ),
          body: _buildBody(context),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context) {
    switch (viewModel.status) {
      case LoadStatus.loading:
        return const LoadingView();
      case LoadStatus.failed:
        return ErrorView(onRetry: viewModel.load);
      case LoadStatus.ready:
        return _Ready(viewModel: viewModel);
    }
  }
}

class _Ready extends StatelessWidget {
  const _Ready({required this.viewModel});

  final AppsViewModel viewModel;

  static const List<AppFilter> _filters = <AppFilter>[
    AppFilter.all,
    AppFilter.locked,
    AppFilter.biometric,
    AppFilter.mainCode,
    AppFilter.ownCode,
    AppFilter.combined,
    AppFilter.unlocked,
  ];

  @override
  Widget build(BuildContext context) {
    final session = viewModel.session;
    final entries = viewModel.visible;
    final showBanner = !session.device.accessibilityEnabled;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final widthClass = widthClassOf(constraints.maxWidth);
        final header = <Widget>[
          if (showBanner)
            Padding(
              padding: const EdgeInsets.only(bottom: Space.md),
              child: _AccessibilityBanner(onOpen: session.openAccessibilitySettings),
            ),
          _SearchField(viewModel: viewModel),
          const SizedBox(height: Space.md),
          _FilterRow(viewModel: viewModel, filters: _filters),
          const SizedBox(height: Space.sm),
          Text(
            context.tr(Tx.lockedSummary, <String, Object>{'n': viewModel.lockedCount}),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.palette.muted),
          ),
          const SizedBox(height: Space.md),
        ];

        return ContentWidth(
          maxWidth: widthClass == WidthClass.compact ? Layout.contentMaxWidth : 1040,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.lg),
            child: CustomScrollView(
              slivers: <Widget>[
                SliverList(delegate: SliverChildListDelegate(header)),
                if (entries.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyView(message: context.tr(Tx.noApps)),
                  )
                else if (widthClass == WidthClass.compact)
                  SliverList.separated(
                    itemCount: entries.length,
                    separatorBuilder: (BuildContext c, int i) => const SizedBox(height: Space.sm),
                    itemBuilder: (BuildContext c, int i) => _tile(c, entries[i]),
                  )
                else
                  SliverGrid.builder(
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 480,
                      mainAxisExtent: 76,
                      mainAxisSpacing: Space.sm,
                      crossAxisSpacing: Space.sm,
                    ),
                    itemCount: entries.length,
                    itemBuilder: (BuildContext c, int i) => _tile(c, entries[i]),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: Space.xl)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _tile(BuildContext context, AppEntry entry) {
    return AppTile(
      key: ValueKey<String>(entry.app.package),
      entry: entry,
      iconLoader: viewModel.loadIcon,
      onOpen: () => showAppPolicy(context, viewModel: viewModel, package: entry.app.package),
      onToggle: (bool value) async {
        final result = await viewModel.setLocked(entry.app.package, locked: value);
        if (result == ToggleResult.needMainCode && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.tr(Tx.needMainCode))),
          );
        }
      },
    );
  }
}

class _SearchField extends StatefulWidget {
  const _SearchField({required this.viewModel});

  final AppsViewModel viewModel;

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.viewModel.query);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      textInputAction: TextInputAction.search,
      onChanged: widget.viewModel.setQuery,
      decoration: InputDecoration(
        hintText: context.tr(Tx.searchApps),
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: context.tr(Tx.clearSearch),
                icon: const Icon(Icons.close),
                onPressed: () {
                  _controller.clear();
                  widget.viewModel.setQuery('');
                  setState(() {});
                },
              ),
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({required this.viewModel, required this.filters});

  final AppsViewModel viewModel;
  final List<AppFilter> filters;

  String _label(BuildContext context, AppFilter filter) {
    switch (filter) {
      case AppFilter.all:
        return context.tr(Tx.filterAll);
      case AppFilter.locked:
        return context.tr(Tx.filterLocked);
      case AppFilter.biometric:
        return context.tr(Tx.statusBiometric);
      case AppFilter.mainCode:
        return context.tr(Tx.statusMainCode);
      case AppFilter.ownCode:
        return context.tr(Tx.statusOwnCode);
      case AppFilter.combined:
        return context.tr(Tx.statusCombined);
      case AppFilter.unlocked:
        return context.tr(Tx.statusNone);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: Layout.minTarget,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (BuildContext c, int i) => const SizedBox(width: Space.sm),
        itemBuilder: (BuildContext c, int i) {
          final filter = filters[i];
          return Center(
            child: ChoiceChip(
              label: Text(_label(c, filter)),
              selected: viewModel.filter == filter,
              onSelected: (_) => viewModel.setFilter(filter),
            ),
          );
        },
      ),
    );
  }
}

class _AccessibilityBanner extends StatelessWidget {
  const _AccessibilityBanner({required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(Corner.medium),
        border: Border.all(color: p.attention, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Space.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.warning_amber_rounded, color: p.attention),
                const SizedBox(width: Space.sm),
                Expanded(
                  child: Text(
                    context.tr(Tx.a11yBannerTitle),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Space.sm),
            Text(context.tr(Tx.a11yBannerBody), style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: Space.md),
            FilledButton(onPressed: onOpen, child: Text(context.tr(Tx.a11yBannerAction))),
          ],
        ),
      ),
    );
  }
}
