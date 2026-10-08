// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get infoTerm_ftp => 'Functional Threshold Power (FTP)';

  @override
  String get infoTerm_ftp_desc =>
      'The highest average power in watts you can sustain for about an hour. Serves as the basis for your cycling training zones.';

  @override
  String get infoTerm_lthr => 'Lactate Threshold Heart Rate (LTHR)';

  @override
  String get infoTerm_lthr_desc =>
      'The highest average heart rate you can sustain for about an hour.';

  @override
  String get infoTerm_css => 'Critical Swim Speed (CSS)';

  @override
  String get infoTerm_css_desc =>
      'Your theoretical continuous swimming speed without exhaustion. Basis for your swimming training zones.';

  @override
  String get infoTerm_zones => 'Training Zones';

  @override
  String get infoTerm_zones_desc =>
      'Intensity ranges calculated from your threshold values. Each zone trains different energy systems in your body.';

  @override
  String get infoTerm_maxHr => 'Maximum Heart Rate (Max-HR)';

  @override
  String get infoTerm_maxHr_desc =>
      'The highest heart rate your heart can reach during maximum effort.';

  @override
  String get infoTerm_restingHr => 'Resting Heart Rate';

  @override
  String get infoTerm_restingHr_desc =>
      'Your heart rate in a state of absolute rest. A low resting heart rate is often a sign of good aerobic fitness.';
}
