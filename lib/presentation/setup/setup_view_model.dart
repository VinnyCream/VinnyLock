import 'package:flutter/foundation.dart';
import 'package:vinnylock/presentation/shell/session_view_model.dart';

/// Ba bước thiết lập lần đầu: mã chung, câu hỏi khôi phục, bật dịch vụ khóa.
class SetupViewModel extends ChangeNotifier {
  SetupViewModel(this.session);

  static const int totalSteps = 3;

  final SessionViewModel session;
  int _step = 0;

  int get step => _step;
  bool get isFirst => _step == 0;
  bool get isLast => _step == totalSteps - 1;

  /// Bước 1 bắt buộc có mã chung. Hai bước còn lại cho phép bỏ qua (có cảnh báo).
  bool get canContinue => _step != 0 || session.device.hasMainCode;

  void back() {
    if (isFirst) return;
    _step -= 1;
    notifyListeners();
  }

  Future<void> next() async {
    if (!canContinue) return;
    if (isLast) {
      await session.completeOnboarding();
      return;
    }
    _step += 1;
    notifyListeners();
  }
}
