import 'package:vinnylock/data/native/native_call.dart';
import 'package:vinnylock/data/repositories/native_repositories.dart';
import 'package:vinnylock/domain/repositories/repositories.dart';

/// Nơi duy nhất lắp ráp các phụ thuộc (dependency injection thủ công).
/// Test dựng AppContainer với repository giả, không cần Android.
class AppContainer {
  const AppContainer({
    required this.config,
    required this.catalog,
    required this.security,
  });

  factory AppContainer.production() {
    final call = productionNativeCall();
    return AppContainer(
      config: NativeConfigRepository(call),
      catalog: NativeAppCatalogRepository(call),
      security: NativeSecurityRepository(call),
    );
  }

  final ConfigRepository config;
  final AppCatalogRepository catalog;
  final SecurityRepository security;
}
