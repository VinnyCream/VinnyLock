// Mô hình cấu hình của ứng dụng. Thuần Dart, không phụ thuộc Flutter hay Android.
// Cùng một lược đồ JSON với bên Kotlin (model/LockModels.kt).

/// Enum có tên gọi cố định khi lưu xuống JSON.
abstract interface class WireEnum {
  String get wire;
}

T parseWire<T extends WireEnum>(List<T> values, String? raw, T fallback) {
  for (final value in values) {
    if (value.wire == raw) return value;
  }
  return fallback;
}

/// Sàn số lần nhập sai trước khi bị phạt. Không cho đặt thấp hơn.
const int kMinAttemptThreshold = 5;
const int kMaxAttemptThreshold = 20;

int clampAttemptThreshold(int value) {
  if (value < kMinAttemptThreshold) return kMinAttemptThreshold;
  if (value > kMaxAttemptThreshold) return kMaxAttemptThreshold;
  return value;
}

enum AuthMode implements WireEnum {
  biometricOnly('biometricOnly'),
  codeOnly('codeOnly'),
  both('both'),
  either('either');

  const AuthMode(this.wire);
  @override
  final String wire;
}

enum AuthOrder implements WireEnum {
  codeFirst('codeFirst'),
  biometricFirst('biometricFirst');

  const AuthOrder(this.wire);
  @override
  final String wire;
}

enum RelockKind implements WireEnum {
  immediate('immediate'),
  screenOff('screenOff'),
  afterSeconds('afterSeconds');

  const RelockKind(this.wire);
  @override
  final String wire;
}

class RelockRule {
  const RelockRule(this.kind, [this.seconds = 60]);

  static const RelockRule immediate = RelockRule(RelockKind.immediate);
  static const RelockRule screenOff = RelockRule(RelockKind.screenOff);

  final RelockKind kind;
  final int seconds;

  @override
  bool operator ==(Object other) =>
      other is RelockRule && other.kind == kind && other.seconds == seconds;

  @override
  int get hashCode => Object.hash(kind, seconds);
}

enum PenaltyKind implements WireEnum {
  fixed('fixed'),
  escalating('escalating');

  const PenaltyKind(this.wire);
  @override
  final String wire;
}

enum PenaltyPreset implements WireEnum {
  gentle('gentle', <int>[30, 60, 120, 300, 600]),
  standard('standard', <int>[30, 60, 300, 900, 3600]),
  strict('strict', <int>[60, 300, 900, 3600, 21600]);

  const PenaltyPreset(this.wire, this.stepsSeconds);
  @override
  final String wire;

  /// Thời gian chờ ở lần sai thứ N sau khi chạm ngưỡng. Lần cuối lặp lại.
  final List<int> stepsSeconds;
}

enum AttemptScope implements WireEnum {
  app('app'),
  all('all');

  const AttemptScope(this.wire);
  @override
  final String wire;
}

class AttemptPolicy {
  const AttemptPolicy({
    this.threshold = kMinAttemptThreshold,
    this.penaltyKind = PenaltyKind.escalating,
    this.fixedSeconds = 60,
    this.preset = PenaltyPreset.standard,
    this.scope = AttemptScope.app,
    this.resetAfterHours = 24,
  });

  final int threshold;
  final PenaltyKind penaltyKind;
  final int fixedSeconds;
  final PenaltyPreset preset;
  final AttemptScope scope;
  final int resetAfterHours;

  AttemptPolicy copyWith({
    int? threshold,
    PenaltyKind? penaltyKind,
    int? fixedSeconds,
    PenaltyPreset? preset,
    AttemptScope? scope,
    int? resetAfterHours,
  }) {
    return AttemptPolicy(
      threshold: clampAttemptThreshold(threshold ?? this.threshold),
      penaltyKind: penaltyKind ?? this.penaltyKind,
      fixedSeconds: fixedSeconds ?? this.fixedSeconds,
      preset: preset ?? this.preset,
      scope: scope ?? this.scope,
      resetAfterHours: resetAfterHours ?? this.resetAfterHours,
    );
  }
}

/// Giới hạn riêng cho đường trả lời câu hỏi khôi phục (độc lập với giới hạn nhập mã).
class RecoveryPolicy {
  const RecoveryPolicy({
    this.threshold = kMinAttemptThreshold,
    this.preset = PenaltyPreset.standard,
  });

  final int threshold;
  final PenaltyPreset preset;

  RecoveryPolicy copyWith({int? threshold, PenaltyPreset? preset}) {
    return RecoveryPolicy(
      threshold: clampAttemptThreshold(threshold ?? this.threshold),
      preset: preset ?? this.preset,
    );
  }
}

class LockScreenOptions {
  const LockScreenOptions({
    this.hidePattern = false,
    this.shuffleKeypad = false,
    this.vibrate = true,
    this.showAppName = true,
  });

  final bool hidePattern;
  final bool shuffleKeypad;
  final bool vibrate;
  final bool showAppName;

  LockScreenOptions copyWith({
    bool? hidePattern,
    bool? shuffleKeypad,
    bool? vibrate,
    bool? showAppName,
  }) {
    return LockScreenOptions(
      hidePattern: hidePattern ?? this.hidePattern,
      shuffleKeypad: shuffleKeypad ?? this.shuffleKeypad,
      vibrate: vibrate ?? this.vibrate,
      showAppName: showAppName ?? this.showAppName,
    );
  }
}

enum IconMode implements WireEnum {
  normal('normal'),
  disguise('disguise'),
  hidden('hidden');

  const IconMode(this.wire);
  @override
  final String wire;
}

