import 'package:flutter/services.dart';

/// Cổng gọi sang Android. Đặt thành một hàm để test truyền bản giả vào được.
typedef NativeCall = Future<Object?> Function(String method, [Map<String, Object?>? args]);

const String kNativeChannelName = 'com.vinnycream.vinnylock/native';

NativeCall productionNativeCall() {
  const channel = MethodChannel(kNativeChannelName);
  return (String method, [Map<String, Object?>? args]) {
    return channel.invokeMethod<Object?>(method, args);
  };
}

/// Tên lệnh dùng chung hai phía. Phải khớp ChannelHandler.kt.
abstract final class NativeMethod {
  static const loadConfig = 'loadConfig';
  static const saveConfig = 'saveConfig';
  static const loadState = 'loadState';
  static const listApps = 'listApps';
  static const loadIcon = 'loadIcon';
  static const setMainCode = 'setMainCode';
  static const setAppCode = 'setAppCode';
  static const clearAppCode = 'clearAppCode';
  static const setRecovery = 'setRecovery';
  static const applyIconMode = 'applyIconMode';
  static const openAccessibilitySettings = 'openAccessibilitySettings';
  static const openAppInfo = 'openAppInfo';
}
