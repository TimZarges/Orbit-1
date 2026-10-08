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
}
