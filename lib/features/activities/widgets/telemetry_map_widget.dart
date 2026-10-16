import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/design/app_typography.dart';
import '../models/activity_stream.dart';

/// Farbcodierungs-Modus für den GPS-Track auf der Karte.
enum TelemetryMapColorMode {
  heartRateZone('HF-Zone'),
  powerZone('Watt-Zone'),
  paceSpeed('Pace/Speed');

  final String label;
  const TelemetryMapColorMode(this.label);
}

/// Interaktive GPS-Streckenkarte mit `flutter_map` im ORBIT Dark-Cockpit (Phase 19.3).
///
/// Unterstützt:
/// - **Ohne Karten-Opt-in (DSGVO-Default):** Rendert die GPS-Polylinie in `FlutterMap`
///   komplett ohne externen `TileLayer` vor einem edlen `#001F47` Navy-Hintergrund
///   (keine IP-Übertragung an Kartenserver) + Overlay-Button
///   „Kartenkacheln aktivieren (OpenStreetMap/Carto)“.
/// - **Mit aktivierten Kacheln:** Rendert dunkle CartoDB Dark Matter / OpenStreetMap Kacheln.
/// - **Farbcodierter GPS-Track:** Umschaltbar nach **HF-Zone**, **Watt-Zone** oder **Pace/Speed**.
/// - **Marker:** Start (Grün), Ziel (Rot), Runden-/Kilometer-Splits und live synchronisierter
///   Volt-Marker beim Scrubbing über die Telemetrie-Graphen.
class TelemetryMapWidget extends StatefulWidget {
  final List<ActivityStreamPoint> points;
  final ActivityStreamPoint? scrubPoint;
  final double height;
  final double ftpWatts;
  final double maxHrBpm;
  final bool initialTilesEnabled;
  final TileProvider? tileProviderOverride;

  const TelemetryMapWidget({
    super.key,
    required this.points,
    this.scrubPoint,
    this.height = 280,
    this.ftpWatts = 250,
    this.maxHrBpm = 190,
    this.initialTilesEnabled = false,
    this.tileProviderOverride,
  });

  @override
  State<TelemetryMapWidget> createState() => _TelemetryMapWidgetState();
}

class _TelemetryMapWidgetState extends State<TelemetryMapWidget> {
  late bool _tilesEnabled;
  TelemetryMapColorMode _colorMode = TelemetryMapColorMode.powerZone;

  @override
  void initState() {
    super.initState();
    _tilesEnabled = widget.initialTilesEnabled;
    final hasPower = widget.points.any((p) => (p.power ?? 0) > 0);
    final hasHr = widget.points.any((p) => (p.hr ?? 0) > 0);
    if (!hasPower && hasHr) {
      _colorMode = TelemetryMapColorMode.heartRateZone;
    } else if (!hasPower && !hasHr) {
      _colorMode = TelemetryMapColorMode.paceSpeed;
    }
  }

