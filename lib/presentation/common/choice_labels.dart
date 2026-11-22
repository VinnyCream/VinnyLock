import 'package:vinnylock/domain/entities/lock_config.dart';
import 'package:vinnylock/l10n/ltext.dart';
import 'package:vinnylock/l10n/tx.dart';

/// Các mốc thời gian khóa lại cho người dùng chọn. Id ổn định, dùng làm giá trị lưu của ô chọn.
const List<String> kRelockIds = <String>[
  'immediate',
  'screenOff',
  's30',
  's60',
  'm5',
  'm15',
  'm30',
];

RelockRule relockFromId(String id) {
  switch (id) {
    case 'screenOff':
      return RelockRule.screenOff;
    case 's30':
      return const RelockRule(RelockKind.afterSeconds, 30);
    case 's60':
      return const RelockRule(RelockKind.afterSeconds, 60);
    case 'm5':
      return const RelockRule(RelockKind.afterSeconds, 300);
    case 'm15':
      return const RelockRule(RelockKind.afterSeconds, 900);
    case 'm30':
      return const RelockRule(RelockKind.afterSeconds, 1800);
    default:
      return RelockRule.immediate;
  }
}

/// Chuyển luật về id gần nhất trong danh sách (luật tùy ý từ file cũ vẫn hiển thị được).
String relockToId(RelockRule rule) {
  switch (rule.kind) {
    case RelockKind.immediate:
      return 'immediate';
    case RelockKind.screenOff:
      return 'screenOff';
    case RelockKind.afterSeconds:
      final s = rule.seconds;
      if (s <= 30) return 's30';
      if (s <= 60) return 's60';
      if (s <= 300) return 'm5';
      if (s <= 900) return 'm15';
      return 'm30';
  }
}

(LText, Map<String, Object>?) relockLabel(String id) {
  switch (id) {
    case 'immediate':
      return (Tx.relockImmediate, null);
    case 'screenOff':
      return (Tx.relockScreenOff, null);
    case 's30':
      return (Tx.relockSeconds, <String, Object>{'n': 30});
    case 's60':
      return (Tx.relockSeconds, <String, Object>{'n': 60});
    case 'm5':
      return (Tx.relockMinutes, <String, Object>{'n': 5});
    case 'm15':
      return (Tx.relockMinutes, <String, Object>{'n': 15});
    default:
      return (Tx.relockMinutes, <String, Object>{'n': 30});
  }
}

LText authModeLabel(AuthMode mode) {
  switch (mode) {
    case AuthMode.biometricOnly:
      return Tx.modeBiometric;
    case AuthMode.codeOnly:
      return Tx.modeCode;
    case AuthMode.both:
      return Tx.modeBoth;
    case AuthMode.either:
      return Tx.modeEither;
  }
}

LText authOrderLabel(AuthOrder order) {
  return order == AuthOrder.codeFirst ? Tx.orderCodeFirst : Tx.orderBiometricFirst;
}
