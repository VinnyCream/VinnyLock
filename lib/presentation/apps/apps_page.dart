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
import 'package:vinnylock/presentation/common/code_kind_picker.dart';
import 'package:vinnylock/presentation/common/content_width.dart';
import 'package:vinnylock/presentation/common/state_views.dart';
import 'package:vinnylock/presentation/shell/session_view_model.dart';

/// Các bộ lọc theo cách khóa, mở từ nút lọc cạnh ô tìm.
const List<AppFilter> _typeFilters = <AppFilter>[
  AppFilter.biometric,
  AppFilter.mainCode,
  AppFilter.ownCode,
  AppFilter.combined,
];

/// Ba tab chính. Bộ lọc theo cách khóa nằm ngoài ba tab này.
const List<AppFilter> _tabFilters = <AppFilter>[
  AppFilter.all,
  AppFilter.locked,
  AppFilter.unlocked,
];

String _filterLabel(BuildContext context, AppFilter filter) {
  switch (filter) {
    case AppFilter.all:
      return context.tr(Tx.filterAll);
    case AppFilter.locked:
      return context.tr(Tx.tabLocked);
    case AppFilter.unlocked:
      return context.tr(Tx.tabUnlocked);
    case AppFilter.biometric:
      return context.tr(Tx.statusBiometric);
    case AppFilter.mainCode:
      return context.tr(Tx.statusMainCode);
    case AppFilter.ownCode:
      return context.tr(Tx.statusOwnCode);
    case AppFilter.combined:
      return context.tr(Tx.statusCombined);
  }
}

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
              IconButton(
                tooltip: context.tr(Tx.legendButton),
                icon: const Icon(Icons.info_outline),
                onPressed: () => showLegend(context),
              ),
              const SizedBox(width: Space.xs),
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

  @override
  Widget build(BuildContext context) {
    final entries = viewModel.visible;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final widthClass = widthClassOf(constraints.maxWidth);
        final header = <Widget>[
          _StatusCards(viewModel: viewModel),
          Row(
            children: <Widget>[
              Expanded(child: _SearchField(viewModel: viewModel)),
              const SizedBox(width: Space.sm),
              _FilterButton(viewModel: viewModel),
            ],
          ),
          const SizedBox(height: Space.md),
          _Tabs(viewModel: viewModel),
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
                      mainAxisExtent: 84,
                      mainAxisSpacing: Space.sm,
                      crossAxisSpacing: Space.sm,
                    ),
                    itemCount: entries.length,
                    itemBuilder: (BuildContext c, int i) => _tile(c, entries[i]),
                  ),
                // Chừa chỗ cho thanh điều hướng nổi ở dưới.
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
          await _offerMainCode(context, viewModel.session);
        }
      },
    );
  }
}

/// Khi chưa có mã chung: giải thích ngắn rồi cho đặt ngay, không bắt người dùng đi tìm.
Future<void> _offerMainCode(BuildContext context, SessionViewModel session) async {
  final go = await showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(context.tr(Tx.riskNoCodeTitle)),
        content: Text(context.tr(Tx.needMainCode)),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.tr(Tx.cancel)),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.tr(Tx.riskNoCodeAction)),
          ),
        ],
      );
    },
  );
  if (go != true || !context.mounted) return;
  final kind = await pickCodeKind(context);
  if (kind == null) return;
  await session.setMainCode(kind);
}

class _StatusCards extends StatelessWidget {
  const _StatusCards({required this.viewModel});

  final AppsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final session = viewModel.session;
    final device = session.device;
    final cards = <Widget>[
      if (!device.hasMainCode)
        _RiskCard(
          title: Tx.riskNoCodeTitle,
          body: Tx.riskNoCodeBody,
          action: Tx.riskNoCodeAction,
          onAction: () => _offerMainCodeDirect(context, session),
        ),
      if (!device.accessibilityEnabled)
        _RiskCard(
          title: Tx.a11yBannerTitle,
          body: Tx.a11yBannerBody,
          action: Tx.a11yBannerAction,
          onAction: session.openAccessibilitySettings,
        ),
      if (device.hasMainCode && device.accessibilityEnabled)
        _OkCard(viewModel: viewModel),
    ];
    return Column(
      children: <Widget>[
        for (final card in cards)
          Padding(padding: const EdgeInsets.only(bottom: Space.md), child: card),
      ],
    );
  }

  Future<void> _offerMainCodeDirect(BuildContext context, SessionViewModel session) async {
    final kind = await pickCodeKind(context);
    if (kind == null) return;
    await session.setMainCode(kind);
  }
}

/// Thẻ cảnh báo: màu hổ phách kèm biểu tượng và chữ, không chỉ dựa vào màu.
class _RiskCard extends StatelessWidget {
  const _RiskCard({
    required this.title,
    required this.body,
    required this.action,
    required this.onAction,
  });

