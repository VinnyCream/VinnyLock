import 'package:vinnylock/l10n/ltext.dart';

/// Toàn bộ chữ của giao diện, tập trung một chỗ. Mỗi mục có đủ tiếng Việt và English.
/// Chữ của từng cài đặt nằm cùng chỗ với định nghĩa cài đặt (settings_registry.dart).
abstract final class Tx {
  // Chung
  static const appName = LText(vi: 'Vinny Lock', en: 'Vinny Lock');
  static const save = LText(vi: 'Lưu', en: 'Save');
  static const cancel = LText(vi: 'Hủy', en: 'Cancel');
  static const done = LText(vi: 'Xong', en: 'Done');
  static const next = LText(vi: 'Tiếp tục', en: 'Continue');
  static const back = LText(vi: 'Quay lại', en: 'Back');
  static const skip = LText(vi: 'Bỏ qua', en: 'Skip');
  static const confirm = LText(vi: 'Xác nhận', en: 'Confirm');
  static const close = LText(vi: 'Đóng', en: 'Close');
  static const loading = LText(vi: 'Đang tải...', en: 'Loading...');
  static const retry = LText(vi: 'Thử lại', en: 'Try again');
  static const loadError = LText(vi: 'Không tải được dữ liệu', en: 'Could not load data');
  static const change = LText(vi: 'Đổi', en: 'Change');

  // Điều hướng
  static const navApps = LText(vi: 'Ứng dụng', en: 'Apps');
  static const navSettings = LText(vi: 'Cài đặt', en: 'Settings');
  static const navGuide = LText(vi: 'Hướng dẫn', en: 'Guide');

  // Trang ứng dụng
  static const searchApps = LText(vi: 'Tìm ứng dụng', en: 'Search apps');
  static const filterAll = LText(vi: 'Tất cả', en: 'All');
  static const noApps = LText(vi: 'Không tìm thấy ứng dụng nào', en: 'No apps found');
  static const lockedSummary = LText(vi: '{n} ứng dụng đang khóa', en: '{n} apps locked');
  static const legendTitle = LText(vi: 'Ý nghĩa chấm trạng thái', en: 'Status marks');
  static const legendButton = LText(vi: 'Chú giải', en: 'Legend');
  static const toggleLock = LText(vi: 'Khóa {name}', en: 'Lock {name}');
  static const a11yBannerTitle = LText(vi: 'Dịch vụ khóa chưa bật', en: 'Lock service is off');
  static const a11yBannerBody = LText(
    vi: 'Bật Vinny Lock trong Cài đặt › Trợ năng để việc khóa có hiệu lực.',
    en: 'Turn on Vinny Lock in Settings › Accessibility so locking can work.',
  );
  static const a11yBannerAction = LText(vi: 'Mở Trợ năng', en: 'Open Accessibility');

  // Trạng thái khóa
  static const statusNone = LText(vi: 'Chưa khóa', en: 'Not locked');
  static const statusBiometric = LText(vi: 'Sinh trắc', en: 'Biometric');
  static const statusMainCode = LText(vi: 'Mã chung', en: 'Shared code');
  static const statusOwnCode = LText(vi: 'Mã riêng', en: 'Own code');
  static const statusCombined = LText(vi: 'Kết hợp', en: 'Combined');
  static const statusNoneDesc = LText(vi: 'Ứng dụng mở tự do.', en: 'Opens freely.');
  static const statusBiometricDesc = LText(
    vi: 'Chỉ cần vân tay hoặc khuôn mặt.',
    en: 'Only a fingerprint or face is needed.',
  );
  static const statusMainCodeDesc = LText(
    vi: 'Dùng mã chung của Vinny Lock.',
    en: 'Uses the shared Vinny Lock code.',
  );
  static const statusOwnCodeDesc = LText(
    vi: 'Dùng mã riêng đặt cho ứng dụng này.',
    en: 'Uses a code set only for this app.',
  );
  static const statusCombinedDesc = LText(
    vi: 'Kết hợp sinh trắc và mã, theo thứ tự hoặc một trong hai.',
    en: 'Biometrics and a code, in order or either one.',
  );

