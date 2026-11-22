import 'dart:convert';

import 'package:vinnylock/domain/entities/lock_config.dart';

/// Chuyển LockConfig qua lại với JSON. Lược đồ phải khớp bên Kotlin (LockModels.kt).
/// Đọc rất khoan dung: thiếu hoặc sai trường thì dùng giá trị mặc định,
/// để một file hỏng không bao giờ làm app không mở được.
abstract final class ConfigCodec {
  static String encode(LockConfig config) => jsonEncode(toMap(config));

  static LockConfig decode(String? raw) {
    if (raw == null || raw.isEmpty) return LockConfig.initial;
    try {
      final Object? data = jsonDecode(raw);
      if (data is Map<String, Object?>) return fromMap(data);
    } on FormatException {
      // Rơi xuống giá trị mặc định bên dưới.
    }
    return LockConfig.initial;
  }

  static Map<String, Object?> toMap(LockConfig c) {
    return <String, Object?>{
      'onboardingDone': c.onboardingDone,
      'language': c.language.wire,
      'theme': c.theme.wire,
      'allowWeakBiometric': c.allowWeakBiometric,
      'defaults': <String, Object?>{
        'mode': c.defaults.mode.wire,
        'order': c.defaults.order.wire,
        'relock': _relockToMap(c.defaults.relock),
      },
      'attempts': <String, Object?>{
        'threshold': c.attempts.threshold,
        'penaltyKind': c.attempts.penaltyKind.wire,
        'fixedSeconds': c.attempts.fixedSeconds,
        'preset': c.attempts.preset.wire,
        'scope': c.attempts.scope.wire,
        'resetAfterHours': c.attempts.resetAfterHours,
      },
      'recovery': <String, Object?>{
        'threshold': c.recovery.threshold,
        'preset': c.recovery.preset.wire,
      },
      'lockScreen': <String, Object?>{
        'hidePattern': c.lockScreen.hidePattern,
        'shuffleKeypad': c.lockScreen.shuffleKeypad,
        'vibrate': c.lockScreen.vibrate,
        'showAppName': c.lockScreen.showAppName,
      },
      'icon': <String, Object?>{
        'mode': c.icon.mode.wire,
        'disguise': c.icon.disguise.wire,
      },
      'apps': <String, Object?>{
        for (final p in c.apps.values) p.package: _appToMap(p),
      },
    };
  }

  static LockConfig fromMap(Map<String, Object?> m) {
    final defaults = _map(m['defaults']);
    final attempts = _map(m['attempts']);
    final recovery = _map(m['recovery']);
    final screen = _map(m['lockScreen']);
    final icon = _map(m['icon']);
    final appsRaw = _map(m['apps']);

    final apps = <String, AppPolicy>{};
    appsRaw.forEach((String package, Object? value) {
      apps[package] = _appFromMap(package, _map(value));
    });

    const base = LockConfig.initial;
    return LockConfig(
      onboardingDone: _bool(m['onboardingDone'], base.onboardingDone),
      language: parseWire(LanguageSetting.values, _str(m['language']), base.language),
      theme: parseWire(ThemeSetting.values, _str(m['theme']), base.theme),
      allowWeakBiometric: _bool(m['allowWeakBiometric'], base.allowWeakBiometric),
      defaults: DefaultPolicy(
        mode: parseWire(AuthMode.values, _str(defaults['mode']), base.defaults.mode),
        order: parseWire(AuthOrder.values, _str(defaults['order']), base.defaults.order),
        relock: _relockFromMap(defaults['relock']) ?? base.defaults.relock,
      ),
      attempts: AttemptPolicy(
        threshold: clampAttemptThreshold(_int(attempts['threshold'], base.attempts.threshold)),
        penaltyKind: parseWire(
          PenaltyKind.values,
          _str(attempts['penaltyKind']),
          base.attempts.penaltyKind,
        ),
        fixedSeconds: _int(attempts['fixedSeconds'], base.attempts.fixedSeconds),
        preset: parseWire(PenaltyPreset.values, _str(attempts['preset']), base.attempts.preset),
        scope: parseWire(AttemptScope.values, _str(attempts['scope']), base.attempts.scope),
        resetAfterHours: _int(attempts['resetAfterHours'], base.attempts.resetAfterHours),
      ),
      recovery: RecoveryPolicy(
        threshold: clampAttemptThreshold(_int(recovery['threshold'], base.recovery.threshold)),
        preset: parseWire(PenaltyPreset.values, _str(recovery['preset']), base.recovery.preset),
      ),
      lockScreen: LockScreenOptions(
        hidePattern: _bool(screen['hidePattern'], base.lockScreen.hidePattern),
        shuffleKeypad: _bool(screen['shuffleKeypad'], base.lockScreen.shuffleKeypad),
        vibrate: _bool(screen['vibrate'], base.lockScreen.vibrate),
        showAppName: _bool(screen['showAppName'], base.lockScreen.showAppName),
      ),
      icon: IconSettings(
        mode: parseWire(IconMode.values, _str(icon['mode']), base.icon.mode),
        disguise: parseWire(DisguiseIcon.values, _str(icon['disguise']), base.icon.disguise),
      ),
      apps: apps,
    );
  }

  static Map<String, Object?> _relockToMap(RelockRule rule) {
    return <String, Object?>{'kind': rule.kind.wire, 'seconds': rule.seconds};
  }

  static RelockRule? _relockFromMap(Object? raw) {
    final m = _map(raw);
    if (m.isEmpty) return null;
    final kind = parseWire(RelockKind.values, _str(m['kind']), RelockKind.immediate);
    final seconds = _int(m['seconds'], 60);
    return RelockRule(kind, seconds < 1 ? 1 : seconds);
  }

  static Map<String, Object?> _appToMap(AppPolicy p) {
    return <String, Object?>{
      'enabled': p.enabled,
      'mode': p.mode?.wire,
      'order': p.order?.wire,
      'relock': p.relock == null ? null : _relockToMap(p.relock!),
      'allowRecovery': p.allowRecovery,
    };
  }

  static AppPolicy _appFromMap(String package, Map<String, Object?> m) {
    final modeRaw = _str(m['mode']);
    final orderRaw = _str(m['order']);
    return AppPolicy(
      package: package,
      enabled: _bool(m['enabled'], false),
      mode: modeRaw == null ? null : parseWire(AuthMode.values, modeRaw, AuthMode.codeOnly),
      order: orderRaw == null ? null : parseWire(AuthOrder.values, orderRaw, AuthOrder.codeFirst),
      relock: _relockFromMap(m['relock']),
      allowRecovery: _bool(m['allowRecovery'], true),
    );
  }

  static Map<String, Object?> _map(Object? v) {
    if (v is Map<Object?, Object?>) {
      return <String, Object?>{
        for (final e in v.entries)
          if (e.key is String) e.key! as String: e.value,
      };
    }
    return const <String, Object?>{};
  }

  static String? _str(Object? v) => v is String ? v : null;
  static bool _bool(Object? v, bool fallback) => v is bool ? v : fallback;
  static int _int(Object? v, int fallback) => v is num ? v.toInt() : fallback;
}