  final LText title;
  final LText body;
  final LText action;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: p.attentionContainer,
        borderRadius: BorderRadius.circular(Corner.large),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Space.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.warning_amber_rounded, color: p.onAttentionContainer),
                const SizedBox(width: Space.sm),
                Expanded(
                  child: Text(
                    context.tr(title),
                    style: text.titleMedium?.copyWith(color: p.onAttentionContainer),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Space.sm),
            Text(
              context.tr(body),
              style: text.bodyMedium?.copyWith(color: p.onAttentionContainer),
            ),
            const SizedBox(height: Space.md),
            FilledButton(onPressed: onAction, child: Text(context.tr(action))),
          ],
        ),
      ),
    );
  }
}

/// Thẻ trạng thái tốt, kèm lối vào lời khuyên cho ứng dụng ngân hàng.
class _OkCard extends StatelessWidget {
  const _OkCard({required this.viewModel});

  final AppsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final locked = viewModel.lockedCount;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: p.brandContainer,
        borderRadius: BorderRadius.circular(Corner.large),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Space.lg, Space.lg, Space.sm, Space.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.verified_user_outlined, color: p.onBrandContainer),
                const SizedBox(width: Space.sm),
                Expanded(
                  child: Text(
                    context.tr(locked > 0 ? Tx.protectedTitle : Tx.readyTitle),
                    style: text.titleMedium?.copyWith(color: p.onBrandContainer),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Space.xs),
            Padding(
              padding: const EdgeInsets.only(right: Space.md),
              child: Text(
                locked > 0
                    ? context.tr(Tx.protectedBody, <String, Object>{'n': locked})
                    : context.tr(Tx.readyBody),
                style: text.bodyMedium?.copyWith(color: p.onBrandContainer),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                style: TextButton.styleFrom(foregroundColor: p.onBrandContainer),
                onPressed: () => _showBankAdvice(context, viewModel.session),
                child: Text(context.tr(Tx.bankTitle)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showBankAdvice(BuildContext context, SessionViewModel session) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(context.tr(Tx.bankTitle)),
          content: SingleChildScrollView(child: Text(context.tr(Tx.bankBody))),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(context.tr(Tx.close)),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                session.openAccessibilitySettings();
              },
              child: Text(context.tr(Tx.bankAction)),
            ),
          ],
        );
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
      onChanged: (String v) {
        widget.viewModel.setQuery(v);
        setState(() {});
      },
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

/// Nút tròn mở bảng lọc theo cách khóa. Sáng lên khi đang lọc.
class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.viewModel});

  final AppsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final active = _typeFilters.contains(viewModel.filter);
    return Material(
      color: active ? p.brand : p.surface,
      shape: CircleBorder(side: BorderSide(color: active ? p.brand : p.statusNone)),
      child: IconButton(
        tooltip: context.tr(Tx.filterButton),
        constraints: const BoxConstraints.tightFor(width: 56, height: 56),
        icon: Icon(Icons.tune, color: active ? p.onBrand : p.onSurface),
        onPressed: () => _open(context),
      ),
    );
  }

  Future<void> _open(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      constraints: const BoxConstraints(maxWidth: 560),
      builder: (BuildContext sheetContext) {
        return ListenableBuilder(
          listenable: viewModel,
          builder: (BuildContext context, Widget? _) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(Space.xl, 0, Space.xl, Space.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(context.tr(Tx.filterButton), style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: Space.lg),
                  Wrap(
                    spacing: Space.sm,
                    runSpacing: Space.sm,
                    children: <Widget>[
                      for (final filter in _typeFilters)
                        ChoiceChip(
                          label: Text(_filterLabel(context, filter)),
                          selected: viewModel.filter == filter,
                          onSelected: (bool on) {
                            viewModel.setFilter(on ? filter : AppFilter.all);
                            Navigator.of(sheetContext).pop();
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: Space.lg),
                  TextButton(
                    onPressed: () {
                      viewModel.setFilter(AppFilter.all);
                      Navigator.of(sheetContext).pop();
                    },
                    child: Text(context.tr(Tx.filterClear)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

/// Ba tab dạng viên thuốc: Tất cả, Đang khóa, Chưa khóa.
class _Tabs extends StatelessWidget {
  const _Tabs({required this.viewModel});

  final AppsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: p.tone,
        borderRadius: BorderRadius.circular(Corner.pill),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Space.xs),
        child: Row(
          children: <Widget>[
            for (final filter in _tabFilters)
              Expanded(
                child: _Tab(
                  label: _filterLabel(context, filter),
                  selected: viewModel.filter == filter,
                  onTap: () => viewModel.setFilter(filter),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: selected ? p.surface : Colors.transparent,
        borderRadius: BorderRadius.circular(Corner.pill),
        child: InkWell(
          borderRadius: BorderRadius.circular(Corner.pill),
          onTap: onTap,
          child: SizedBox(
            height: Layout.minTarget,
            child: Center(
              child: ExcludeSemantics(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: selected ? p.brand : p.muted,
                      ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