  // Bảng chỉnh riêng từng ứng dụng
  static const sheetLockToggle = LText(vi: 'Khóa ứng dụng này', en: 'Lock this app');
  static const unlockMethod = LText(vi: 'Cách mở khóa', en: 'Unlock method');
  static const useDefault = LText(vi: 'Theo mặc định', en: 'Use default');
  static const modeBiometric = LText(vi: 'Sinh trắc', en: 'Biometric');
  static const modeCode = LText(vi: 'Mã', en: 'Code');
  static const modeBoth = LText(vi: 'Cả hai', en: 'Both');
  static const modeEither = LText(vi: 'Một trong hai', en: 'Either');
  static const orderTitle = LText(vi: 'Thứ tự khi cần cả hai', en: 'Order when both are needed');
  static const orderCodeFirst = LText(vi: 'Mã trước', en: 'Code first');
  static const orderBiometricFirst = LText(vi: 'Sinh trắc trước', en: 'Biometric first');
  static const relockTitle = LText(vi: 'Khóa lại', en: 'Relock');
  static const ownCodeTitle = LText(vi: 'Mã riêng', en: 'Own code');
  static const ownCodeNone = LText(vi: 'Đang dùng mã chung.', en: 'Using the shared code.');
  static const ownCodeSet = LText(vi: 'Ứng dụng này có mã riêng.', en: 'This app has its own code.');
  static const setOwnPin = LText(vi: 'Đặt PIN riêng', en: 'Set own PIN');
  static const setOwnPattern = LText(vi: 'Đặt hình vẽ riêng', en: 'Set own pattern');
  static const removeOwnCode = LText(vi: 'Xóa mã riêng', en: 'Remove own code');
  static const allowRecoveryTitle = LText(
    vi: 'Cho phép trả lời câu hỏi để vào',
    en: 'Allow the recovery question',
  );
  static const allowRecoveryBody = LText(
    vi: 'Tắt nếu muốn ứng dụng này chỉ mở bằng mã hoặc sinh trắc. Khi đó nếu quên mã, bạn sẽ không còn đường vào.',
    en: 'Turn off to open this app only with its code or biometrics. If you forget the code you will have no way in.',
  );
  static const codeSaved = LText(vi: 'Đã lưu mã', en: 'Code saved');
  static const codeNotSet = LText(vi: 'Chưa đặt mã', en: 'Code not set');

  // Cài đặt: nhóm
  static const settingsTitle = LText(vi: 'Cài đặt', en: 'Settings');
  static const searchSettings = LText(vi: 'Tìm trong cài đặt', en: 'Search settings');
  static const noSettingResults = LText(vi: 'Không có cài đặt phù hợp', en: 'No matching settings');
  static const groupLock = LText(vi: 'Khóa', en: 'Locking');
  static const groupLockSub = LText(
    vi: 'Cách mở khóa, khóa lại, nhập sai',
    en: 'Unlocking, relock, wrong attempts',
  );
  static const groupScreen = LText(vi: 'Màn hình khóa', en: 'Lock screen');
  static const groupScreenSub = LText(vi: 'Giao diện và phản hồi', en: 'Look and feedback');
  static const groupHide = LText(vi: 'Ẩn và ngụy trang', en: 'Hide and disguise');
  static const groupHideSub = LText(vi: 'Icon của ứng dụng', en: 'The app icon');
  static const groupRecovery = LText(vi: 'Khôi phục', en: 'Recovery');
  static const groupRecoverySub = LText(vi: 'Câu hỏi bí mật khi quên mã', en: 'Secret question for a lost code');
  static const groupSystem = LText(vi: 'Hệ thống', en: 'System');
  static const groupSystemSub = LText(vi: 'Ngôn ngữ, giao diện, quyền', en: 'Language, theme, permissions');

