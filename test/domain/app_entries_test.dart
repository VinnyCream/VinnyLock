import 'package:flutter_test/flutter_test.dart';
import 'package:vinnylock/domain/entities/app_entry.dart';
import 'package:vinnylock/domain/entities/device_state.dart';
import 'package:vinnylock/domain/entities/lock_config.dart';
import 'package:vinnylock/domain/usecases/app_entries.dart';

void main() {
  const apps = <InstalledApp>[
    InstalledApp(package: 'com.z.zalo', label: 'Zalo'),
    InstalledApp(package: 'com.a.maytinh', label: 'Máy tính'),
    InstalledApp(package: 'com.g.gallery', label: 'Thư viện ảnh'),
  ];

  final config = LockConfig.initial
      .upsertApp(const AppPolicy(package: 'com.g.gallery', enabled: true, mode: AuthMode.biometricOnly))
      .upsertApp(const AppPolicy(package: 'com.z.zalo', enabled: true, mode: AuthMode.codeOnly));
  const device = DeviceState(ownCodePackages: <String>{'com.z.zalo'});

  List<AppEntry> build() => buildAppEntries(apps: apps, config: config, device: device);

  test('sắp xếp theo tên không phân biệt dấu', () {
    final labels = build().map((AppEntry e) => e.app.label).toList();
    expect(labels, <String>['Máy tính', 'Thư viện ảnh', 'Zalo']);
  });

  test('phân loại trạng thái theo cấu hình', () {
    final byPackage = {for (final e in build()) e.app.package: e.status};
    expect(byPackage['com.g.gallery'], LockStatus.biometric);
    expect(byPackage['com.z.zalo'], LockStatus.ownCode);
    expect(byPackage['com.a.maytinh'], LockStatus.none);
  });

  test('tìm không dấu và nhiều từ theo thứ tự bất kỳ', () {
    expect(filterAppEntries(build(), query: 'may tinh').single.app.package, 'com.a.maytinh');
    expect(filterAppEntries(build(), query: 'anh thu').single.app.package, 'com.g.gallery');
  });

  test('bộ lọc đã khóa và chưa khóa', () {
    expect(filterAppEntries(build(), filter: AppFilter.locked), hasLength(2));
    expect(filterAppEntries(build(), filter: AppFilter.unlocked), hasLength(1));
  });
}