enum DisguiseIcon implements WireEnum {
  calculator('calculator'),
  notes('notes'),
  weather('weather');

  const DisguiseIcon(this.wire);
  @override
  final String wire;
}

class IconSettings {
  const IconSettings({
    this.mode = IconMode.normal,
    this.disguise = DisguiseIcon.calculator,
  });

  final IconMode mode;
  final DisguiseIcon disguise;

  IconSettings copyWith({IconMode? mode, DisguiseIcon? disguise}) {
    return IconSettings(
      mode: mode ?? this.mode,
      disguise: disguise ?? this.disguise,
    );
  }
}

enum LanguageSetting implements WireEnum {
  system('system'),
  vi('vi'),
  en('en');

  const LanguageSetting(this.wire);
  @override
  final String wire;
}

enum ThemeSetting implements WireEnum {
  system('system'),
  light('light'),
  dark('dark');

  const ThemeSetting(this.wire);
  @override
  final String wire;
}

/// Cách khóa mặc định, áp dụng cho ứng dụng nào không ghi đè.
class DefaultPolicy {
  const DefaultPolicy({
    this.mode = AuthMode.codeOnly,
    this.order = AuthOrder.codeFirst,
    this.relock = RelockRule.immediate,
  });

  final AuthMode mode;
  final AuthOrder order;
  final RelockRule relock;

  DefaultPolicy copyWith({AuthMode? mode, AuthOrder? order, RelockRule? relock}) {
    return DefaultPolicy(
      mode: mode ?? this.mode,
      order: order ?? this.order,
      relock: relock ?? this.relock,
    );
  }
}

const Object _keep = Object();

/// Cài đặt riêng của một ứng dụng. Trường null nghĩa là "theo mặc định".
class AppPolicy {
  const AppPolicy({
    required this.package,
    this.enabled = false,
    this.mode,
    this.order,
    this.relock,
    this.allowRecovery = true,
  });

  final String package;
  final bool enabled;
  final AuthMode? mode;
  final AuthOrder? order;
  final RelockRule? relock;
  final bool allowRecovery;

  /// Truyền null tường minh vào mode/order/relock để xóa ghi đè (về mặc định).
  AppPolicy copyWith({
    bool? enabled,
    Object? mode = _keep,
    Object? order = _keep,
    Object? relock = _keep,
    bool? allowRecovery,
  }) {
    return AppPolicy(
      package: package,
      enabled: enabled ?? this.enabled,
      mode: identical(mode, _keep) ? this.mode : mode as AuthMode?,
      order: identical(order, _keep) ? this.order : order as AuthOrder?,
      relock: identical(relock, _keep) ? this.relock : relock as RelockRule?,
      allowRecovery: allowRecovery ?? this.allowRecovery,
    );
  }
}

/// Chính sách đã gộp mặc định và ghi đè riêng.
class EffectivePolicy {
  const EffectivePolicy({
    required this.mode,
    required this.order,
    required this.relock,
    required this.allowRecovery,
  });

  final AuthMode mode;
  final AuthOrder order;
  final RelockRule relock;
  final bool allowRecovery;
}

class LockConfig {
  const LockConfig({
    this.onboardingDone = false,
    this.language = LanguageSetting.system,
    this.theme = ThemeSetting.system,
    this.allowWeakBiometric = true,
    this.defaults = const DefaultPolicy(),
    this.attempts = const AttemptPolicy(),
    this.recovery = const RecoveryPolicy(),
    this.lockScreen = const LockScreenOptions(),
    this.icon = const IconSettings(),
    this.apps = const <String, AppPolicy>{},
  });

  static const LockConfig initial = LockConfig();

  final bool onboardingDone;
  final LanguageSetting language;
  final ThemeSetting theme;
  final bool allowWeakBiometric;
  final DefaultPolicy defaults;
  final AttemptPolicy attempts;
  final RecoveryPolicy recovery;
  final LockScreenOptions lockScreen;
  final IconSettings icon;
  final Map<String, AppPolicy> apps;

  LockConfig copyWith({
    bool? onboardingDone,
    LanguageSetting? language,
    ThemeSetting? theme,
    bool? allowWeakBiometric,
    DefaultPolicy? defaults,
    AttemptPolicy? attempts,
    RecoveryPolicy? recovery,
    LockScreenOptions? lockScreen,
    IconSettings? icon,
    Map<String, AppPolicy>? apps,
  }) {
    return LockConfig(
      onboardingDone: onboardingDone ?? this.onboardingDone,
      language: language ?? this.language,
      theme: theme ?? this.theme,
      allowWeakBiometric: allowWeakBiometric ?? this.allowWeakBiometric,
      defaults: defaults ?? this.defaults,
      attempts: attempts ?? this.attempts,
      recovery: recovery ?? this.recovery,
      lockScreen: lockScreen ?? this.lockScreen,
      icon: icon ?? this.icon,
      apps: apps ?? this.apps,
    );
  }

  LockConfig upsertApp(AppPolicy policy) {
    final next = Map<String, AppPolicy>.of(apps);
    next[policy.package] = policy;
    return copyWith(apps: next);
  }

  /// Chính sách thực tế của một ứng dụng (mặc định + ghi đè riêng).
  EffectivePolicy effectiveFor(String package) {
    final own = apps[package];
    return EffectivePolicy(
      mode: own?.mode ?? defaults.mode,
      order: own?.order ?? defaults.order,
      relock: own?.relock ?? defaults.relock,
      allowRecovery: own?.allowRecovery ?? true,
    );
  }

  int get lockedCount => apps.values.where((AppPolicy p) => p.enabled).length;
}