  // Nhãn của các lựa chọn dùng chung
  static const relockImmediate = LText(vi: 'Ngay khi thoát', en: 'As soon as you leave');
  static const relockScreenOff = LText(vi: 'Khi tắt màn hình', en: 'When the screen turns off');
  static const relockSeconds = LText(vi: 'Sau {n} giây', en: 'After {n} seconds');
  static const relockMinutes = LText(vi: 'Sau {n} phút', en: 'After {n} minutes');
  static const scopeApp = LText(vi: 'Chỉ ứng dụng đó', en: 'Only that app');
  static const scopeAll = LText(vi: 'Tất cả ứng dụng', en: 'All apps');
  static const hoursLabel = LText(vi: '{n} giờ', en: '{n} hours');
  static const timesLabel = LText(vi: '{n} lần', en: '{n} tries');
  static const iconNormal = LText(vi: 'Bình thường', en: 'Normal');
  static const iconDisguise = LText(vi: 'Ngụy trang', en: 'Disguised');
  static const iconHidden = LText(vi: 'Ẩn hẳn', en: 'Hidden');
  static const disguiseCalculator = LText(vi: 'Máy tính', en: 'Calculator');
  static const disguiseNotes = LText(vi: 'Ghi chú', en: 'Notes');
  static const disguiseWeather = LText(vi: 'Thời tiết', en: 'Weather');
  static const langSystem = LText(vi: 'Theo hệ thống', en: 'System default');
  static const langVi = LText(vi: 'Tiếng Việt', en: 'Tiếng Việt');
  static const langEn = LText(vi: 'English', en: 'English');
  static const themeSystem = LText(vi: 'Theo hệ thống', en: 'System default');
  static const themeLight = LText(vi: 'Sáng', en: 'Light');
  static const themeDark = LText(vi: 'Tối', en: 'Dark');
  static const presetLight = LText(vi: 'Nhẹ', en: 'Light');
  static const presetBalanced = LText(vi: 'Cân bằng', en: 'Balanced');
  static const presetStrong = LText(vi: 'Chắc', en: 'Strong');
  static const presetLightDesc = LText(
    vi: 'Chỉ sinh trắc, khóa lại sau 1 phút.',
    en: 'Biometrics only, relock after 1 minute.',
  );
  static const presetBalancedDesc = LText(
    vi: 'Mã, khóa lại ngay khi thoát.',
    en: 'A code, relock as soon as you leave.',
  );
  static const presetStrongDesc = LText(
    vi: 'Mã rồi sinh trắc, khóa ngay, hình phạt nặng.',
    en: 'Code then biometrics, relock at once, heavy penalties.',
  );
  static const codePin = LText(vi: 'PIN', en: 'PIN');
  static const codePattern = LText(vi: 'Hình vẽ', en: 'Pattern');

  // Hộp thoại
  static const hideConfirmTitle = LText(vi: 'Ẩn hẳn ứng dụng?', en: 'Hide the app completely?');
  static const hideConfirmBody = LText(
    vi: 'Icon sẽ biến mất khỏi màn hình và ô tìm kiếm. Cách mở lại: mở một ứng dụng đang bị khóa rồi chạm vào ổ khóa 7 lần, hoặc vào Cài đặt › Trợ năng › Vinny Lock. Bạn đã nhớ chưa?',
    en: 'The icon will disappear from the home screen and search. To open it again: open a locked app and tap the lock 7 times, or go to Settings › Accessibility › Vinny Lock. Got it?',
  );
  static const hideConfirmAction = LText(vi: 'Đã nhớ, ẩn đi', en: 'Got it, hide');
  static const resetConfirmTitle = LText(vi: 'Đặt lại cài đặt?', en: 'Reset settings?');
  static const resetConfirmBody = LText(
    vi: 'Các cài đặt chung về mặc định. Danh sách ứng dụng đã khóa, mã và câu hỏi khôi phục được giữ nguyên.',
    en: 'General settings go back to default. Your locked apps, codes and recovery question are kept.',
  );
  static const resetConfirmAction = LText(vi: 'Đặt lại', en: 'Reset');
  static const recoveryDialogTitle = LText(vi: 'Câu hỏi khôi phục', en: 'Recovery question');
  static const recoveryQuestionLabel = LText(vi: 'Câu hỏi', en: 'Question');
  static const recoveryQuestionHint = LText(
    vi: 'Có dấu thoải mái. Đừng chọn câu mà người quen đoán được.',
    en: 'Write it freely. Avoid something people around you can guess.',
  );
  static const recoveryAnswerLabel = LText(vi: 'Câu trả lời', en: 'Answer');
  static const recoveryAnswerHint = LText(
    vi: 'Chữ thường, không dấu, có thể có dấu cách. Ví dụ: ha noi',
    en: 'Lowercase, no accents, spaces allowed. Example: ha noi',
  );
  static const recoverySaved = LText(vi: 'Đã lưu câu hỏi khôi phục', en: 'Recovery question saved');
  static const recoveryInvalid = LText(
    vi: 'Cần một câu hỏi và một câu trả lời hợp lệ.',
    en: 'A question and a valid answer are needed.',
  );
  static const mainCodeChanged = LText(vi: 'Đã đổi mã chung', en: 'Shared code changed');

