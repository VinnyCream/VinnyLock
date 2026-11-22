import 'package:vinnylock/core/text_fold.dart';
import 'package:vinnylock/domain/entities/app_entry.dart';
import 'package:vinnylock/domain/entities/device_state.dart';
import 'package:vinnylock/domain/entities/lock_config.dart';

/// Bộ lọc nhanh trên danh sách ứng dụng.
enum AppFilter { all, locked, biometric, mainCode, ownCode, combined, unlocked }

/// Gộp danh sách app cài trên máy với cấu hình thành các dòng hiển thị.
/// Sắp xếp theo tên (không phân biệt dấu) cho ổn định và dễ tìm.
List<AppEntry> buildAppEntries({
  required List<InstalledApp> apps,
  required LockConfig config,
  required DeviceState device,
}) {
  final entries = <AppEntry>[
    for (final app in apps)
      AppEntry(
        app: app,
        status: classifyLockStatus(
          config: config,
          package: app.package,
          hasOwnCode: device.hasOwnCode(app.package),
        ),
        enabled: config.apps[app.package]?.enabled ?? false,
        hasOwnCode: device.hasOwnCode(app.package),
      ),
  ];
  entries.sort((AppEntry a, AppEntry b) {
    return foldDiacritics(a.app.label).compareTo(foldDiacritics(b.app.label));
  });
  return entries;
}

bool _matchesFilter(AppEntry entry, AppFilter filter) {
  switch (filter) {
    case AppFilter.all:
      return true;
    case AppFilter.locked:
      return entry.status != LockStatus.none;
    case AppFilter.unlocked:
      return entry.status == LockStatus.none;
    case AppFilter.biometric:
      return entry.status == LockStatus.biometric;
    case AppFilter.mainCode:
      return entry.status == LockStatus.mainCode;
    case AppFilter.ownCode:
      return entry.status == LockStatus.ownCode;
    case AppFilter.combined:
      return entry.status == LockStatus.combined;
  }
}

/// Tìm theo tên hoặc tên gói, bỏ dấu và không phân biệt hoa thường.
/// Mọi từ trong ô tìm phải xuất hiện (thứ tự bất kỳ).
List<AppEntry> filterAppEntries(
  List<AppEntry> entries, {
  String query = '',
  AppFilter filter = AppFilter.all,
}) {
  final terms = foldDiacritics(query).split(' ').where((String t) => t.isNotEmpty).toList();
  return <AppEntry>[
    for (final entry in entries)
      if (_matchesFilter(entry, filter) && _matchesTerms(entry, terms)) entry,
  ];
}

bool _matchesTerms(AppEntry entry, List<String> terms) {
  if (terms.isEmpty) return true;
  final haystack = '${foldDiacritics(entry.app.label)} ${entry.app.package.toLowerCase()}';
  return terms.every(haystack.contains);
}
