import 'package:flutter/material.dart';
import 'package:vinnylock/app/theme/tokens.dart';
import 'package:vinnylock/l10n/ltext.dart';
import 'package:vinnylock/l10n/tx.dart';
import 'package:vinnylock/presentation/common/code_kind_picker.dart';
import 'package:vinnylock/presentation/common/content_width.dart';
import 'package:vinnylock/presentation/settings/recovery_form.dart';
import 'package:vinnylock/presentation/setup/setup_view_model.dart';

class SetupPage extends StatefulWidget {
  const SetupPage({super.key, required this.viewModel});

  final SetupViewModel viewModel;

  @override
  State<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends State<SetupPage> {
  SetupViewModel get _vm => widget.viewModel;
  bool _recoverySaved = false;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge(<Listenable>[_vm, _vm.session]),
      builder: (BuildContext context, Widget? _) {
        final text = Theme.of(context).textTheme;
        return Scaffold(
          body: SafeArea(
            child: ContentWidth(
              child: Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(Space.xl, Space.lg, Space.xl, 0),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: LinearProgressIndicator(
                            value: (_vm.step + 1) / SetupViewModel.totalSteps,
                            minHeight: 6,
                            borderRadius: BorderRadius.circular(Corner.small),
                          ),
                        ),
                        const SizedBox(width: Space.md),
                        Text(
                          context.tr(Tx.stepOf, <String, Object>{
                            'n': _vm.step + 1,
                            'total': SetupViewModel.totalSteps,
                          }),
                          style: text.bodySmall?.copyWith(color: context.palette.muted),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        Space.xl,
                        Space.xl,
                        Space.xl,
                        Space.xl + MediaQuery.viewInsetsOf(context).bottom,
                      ),
                      child: _stepBody(context),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(Space.xl),
                    child: Row(
                      children: <Widget>[
                        if (!_vm.isFirst)
                          TextButton(onPressed: _vm.back, child: Text(context.tr(Tx.back))),
                        const Spacer(),
                        FilledButton(
                          onPressed: _vm.canContinue ? _vm.next : null,
                          child: Text(context.tr(_vm.isLast ? Tx.setupFinish : Tx.next)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _stepBody(BuildContext context) {
    switch (_vm.step) {
      case 0:
        return _codeStep(context);
      case 1:
        return _recoveryStep(context);
      default:
        return _accessStep(context);
    }
  }

  Widget _codeStep(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final has = _vm.session.device.hasMainCode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(Icons.lock_outline, size: 48, color: context.palette.brand),
        const SizedBox(height: Space.lg),
        Text(context.tr(Tx.setupWelcomeTitle), style: text.titleLarge),
        const SizedBox(height: Space.sm),
        Text(context.tr(Tx.setupWelcomeBody), style: text.bodyLarge),
        const SizedBox(height: Space.xl),
        Text(context.tr(Tx.setupCodeTitle), style: text.titleMedium),
        const SizedBox(height: Space.xs),
        Text(
          context.tr(Tx.setupCodeBody),
          style: text.bodyMedium?.copyWith(color: context.palette.muted),
        ),
        const SizedBox(height: Space.lg),
        if (has)
          Row(
            children: <Widget>[
              Icon(Icons.check_circle_outline, color: context.palette.brand),
              const SizedBox(width: Space.sm),
              Expanded(child: Text(context.tr(Tx.setupCodeDone), style: text.labelLarge)),
              TextButton(onPressed: _setCode, child: Text(context.tr(Tx.change))),
            ],
          )
        else
          FilledButton(onPressed: _setCode, child: Text(context.tr(Tx.setupCodeTitle))),
      ],
    );
  }

  Future<void> _setCode() async {
    final kind = await pickCodeKind(context);
    if (kind == null || !mounted) return;
    await _vm.session.setMainCode(kind);
  }

  Widget _recoveryStep(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(context.tr(Tx.setupRecoveryTitle), style: text.titleLarge),
        const SizedBox(height: Space.sm),
        Text(context.tr(Tx.setupRecoveryBody), style: text.bodyLarge),
        const SizedBox(height: Space.xl),
        if (_recoverySaved || _vm.session.device.hasRecovery)
          Row(
            children: <Widget>[
              Icon(Icons.check_circle_outline, color: context.palette.brand),
              const SizedBox(width: Space.sm),
              Expanded(child: Text(context.tr(Tx.recoverySaved), style: text.labelLarge)),
              TextButton(
                onPressed: () => setState(() => _recoverySaved = false),
                child: Text(context.tr(Tx.change)),
              ),
            ],
          )
        else ...<Widget>[
          RecoveryForm(
            submitLabel: Tx.save,
            onSubmit: (String question, String answer) async {
              final ok = await _vm.session.setRecovery(question: question, answer: answer);
              if (ok && mounted) setState(() => _recoverySaved = true);
              return ok;
            },
          ),
          const SizedBox(height: Space.lg),
          Text(
            context.tr(Tx.setupSkipWarning),
            style: text.bodySmall?.copyWith(color: context.palette.attention),
          ),
        ],
      ],
    );
  }

  Widget _accessStep(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    final on = _vm.session.device.accessibilityEnabled;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(context.tr(Tx.setupAccessTitle), style: text.titleLarge),
        const SizedBox(height: Space.sm),
        Text(context.tr(Tx.setupAccessBody), style: text.bodyLarge),
        const SizedBox(height: Space.lg),
        Text(
          context.tr(Tx.setupAccessRestricted),
          style: text.bodyMedium?.copyWith(color: p.muted),
        ),
        const SizedBox(height: Space.xl),
        Row(
          children: <Widget>[
            Icon(on ? Icons.check_circle_outline : Icons.error_outline, color: on ? p.brand : p.attention),
            const SizedBox(width: Space.sm),
            Text(context.tr(on ? Tx.setupAccessOn : Tx.setupAccessOff), style: text.labelLarge),
          ],
        ),
        const SizedBox(height: Space.lg),
        Wrap(
          spacing: Space.sm,
          runSpacing: Space.sm,
          children: <Widget>[
            FilledButton(
              onPressed: _vm.session.openAccessibilitySettings,
              child: Text(context.tr(Tx.setupAccessOpen)),
            ),
            OutlinedButton(
              onPressed: _vm.session.openAppInfo,
              child: Text(context.tr(Tx.setupAccessOpenInfo)),
            ),
          ],
        ),
      ],
    );
  }
}
