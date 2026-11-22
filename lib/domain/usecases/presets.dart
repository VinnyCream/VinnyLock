import 'package:vinnylock/domain/entities/lock_config.dart';

/// Ba mức cài đặt nhanh cho người không muốn tự chỉnh từng mục.
/// Áp dụng xong vẫn chỉnh tiếp được từng mục trong Cài đặt.
enum SecurityPreset { light, balanced, strong }

LockConfig applyPreset(LockConfig config, SecurityPreset preset) {
  switch (preset) {
    case SecurityPreset.light:
      return config.copyWith(
        defaults: const DefaultPolicy(
          mode: AuthMode.biometricOnly,
          relock: RelockRule(RelockKind.afterSeconds, 60),
        ),
        attempts: config.attempts.copyWith(
          threshold: 8,
          penaltyKind: PenaltyKind.fixed,
          fixedSeconds: 30,
        ),
      );
    case SecurityPreset.balanced:
      return config.copyWith(
        defaults: const DefaultPolicy(),
        attempts: config.attempts.copyWith(
          threshold: kMinAttemptThreshold,
          penaltyKind: PenaltyKind.escalating,
          preset: PenaltyPreset.standard,
        ),
      );
    case SecurityPreset.strong:
      return config.copyWith(
        defaults: const DefaultPolicy(
          mode: AuthMode.both,
          order: AuthOrder.codeFirst,
        ),
        attempts: config.attempts.copyWith(
          threshold: kMinAttemptThreshold,
          penaltyKind: PenaltyKind.escalating,
          preset: PenaltyPreset.strict,
          scope: AttemptScope.all,
        ),
        lockScreen: config.lockScreen.copyWith(shuffleKeypad: true, hidePattern: true),
      );
  }
}
