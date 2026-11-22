import 'package:flutter/material.dart';
import 'package:vinnylock/core/text_fold.dart';
import 'package:vinnylock/domain/entities/lock_config.dart';
import 'package:vinnylock/l10n/ltext.dart';
import 'package:vinnylock/l10n/tx.dart';
import 'package:vinnylock/presentation/common/choice_labels.dart';

// Danh mục cài đặt theo dạng dữ liệu. Một nguồn duy nhất cho ba nơi:
// trang Cài đặt (điều khiển), trang Hướng dẫn (giải thích) và ô tìm kiếm.
// Thêm một cài đặt mới chỉ cần thêm một mục vào danh sách cuối file.

enum SettingGroup { lock, screen, hide, recovery, system }

class GroupInfo {
  const GroupInfo({required this.title, required this.subtitle, required this.icon});

  final LText title;
  final LText subtitle;
  final IconData icon;
}

const Map<SettingGroup, GroupInfo> kGroupInfo = <SettingGroup, GroupInfo>{
  SettingGroup.lock: GroupInfo(title: Tx.groupLock, subtitle: Tx.groupLockSub, icon: Icons.lock_outline),
  SettingGroup.screen: GroupInfo(
    title: Tx.groupScreen,
    subtitle: Tx.groupScreenSub,
    icon: Icons.phone_android_outlined,
  ),
  SettingGroup.hide: GroupInfo(
    title: Tx.groupHide,
    subtitle: Tx.groupHideSub,
    icon: Icons.visibility_off_outlined,
  ),
  SettingGroup.recovery: GroupInfo(
    title: Tx.groupRecovery,
    subtitle: Tx.groupRecoverySub,
    icon: Icons.help_outline,
  ),
  SettingGroup.system: GroupInfo(
    title: Tx.groupSystem,
    subtitle: Tx.groupSystemSub,
    icon: Icons.tune,
  ),
};

class ConfirmSpec {
  const ConfirmSpec({required this.title, required this.body, required this.action});

  final LText title;
  final LText body;
  final LText action;
}

class ChoiceOption {
  const ChoiceOption({required this.id, required this.label, this.args, this.confirm});

  final String id;
  final LText label;
  final Map<String, Object>? args;

  /// Có giá trị thì hỏi xác nhận trước khi áp dụng lựa chọn này.
  final ConfirmSpec? confirm;
}

enum SettingAction {
  changeMainCode,
  editRecovery,
  permissions,
  openAccessibility,
  openAppInfo,
  resetAll,
}

sealed class SettingControl {
  const SettingControl();
}

class ToggleControl extends SettingControl {
  const ToggleControl({required this.read, required this.write});

  final bool Function(LockConfig) read;
  final LockConfig Function(LockConfig, bool) write;
}

class ChoiceControl extends SettingControl {
  const ChoiceControl({required this.options, required this.read, required this.write});

  final List<ChoiceOption> options;
  final String Function(LockConfig) read;
  final LockConfig Function(LockConfig, String) write;
}

class StepperControl extends SettingControl {
  const StepperControl({
    required this.min,
    required this.max,
    required this.unit,
    required this.read,
    required this.write,
  });

  final int min;
  final int max;
  final LText unit;
  final int Function(LockConfig) read;
  final LockConfig Function(LockConfig, int) write;
}

class ActionControl extends SettingControl {
  const ActionControl(this.action);

  final SettingAction action;
}

class SettingDef {
  const SettingDef({
    required this.id,
    required this.group,
    required this.title,
    required this.summary,
    required this.control,
    this.keywords = '',
    this.visible,
  });

  final String id;
  final SettingGroup group;
  final LText title;

  /// Giải thích ngắn. Hiện dưới tiêu đề ở Cài đặt và là nội dung của trang Hướng dẫn.
  final LText summary;
  final SettingControl control;

  /// Từ đồng nghĩa hai ngôn ngữ, không dấu, để tìm kiếm thông minh.
  final String keywords;

  /// Điều kiện hiện mục này theo cấu hình hiện tại (null là luôn hiện).
  final bool Function(LockConfig)? visible;

  bool isVisible(LockConfig config) => visible?.call(config) ?? true;
}

