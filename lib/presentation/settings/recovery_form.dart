import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vinnylock/app/theme/tokens.dart';
import 'package:vinnylock/core/text_fold.dart';
import 'package:vinnylock/l10n/ltext.dart';
import 'package:vinnylock/l10n/tx.dart';

/// Câu trả lời chỉ nhận chữ thường không dấu, chữ số và dấu cách.
/// Gõ chữ có dấu hoặc chữ hoa sẽ tự được đổi sang dạng chuẩn.
class AnswerInputFormatter extends TextInputFormatter {
  const AnswerInputFormatter();

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final cleaned = sanitizeAnswerInput(newValue.text);
    if (cleaned == newValue.text) return newValue;
    final base = newValue.selection.baseOffset;
    final cursor = base < 0
        ? cleaned.length
        : sanitizeAnswerInput(newValue.text.substring(0, base.clamp(0, newValue.text.length))).length;
    return TextEditingValue(
      text: cleaned,
      selection: TextSelection.collapsed(offset: cursor),
    );
  }
}

/// Hợp lệ khi có câu hỏi từ 4 ký tự và câu trả lời chuẩn hóa từ 2 ký tự.
bool isRecoveryInputValid({required String question, required String answer}) {
  return question.trim().length >= 4 && normalizeAnswer(answer).length >= 2;
}

/// Form nhập câu hỏi và câu trả lời khôi phục, dùng ở hộp thoại và ở bước thiết lập đầu tiên.
class RecoveryForm extends StatefulWidget {
  const RecoveryForm({
    super.key,
    required this.onSubmit,
    required this.submitLabel,
    this.initialQuestion,
  });

  final Future<bool> Function(String question, String answer) onSubmit;
  final LText submitLabel;
  final String? initialQuestion;

  @override
  State<RecoveryForm> createState() => _RecoveryFormState();
}

class _RecoveryFormState extends State<RecoveryForm> {
  late final TextEditingController _question =
      TextEditingController(text: widget.initialQuestion ?? '');
  final TextEditingController _answer = TextEditingController();
  bool _hidden = false;
  bool _busy = false;
  bool _failed = false;

  @override
  void dispose() {
    _question.dispose();
    _answer.dispose();
    super.dispose();
  }

  bool get _valid => isRecoveryInputValid(question: _question.text, answer: _answer.text);

  Future<void> _submit() async {
    if (!_valid || _busy) return;
    setState(() {
      _busy = true;
      _failed = false;
    });
    final ok = await widget.onSubmit(_question.text.trim(), normalizeAnswer(_answer.text));
    if (!mounted) return;
    setState(() {
      _busy = false;
      _failed = !ok;
    });
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(context.tr(Tx.recoveryQuestionLabel), style: text.labelLarge),
        const SizedBox(height: Space.sm),
        TextField(
          controller: _question,
          textCapitalization: TextCapitalization.sentences,
          maxLength: 120,
          onChanged: (_) => setState(() {}),
        ),
        Text(
          context.tr(Tx.recoveryQuestionHint),
          style: text.bodySmall?.copyWith(color: context.palette.muted),
        ),
        const SizedBox(height: Space.lg),
        Text(context.tr(Tx.recoveryAnswerLabel), style: text.labelLarge),
        const SizedBox(height: Space.sm),
        TextField(
          controller: _answer,
          obscureText: _hidden,
          autocorrect: false,
          enableSuggestions: false,
          maxLength: 60,
          inputFormatters: const <TextInputFormatter>[AnswerInputFormatter()],
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            suffixIcon: IconButton(
              tooltip: context.tr(_hidden ? Tx.showAnswer : Tx.hideAnswer),
              icon: Icon(_hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined),
              onPressed: () => setState(() => _hidden = !_hidden),
            ),
          ),
        ),
        Text(
          context.tr(Tx.recoveryAnswerHint),
          style: text.bodySmall?.copyWith(color: context.palette.muted),
        ),
        if (_failed) ...<Widget>[
          const SizedBox(height: Space.sm),
          Text(
            context.tr(Tx.recoveryInvalid),
            style: text.bodySmall?.copyWith(color: context.palette.danger),
          ),
        ],
        const SizedBox(height: Space.lg),
        FilledButton(
          onPressed: _valid && !_busy ? _submit : null,
          child: Text(context.tr(widget.submitLabel)),
        ),
      ],
    );
  }
}
