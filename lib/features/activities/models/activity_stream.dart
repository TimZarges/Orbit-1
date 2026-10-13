/// Einzelner Sekunden-Datenpunkt im Telemetrie-Stream.
class ActivityStreamPoint {
  final int timeSec;
  final double? hr;
  final double? power;
  final double? cadence;
  final double? speedMps;
  final double? altitudeM;
  final double? lat;
  final double? lng;
  final double? tempC;
  final double? coreTempC;
  final double distanceM;

  const ActivityStreamPoint({
    required this.timeSec,
    this.hr,
    this.power,
    this.cadence,
    this.speedMps,
    this.altitudeM,
    this.lat,
    this.lng,
    this.tempC,
    this.coreTempC,
    this.distanceM = 0.0,
  });

  factory ActivityStreamPoint.fromArrays({
    required int index,
    required List<dynamic> time,
    List<dynamic>? heartRate,
    List<dynamic>? power,
    List<dynamic>? cadence,
    List<dynamic>? speed,
    List<dynamic>? altitude,
    List<dynamic>? positionLat,
    List<dynamic>? positionLng,
    List<dynamic>? temperature,
    List<dynamic>? coreTemperature,
    double cumulativeDistance = 0.0,
  }) {
    final t = (time[index] as num?)?.toInt() ?? index;
    final h = heartRate != null && index < heartRate.length ? (heartRate[index] as num?)?.toDouble() : null;
    final p = power != null && index < power.length ? (power[index] as num?)?.toDouble() : null;
    final c = cadence != null && index < cadence.length ? (cadence[index] as num?)?.toDouble() : null;
    final s = speed != null && index < speed.length ? (speed[index] as num?)?.toDouble() : null;
    final a = altitude != null && index < altitude.length ? (altitude[index] as num?)?.toDouble() : null;
    final lat = positionLat != null && index < positionLat.length ? (positionLat[index] as num?)?.toDouble() : null;
    final lng = positionLng != null && index < positionLng.length ? (positionLng[index] as num?)?.toDouble() : null;
    final temp = temperature != null && index < temperature.length ? (temperature[index] as num?)?.toDouble() : null;
    final cTemp = coreTemperature != null && index < coreTemperature.length ? (coreTemperature[index] as num?)?.toDouble() : null;

    return ActivityStreamPoint(
      timeSec: t,
      hr: h,
      power: p,
      cadence: c,
      speedMps: s,
      altitudeM: a,
      lat: lat,
      lng: lng,
      tempC: temp,
      coreTempC: cTemp,
      distanceM: cumulativeDistance,
    );
  }
}

/// Vollständiger Zeitreihen-Stream einer absolvierten Aktivität (auf 1 Hz gesampelt).
class ActivityStream {
  final int version;
  final int sampleRateSec;
  final int lengthSec;
  final List<ActivityStreamPoint> points;

  const ActivityStream({
    this.version = 1,
    this.sampleRateSec = 1,
    required this.lengthSec,
    required this.points,
  });

  bool get hasHr => points.any((p) => p.hr != null && p.hr! > 0);
  bool get hasPower => points.any((p) => p.power != null && p.power! > 0);
  bool get hasCadence => points.any((p) => p.cadence != null && p.cadence! > 0);
  bool get hasSpeed => points.any((p) => p.speedMps != null && p.speedMps! > 0);
  bool get hasAltitude => points.any((p) => p.altitudeM != null);
  bool get hasGps => points.any((p) => p.lat != null && p.lng != null);
  bool get hasTemp => points.any((p) => p.tempC != null || p.coreTempC != null);

  double get maxPower => points.map((p) => p.power ?? 0.0).fold(0.0, (a, b) => a > b ? a : b);
  double get maxHr => points.map((p) => p.hr ?? 0.0).fold(0.0, (a, b) => a > b ? a : b);
  double get maxSpeedMps => points.map((p) => p.speedMps ?? 0.0).fold(0.0, (a, b) => a > b ? a : b);

  factory ActivityStream.fromJsonMap(Map<String, dynamic> json) {
    final version = (json['version'] as num?)?.toInt() ?? 1;
    final sampleRateSec = (json['sampleRateSec'] as num?)?.toInt() ?? 1;
    final length = (json['length'] as num?)?.toInt() ?? 0;

    final timeList = json['time'] as List<dynamic>? ?? [];
    final hrList = json['heartRate'] as List<dynamic>?;
    final powerList = json['power'] as List<dynamic>?;
    final cadList = json['cadence'] as List<dynamic>?;
    final speedList = json['speed'] as List<dynamic>?;
    final altList = json['altitude'] as List<dynamic>?;
    final latList = json['positionLat'] as List<dynamic>?;
    final lngList = json['positionLng'] as List<dynamic>?;
    final tempList = json['temperature'] as List<dynamic>?;
    final coreTempList = json['coreTemperature'] as List<dynamic>?;

    final count = timeList.isNotEmpty ? timeList.length : length;
    final points = <ActivityStreamPoint>[];

    double cumulativeDist = 0.0;
    for (int i = 0; i < count; i++) {
      final s = (speedList != null && i < speedList.length) ? (speedList[i] as num?)?.toDouble() : null;
      if (s != null && s > 0) {
        cumulativeDist += s * sampleRateSec;
      }

      points.add(ActivityStreamPoint.fromArrays(
        index: i,
        time: timeList.isNotEmpty ? timeList : List.generate(count, (idx) => idx * sampleRateSec),
        heartRate: hrList,
        power: powerList,
        cadence: cadList,
        speed: speedList,
        altitude: altList,
        positionLat: latList,
        positionLng: lngList,
        temperature: tempList,
        coreTemperature: coreTempList,
        cumulativeDistance: cumulativeDist,
      ));
    }

    return ActivityStream(
      version: version,
      sampleRateSec: sampleRateSec,
      lengthSec: count * sampleRateSec,
      points: points,
    );
  }
}