  void _requestTileConsent() {
    if (_tilesEnabled) {
      setState(() => _tilesEnabled = false);
      return;
    }

    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text(
          'Externe Kartenkacheln aktivieren?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Beim Laden von Kartenkacheln (OpenStreetMap / Carto Dark Matter) wird deine IP-Adresse an den Kartenanbieter übertragen (DSGVO-Opt-in). '
          'Ohne Kacheln bleibt die GPS-Strecke auf dem dunklen Navy-Hintergrund (#001F47) vollständig interaktiv.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text(
              'Abbrechen',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            key: const Key('telemetry_map_confirm_optin_button'),
            onPressed: () {
              setState(() => _tilesEnabled = true);
              Navigator.of(dialogCtx).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.volt,
              foregroundColor: AppColors.navy,
            ),
            child: const Text('Kacheln aktivieren'),
          ),
        ],
      ),
    );
  }

  /// Ermittelt die Zone (1..7) und zugehörige ORBIT-Zonenfarbe für einen Punkt gemäß gewähltem Modus.
  Color _colorForPoint(ActivityStreamPoint pt, double maxSpeedMps) {
    switch (_colorMode) {
      case TelemetryMapColorMode.heartRateZone:
        final hr = pt.hr;
        if (hr == null || hr <= 0 || widget.maxHrBpm <= 0) {
          return AppColors.channelHeartRate;
        }
        final pct = hr / widget.maxHrBpm;
        if (pct < 0.60) return AppColors.zoneColor(1);
        if (pct < 0.70) return AppColors.zoneColor(2);
        if (pct < 0.80) return AppColors.zoneColor(3);
        if (pct < 0.90) return AppColors.zoneColor(4);
        return AppColors.zoneColor(5);

      case TelemetryMapColorMode.powerZone:
        final p = pt.power;
        if (p == null || p <= 0 || widget.ftpWatts <= 0) {
          return AppColors.channelPower;
        }
        final pct = p / widget.ftpWatts;
        if (pct < 0.55) return AppColors.zoneColor(1);
        if (pct < 0.75) return AppColors.zoneColor(2);
        if (pct < 0.90) return AppColors.zoneColor(3);
        if (pct < 1.05) return AppColors.zoneColor(4);
        if (pct < 1.20) return AppColors.zoneColor(5);
        if (pct < 1.50) return AppColors.zoneColor(6);
        return AppColors.zoneColor(7);

      case TelemetryMapColorMode.paceSpeed:
        final s = pt.speedMps;
        if (s == null || s <= 0 || maxSpeedMps <= 0) {
          return AppColors.channelPace;
        }
        final ratio = (s / maxSpeedMps).clamp(0.0, 1.0);
        if (ratio < 0.45) return AppColors.zoneColor(1);
        if (ratio < 0.60) return AppColors.zoneColor(2);
        if (ratio < 0.75) return AppColors.zoneColor(3);
        if (ratio < 0.88) return AppColors.zoneColor(4);
        return AppColors.zoneColor(5);
    }
  }

  /// Erzeugt farbcodierte Polylinien-Segmente aus den GPS-Punkten.
  List<Polyline> _buildColoredPolylines(List<ActivityStreamPoint> gpsPoints) {
    if (gpsPoints.length < 2) return const [];

    double maxSpeed = 0;
    for (final p in gpsPoints) {
      if ((p.speedMps ?? 0) > maxSpeed) {
        maxSpeed = p.speedMps!;
      }
    }

    final polylines = <Polyline>[];
    var currentSegment = <LatLng>[
      LatLng(gpsPoints.first.lat!, gpsPoints.first.lng!),
    ];
    var currentColor = _colorForPoint(gpsPoints.first, maxSpeed);

    for (int i = 1; i < gpsPoints.length; i++) {
      final pt = gpsPoints[i];
      final latLng = LatLng(pt.lat!, pt.lng!);
      final ptColor = _colorForPoint(pt, maxSpeed);

      currentSegment.add(latLng);
      if (ptColor != currentColor || i == gpsPoints.length - 1) {
        polylines.add(
          Polyline(
            points: List<LatLng>.unmodifiable(currentSegment),
            color: currentColor,
            strokeWidth: 4.0,
          ),
        );
        currentSegment = <LatLng>[latLng];
        currentColor = ptColor;
      }
    }

    return polylines;
  }

  /// Ermittelt Runden-/Kilometer-Split-Punkte entlang der GPS-Spur.
  List<(int, LatLng)> _buildSplitMarkers(List<ActivityStreamPoint> gpsPoints) {
    if (gpsPoints.isEmpty) return const [];
    final totalDist = gpsPoints.last.distanceM;
    if (totalDist < 1000) return const [];

    // Wähle sinnvolles Split-Intervall (1 km bei Läufen/kurzen Fahrten, 5 km bei langen Fahrten)
    final splitStepM = totalDist > 15000 ? 5000.0 : 1000.0;
    final splits = <(int, LatLng)>[];
    double nextThreshold = splitStepM;
    int splitIndex = 1;

    for (final p in gpsPoints) {
      if (p.distanceM >= nextThreshold && p.lat != null && p.lng != null) {
        splits.add((splitIndex, LatLng(p.lat!, p.lng!)));
        splitIndex++;
        nextThreshold += splitStepM;
        if (splits.length >= 20) break;
      }
    }
    return splits;
  }

  /// Berechnet Zentrum und Zoomstufe passend zur Bounding-Box der GPS-Spur.
  (LatLng, double) _computeCenterAndZoom(List<ActivityStreamPoint> gpsPoints) {
    double minLat = 90.0;
    double maxLat = -90.0;
    double minLng = 180.0;
    double maxLng = -180.0;

    for (final p in gpsPoints) {
      final lat = p.lat!;
      final lng = p.lng!;
      if (lat < minLat) minLat = lat;
      if (lat > maxLat) maxLat = lat;
      if (lng < minLng) minLng = lng;
      if (lng > maxLng) maxLng = lng;
    }

    final center = LatLng((minLat + maxLat) / 2, (minLng + maxLng) / 2);
    final maxDelta = max((maxLat - minLat).abs(), (maxLng - minLng).abs());

    double zoom = 14.0;
    if (maxDelta > 0.5) {
      zoom = 9.5;
    } else if (maxDelta > 0.2) {
      zoom = 11.0;
    } else if (maxDelta > 0.08) {
      zoom = 12.2;
    } else if (maxDelta > 0.03) {
      zoom = 13.5;
    } else if (maxDelta > 0.01) {
      zoom = 14.5;
    } else {
      zoom = 15.2;
    }

    return (center, zoom);
  }

  @override
  Widget build(BuildContext context) {
    final gpsPoints =
        widget.points.where((p) => p.lat != null && p.lng != null).toList();

    if (gpsPoints.isEmpty) {
      return Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: AppColors.navy,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF334155)),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off_outlined,
              color: Colors.grey.shade500,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              'Keine GPS-Strecke erfasst (Indoor / Rolle)',
              style: AppTypography.bodySmall.copyWith(
                color: Colors.grey.shade300,
              ),
            ),
          ],
        ),
      );
    }

    final (center, zoom) = _computeCenterAndZoom(gpsPoints);
    final coloredPolylines = _buildColoredPolylines(gpsPoints);
    final splitMarkers = _buildSplitMarkers(gpsPoints);
    final startLatLng = LatLng(gpsPoints.first.lat!, gpsPoints.first.lng!);
    final finishLatLng = LatLng(gpsPoints.last.lat!, gpsPoints.last.lng!);

    final scrubLatLng =
        (widget.scrubPoint?.lat != null && widget.scrubPoint?.lng != null)
            ? LatLng(widget.scrubPoint!.lat!, widget.scrubPoint!.lng!)
            : null;

    return Container(
      key: const Key('telemetry_map_container'),
      height: widget.height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.navy, // #001F47 DSGVO Vektor-Hintergrund
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Stack(
        children: [
          // Echte interaktive FlutterMap
          FlutterMap(
            options: MapOptions(
              initialCenter: center,
              initialZoom: zoom,
              backgroundColor: AppColors.navy,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              // Nur nach explizitem DSGVO-Opt-in werden externe Kartenkacheln geladen
              if (_tilesEnabled)
                TileLayer(
                  urlTemplate:
                      'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c', 'd'],
                  userAgentPackageName: 'app.orbit.training',
                  tileProvider: widget.tileProviderOverride,
                ),

              // Farbcodierte GPS-Polylinie (HF-Zone, Watt-Zone oder Pace/Speed)
              PolylineLayer(
                polylines: coloredPolylines,
              ),

              // Start-, Ziel-, Split- und Scrubbing-Marker
              MarkerLayer(
                markers: [
                  // Runden-/Distanz-Splits
                  for (final split in splitMarkers)
                    Marker(
                      point: split.$2,
                      width: 22,
                      height: 22,
                      child: Container(
                        key: Key('telemetry_map_split_${split.$1}'),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.navy,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white70, width: 1.5),
                        ),
                        child: Text(
                          '${split.$1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                  // Start-Marker (Grün)
                  Marker(
                    point: startLatLng,
                    width: 20,
                    height: 20,
                    child: Container(
                      key: const Key('telemetry_map_start_marker'),
                      decoration: BoxDecoration(
                        color: AppColors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),

                  // Ziel-Marker (Rot)
                  Marker(
                    point: finishLatLng,
                    width: 20,
                    height: 20,
                    child: Container(
                      key: const Key('telemetry_map_finish_marker'),
                      decoration: BoxDecoration(
                        color: AppColors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),

                  // Live Scrubbing-Marker (Volt)
                  if (scrubLatLng != null)
                    Marker(
                      point: scrubLatLng,
                      width: 28,
                      height: 28,
                      child: Container(
                        key: const Key('telemetry_map_scrub_marker'),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.volt.withValues(alpha: 0.35),
                          shape: BoxShape.circle,
                        ),
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: AppColors.volt,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.navy, width: 2),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),

          // Links oben: GPS-Strecke & Distanz
          Positioned(
            top: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A).withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.route,
                    size: 14,
                    color: AppColors.volt,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'GPS-Strecke (${(gpsPoints.last.distanceM / 1000).toStringAsFixed(1)} km)',
                    style: AppTypography.label.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Rechts oben: Umschalter für Farbcodierung (HF-Zone / Watt-Zone / Pace)
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A).withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: TelemetryMapColorMode.values.map((mode) {
                  final isSelected = _colorMode == mode;
                  return InkWell(
                    key: Key('telemetry_map_mode_${mode.name}'),
                    onTap: () => setState(() => _colorMode = mode),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.volt : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        mode.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? AppColors.navy : Colors.white70,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Rechts unten: DSGVO Kartenkacheln-Opt-in Button
          Positioned(
            bottom: 10,
            right: 10,
            child: InkWell(
              key: const Key('telemetry_map_optin_button'),
              onTap: _requestTileConsent,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _tilesEnabled ? Icons.layers : Icons.layers_outlined,
                      size: 14,
                      color: _tilesEnabled ? AppColors.volt : Colors.white70,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _tilesEnabled
                          ? 'Kartenkacheln aktiv (Carto/OSM)'
                          : 'Kartenkacheln aktivieren (OpenStreetMap/Carto)',
                      style: AppTypography.label.copyWith(
                        color: _tilesEnabled ? AppColors.volt : Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