  // Hướng dẫn lần đầu
  static const setupWelcomeTitle = LText(vi: 'Chào mừng đến Vinny Lock', en: 'Welcome to Vinny Lock');
  static const setupWelcomeBody = LText(
    vi: 'Khóa ứng dụng ngay trên máy bạn. Không quảng cáo, không Internet, không thu thập gì. Ba bước ngắn để bắt đầu.',
    en: 'Lock apps right on your phone. No ads, no internet, no tracking. Three short steps to start.',
  );
  static const stepCode = LText(vi: 'Mã chung', en: 'Shared code');
  static const stepRecovery = LText(vi: 'Khôi phục', en: 'Recovery');
  static const stepAccess = LText(vi: 'Dịch vụ khóa', en: 'Lock service');
  static const setupCodeTitle = LText(vi: 'Đặt mã chung', en: 'Set the shared code');
  static const setupCodeBody = LText(
    vi: 'Mã này dùng để mở Vinny Lock và các ứng dụng bị khóa. Bạn có thể đặt mã riêng cho từng ứng dụng sau.',
    en: 'This code opens Vinny Lock and your locked apps. You can set a separate code per app later.',
  );
  static const setupCodeDone = LText(vi: 'Đã đặt mã chung', en: 'Shared code is set');
  static const setupRecoveryTitle = LText(vi: 'Đặt câu hỏi khôi phục', en: 'Set a recovery question');
  static const setupRecoveryBody = LText(
    vi: 'Vì app không có Internet nên không có "quên mật khẩu" qua email. Câu hỏi này là đường vào duy nhất nếu bạn quên mã.',
    en: 'Because the app has no internet there is no email reset. This question is your only way in if you forget the code.',
  );
  static const setupSkipWarning = LText(
    vi: 'Bỏ qua thì nếu quên mã sẽ không có cách lấy lại.',
    en: 'If you skip this and forget the code, there is no way back.',
  );
  static const setupAccessTitle = LText(vi: 'Bật dịch vụ khóa', en: 'Turn on the lock service');
  static const setupAccessBody = LText(
    vi: 'Vinny Lock dùng dịch vụ Trợ năng của Android chỉ để biết ứng dụng nào vừa mở và hiện màn hình khóa. App không đọc nội dung màn hình và không có quyền Internet nên không thể gửi gì đi.',
    en: 'Vinny Lock uses the Android Accessibility service only to know which app just opened and to show the lock screen. It does not read screen content and has no internet permission, so nothing can leave your phone.',
  );
  static const setupAccessRestricted = LText(
    vi: 'Nếu Android báo "Cài đặt bị hạn chế" (app cài từ ngoài cửa hàng): mở Thông tin ứng dụng, chạm ⋮ ở góc, chọn "Cho phép cài đặt bị hạn chế", rồi quay lại bật dịch vụ.',
    en: 'If Android says "Restricted setting" (apps installed outside a store): open App info, tap ⋮ in the corner, choose "Allow restricted settings", then come back and turn the service on.',
  );
  static const setupAccessOpen = LText(vi: 'Mở Trợ năng', en: 'Open Accessibility');
  static const setupAccessOpenInfo = LText(vi: 'Mở Thông tin ứng dụng', en: 'Open App info');
  static const setupAccessOn = LText(vi: 'Dịch vụ đang bật', en: 'Service is on');
  static const setupAccessOff = LText(vi: 'Dịch vụ chưa bật', en: 'Service is off');
  static const setupFinish = LText(vi: 'Vào Vinny Lock', en: 'Open Vinny Lock');

