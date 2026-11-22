import 'package:flutter/widgets.dart';

/// Một đoạn chữ song ngữ. Cả hai ngôn ngữ đều bắt buộc nên không thể
/// quên dịch: thiếu thì không biên dịch được.
class LText {
  const LText({required this.vi, required this.en});

  final String vi;
  final String en;

  String resolve(String languageCode, [Map<String, Object>? args]) {
    var text = languageCode == 'vi' ? vi : en;
    if (args != null) {
      args.forEach((String key, Object value) {
        text = text.replaceAll('{$key}', value.toString());
      });
    }
    return text;
  }
}

extension LTextContext on BuildContext {
  String get languageCode => Localizations.localeOf(this).languageCode;

  /// Lấy chữ theo ngôn ngữ hiện tại. `{n}` trong chuỗi được thay bằng args['n'].
  String tr(LText text, [Map<String, Object>? args]) {
    return text.resolve(languageCode, args);
  }
}
