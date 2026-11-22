import 'package:flutter/material.dart';
import 'package:vinnylock/app/theme/tokens.dart';
import 'package:vinnylock/domain/entities/app_entry.dart';
import 'package:vinnylock/l10n/ltext.dart';
import 'package:vinnylock/l10n/tx.dart';

extension LockStatusUi on LockStatus {
  LText get label {
    switch (this) {
      case LockStatus.none:
        return Tx.statusNone;
      case LockStatus.biometric:
        return Tx.statusBiometric;
      case LockStatus.mainCode:
        return Tx.statusMainCode;
      case LockStatus.ownCode:
        return Tx.statusOwnCode;
      case LockStatus.combined:
        return Tx.statusCombined;
    }
  }

  LText get description {
    switch (this) {
      case LockStatus.none:
        return Tx.statusNoneDesc;
      case LockStatus.biometric:
        return Tx.statusBiometricDesc;
      case LockStatus.mainCode:
        return Tx.statusMainCodeDesc;
      case LockStatus.ownCode:
        return Tx.statusOwnCodeDesc;
      case LockStatus.combined:
        return Tx.statusCombinedDesc;
    }
  }

  Color colorOf(Palette p) {
    switch (this) {
      case LockStatus.none:
        return p.statusNone;
      case LockStatus.biometric:
        return p.statusBiometric;
      case LockStatus.mainCode:
        return p.statusMainCode;
      case LockStatus.ownCode:
        return p.statusOwnCode;
      case LockStatus.combined:
        return p.statusCombined;
    }
  }
}

/// Chấm trạng thái. Mỗi loại có một hình riêng, không dựa vào màu một mình:
/// vòng rỗng, tròn đặc, vuông, thoi, vòng có chấm.
class StatusMark extends StatelessWidget {
  const StatusMark({super.key, required this.status, this.size = 14});

  final LockStatus status;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: CustomPaint(
        size: Size.square(size),
        painter: _MarkPainter(status, status.colorOf(context.palette)),
      ),
    );
  }
}

class _MarkPainter extends CustomPainter {
  _MarkPainter(this.status, this.color);

  final LockStatus status;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()..color = color;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    switch (status) {
      case LockStatus.none:
        canvas.drawCircle(c, r - 1, stroke);
      case LockStatus.biometric:
        canvas.drawCircle(c, r, fill);
      case LockStatus.mainCode:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCircle(center: c, radius: r - 1),
            const Radius.circular(2),
          ),
          fill,
        );
      case LockStatus.ownCode:
        final path = Path()
          ..moveTo(c.dx, c.dy - r)
          ..lineTo(c.dx + r, c.dy)
          ..lineTo(c.dx, c.dy + r)
          ..lineTo(c.dx - r, c.dy)
          ..close();
        canvas.drawPath(path, fill);
      case LockStatus.combined:
        canvas.drawCircle(c, r - 1, stroke);
        canvas.drawCircle(c, r / 3, fill);
    }
  }

  @override
  bool shouldRepaint(_MarkPainter old) => old.status != status || old.color != color;
}

/// Chấm kèm tên trạng thái, dùng ở dòng ứng dụng và chú giải.
class StatusLabel extends StatelessWidget {
  const StatusLabel({super.key, required this.status});

  final LockStatus status;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        StatusMark(status: status),
        const SizedBox(width: Space.sm),
        Flexible(
          child: Text(
            context.tr(status.label),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.palette.muted),
          ),
        ),
      ],
    );
  }
}
