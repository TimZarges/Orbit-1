/// Datei-Header: `lib/core/widgets/responsive_content_frame.dart`
/// Zweck: Responsive Breitenbegrenzung und zentrierte Inhaltsdarstellung für
/// große Bildschirme (Web, Desktop, Tablet ab `900px` Breite) bei voller Breite
/// auf mobilen Smartphones.
/// Architektur-Einordnung: Core-UI-Baustein (`lib/core/widgets/`), nutzt
/// `const`-Konstruktoren und verursacht keinen Rebuild-Overhead (`AGENTS.md` Regel 10).
library;

import 'package:flutter/material.dart';

/// Responsive Inhaltsrahmen für Web, Tablet und Desktop.
///
/// Was: Begrenzt auf breiten Viewports (`width >= 900px`) die maximale Breite
/// des Inhalts auf [maxWidth] (Standard `1040.0`) und zentriert ihn horizontal,
/// während auf schmalen Mobilgeräten die gesamte Breite genutzt wird.
/// Warum: Verhindert überbreite Karten und Formulare im Web-Browser und sorgt
/// für ein ruhiges, professionelles Sport-Layout auf großen Monitoren.
class ResponsiveContentFrame extends StatelessWidget {
  /// Schwellenwert für das Umschalten auf das Web-/Desktop-Layout.
  static const double desktopBreakpoint = 900.0;

  /// Schwellenwert für eine ausgeklappte (`extended`) Seitenleiste.
  static const double extendedRailBreakpoint = 1160.0;

  /// Das einzubettende Child-Widget.
  final Widget child;

  /// Maximale Breite auf großen Bildschirmen in logischen Pixeln.
  final double maxWidth;

  /// Erstellt einen [ResponsiveContentFrame].
  const ResponsiveContentFrame({
    super.key,
    required this.child,
    this.maxWidth = 1040.0,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < desktopBreakpoint) {
          return child;
        }
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: child,
          ),
        );
      },
    );
  }
}