/// Tìm trong cả hai ngôn ngữ cùng lúc, bỏ dấu, mọi từ trong ô tìm đều phải có mặt.
List<SettingDef> searchSettings(List<SettingDef> defs, String query) {
  final terms = foldDiacritics(query).split(' ').where((String t) => t.isNotEmpty).toList();
  if (terms.isEmpty) return defs;
  return <SettingDef>[
    for (final def in defs)
      if (_matches(def, terms)) def,
  ];
}

bool _matches(SettingDef def, List<String> terms) {
  final haystack = foldDiacritics(
    '${def.title.vi} ${def.title.en} ${def.summary.vi} ${def.summary.en} ${def.keywords} '
    '${kGroupInfo[def.group]!.title.vi} ${kGroupInfo[def.group]!.title.en}',
  );
  return terms.every(haystack.contains);
}

List<ChoiceOption> _hourOptions(List<int> hours) => <ChoiceOption>[
      for (final h in hours)
        ChoiceOption(id: '$h', label: Tx.hoursLabel, args: <String, Object>{'n': h}),
    ];

const List<ChoiceOption> _penaltySecondsOptions = <ChoiceOption>[
  ChoiceOption(id: '30', label: Tx.relockSeconds, args: <String, Object>{'n': 30}),
  ChoiceOption(id: '60', label: Tx.relockMinutes, args: <String, Object>{'n': 1}),
  ChoiceOption(id: '300', label: Tx.relockMinutes, args: <String, Object>{'n': 5}),
  ChoiceOption(id: '900', label: Tx.relockMinutes, args: <String, Object>{'n': 15}),
];

const List<ChoiceOption> _penaltyPresetOptions = <ChoiceOption>[
  ChoiceOption(id: 'gentle', label: Tx.presetLight),
  ChoiceOption(id: 'standard', label: Tx.presetBalanced),
  ChoiceOption(id: 'strict', label: Tx.presetStrong),
];

/// Nhãn cho từng mức phạt, kèm mô tả thời gian để người dùng biết sẽ phải chờ bao lâu.
String describePenaltyPreset(PenaltyPreset preset) {
  String fmt(int s) => s >= 3600 ? '${s ~/ 3600}h' : (s >= 60 ? '${s ~/ 60}m' : '${s}s');
  return preset.stepsSeconds.map(fmt).join(' > ');
}

