import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:vinnylock/app/container.dart';
import 'package:vinnylock/app/theme/app_theme.dart';
import 'package:vinnylock/domain/entities/lock_config.dart';
import 'package:vinnylock/l10n/ltext.dart';
import 'package:vinnylock/l10n/tx.dart';
import 'package:vinnylock/presentation/apps/apps_view_model.dart';
import 'package:vinnylock/presentation/common/state_views.dart';
import 'package:vinnylock/presentation/setup/setup_page.dart';
import 'package:vinnylock/presentation/setup/setup_view_model.dart';
import 'package:vinnylock/presentation/shell/home_shell.dart';
import 'package:vinnylock/presentation/shell/session_view_model.dart';

const List<Locale> _supported = <Locale>[Locale('vi'), Locale('en')];

class VinnyLockApp extends StatefulWidget {
  const VinnyLockApp({super.key, required this.container});

  final AppContainer container;

  @override
  State<VinnyLockApp> createState() => _VinnyLockAppState();
}

class _VinnyLockAppState extends State<VinnyLockApp> with WidgetsBindingObserver {
  late final SessionViewModel _session;
  late final AppsViewModel _apps;
  late final SetupViewModel _setup;

  @override
  void initState() {
    super.initState();
    _session = SessionViewModel(
      configRepository: widget.container.config,
      securityRepository: widget.container.security,
    );
    _apps = AppsViewModel(session: _session, catalog: widget.container.catalog);
    _setup = SetupViewModel(_session);
    WidgetsBinding.instance.addObserver(this);
    _session.load();
    _apps.load();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Quay lại từ màn hình cài đặt của Android: đọc lại quyền Trợ năng và mã đã đặt.
    if (state == AppLifecycleState.resumed) _session.refreshDevice();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _apps.dispose();
    _setup.dispose();
    _session.dispose();
    super.dispose();
  }

  Locale? _localeOf(LanguageSetting setting) {
    switch (setting) {
      case LanguageSetting.system:
        return null;
      case LanguageSetting.vi:
        return const Locale('vi');
      case LanguageSetting.en:
        return const Locale('en');
    }
  }

  ThemeMode _themeModeOf(ThemeSetting setting) {
    switch (setting) {
      case ThemeSetting.system:
        return ThemeMode.system;
      case ThemeSetting.light:
        return ThemeMode.light;
      case ThemeSetting.dark:
        return ThemeMode.dark;
    }
  }

  /// Ngôn ngữ hệ thống không phải vi hoặc en thì dùng English.
  Locale _resolve(List<Locale>? requested, Iterable<Locale> supported) {
    for (final locale in requested ?? const <Locale>[]) {
      if (locale.languageCode == 'vi') return const Locale('vi');
      if (locale.languageCode == 'en') return const Locale('en');
    }
    return const Locale('en');
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _session,
      builder: (BuildContext context, Widget? _) {
        final config = _session.config;
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          onGenerateTitle: (BuildContext c) => c.tr(Tx.appName),
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: _themeModeOf(config.theme),
          locale: _localeOf(config.language),
          supportedLocales: _supported,
          localeListResolutionCallback: _resolve,
          localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: _home(),
        );
      },
    );
  }

  Widget _home() {
    switch (_session.status) {
      case LoadStatus.loading:
        return const Scaffold(body: LoadingView());
      case LoadStatus.failed:
        return Scaffold(body: ErrorView(onRetry: _session.load));
      case LoadStatus.ready:
        if (!_session.config.onboardingDone) return SetupPage(viewModel: _setup);
        return HomeShell(session: _session, apps: _apps);
    }
  }
}
