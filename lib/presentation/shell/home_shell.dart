import 'package:flutter/material.dart';
import 'package:vinnylock/app/theme/tokens.dart';
import 'package:vinnylock/l10n/ltext.dart';
import 'package:vinnylock/l10n/tx.dart';
import 'package:vinnylock/presentation/apps/apps_page.dart';
import 'package:vinnylock/presentation/apps/apps_view_model.dart';
import 'package:vinnylock/presentation/common/content_width.dart';
import 'package:vinnylock/presentation/guide/guide_page.dart';
import 'package:vinnylock/presentation/settings/settings_page.dart';
import 'package:vinnylock/presentation/shell/session_view_model.dart';

/// Một đích điều hướng. Cả thanh dưới lẫn thanh bên dùng chung danh sách này.
class _Destination {
  const _Destination(this.label, this.icon, this.selectedIcon);

  final LText label;
  final IconData icon;
  final IconData selectedIcon;
}

const List<_Destination> _destinations = <_Destination>[
  _Destination(Tx.navApps, Icons.apps_outlined, Icons.apps),
  _Destination(Tx.navSettings, Icons.settings_outlined, Icons.settings),
  _Destination(Tx.navGuide, Icons.menu_book_outlined, Icons.menu_book),
];

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.session, required this.apps});

  final SessionViewModel session;
  final AppsViewModel apps;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    // IndexedStack giữ nguyên vị trí cuộn và nội dung ô tìm của từng trang khi đổi tab.
    final pages = IndexedStack(
      index: _index,
      children: <Widget>[
        AppsPage(viewModel: widget.apps),
        SettingsPage(session: widget.session),
        const GuidePage(),
      ],
    );

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final widthClass = widthClassOf(constraints.maxWidth);
        if (widthClass == WidthClass.compact) {
          return Scaffold(
            body: pages,
            bottomNavigationBar: _PillNav(
              index: _index,
              onSelected: (int i) => setState(() => _index = i),
            ),
          );
        }
        final extended = widthClass == WidthClass.expanded;
        return Scaffold(
          body: Row(
            children: <Widget>[
              SafeArea(
                child: NavigationRail(
                  extended: extended,
                  minExtendedWidth: 200,
                  selectedIndex: _index,
                  labelType: extended ? NavigationRailLabelType.none : NavigationRailLabelType.all,
                  onDestinationSelected: (int i) => setState(() => _index = i),
                  leading: const SizedBox(height: Space.lg),
                  destinations: <NavigationRailDestination>[
                    for (final d in _destinations)
                      NavigationRailDestination(
                        icon: Icon(d.icon),
                        selectedIcon: Icon(d.selectedIcon),
                        label: Text(context.tr(d.label)),
                      ),
                  ],
                ),
              ),
              const VerticalDivider(),
              Expanded(child: pages),
            ],
          ),
        );
      },
    );
  }
}


/// Thanh điều hướng dạng viên thuốc nổi cho màn hình hẹp. Mục đang chọn mở rộng
/// ra kèm chữ, các mục còn lại chỉ có biểu tượng nhưng vẫn có nhãn cho trình đọc màn hình.
class _PillNav extends StatelessWidget {
  const _PillNav({required this.index, required this.onSelected});

  final int index;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SafeArea(
      minimum: const EdgeInsets.only(bottom: Space.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Space.lg),
        child: Material(
          color: p.surface,
          elevation: 3,
          shadowColor: p.onSurface.withAlpha(90),
          shape: const StadiumBorder(),
          child: Padding(
            padding: const EdgeInsets.all(Space.xs),
            child: Row(
              children: <Widget>[
                for (var i = 0; i < _destinations.length; i++)
                  Expanded(
                    flex: i == index ? 2 : 1,
                    child: _PillItem(
                      destination: _destinations[i],
                      selected: i == index,
                      onTap: () => onSelected(i),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PillItem extends StatelessWidget {
  const _PillItem({required this.destination, required this.selected, required this.onTap});

  final _Destination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final label = context.tr(destination.label);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: selected ? p.brandContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(Corner.pill),
        child: InkWell(
          borderRadius: BorderRadius.circular(Corner.pill),
          onTap: onTap,
          child: SizedBox(
            height: 52,
            child: ExcludeSemantics(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(
                    selected ? destination.selectedIcon : destination.icon,
                    color: selected ? p.onBrandContainer : p.muted,
                  ),
                  if (selected) ...<Widget>[
                    const SizedBox(width: Space.sm),
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: p.onBrandContainer,
                            ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
