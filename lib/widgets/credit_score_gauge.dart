import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CreditScoreGauge extends StatelessWidget {
  final int score;
  final String label;

  const CreditScoreGauge({super.key, required this.score, required this.label});

  Color get _scoreColor {
    if (score >= 800) return AppColors.forest;
    if (score >= 600) return AppColors.gold;
    return AppColors.danger;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      height: 160,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: (score / 1000).clamp(0.0, 1.0)),
        duration: const Duration(milliseconds: 1200),
        curve: Curves.easeOutCubic,
        builder: (context, progress, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(160, 160),
                painter: _GaugePainter(progress: progress, color: _scoreColor),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TweenAnimationBuilder<int>(
                    tween: IntTween(begin: 0, end: (progress * 1000).round()),
                    duration: const Duration(milliseconds: 1200),
                    builder: (context, value, _) => Text(
                      "$value",
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: _scoreColor),
                    ),
                  ),
                  Text(label, style: const TextStyle(fontSize: 12, color: AppColors.inkMuted, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double progress;
  final Color color;

  _GaugePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    const startAngle = -pi * 1.25;
    const sweepTotal = pi * 1.5;

    final trackPaint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = color
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweepTotal, false, trackPaint);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweepTotal * progress, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) => oldDelegate.progress != progress || oldDelegate.color != color;
}
