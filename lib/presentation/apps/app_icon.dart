import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:vinnylock/app/theme/tokens.dart';

typedef IconLoader = Future<Uint8List?> Function(String package);

/// Icon ứng dụng lấy từ Android, tải một lần cho mỗi dòng. Chưa có thì hiện chữ cái đầu.
class AppIcon extends StatefulWidget {
  const AppIcon({
    super.key,
    required this.package,
    required this.label,
    required this.loader,
    this.size = Layout.iconSize,
  });

  final String package;
  final String label;
  final IconLoader loader;
  final double size;

  @override
  State<AppIcon> createState() => _AppIconState();
}

class _AppIconState extends State<AppIcon> {
  late Future<Uint8List?> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.loader(widget.package);
  }

  @override
  void didUpdateWidget(AppIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.package != widget.package) {
      _future = widget.loader(widget.package);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: widget.size,
      child: FutureBuilder<Uint8List?>(
        future: _future,
        builder: (BuildContext context, AsyncSnapshot<Uint8List?> snapshot) {
          final bytes = snapshot.data;
          if (bytes == null) return _Placeholder(label: widget.label);
          return ExcludeSemantics(
            child: Image.memory(
              bytes,
              gaplessPlayback: true,
              filterQuality: FilterQuality.medium,
              errorBuilder: (BuildContext c, Object e, StackTrace? s) {
                return _Placeholder(label: widget.label);
              },
            ),
          );
        },
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final letter = label.trim().isEmpty ? '?' : label.trim().substring(0, 1).toUpperCase();
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.palette.tone,
        borderRadius: BorderRadius.circular(Corner.medium),
      ),
      child: Center(
        child: Text(
          letter,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: context.palette.muted),
        ),
      ),
    );
  }
}
