// Chuẩn hóa chữ cho tìm kiếm và cho câu trả lời khôi phục.
// Không phụ thuộc Flutter nên kiểm thử được bằng `dart test` thuần.

const Map<String, String> _vietnameseGroups = <String, String>{
  'a': 'àáạảãâầấậẩẫăằắặẳẵ',
  'e': 'èéẹẻẽêềếệểễ',
  'i': 'ìíịỉĩ',
  'o': 'òóọỏõôồốộổỗơờớợởỡ',
  'u': 'ùúụủũưừứựửữ',
  'y': 'ỳýỵỷỹ',
  'd': 'đ',
};

final Map<int, String> _foldTable = _buildFoldTable();
final RegExp _spaces = RegExp(r'\s+');
final RegExp _notAnswerChar = RegExp(r'[^a-z0-9 ]');

Map<int, String> _buildFoldTable() {
  final table = <int, String>{};
  _vietnameseGroups.forEach((String base, String chars) {
    for (final rune in chars.runes) {
      table[rune] = base;
    }
  });
  return table;
}

// Chữ thường và bỏ dấu, chưa gộp khoảng trắng.
String _foldRunes(String input) {
  final buffer = StringBuffer();
  for (final rune in input.toLowerCase().runes) {
    // Dấu tổ hợp (khi bàn phím gửi chữ ở dạng NFD) thì bỏ qua.
    if (rune >= 0x0300 && rune <= 0x036F) continue;
    buffer.write(_foldTable[rune] ?? String.fromCharCode(rune));
  }
  return buffer.toString();
}

/// Chữ thường, bỏ dấu tiếng Việt (đ thành d), gộp khoảng trắng, cắt hai đầu.
/// Dùng cho tìm kiếm ứng dụng và tìm kiếm cài đặt.
String foldDiacritics(String input) {
  return _foldRunes(input).replaceAll(_spaces, ' ').trim();
}

/// Quy tắc nhập câu trả lời khôi phục: chữ thường, không dấu, chỉ gồm
/// chữ cái a-z, chữ số và dấu cách. Chưa gộp khoảng trắng để con trỏ
/// không nhảy khi người dùng đang gõ.
String sanitizeAnswerInput(String input) {
  return _foldRunes(input).replaceAll(_notAnswerChar, '');
}

/// Dạng chuẩn để so khớp câu trả lời. Phải giống hệt bên Kotlin (TextFold).
String normalizeAnswer(String input) {
  return sanitizeAnswerInput(input).replaceAll(_spaces, ' ').trim();
}