  // Hướng dẫn trong app
  static const guideTitle = LText(vi: 'Hướng dẫn', en: 'Guide');
  static const guideIntro = LText(
    vi: 'Mỗi cài đặt có giải thích ngắn dưới đây, xếp theo cùng nhóm với trang Cài đặt.',
    en: 'Every setting is explained below, grouped the same way as the Settings page.',
  );
  static const guidePrivacyTitle = LText(vi: 'Quyền riêng tư', en: 'Privacy');
  static const guidePrivacyBody = LText(
    vi: 'Vinny Lock không có quyền Internet, camera, vị trí, danh bạ hay bộ nhớ. Mọi cài đặt và mã nằm trong bộ nhớ riêng của app trên máy bạn. Gỡ app là mọi thứ trở lại như chưa cài.',
    en: 'Vinny Lock has no internet, camera, location, contacts or storage permission. Settings and codes stay in the private storage of the app on your phone. Uninstall it and everything is back as if never installed.',
  );

  // Trang quyền
  static const permissionsTitle = LText(vi: 'Quyền của ứng dụng', en: 'App permissions');
  static const permAccessibility = LText(vi: 'Dịch vụ Trợ năng', en: 'Accessibility service');
  static const permAccessibilityDesc = LText(
    vi: 'Biết ứng dụng nào đang mở để hiện màn hình khóa. Không đọc nội dung màn hình.',
    en: 'Knows which app is opening so it can show the lock screen. Does not read screen content.',
  );
  static const permBiometric = LText(vi: 'Sinh trắc học', en: 'Biometrics');
  static const permBiometricDesc = LText(
    vi: 'Hệ thống Android tự xử lý vân tay và khuôn mặt, app chỉ nhận kết quả đúng hoặc sai.',
    en: 'Android handles fingerprints and faces itself. The app only gets pass or fail.',
  );
  static const permVibrate = LText(vi: 'Rung', en: 'Vibration');
  static const permVibrateDesc = LText(vi: 'Phản hồi khi nhập sai mã.', en: 'Feedback on a wrong code.');
  static const notUsedTitle = LText(vi: 'Không dùng', en: 'Not used');
  static const notUsedList = LText(
    vi: 'Internet, Camera, Vị trí, Danh bạ, Bộ nhớ, Micro, Thông báo',
    en: 'Internet, Camera, Location, Contacts, Storage, Microphone, Notifications',
  );
  static const openAppInfo = LText(vi: 'Mở Thông tin ứng dụng', en: 'Open App info');

  // Bổ sung
  static const filterLocked = LText(vi: 'Đang khóa', en: 'Locked');
  static const pickCodeKindTitle = LText(vi: 'Chọn kiểu mã', en: 'Choose a code type');
  static const needMainCode = LText(
    vi: 'Hãy đặt mã chung trước. Mã chung vừa bảo vệ Vinny Lock vừa là đường dự phòng khi sinh trắc không dùng được.',
    en: 'Set the shared code first. It protects Vinny Lock itself and is the fallback when biometrics are unavailable.',
  );
  static const biometricUnavailable = LText(
    vi: 'Máy chưa cài vân tay hoặc khuôn mặt. Hãy thêm trong Cài đặt của Android.',
    en: 'No fingerprint or face is set up. Add one in Android Settings.',
  );
  static const codeCancelled = LText(vi: 'Chưa đặt mã', en: 'No code was set');
  static const mainCodeLabel = LText(vi: 'Mã chung', en: 'Shared code');
  static const mainCodeSetPin = LText(vi: 'Đang dùng PIN', en: 'Using a PIN');
  static const mainCodeSetPattern = LText(vi: 'Đang dùng hình vẽ', en: 'Using a pattern');
  static const showAnswer = LText(vi: 'Hiện câu trả lời', en: 'Show answer');
  static const hideAnswer = LText(vi: 'Ẩn câu trả lời', en: 'Hide answer');
  static const clearSearch = LText(vi: 'Xóa ô tìm', en: 'Clear search');
  static const stepOf = LText(vi: 'Bước {n} trên {total}', en: 'Step {n} of {total}');
  static const decrease = LText(vi: 'Giảm', en: 'Decrease');
  static const increase = LText(vi: 'Tăng', en: 'Increase');
  static const presetsTitle = LText(vi: 'Mức nhanh', en: 'Quick levels');
  static const presetsBody = LText(
    vi: 'Chọn một mức để cài nhiều mục cùng lúc, rồi chỉnh tiếp từng mục nếu muốn.',
    en: 'Pick a level to set many options at once, then fine tune each one if you like.',
  );
  static const presetApplied = LText(vi: 'Đã áp dụng mức nhanh', en: 'Quick level applied');
  static const guideSearch = LText(vi: 'Tìm trong hướng dẫn', en: 'Search the guide');
  static const unlockedAppsHint = LText(
    vi: 'Bật công tắc để khóa. Chạm vào ứng dụng để chỉnh riêng.',
    en: 'Turn the switch on to lock. Tap an app to fine tune it.',
  );

