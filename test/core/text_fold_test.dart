import 'package:flutter_test/flutter_test.dart';
import 'package:vinnylock/core/text_fold.dart';

void main() {
  group('foldDiacritics', () {
    test('bỏ dấu tiếng Việt và đổi đ thành d', () {
      expect(foldDiacritics('Ngôn ngữ Nhật'), 'ngon ngu nhat');
      expect(foldDiacritics('Đồng hồ'), 'dong ho');
    });

    test('gộp khoảng trắng và cắt hai đầu', () {
      expect(foldDiacritics('  Máy   tính  '), 'may tinh');
    });

    test('bỏ dấu tổ hợp khi chữ ở dạng NFD', () {
      expect(foldDiacritics('á'), 'a');
    });
  });

  group('sanitizeAnswerInput', () {
    test('chỉ giữ a-z, 0-9 và dấu cách', () {
      expect(sanitizeAnswerInput('Hà Nội!'), 'ha noi');
      expect(sanitizeAnswerInput('abc-123_x'), 'abc123x');
    });

    test('giữ dấu cách cuối để con trỏ không nhảy', () {
      expect(sanitizeAnswerInput('ha '), 'ha ');
    });
  });

  group('normalizeAnswer', () {
    test('gộp khoảng trắng và cắt hai đầu', () {
      expect(normalizeAnswer('  Con   Mèo  Của Tôi '), 'con meo cua toi');
    });

    test('hai cách gõ cùng một câu trả lời cho kết quả giống nhau', () {
      expect(normalizeAnswer('Sài Gòn'), normalizeAnswer('sai gon'));
    });

    test('chuỗi rỗng giữ nguyên là rỗng', () {
      expect(normalizeAnswer('   '), '');
    });
  });
}
