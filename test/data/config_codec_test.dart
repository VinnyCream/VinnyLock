import 'package:flutter_test/flutter_test.dart';
import 'package:vinnylock/data/models/config_codec.dart';
import 'package:vinnylock/domain/entities/lock_config.dart';

void main() {
  group('ConfigCodec', () {
    test('null, rỗng và JSON hỏng đều cho cấu hình mặc định', () {
      expect(ConfigCodec.decode(null).onboardingDone, isFalse);
      expect(ConfigCodec.decode('').onboardingDone, isFalse);
      expect(ConfigCodec.decode('{không phải json').onboardingDone, isFalse);
    });

    test('mã hóa rồi giải mã giữ nguyên các ghi đè theo từng app', () {
      final config = LockConfig.initial.upsertApp(
        const AppPolicy(
          package: 'com.example.gallery',
          enabled: true,
          mode: AuthMode.both,
          allowRecovery: false,
        ),
      );
      final back = ConfigCodec.decode(ConfigCodec.encode(config));
      final app = back.apps['com.example.gallery'];
      expect(app, isNotNull);
      expect(app!.enabled, isTrue);
      expect(app.mode, AuthMode.both);
      expect(app.allowRecovery, isFalse);
    });

    test('ngưỡng sai bị kẹp về tối thiểu 5 khi file bị sửa tay', () {
      final back = ConfigCodec.decode('{"attempts":{"threshold":1}}');
      expect(back.attempts.threshold, kMinAttemptThreshold);
    });

    test('khóa lạ và kiểu sai không làm hỏng việc đọc', () {
      final back = ConfigCodec.decode('{"language":42,"apps":"x","zzz":1}');
      expect(back.apps, isEmpty);
    });
  });
}
