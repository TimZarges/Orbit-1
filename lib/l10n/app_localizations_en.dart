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

  @override
  String get readiness_title => 'Daily Readiness';

  @override
  String get readiness_building_baseline => 'Building Baseline';

  @override
  String get readiness_building_baseline_desc =>
      'ORBIT requires at least 14 days of data to reliably determine your personal normal range.';

  @override
  String get readiness_normal => 'Normal';

  @override
  String get readiness_normal_desc =>
      'Resting heart rate and HRV are within your typical personal range.';

  @override
  String get readiness_slight_deviation => 'Slight Deviation';

  @override
  String get readiness_slight_deviation_desc =>
      'Individual values slightly deviate from your 28-day baseline. Pay attention to how you feel and ensure adequate recovery.';

  @override
  String get readiness_noticeable_deviation => 'Noticeable Deviation';

  @override
  String get readiness_noticeable_deviation_desc =>
      'Resting heart rate or HRV deviate noticeably from your normal range. Prioritize recovery; consult a physician if you experience persistent symptoms or feel unwell.';

  @override
  String get readiness_no_data => 'No Health Data Yet';

  @override
  String get readiness_no_data_desc =>
      'Connect your Garmin account or enable demo data to see your daily readiness.';

  @override
  String get readiness_coach_no_permission => 'Health Permission Required';

  @override
  String get readiness_coach_no_permission_desc =>
      'The athlete has not enabled health data sharing with their coach.';

  @override
  String get health_resting_hr => 'Resting HR';

  @override
  String get health_hrv => 'HRV';

  @override
  String get health_sleep => 'Sleep';

  @override
  String get health_info_title => 'About Daily Readiness';

  @override
  String get health_info_disclaimer =>
      'Note: Daily readiness is a sports science guideline for training and recovery. It does not constitute medical advice or a treatment recommendation.';
}
