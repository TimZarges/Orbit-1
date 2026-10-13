import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en')
  ];

  /// No description provided for @infoTerm_ftp.
  ///
  /// In de, this message translates to:
  /// **'Functional Threshold Power (FTP)'**
  String get infoTerm_ftp;

  /// No description provided for @infoTerm_ftp_desc.
  ///
  /// In de, this message translates to:
  /// **'Die höchste durchschnittliche Leistung in Watt, die du für etwa eine Stunde aufrechterhalten kannst. Dient als Basis für deine Rad-Trainingszonen.'**
  String get infoTerm_ftp_desc;

  /// No description provided for @infoTerm_lthr.
  ///
  /// In de, this message translates to:
  /// **'Schwellen-Herzfrequenz (LTHR)'**
  String get infoTerm_lthr;

  /// No description provided for @infoTerm_lthr_desc.
  ///
  /// In de, this message translates to:
  /// **'Die höchste durchschnittliche Herzfrequenz, die du für etwa eine Stunde aufrechterhalten kannst.'**
  String get infoTerm_lthr_desc;

  /// No description provided for @infoTerm_css.
  ///
  /// In de, this message translates to:
  /// **'Critical Swim Speed (CSS)'**
  String get infoTerm_css;

  /// No description provided for @infoTerm_css_desc.
  ///
  /// In de, this message translates to:
  /// **'Deine theoretische Dauer-Schwimmgeschwindigkeit ohne Erschöpfung. Basis für deine Schwimm-Trainingszonen.'**
  String get infoTerm_css_desc;

  /// No description provided for @infoTerm_zones.
  ///
  /// In de, this message translates to:
  /// **'Trainingszonen'**
  String get infoTerm_zones;

  /// No description provided for @infoTerm_zones_desc.
  ///
  /// In de, this message translates to:
  /// **'Intensitätsbereiche, die aus deinen Schwellenwerten berechnet werden. Jede Zone trainiert unterschiedliche Energiesysteme deines Körpers.'**
  String get infoTerm_zones_desc;

  /// No description provided for @infoTerm_maxHr.
  ///
  /// In de, this message translates to:
  /// **'Maximale Herzfrequenz (Max-HF)'**
  String get infoTerm_maxHr;

  /// No description provided for @infoTerm_maxHr_desc.
  ///
  /// In de, this message translates to:
  /// **'Die höchste Herzfrequenz, die dein Herz bei maximaler Anstrengung erreichen kann.'**
  String get infoTerm_maxHr_desc;

  /// No description provided for @infoTerm_restingHr.
  ///
  /// In de, this message translates to:
  /// **'Ruhepuls'**
  String get infoTerm_restingHr;

  /// No description provided for @infoTerm_restingHr_desc.
  ///
  /// In de, this message translates to:
  /// **'Deine Herzfrequenz im absoluten Ruhezustand. Ein niedriger Ruhepuls ist oft ein Zeichen für gute aerobe Fitness.'**
  String get infoTerm_restingHr_desc;

  /// No description provided for @readiness_title.
  ///
  /// In de, this message translates to:
  /// **'Tagesform'**
  String get readiness_title;

  /// No description provided for @readiness_building_baseline.
  ///
  /// In de, this message translates to:
  /// **'Basislinie im Aufbau'**
  String get readiness_building_baseline;

  /// No description provided for @readiness_building_baseline_desc.
  ///
  /// In de, this message translates to:
  /// **'ORBIT benötigt mindestens 14 Tage Messwerte, um deinen persönlichen Normalbereich verlässlich zu bestimmen.'**
  String get readiness_building_baseline_desc;

  /// No description provided for @readiness_normal.
  ///
  /// In de, this message translates to:
  /// **'Unauffällig'**
  String get readiness_normal;

  /// No description provided for @readiness_normal_desc.
  ///
  /// In de, this message translates to:
  /// **'Ruhepuls und HRV liegen im gewohnten persönlichen Bereich.'**
  String get readiness_normal_desc;

  /// No description provided for @readiness_slight_deviation.
  ///
  /// In de, this message translates to:
  /// **'Leichte Abweichung'**
  String get readiness_slight_deviation;

  /// No description provided for @readiness_slight_deviation_desc.
  ///
  /// In de, this message translates to:
  /// **'Einzelne Werte weichen leicht von deiner 28-Tage-Basislinie ab. Achte auf dein Körpergefühl und ausreichende Regeneration.'**
  String get readiness_slight_deviation_desc;

  /// No description provided for @readiness_noticeable_deviation.
  ///
  /// In de, this message translates to:
  /// **'Deutliche Abweichung'**
  String get readiness_noticeable_deviation;

  /// No description provided for @readiness_noticeable_deviation_desc.
  ///
  /// In de, this message translates to:
  /// **'Ruhepuls oder HRV weichen merklich von deinem Normalbereich ab. Erholung beachten; bei anhaltenden Beschwerden oder Unwohlsein ärztlichen Rat einholen.'**
  String get readiness_noticeable_deviation_desc;

  /// No description provided for @readiness_no_data.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Health-Daten'**
  String get readiness_no_data;

  /// No description provided for @readiness_no_data_desc.
  ///
  /// In de, this message translates to:
  /// **'Verbinde dein Garmin-Konto oder aktiviere die Demo-Daten, um deine Tagesform zu sehen.'**
  String get readiness_no_data_desc;

  /// No description provided for @readiness_coach_no_permission.
  ///
  /// In de, this message translates to:
  /// **'Health-Freigabe erforderlich'**
  String get readiness_coach_no_permission;

  /// No description provided for @readiness_coach_no_permission_desc.
  ///
  /// In de, this message translates to:
  /// **'Der Athlet hat die Weitergabe seiner Gesundheitsdaten aktuell nicht freigegeben.'**
  String get readiness_coach_no_permission_desc;

  /// No description provided for @health_resting_hr.
  ///
  /// In de, this message translates to:
  /// **'Ruhepuls'**
  String get health_resting_hr;

  /// No description provided for @health_hrv.
  ///
  /// In de, this message translates to:
  /// **'HRV'**
  String get health_hrv;

  /// No description provided for @health_sleep.
  ///
  /// In de, this message translates to:
  /// **'Schlaf'**
  String get health_sleep;

  /// No description provided for @health_info_title.
  ///
  /// In de, this message translates to:
  /// **'Über die Tagesform'**
  String get health_info_title;

  /// No description provided for @health_info_disclaimer.
  ///
  /// In de, this message translates to:
  /// **'Hinweis: Die Tagesform ist eine sportwissenschaftliche Orientierungshilfe zur Trainingssteuerung und Erholung. Sie stellt keine medizinische Diagnose oder Behandlungsempfehlung dar.'**
  String get health_info_disclaimer;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
