import 'package:flutter/material.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/routing/app_router.dart';
import 'beta_bug_reporter_sheet.dart';

/// Global greifbarer, schwebender Bug-Käfer-Button für die Beta-Testphase (Phase 38.1).
///
/// Wird im `MaterialApp.builder` auf oberster Z-Index-Ebene platziert. Dadurch bleibt
/// der Käfer auch bei geöffneten modalen Bottom-Sheets (Workout-Detail, Benachrichtigungen,
/// Workout-Builder etc.) vollständig sichtbar, interaktiv und frei verschiebbar.
///
/// Ein Antippen erfasst automatisch den Bildschirm inklusive aller offenen Overlays
/// und öffnet das [BetaBugReporterSheet].
class GlobalFloatingBugBeetle extends StatefulWidget {
  /// Ermöglicht das gezielte Deaktivieren des Käfers (z. B. in speziellen Test-Szenarien).
  final bool enabled;

  const GlobalFloatingBugBeetle({
    super.key,
    this.enabled = true,
  });

  @override
  State<GlobalFloatingBugBeetle> createState() =>
      _GlobalFloatingBugBeetleState();
}

class _GlobalFloatingBugBeetleState extends State<GlobalFloatingBugBeetle> {
  Offset? _offset;
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return const SizedBox.shrink();

    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);

    // Standard-Positionierung: Unten rechts über der Bottom Navigation Bar (ca. 130px von unten)
    final defaultOffset = Offset(
      size.width - 64.0 - padding.right,
      size.height - 130.0 - padding.bottom,
    );
    final currentOffset = _offset ?? defaultOffset;

    // Klemmen der Koordinaten an die sicheren Bildschirmränder
    final clampedX = currentOffset.dx.clamp(
      padding.left + 8.0,
      size.width - padding.right - 56.0,
    );
    final clampedY = currentOffset.dy.clamp(
      padding.top + 8.0,
      size.height - padding.bottom - 56.0,
    );

    return Positioned(
      left: clampedX,
      top: clampedY,
      child: Material(
        type: MaterialType.transparency,
        child: GestureDetector(
          onPanStart: (_) {
            setState(() => _isDragging = true);
          },
          onPanUpdate: (details) {
            setState(() {
              _offset = Offset(
                clampedX + details.delta.dx,
                clampedY + details.delta.dy,
              );
            });
          },
          onPanEnd: (_) {
            setState(() => _isDragging = false);
          },
          child: Tooltip(
            message: 'Beta-Feedback & Bug melden',
            child: InkWell(
              key: const Key('global_floating_bug_beetle'),
              onTap: () {
                final navContext = rootNavigatorKey.currentContext ?? context;
                showBetaBugReporterSheet(navContext);
              },
              borderRadius: BorderRadius.circular(24),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.navy,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.volt,
                    width: _isDragging ? 2.5 : 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.volt
                          .withValues(alpha: _isDragging ? 0.4 : 0.2),
                      blurRadius: _isDragging ? 12 : 6,
                      spreadRadius: _isDragging ? 2 : 1,
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.bug_report_rounded,
                    color: AppColors.volt,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
