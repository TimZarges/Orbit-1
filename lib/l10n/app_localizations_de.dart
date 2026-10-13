// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get infoTerm_ftp => 'Functional Threshold Power (FTP)';

  @override
  String get infoTerm_ftp_desc =>
      'Die höchste durchschnittliche Leistung in Watt, die du für etwa eine Stunde aufrechterhalten kannst. Dient als Basis für deine Rad-Trainingszonen.';

  @override
  String get infoTerm_lthr => 'Schwellen-Herzfrequenz (LTHR)';

  @override
  String get infoTerm_lthr_desc =>
      'Die höchste durchschnittliche Herzfrequenz, die du für etwa eine Stunde aufrechterhalten kannst.';

  @override
  String get infoTerm_css => 'Critical Swim Speed (CSS)';

  @override
  String get infoTerm_css_desc =>
      'Deine theoretische Dauer-Schwimmgeschwindigkeit ohne Erschöpfung. Basis für deine Schwimm-Trainingszonen.';

  @override
  String get infoTerm_zones => 'Trainingszonen';

  @override
  String get infoTerm_zones_desc =>
      'Intensitätsbereiche, die aus deinen Schwellenwerten berechnet werden. Jede Zone trainiert unterschiedliche Energiesysteme deines Körpers.';

  @override
  String get infoTerm_maxHr => 'Maximale Herzfrequenz (Max-HF)';

  @override
  String get infoTerm_maxHr_desc =>
      'Die höchste Herzfrequenz, die dein Herz bei maximaler Anstrengung erreichen kann.';

  @override
  String get infoTerm_restingHr => 'Ruhepuls';

  @override
  String get infoTerm_restingHr_desc =>
      'Deine Herzfrequenz im absoluten Ruhezustand. Ein niedriger Ruhepuls ist oft ein Zeichen für gute aerobe Fitness.';

  @override
  String get readiness_title => 'Tagesform';

  @override
  String get readiness_building_baseline => 'Basislinie im Aufbau';

  @override
  String get readiness_building_baseline_desc =>
      'ORBIT benötigt mindestens 14 Tage Messwerte, um deinen persönlichen Normalbereich verlässlich zu bestimmen.';

  @override
  String get readiness_normal => 'Unauffällig';

  @override
  String get readiness_normal_desc =>
      'Ruhepuls und HRV liegen im gewohnten persönlichen Bereich.';

  @override
  String get readiness_slight_deviation => 'Leichte Abweichung';

  @override
  String get readiness_slight_deviation_desc =>
      'Einzelne Werte weichen leicht von deiner 28-Tage-Basislinie ab. Achte auf dein Körpergefühl und ausreichende Regeneration.';

  @override
  String get readiness_noticeable_deviation => 'Deutliche Abweichung';

  @override
  String get readiness_noticeable_deviation_desc =>
      'Ruhepuls oder HRV weichen merklich von deinem Normalbereich ab. Erholung beachten; bei anhaltenden Beschwerden oder Unwohlsein ärztlichen Rat einholen.';

  @override
  String get readiness_no_data => 'Noch keine Health-Daten';

  @override
  String get readiness_no_data_desc =>
      'Verbinde dein Garmin-Konto oder aktiviere die Demo-Daten, um deine Tagesform zu sehen.';

  @override
  String get readiness_coach_no_permission => 'Health-Freigabe erforderlich';

  @override
  String get readiness_coach_no_permission_desc =>
      'Der Athlet hat die Weitergabe seiner Gesundheitsdaten aktuell nicht freigegeben.';

  @override
  String get health_resting_hr => 'Ruhepuls';

  @override
  String get health_hrv => 'HRV';

  @override
  String get health_sleep => 'Schlaf';

  @override
  String get health_info_title => 'Über die Tagesform';

  @override
  String get health_info_disclaimer =>
      'Hinweis: Die Tagesform ist eine sportwissenschaftliche Orientierungshilfe zur Trainingssteuerung und Erholung. Sie stellt keine medizinische Diagnose oder Behandlungsempfehlung dar.';
}
