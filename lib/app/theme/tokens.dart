import 'package:flutter/material.dart';

// Token thiết kế. Nguồn sự thật là DESIGN.md. Không thêm màu, cỡ chữ hay bo góc
// ngoài file này mà chưa cập nhật DESIGN.md.

/// Thang khoảng cách (lưới 4 và 8).
abstract final class Space {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double huge = 48;
}

/// Các mức bo góc. `pill` cho thanh điều hướng, ô tìm và nút phân đoạn.
abstract final class Corner {
  static const double small = 8;
  static const double medium = 12;
  static const double large = 20;
  static const double pill = 999;
}

/// Bốn cỡ chữ, hai độ đậm.
abstract final class Type {
  static const double title = 22;
  static const double body = 16;
  static const double label = 14;
  static const double caption = 12;
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight strong = FontWeight.w600;
}

abstract final class Layout {
  /// Chiều rộng tối đa của nội dung đọc, để màn hình lớn không bị kéo giãn.
  static const double contentMaxWidth = 640;
  static const double compactMax = 600;
  static const double expandedMin = 840;
  static const double minTarget = 48;
  static const double iconSize = 40;
}

@immutable
class Palette {
  const Palette({
    required this.background,
    required this.surface,
    required this.tone,
    required this.onSurface,
    required this.muted,
    required this.brand,
    required this.onBrand,
    required this.brandContainer,
    required this.onBrandContainer,
    required this.danger,
    required this.onDanger,
    required this.attention,
    required this.attentionContainer,
    required this.onAttentionContainer,
    required this.statusNone,
    required this.statusBiometric,
    required this.statusMainCode,
    required this.statusOwnCode,
    required this.statusCombined,
  });

  final Color background;
  final Color surface;
  final Color tone;
  final Color onSurface;
  final Color muted;
  final Color brand;
  final Color onBrand;
  final Color brandContainer;
  final Color onBrandContainer;
  final Color danger;
  final Color onDanger;
  final Color attention;
  final Color attentionContainer;
  final Color onAttentionContainer;
  final Color statusNone;
  final Color statusBiometric;
  final Color statusMainCode;
  final Color statusOwnCode;
  final Color statusCombined;

  /// Tỉ lệ tương phản đã tính bằng công thức WCAG, xem DESIGN.md.
  static const Palette light = Palette(
    background: Color(0xFFF6F7F5),
    surface: Color(0xFFFFFFFF),
    tone: Color(0xFFECEFEC),
    onSurface: Color(0xFF14201E),
    muted: Color(0xFF4A5A57),
    brand: Color(0xFF0F766E),
    onBrand: Color(0xFFFFFFFF),
    brandContainer: Color(0xFFD5EFEA),
    onBrandContainer: Color(0xFF0B3B37),
    danger: Color(0xFFB3261E),
    onDanger: Color(0xFFFFFFFF),
    attention: Color(0xFFB45309),
    attentionContainer: Color(0xFFFFF1E0),
    onAttentionContainer: Color(0xFF5A2B04),
    statusNone: Color(0xFF6B7775),
    statusBiometric: Color(0xFF1D4ED8),
    statusMainCode: Color(0xFF0F766E),
    statusOwnCode: Color(0xFFB45309),
    statusCombined: Color(0xFF9D174D),
  );

  static const Palette dark = Palette(
    background: Color(0xFF0E1514),
    surface: Color(0xFF151E1D),
    tone: Color(0xFF1E2A28),
    onSurface: Color(0xFFE6EEEC),
    muted: Color(0xFFA5B5B1),
    brand: Color(0xFF4FD1C5),
    onBrand: Color(0xFF05211F),
    brandContainer: Color(0xFF123F3B),
    onBrandContainer: Color(0xFFBFF1EA),
    danger: Color(0xFFFFB4AB),
    onDanger: Color(0xFF3A0A06),
    attention: Color(0xFFF4A259),
    attentionContainer: Color(0xFF3A2A14),
    onAttentionContainer: Color(0xFFFBD9B0),
    statusNone: Color(0xFF8FA09C),
    statusBiometric: Color(0xFF7AA2FF),
    statusMainCode: Color(0xFF4FD1C5),
    statusOwnCode: Color(0xFFF4A259),
    statusCombined: Color(0xFFF28BB1),
  );
}

/// Cho widget lấy bảng màu qua Theme thay vì import trực tiếp.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors(this.palette);

  final Palette palette;

  @override
  AppColors copyWith({Palette? palette}) => AppColors(palette ?? this.palette);

  // Hai bảng màu sáng và tối được chọn theo Brightness, không nội suy.
  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return t < 0.5 ? this : other;
  }
}

extension AppColorsContext on BuildContext {
  Palette get palette => Theme.of(this).extension<AppColors>()!.palette;
}
