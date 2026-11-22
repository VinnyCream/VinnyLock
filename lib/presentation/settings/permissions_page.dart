import 'package:flutter/material.dart';
import 'package:vinnylock/app/theme/tokens.dart';
import 'package:vinnylock/l10n/ltext.dart';
import 'package:vinnylock/l10n/tx.dart';
import 'package:vinnylock/presentation/common/content_width.dart';
import 'package:vinnylock/presentation/shell/session_view_model.dart';

class PermissionsPage extends StatelessWidget {
  const PermissionsPage({super.key, required this.session});

  final SessionViewModel session;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: session,
      builder: (BuildContext context, Widget? _) {
        final device = session.device;
        final text = Theme.of(context).textTheme;
        return Scaffold(
          appBar: AppBar(title: Text(context.tr(Tx.permissionsTitle))),
          body: ContentWidth(
            child: ListView(
              padding: const EdgeInsets.all(Space.lg),
              children: <Widget>[
                _PermissionRow(
                  icon: Icons.accessibility_new,
                  title: context.tr(Tx.permAccessibility),
                  body: context.tr(Tx.permAccessibilityDesc),
                  on: device.accessibilityEnabled,
                  statusText: context.tr(
                    device.accessibilityEnabled ? Tx.setupAccessOn : Tx.setupAccessOff,
                  ),
                ),
                const SizedBox(height: Space.lg),
                _PermissionRow(
                  icon: Icons.fingerprint,
                  title: context.tr(Tx.permBiometric),
                  body: context.tr(Tx.permBiometricDesc),
                  on: device.biometricAvailable,
                  statusText: context.tr(
                    device.biometricAvailable ? Tx.setupAccessOn : Tx.biometricUnavailable,
                  ),
                ),
                const SizedBox(height: Space.lg),
                _PermissionRow(
                  icon: Icons.vibration,
                  title: context.tr(Tx.permVibrate),
                  body: context.tr(Tx.permVibrateDesc),
                  on: true,
                  statusText: context.tr(Tx.setupAccessOn),
                ),
                const SizedBox(height: Space.xl),
                Text(context.tr(Tx.notUsedTitle), style: text.titleMedium),
                const SizedBox(height: Space.xs),
                Text(
                  context.tr(Tx.notUsedList),
                  style: text.bodyMedium?.copyWith(color: context.palette.muted),
                ),
                const SizedBox(height: Space.xl),
                Wrap(
                  spacing: Space.sm,
                  runSpacing: Space.sm,
                  children: <Widget>[
                    FilledButton(
                      onPressed: session.openAccessibilitySettings,
                      child: Text(context.tr(Tx.a11yBannerAction)),
                    ),
                    OutlinedButton(
                      onPressed: session.openAppInfo,
                      child: Text(context.tr(Tx.openAppInfo)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PermissionRow extends StatelessWidget {
  const _PermissionRow({
    required this.icon,
    required this.title,
    required this.body,
    required this.on,
    required this.statusText,
  });

  final IconData icon;
  final String title;
  final String body;
  final bool on;
  final String statusText;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(icon, color: p.muted),
        const SizedBox(width: Space.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(title, style: text.titleMedium),
              const SizedBox(height: Space.xs),
              Text(body, style: text.bodyMedium?.copyWith(color: p.muted)),
              const SizedBox(height: Space.xs),
              Row(
                children: <Widget>[
                  Icon(
                    on ? Icons.check_circle_outline : Icons.error_outline,
                    size: 16,
                    color: on ? p.brand : p.attention,
                  ),
                  const SizedBox(width: Space.xs),
                  Flexible(
                    child: Text(
                      statusText,
                      style: text.bodySmall?.copyWith(color: on ? p.brand : p.attention),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
