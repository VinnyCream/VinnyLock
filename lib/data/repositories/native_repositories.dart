import 'dart:async';
import 'dart:typed_data';

import 'package:vinnylock/data/models/config_codec.dart';
import 'package:vinnylock/data/native/native_call.dart';
import 'package:vinnylock/domain/entities/device_state.dart';
import 'package:vinnylock/domain/entities/lock_config.dart';
import 'package:vinnylock/domain/repositories/repositories.dart';

class NativeConfigRepository implements ConfigRepository {
  NativeConfigRepository(this._call);

  final NativeCall _call;
  final StreamController<LockConfig> _changes = StreamController<LockConfig>.broadcast();

  @override
  Stream<LockConfig> get changes => _changes.stream;

  @override
  Future<LockConfig> load() async {
    final raw = await _call(NativeMethod.loadConfig);
    return ConfigCodec.decode(raw is String ? raw : null);
  }

  @override
  Future<void> save(LockConfig config) async {
    await _call(NativeMethod.saveConfig, <String, Object?>{
      'json': ConfigCodec.encode(config),
    });
    _changes.add(config);
  }
}

class NativeAppCatalogRepository implements AppCatalogRepository {
  NativeAppCatalogRepository(this._call);

  final NativeCall _call;
  final Map<String, Uint8List?> _iconCache = <String, Uint8List?>{};

  @override
  Future<List<InstalledApp>> listApps() async {
    final raw = await _call(NativeMethod.listApps);
    if (raw is! List<Object?>) return const <InstalledApp>[];
    final apps = <InstalledApp>[];
    for (final item in raw) {
      if (item is! Map<Object?, Object?>) continue;
      final package = item['package'];
      final label = item['label'];
      if (package is String && label is String) {
        apps.add(InstalledApp(package: package, label: label));
      }
    }
    return apps;
  }

  @override
  Future<Uint8List?> loadIcon(String package, int sizePx) async {
    final key = '$package@$sizePx';
    if (_iconCache.containsKey(key)) return _iconCache[key];
    final raw = await _call(NativeMethod.loadIcon, <String, Object?>{
      'package': package,
      'size': sizePx,
    });
    final bytes = raw is Uint8List ? raw : null;
    _iconCache[key] = bytes;
    return bytes;
  }
}

class NativeSecurityRepository implements SecurityRepository {
  NativeSecurityRepository(this._call);

  final NativeCall _call;

  @override
  Future<DeviceState> loadState() async {
    final raw = await _call(NativeMethod.loadState);
    if (raw is! Map<Object?, Object?>) return DeviceState.empty;
    final kindRaw = raw['mainCodeKind'];
    final owned = raw['ownCodePackages'];
    final question = raw['recoveryQuestion'];
    return DeviceState(
      hasMainCode: raw['hasMainCode'] == true,
      mainCodeKind: kindRaw is String ? parseWire(CodeKind.values, kindRaw, CodeKind.pin) : null,
      hasRecovery: raw['hasRecovery'] == true,
      recoveryQuestion: question is String ? question : null,
      accessibilityEnabled: raw['accessibilityEnabled'] == true,
      biometricAvailable: raw['biometricAvailable'] == true,
      ownCodePackages: owned is List<Object?>
          ? <String>{for (final p in owned) if (p is String) p}
          : const <String>{},
    );
  }

  @override
  Future<bool> setMainCode(CodeKind kind) async {
    final ok = await _call(NativeMethod.setMainCode, <String, Object?>{'kind': kind.wire});
    return ok == true;
  }

  @override
  Future<bool> setAppCode(String package, CodeKind kind) async {
    final ok = await _call(NativeMethod.setAppCode, <String, Object?>{
      'package': package,
      'kind': kind.wire,
    });
    return ok == true;
  }

  @override
  Future<void> clearAppCode(String package) async {
    await _call(NativeMethod.clearAppCode, <String, Object?>{'package': package});
  }

  @override
  Future<bool> setRecovery({required String question, required String answer}) async {
    final ok = await _call(NativeMethod.setRecovery, <String, Object?>{
      'question': question,
      'answer': answer,
    });
    return ok == true;
  }

  @override
  Future<void> applyIconMode(IconSettings icon) async {
    await _call(NativeMethod.applyIconMode, <String, Object?>{
      'mode': icon.mode.wire,
      'disguise': icon.disguise.wire,
    });
  }

  @override
  Future<void> openAccessibilitySettings() async {
    await _call(NativeMethod.openAccessibilitySettings);
  }

  @override
  Future<void> openAppInfo() async {
    await _call(NativeMethod.openAppInfo);
  }
}