final List<SettingDef> kSettings = <SettingDef>[
  // ---- Khóa ----
  SettingDef(
    id: 'defaultMode',
    group: SettingGroup.lock,
    title: const LText(vi: 'Cách mở khóa mặc định', en: 'Default unlock method'),
    summary: const LText(
      vi: 'Áp dụng cho mọi ứng dụng chưa được chỉnh riêng. Sinh trắc dùng vân tay hoặc khuôn mặt của máy. "Cả hai" bắt nhập mã rồi sinh trắc, "Một trong hai" cho dùng cái nào cũng được.',
      en: 'Applies to every app you have not fine tuned. Biometric uses your phone fingerprint or face. "Both" asks for a code and biometrics, "Either" accepts whichever you use.',
    ),
    keywords: 'van tay khuon mat face fingerprint pin mat khau ma password sinh trac biometric',
    control: ChoiceControl(
      options: <ChoiceOption>[
        for (final m in AuthMode.values)
          ChoiceOption(id: m.wire, label: authModeLabel(m)),
      ],
      read: (LockConfig c) => c.defaults.mode.wire,
      write: (LockConfig c, String id) => c.copyWith(
        defaults: c.defaults.copyWith(mode: parseWire(AuthMode.values, id, AuthMode.codeOnly)),
      ),
    ),
  ),
  SettingDef(
    id: 'defaultOrder',
    group: SettingGroup.lock,
    title: const LText(vi: 'Thứ tự khi cần cả hai', en: 'Order when both are needed'),
    summary: const LText(
      vi: 'Chọn bước nào đến trước. Mã trước giúp người lấy tay bạn khi đang ngủ vẫn không vào được.',
      en: 'Choose which step comes first. Code first keeps someone from using your finger while you sleep.',
    ),
    keywords: 'thu tu order ngu ngu say sleep',
    visible: (LockConfig c) => c.defaults.mode == AuthMode.both,
    control: ChoiceControl(
      options: <ChoiceOption>[
        for (final o in AuthOrder.values)
          ChoiceOption(id: o.wire, label: authOrderLabel(o)),
      ],
      read: (LockConfig c) => c.defaults.order.wire,
      write: (LockConfig c, String id) => c.copyWith(
        defaults: c.defaults.copyWith(order: parseWire(AuthOrder.values, id, AuthOrder.codeFirst)),
      ),
    ),
  ),
  SettingDef(
    id: 'defaultRelock',
    group: SettingGroup.lock,
    title: const LText(vi: 'Khóa lại', en: 'Relock'),
    summary: const LText(
      vi: 'Khi nào ứng dụng bị khóa lại sau khi bạn rời khỏi nó. "Ngay khi thoát" chắc nhất, thời gian dài hơn thì đỡ phải mở nhiều lần.',
      en: 'When an app locks again after you leave it. "As soon as you leave" is safest, longer times mean fewer unlocks.',
    ),
    keywords: 'khoa lai thoi gian relock timeout tu dong auto lock delay',
    control: ChoiceControl(
      options: <ChoiceOption>[
        for (final id in kRelockIds)
          ChoiceOption(id: id, label: relockLabel(id).$1, args: relockLabel(id).$2),
      ],
      read: (LockConfig c) => relockToId(c.defaults.relock),
      write: (LockConfig c, String id) => c.copyWith(defaults: c.defaults.copyWith(relock: relockFromId(id))),
    ),
  ),
  SettingDef(
    id: 'allowWeakBiometric',
    group: SettingGroup.lock,
    title: const LText(vi: 'Cho phép khuôn mặt mức thường', en: 'Allow standard face unlock'),
    summary: const LText(
      vi: 'Nhiều máy chỉ có khuôn mặt mức thường (dễ bị ảnh đánh lừa hơn vân tay). Tắt mục này thì chỉ nhận sinh trắc mức mạnh.',
      en: 'Many phones only offer standard face unlock, which a photo can fool more easily than a fingerprint. Turn this off to accept strong biometrics only.',
    ),
    keywords: 'khuon mat face weak manh yeu strong security',
    control: ToggleControl(
      read: (LockConfig c) => c.allowWeakBiometric,
      write: (LockConfig c, bool v) => c.copyWith(allowWeakBiometric: v),
    ),
  ),
  SettingDef(
    id: 'attemptThreshold',
    group: SettingGroup.lock,
    title: const LText(vi: 'Số lần nhập sai trước khi bị phạt', en: 'Wrong tries before a penalty'),
    summary: const LText(
      vi: 'Tối thiểu 5 lần, tối đa 20. Sau số lần này, mỗi lần sai tiếp theo sẽ phải chờ.',
      en: 'At least 5, at most 20. After this many, every further wrong try makes you wait.',
    ),
    keywords: 'nhap sai wrong attempts phat penalty gioi han limit',
    control: StepperControl(
      min: kMinAttemptThreshold,
      max: kMaxAttemptThreshold,
      unit: Tx.timesLabel,
      read: (LockConfig c) => c.attempts.threshold,
      write: (LockConfig c, int v) => c.copyWith(attempts: c.attempts.copyWith(threshold: v)),
    ),
  ),
  SettingDef(
    id: 'penaltyKind',
    group: SettingGroup.lock,
    title: const LText(vi: 'Kiểu hình phạt', en: 'Penalty type'),
    summary: const LText(
      vi: '"Cố định" chờ một khoảng như nhau. "Tăng dần" chờ lâu hơn sau mỗi lần sai. Đang bị phạt vẫn có thể trả lời câu hỏi khôi phục.',
      en: '"Fixed" waits the same time each round. "Escalating" waits longer after every miss. During a penalty you can still answer the recovery question.',
    ),
    keywords: 'cho wait cooldown tang dan escalating fixed co dinh',
    control: ChoiceControl(
      options: const <ChoiceOption>[
        ChoiceOption(id: 'fixed', label: LText(vi: 'Cố định', en: 'Fixed')),
        ChoiceOption(id: 'escalating', label: LText(vi: 'Tăng dần', en: 'Escalating')),
      ],
      read: (LockConfig c) => c.attempts.penaltyKind.wire,
      write: (LockConfig c, String id) => c.copyWith(
        attempts: c.attempts.copyWith(
          penaltyKind: parseWire(PenaltyKind.values, id, PenaltyKind.escalating),
        ),
      ),
    ),
  ),
  SettingDef(
    id: 'fixedSeconds',
    group: SettingGroup.lock,
    title: const LText(vi: 'Thời gian chờ cố định', en: 'Fixed wait time'),
    summary: const LText(
      vi: 'Mỗi lần bị phạt phải chờ đúng khoảng này.',
      en: 'Every penalty lasts exactly this long.',
    ),
    keywords: 'giay phut second minute thoi gian cho wait',
    visible: (LockConfig c) => c.attempts.penaltyKind == PenaltyKind.fixed,
    control: ChoiceControl(
      options: _penaltySecondsOptions,
      read: (LockConfig c) => _nearest(c.attempts.fixedSeconds, const <int>[30, 60, 300, 900]).toString(),
      write: (LockConfig c, String id) => c.copyWith(
        attempts: c.attempts.copyWith(fixedSeconds: int.tryParse(id) ?? 60),
      ),
    ),
  ),
  SettingDef(
    id: 'penaltyPreset',
    group: SettingGroup.lock,
    title: const LText(vi: 'Mức tăng dần', en: 'Escalation level'),
    summary: LText(
      vi: 'Nhẹ ${describePenaltyPreset(PenaltyPreset.gentle)}, Cân bằng ${describePenaltyPreset(PenaltyPreset.standard)}, Chắc ${describePenaltyPreset(PenaltyPreset.strict)}. Lần sau cùng được lặp lại. (s giây, m phút, h giờ)',
      en: 'Light ${describePenaltyPreset(PenaltyPreset.gentle)}, Balanced ${describePenaltyPreset(PenaltyPreset.standard)}, Strong ${describePenaltyPreset(PenaltyPreset.strict)}. The last step repeats. (s seconds, m minutes, h hours)',
    ),
    keywords: 'tang dan escalating nhe can bang chac gentle standard strict',
    visible: (LockConfig c) => c.attempts.penaltyKind == PenaltyKind.escalating,
    control: ChoiceControl(
      options: _penaltyPresetOptions,
      read: (LockConfig c) => c.attempts.preset.wire,
      write: (LockConfig c, String id) => c.copyWith(
        attempts: c.attempts.copyWith(preset: parseWire(PenaltyPreset.values, id, PenaltyPreset.standard)),
      ),
    ),
  ),
  SettingDef(
    id: 'penaltyScope',
    group: SettingGroup.lock,
    title: const LText(vi: 'Phạm vi hình phạt', en: 'Penalty scope'),
    summary: const LText(
      vi: '"Chỉ ứng dụng đó" thì khóa riêng ứng dụng bị nhập sai. "Tất cả ứng dụng" thì mọi ứng dụng cùng bị chờ, chắc hơn nhưng bất tiện hơn.',
      en: '"Only that app" penalizes just the app being tried. "All apps" makes every app wait, which is stricter but less convenient.',
    ),
    keywords: 'pham vi scope tat ca all app rieng',
    control: ChoiceControl(
      options: const <ChoiceOption>[
        ChoiceOption(id: 'app', label: Tx.scopeApp),
        ChoiceOption(id: 'all', label: Tx.scopeAll),
      ],
      read: (LockConfig c) => c.attempts.scope.wire,
      write: (LockConfig c, String id) => c.copyWith(
        attempts: c.attempts.copyWith(scope: parseWire(AttemptScope.values, id, AttemptScope.app)),
      ),
    ),
  ),
  SettingDef(
    id: 'resetAfterHours',
    group: SettingGroup.lock,
    title: const LText(vi: 'Xóa số lần sai sau', en: 'Forget wrong tries after'),
    summary: const LText(
      vi: 'Nếu không nhập sai thêm trong khoảng này thì bộ đếm về 0. Mở khóa đúng cũng xóa bộ đếm.',
      en: 'If no further wrong try happens in this time the counter goes back to 0. A correct unlock also clears it.',
    ),
    keywords: 'reset dem counter xoa clear',
    control: ChoiceControl(
      options: _hourOptions(const <int>[1, 6, 12, 24, 72]),
      read: (LockConfig c) => _nearest(c.attempts.resetAfterHours, const <int>[1, 6, 12, 24, 72]).toString(),
      write: (LockConfig c, String id) => c.copyWith(
        attempts: c.attempts.copyWith(resetAfterHours: int.tryParse(id) ?? 24),
      ),
    ),
  ),
  const SettingDef(
    id: 'changeMainCode',
    group: SettingGroup.lock,
    title: LText(vi: 'Đổi mã chung', en: 'Change the shared code'),
    summary: LText(
      vi: 'Mã dùng để mở Vinny Lock và các ứng dụng chưa có mã riêng. Có thể là PIN hoặc hình vẽ. Bạn sẽ nhập mã hiện tại trước khi đổi.',
      en: 'The code that opens Vinny Lock and every app without its own code. A PIN or a pattern. You enter the current code before changing it.',
    ),
    keywords: 'doi ma pin hinh ve pattern change password mat khau',
    control: ActionControl(SettingAction.changeMainCode),
  ),

  // ---- Màn hình khóa ----
  SettingDef(
    id: 'hidePattern',
    group: SettingGroup.screen,
    title: const LText(vi: 'Ẩn nét vẽ khi mở khóa', en: 'Hide the pattern trail'),
    summary: const LText(
      vi: 'Không vẽ đường nối khi bạn vẽ hình, để người nhìn qua vai không thấy.',
      en: 'No line is drawn while you draw, so nobody can read it over your shoulder.',
    ),
    keywords: 'hinh ve pattern duong noi line shoulder surfing',
    control: ToggleControl(
      read: (LockConfig c) => c.lockScreen.hidePattern,
      write: (LockConfig c, bool v) => c.copyWith(lockScreen: c.lockScreen.copyWith(hidePattern: v)),
    ),
  ),
  SettingDef(
    id: 'shuffleKeypad',
    group: SettingGroup.screen,
    title: const LText(vi: 'Xáo trộn bàn phím số', en: 'Shuffle the keypad'),
    summary: const LText(
      vi: 'Các số đổi chỗ mỗi lần, giúp tránh bị nhìn trộm vị trí ngón tay hoặc vết bẩn trên màn hình.',
      en: 'Digits move every time, which defeats guessing from finger positions or smudges.',
    ),
    keywords: 'ban phim so keypad pin xao tron random shuffle',
    control: ToggleControl(
      read: (LockConfig c) => c.lockScreen.shuffleKeypad,
      write: (LockConfig c, bool v) => c.copyWith(lockScreen: c.lockScreen.copyWith(shuffleKeypad: v)),
    ),
  ),
  SettingDef(
    id: 'vibrate',
    group: SettingGroup.screen,
    title: const LText(vi: 'Rung khi nhập sai', en: 'Vibrate on a wrong code'),
    summary: const LText(
      vi: 'Một nhịp rung ngắn để biết mã chưa đúng.',
      en: 'A short buzz tells you the code was wrong.',
    ),
    keywords: 'rung vibrate haptic',
    control: ToggleControl(
      read: (LockConfig c) => c.lockScreen.vibrate,
      write: (LockConfig c, bool v) => c.copyWith(lockScreen: c.lockScreen.copyWith(vibrate: v)),
    ),
  ),
  SettingDef(
    id: 'showAppName',
    group: SettingGroup.screen,
    title: const LText(vi: 'Hiện tên ứng dụng trên màn hình khóa', en: 'Show the app name on the lock screen'),
    summary: const LText(
      vi: 'Tắt nếu không muốn người bên cạnh biết bạn đang khóa ứng dụng nào.',
      en: 'Turn off so people nearby cannot see which app is locked.',
    ),
    keywords: 'ten app name rieng tu privacy',
    control: ToggleControl(
      read: (LockConfig c) => c.lockScreen.showAppName,
      write: (LockConfig c, bool v) => c.copyWith(lockScreen: c.lockScreen.copyWith(showAppName: v)),
    ),
  ),

  // ---- Ẩn và ngụy trang ----
  SettingDef(
    id: 'iconMode',
    group: SettingGroup.hide,
    title: const LText(vi: 'Icon ứng dụng', en: 'App icon'),
    summary: const LText(
      vi: '"Ngụy trang" đổi icon và tên thành một ứng dụng thông thường. "Ẩn hẳn" bỏ icon khỏi màn hình, vẫn mở lại được bằng cách chạm ổ khóa 7 lần trên màn hình khóa hoặc qua Cài đặt › Trợ năng.',
      en: '"Disguised" swaps the icon and name for an everyday app. "Hidden" removes the icon from the home screen. You can still open it by tapping the lock 7 times on a lock screen or through Settings › Accessibility.',
    ),
    keywords: 'an icon hide disguise ngu trang bien mat launcher man hinh chinh home',
    control: ChoiceControl(
      options: const <ChoiceOption>[
        ChoiceOption(id: 'normal', label: Tx.iconNormal),
        ChoiceOption(id: 'disguise', label: Tx.iconDisguise),
        ChoiceOption(
          id: 'hidden',
          label: Tx.iconHidden,
          confirm: ConfirmSpec(
            title: Tx.hideConfirmTitle,
            body: Tx.hideConfirmBody,
            action: Tx.hideConfirmAction,
          ),
        ),
      ],
      read: (LockConfig c) => c.icon.mode.wire,
      write: (LockConfig c, String id) => c.copyWith(
        icon: c.icon.copyWith(mode: parseWire(IconMode.values, id, IconMode.normal)),
      ),
    ),
  ),
  SettingDef(
    id: 'disguiseIcon',
    group: SettingGroup.hide,
    title: const LText(vi: 'Hình ngụy trang', en: 'Disguise as'),
    summary: const LText(
      vi: 'Chọn ứng dụng giả để icon trông như một ứng dụng bình thường. Tên hiện ở màn hình chính đổi theo, riêng tên trong Cài đặt Android vẫn là Vinny Lock.',
      en: 'Pick the decoy the icon should look like. The home screen name follows, but Android Settings still lists Vinny Lock.',
    ),
    keywords: 'may tinh calculator ghi chu notes thoi tiet weather decoy',
    visible: (LockConfig c) => c.icon.mode == IconMode.disguise,
    control: ChoiceControl(
      options: const <ChoiceOption>[
        ChoiceOption(id: 'calculator', label: Tx.disguiseCalculator),
        ChoiceOption(id: 'notes', label: Tx.disguiseNotes),
        ChoiceOption(id: 'weather', label: Tx.disguiseWeather),
      ],
      read: (LockConfig c) => c.icon.disguise.wire,
      write: (LockConfig c, String id) => c.copyWith(
        icon: c.icon.copyWith(disguise: parseWire(DisguiseIcon.values, id, DisguiseIcon.calculator)),
      ),
    ),
  ),

  // ---- Khôi phục ----
  const SettingDef(
    id: 'editRecovery',
    group: SettingGroup.recovery,
    title: LText(vi: 'Câu hỏi khôi phục', en: 'Recovery question'),
    summary: LText(
      vi: 'Bạn tự đặt câu hỏi và câu trả lời. Câu hỏi viết có dấu thoải mái, câu trả lời chỉ gồm chữ thường không dấu và có thể có dấu cách. Đây là đường vào duy nhất khi quên mã và cũng dùng được lúc đang bị phạt.',
      en: 'You write both the question and the answer. The question can use accents, the answer is lowercase without accents and may contain spaces. It is the only way back in if you forget the code and it works during a penalty too.',
    ),
    keywords: 'quen ma forgot cau hoi tra loi question answer khoi phuc recover reset',
    control: ActionControl(SettingAction.editRecovery),
  ),
  SettingDef(
    id: 'recoveryThreshold',
    group: SettingGroup.recovery,
    title: const LText(vi: 'Số lần trả lời sai trước khi bị phạt', en: 'Wrong answers before a penalty'),
    summary: const LText(
      vi: 'Tính riêng với nhập mã, để người đoán câu trả lời cũng bị chặn. Tối thiểu 5 lần.',
      en: 'Counted separately from code tries so guessing the answer is limited too. At least 5.',
    ),
    keywords: 'tra loi sai wrong answer gioi han',
    control: StepperControl(
      min: kMinAttemptThreshold,
      max: kMaxAttemptThreshold,
      unit: Tx.timesLabel,
      read: (LockConfig c) => c.recovery.threshold,
      write: (LockConfig c, int v) => c.copyWith(recovery: c.recovery.copyWith(threshold: v)),
    ),
  ),
  SettingDef(
    id: 'recoveryPreset',
    group: SettingGroup.recovery,
    title: const LText(vi: 'Mức phạt khi trả lời sai', en: 'Penalty for wrong answers'),
    summary: LText(
      vi: 'Cùng ba mức như nhập mã: Nhẹ ${describePenaltyPreset(PenaltyPreset.gentle)}, Cân bằng ${describePenaltyPreset(PenaltyPreset.standard)}, Chắc ${describePenaltyPreset(PenaltyPreset.strict)}.',
      en: 'Same three levels as codes: Light ${describePenaltyPreset(PenaltyPreset.gentle)}, Balanced ${describePenaltyPreset(PenaltyPreset.standard)}, Strong ${describePenaltyPreset(PenaltyPreset.strict)}.',
    ),
    keywords: 'phat penalty tra loi answer',
    control: ChoiceControl(
      options: _penaltyPresetOptions,
      read: (LockConfig c) => c.recovery.preset.wire,
      write: (LockConfig c, String id) => c.copyWith(
        recovery: c.recovery.copyWith(preset: parseWire(PenaltyPreset.values, id, PenaltyPreset.standard)),
      ),
    ),
  ),

  // ---- Hệ thống ----
  SettingDef(
    id: 'language',
    group: SettingGroup.system,
    title: const LText(vi: 'Ngôn ngữ', en: 'Language'),
    summary: const LText(
      vi: 'Tiếng Việt, English hoặc theo hệ thống. Áp dụng cho cả màn hình khóa.',
      en: 'Tiếng Việt, English or follow the system. Applies to the lock screen too.',
    ),
    keywords: 'ngon ngu language tieng viet english vi en',
    control: ChoiceControl(
      options: const <ChoiceOption>[
        ChoiceOption(id: 'system', label: Tx.langSystem),
        ChoiceOption(id: 'vi', label: Tx.langVi),
        ChoiceOption(id: 'en', label: Tx.langEn),
      ],
      read: (LockConfig c) => c.language.wire,
      write: (LockConfig c, String id) => c.copyWith(
        language: parseWire(LanguageSetting.values, id, LanguageSetting.system),
      ),
    ),
  ),
  SettingDef(
    id: 'theme',
    group: SettingGroup.system,
    title: const LText(vi: 'Giao diện sáng tối', en: 'Light or dark'),
    summary: const LText(
      vi: 'Sáng, tối hoặc theo hệ thống.',
      en: 'Light, dark or follow the system.',
    ),
    keywords: 'giao dien theme sang toi dark light mau',
    control: ChoiceControl(
      options: const <ChoiceOption>[
        ChoiceOption(id: 'system', label: Tx.themeSystem),
        ChoiceOption(id: 'light', label: Tx.themeLight),
        ChoiceOption(id: 'dark', label: Tx.themeDark),
      ],
      read: (LockConfig c) => c.theme.wire,
      write: (LockConfig c, String id) => c.copyWith(theme: parseWire(ThemeSetting.values, id, ThemeSetting.system)),
    ),
  ),
  const SettingDef(
    id: 'permissions',
    group: SettingGroup.system,
    title: LText(vi: 'Quyền của ứng dụng', en: 'App permissions'),
    summary: LText(
      vi: 'Xem Vinny Lock dùng quyền nào và vì sao, cùng danh sách quyền không dùng.',
      en: 'See which permissions Vinny Lock uses and why, and the ones it never uses.',
    ),
    keywords: 'quyen permission tro nang accessibility camera internet vi tri location',
    control: ActionControl(SettingAction.permissions),
  ),
  const SettingDef(
    id: 'openAccessibility',
    group: SettingGroup.system,
    title: LText(vi: 'Mở cài đặt Trợ năng', en: 'Open Accessibility settings'),
    summary: LText(
      vi: 'Nơi bật hoặc tắt dịch vụ khóa của Vinny Lock. Phải bật thì việc khóa mới hoạt động.',
      en: 'Where you turn the Vinny Lock service on or off. It must be on for locking to work.',
    ),
    keywords: 'tro nang accessibility bat service dich vu',
    control: ActionControl(SettingAction.openAccessibility),
  ),
  const SettingDef(
    id: 'resetAll',
    group: SettingGroup.system,
    title: LText(vi: 'Đặt lại cài đặt chung', en: 'Reset general settings'),
    summary: LText(
      vi: 'Đưa các cài đặt chung về mặc định. Danh sách ứng dụng đã khóa, mã và câu hỏi khôi phục được giữ nguyên.',
      en: 'Return general settings to default. Locked apps, codes and the recovery question are kept.',
    ),
    keywords: 'dat lai reset mac dinh default',
    control: ActionControl(SettingAction.resetAll),
  ),
];

int _nearest(int value, List<int> options) {
  var best = options.first;
  for (final option in options) {
    if ((option - value).abs() < (best - value).abs()) best = option;
  }
  return best;
}
