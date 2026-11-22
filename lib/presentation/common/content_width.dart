import 'package:flutter/material.dart';
import 'package:vinnylock/app/theme/tokens.dart';

/// Giữ nội dung ở độ rộng dễ đọc và căn giữa trên màn hình lớn.
class ContentWidth extends StatelessWidget {
  const ContentWidth({
    super.key,
    required this.child,
    this.maxWidth = Layout.contentMaxWidth,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

/// Phân loại theo chiều rộng cửa sổ, không theo loại thiết bị.
enum WidthClass { compact, medium, expanded }

WidthClass widthClassOf(double width) {
  if (width < Layout.compactMax) return WidthClass.compact;
  if (width < Layout.expandedMin) return WidthClass.medium;
  return WidthClass.expanded;
}