  // Giao diện mới
  static const tabLocked = LText(vi: 'Đang khóa', en: 'Locked');
  static const tabUnlocked = LText(vi: 'Chưa khóa', en: 'Unlocked');
  static const filterButton = LText(vi: 'Lọc theo cách khóa', en: 'Filter by lock type');
  static const filterClear = LText(vi: 'Bỏ lọc', en: 'Clear filter');
  static const riskNoCodeTitle = LText(vi: 'Chưa có mã chung', en: 'No shared code yet');
  static const riskNoCodeBody = LText(
    vi: 'Chưa đặt mã chung thì chưa khóa được ứng dụng nào và ai cũng mở được Vinny Lock.',
    en: 'Until a shared code is set no app can be locked and anyone can open Vinny Lock.',
  );
  static const riskNoCodeAction = LText(vi: 'Đặt mã chung', en: 'Set shared code');
  static const protectedTitle = LText(vi: 'Đang được bảo vệ', en: 'Protected');
  static const protectedBody = LText(
    vi: '{n} ứng dụng đang khóa. Dịch vụ khóa đang chạy.',
    en: '{n} apps locked. The lock service is running.',
  );
  static const readyTitle = LText(vi: 'Sẵn sàng', en: 'Ready');
  static const readyBody = LText(
    vi: 'Dịch vụ khóa đang chạy. Bật công tắc để khóa một ứng dụng.',
    en: 'The lock service is running. Turn a switch on to lock an app.',
  );
  static const appSettings = LText(vi: 'Chỉnh riêng {name}', en: 'Settings for {name}');
  static const bankTitle = LText(vi: 'Ứng dụng ngân hàng', en: 'Banking apps');
  static const bankBody = LText(
    vi: 'Nhiều ngân hàng cảnh báo khi có bất kỳ dịch vụ Trợ năng nào đang bật, đây là cơ chế của họ và Vinny Lock không thể ẩn. Với app ngân hàng, hãy dùng khóa có sẵn của chính app hoặc của máy (Thư mục bảo mật, Khóa ứng dụng của hãng, Không gian riêng của Android 15). Có thể tắt dịch vụ Trợ năng của Vinny Lock lúc giao dịch rồi bật lại.',
    en: 'Many banks warn when any Accessibility service is on. That is their check and Vinny Lock cannot hide it. For banking apps use the lock built into the app or the phone (Secure Folder, the maker app lock, Android 15 Private Space). You can also turn the Vinny Lock Accessibility service off while you bank and back on after.',
  );
  static const bankAction = LText(vi: 'Mở Trợ năng', en: 'Open Accessibility');
  static const settingsHeroTitle = LText(vi: 'Thay đổi mã chung', en: 'Change shared code');
  static const settingsHeroBody = LText(
    vi: 'Mã dùng để mở Vinny Lock và các ứng dụng chưa có mã riêng.',
    en: 'The code that opens Vinny Lock and every app without its own code.',
  );
  static const settingsHeroAction = LText(vi: 'Đổi mã', en: 'Change code');
}
