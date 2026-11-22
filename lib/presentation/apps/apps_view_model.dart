
import 'package:flutter/foundation.dart';
import 'package:vinnylock/domain/entities/app_entry.dart';
import 'package:vinnylock/domain/entities/device_state.dart';
import 'package:vinnylock/domain/entities/lock_config.dart';
import 'package:vinnylock/domain/repositories/repositories.dart';
import 'package:vinnylock/domain/usecases/app_entries.dart';
import 'package:vinnylock/presentation/shell/session_view_model.dart';

enum ToggleResult { ok, needMainCode }

/// ViewModel của trang Ứng dụng: danh sách, tìm kiếm, lọc, bật tắt khóa.
class AppsViewModel extends ChangeNotifier {
  AppsViewModel({
    required this.session,
    required AppCatalogRepository catalog,
  }) : _catalog = catalog {
    session.addListener(_onSessionChanged);
  }

  static const int _iconSizePx = 96;

  final SessionViewModel session;
  final AppCatalogRepository _catalog;

  LoadStatus _status = LoadStatus.loading;
  List<InstalledApp> _apps = const <InstalledApp>[];
  List<AppEntry> _all = const <AppEntry>[];
  List<AppEntry> _visible = const <AppEntry>[];
  String _query = '';
  AppFilter _filter = AppFilter.all;

  LoadStatus get status => _status;
  List<AppEntry> get visible => _visible;
  String get query => _query;
  AppFilter get filter => _filter;
  int get lockedCount => _all.where((AppEntry e) => e.enabled).length;

  Future<void> load() async {
    _status = LoadStatus.loading;
    notifyListeners();
    try {
      _apps = await _catalog.listApps();
      _status = LoadStatus.ready;
    } on Object {
      _status = LoadStatus.failed;
    }
    _rebuild();
    notifyListeners();
  }

  void setQuery(String value) {
    if (value == _query) return;
    _query = value;
    _rebuild();
    notifyListeners();
  }

  void setFilter(AppFilter value) {
    if (value == _filter) return;
    _filter = value;
    _rebuild();
    notifyListeners();
  }

  AppEntry? entryOf(String package) {
    for (final entry in _all) {
      if (entry.app.package == package) return entry;
    }
    return null;
  }

  AppPolicy policyOf(String package) {
    return session.config.apps[package] ?? AppPolicy(package: package);
  }

  /// Bật khóa cần có sẵn mã nếu cách mở khóa có dùng mã.
  Future<ToggleResult> setLocked(String package, {required bool locked}) async {
    if (locked && _needsCodeFirst(package)) return ToggleResult.needMainCode;
    await updatePolicy(package, (AppPolicy p) => p.copyWith(enabled: locked));
    return ToggleResult.ok;
  }

  Future<void> updatePolicy(String package, AppPolicy Function(AppPolicy) edit) {
    return session.update((LockConfig c) {
      final current = c.apps[package] ?? AppPolicy(package: package);
      return c.upsertApp(edit(current));
    });
  }

  Future<Uint8List?> loadIcon(String package) => _catalog.loadIcon(package, _iconSizePx);

  bool _needsCodeFirst(String package) {
    final mode = session.config.effectiveFor(package).mode;
    if (mode == AuthMode.biometricOnly) return false;
    final device = session.device;
    return !device.hasMainCode && !device.hasOwnCode(package);
  }

  void _onSessionChanged() {
    _rebuild();
    notifyListeners();
  }

  void _rebuild() {
    _all = buildAppEntries(
      apps: _apps,
      config: session.config,
      device: session.device,
    );
    _visible = filterAppEntries(_all, query: _query, filter: _filter);
  }

  @override
  void dispose() {
    session.removeListener(_onSessionChanged);
    super.dispose();
  }
}
