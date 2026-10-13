import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/design/app_typography.dart';

/// Visueller Daily Ring in Performance-Volt auf Deep-Navy-Hintergrund gemäß DESIGN.md §2.
class DailyRingWidget extends StatefulWidget {
  final double actualLoad;
  final double targetLoad;
  final bool isRestDay;
  final double size;

  const DailyRingWidget({
    super.key,
    required this.actualLoad,
    required this.targetLoad,
    this.isRestDay = false,
    this.size = 140,
  });

  @override
  State<DailyRingWidget> createState() => _DailyRingWidgetState();
}

class _DailyRingWidgetState extends State<DailyRingWidget> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _setupAnimation();
  }

  @override
  void didUpdateWidget(DailyRingWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.actualLoad != widget.actualLoad || oldWidget.targetLoad != widget.targetLoad) {
      _setupAnimation();
    }
  }

  void _setupAnimation() {
    final targetProgress = widget.isRestDay
        ? 1.0
        : (widget.targetLoad > 0 ? (widget.actualLoad / widget.targetLoad).clamp(0.0, 1.5) : (widget.actualLoad > 0 ? 1.0 : 0.0));

    _animation = Tween<double>(begin: 0.0, end: targetProgress).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _animController.forward(from: 0.0);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.of(context).disableAnimations;
    final progress = disableAnimations
        ? (widget.isRestDay ? 1.0 : (widget.targetLoad > 0 ? widget.actualLoad / widget.targetLoad : 0.0))
        : _animation.value;

    final semanticsText = widget.isRestDay
        ? 'Heute ist Ruhetag. Erholung aktiv.'
        : 'Tagesfortschritt: ${widget.actualLoad.round()} von ${widget.targetLoad.round()} Belastungspunkten absolviert.';

    return Semantics(
      label: semanticsText,
      value: '${(progress * 100).round()}%',
      child: AnimatedBuilder(
        animation: _animController,
        builder: (context, _) {
          final curProgress = disableAnimations ? progress : _animation.value;

          return SizedBox(
            width: widget.size,
            height: widget.size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: Size(widget.size, widget.size),
                  painter: _DailyRingPainter(
                    progress: curProgress,
                    isRestDay: widget.isRestDay,
                  ),
                ),
                _buildCenterContent(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCenterContent() {
    if (widget.isRestDay) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.battery_charging_full_rounded, color: AppColors.volt, size: 28),
          const SizedBox(height: 4),
          Text(
            'Ruhetag',
            style: AppTypography.title.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Text(
            'Erholung',
            style: AppTypography.label.copyWith(
              color: AppColors.white.withValues(alpha: 0.7),
              fontSize: 11,
            ),
          ),
        ],
      );
    }

    final pct = widget.targetLoad > 0 ? ((widget.actualLoad / widget.targetLoad) * 100).round() : 0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.targetLoad > 0 ? '${widget.actualLoad.round()} / ${widget.targetLoad.round()}' : '${widget.actualLoad.round()}',
          style: AppTypography.headline.copyWith(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        Text(
          widget.targetLoad > 0 ? '$pct % des Plans' : 'Punkte heute',
          style: AppTypography.label.copyWith(
            color: AppColors.white.withValues(alpha: 0.7),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _DailyRingPainter extends CustomPainter {
  final double progress;
  final bool isRestDay;

  _DailyRingPainter({
    required this.progress,
    required this.isRestDay,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.width * 0.085;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Hintergrund-Track (dunkles Slate-Navy)
    final trackPaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius, trackPaint);

    // Fortschritts-Bogen (Performance Volt)
    final progressPaint = Paint()
      ..color = isRestDay ? const Color(0xFF10B981) : AppColors.volt
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress.clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _DailyRingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isRestDay != isRestDay;
  }
}
