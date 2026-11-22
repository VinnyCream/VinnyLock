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
            bottomNavigationBar: NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (int i) => setState(() => _index = i),
              destinations: <Widget>[
                for (final d in _destinations)
                  NavigationDestination(
                    icon: Icon(d.icon),
                    selectedIcon: Icon(d.selectedIcon),
                    label: context.tr(d.label),
                  ),
              ],
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
