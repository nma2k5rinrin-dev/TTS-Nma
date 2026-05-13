import 'dart:math';

import 'package:flutter/material.dart';

class WaveformView extends StatefulWidget {
  final List<double> levels;
  final Color color;
  final Color? inactiveColor;
  final bool isActive;
  final double progress;
  final double height;
  final int barCount;

  const WaveformView({
    super.key,
    this.levels = const [],
    required this.color,
    this.inactiveColor,
    this.isActive = false,
    this.progress = 0,
    this.height = 48,
    this.barCount = 42,
  });

  @override
  State<WaveformView> createState() => _WaveformViewState();
}

class _WaveformViewState extends State<WaveformView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    if (widget.isActive) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant WaveformView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.isActive && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _WaveformPainter(
              levels: _levels(_controller.value),
              color: widget.color,
              inactiveColor:
                  widget.inactiveColor ?? widget.color.withValues(alpha: 0.18),
              progress: widget.progress.clamp(0, 1).toDouble(),
            ),
          );
        },
      ),
    );
  }

  List<double> _levels(double tick) {
    final count = widget.barCount;
    if (widget.levels.isEmpty) {
      return List<double>.generate(count, (index) {
        final wave = (sin(index * 0.55 + tick * pi * 2) + 1) / 2;
        return (0.18 + wave * 0.62).clamp(0.08, 1).toDouble();
      });
    }

    return List<double>.generate(count, (index) {
      final sourceIndex = ((index / count) * widget.levels.length)
          .floor()
          .clamp(0, widget.levels.length - 1);
      final base = widget.levels[sourceIndex];
      if (!widget.isActive) return base.clamp(0.06, 1).toDouble();

      final pulse = 0.88 + sin(index * 0.4 + tick * pi * 2) * 0.12;
      return (base * pulse).clamp(0.06, 1).toDouble();
    });
  }
}

class _WaveformPainter extends CustomPainter {
  final List<double> levels;
  final Color color;
  final Color inactiveColor;
  final double progress;

  const _WaveformPainter({
    required this.levels,
    required this.color,
    required this.inactiveColor,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (levels.isEmpty) return;

    final barWidth = max(2.0, size.width / (levels.length * 2.2));
    final gap = (size.width - levels.length * barWidth) / (levels.length - 1);
    final centerY = size.height / 2;
    final radius = Radius.circular(barWidth);
    final activeBars = progress <= 0 ? levels.length : levels.length * progress;

    for (var i = 0; i < levels.length; i++) {
      final x = i * (barWidth + gap);
      final h = max(5.0, size.height * levels[i]);
      final rect = Rect.fromLTWH(x, centerY - h / 2, barWidth, h);
      final paint = Paint()
        ..color = i <= activeBars ? color : inactiveColor
        ..style = PaintingStyle.fill;

      canvas.drawRRect(RRect.fromRectAndRadius(rect, radius), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) {
    return oldDelegate.levels != levels ||
        oldDelegate.color != color ||
        oldDelegate.inactiveColor != inactiveColor ||
        oldDelegate.progress != progress;
  }
}
