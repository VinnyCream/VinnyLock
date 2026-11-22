import 'package:flutter_test/flutter_test.dart';
import 'package:vinnylock/domain/entities/lock_config.dart';
import 'package:vinnylock/domain/usecases/presets.dart';

void main() {
  test('mọi mức cài nhanh đều giữ ngưỡng sai từ 5 trở lên', () {
    for (final preset in SecurityPreset.values) {
      final out = applyPreset(LockConfig.initial, preset);
      expect(out.attempts.threshold, greaterThanOrEqualTo(kMinAttemptThreshold));
    }
  });

  test('mức mạnh dùng cả mã lẫn sinh trắc, mã trước', () {
    final out = applyPreset(LockConfig.initial, SecurityPreset.strong);
    expect(out.defaults.mode, AuthMode.both);
    expect(out.defaults.order, AuthOrder.codeFirst);
    expect(out.attempts.scope, AttemptScope.all);
  });

  test('áp mức nhanh không làm mất danh sách app đã khóa', () {
    final base = LockConfig.initial.upsertApp(
      const AppPolicy(package: 'a.b', enabled: true),
    );
    final out = applyPreset(base, SecurityPreset.light);
    expect(out.apps['a.b']?.enabled, isTrue);
  });
}
