import '../models/race_goal.dart';

enum HomeCardType {
  actionBanner,
  heroDailyRing,
  raceCountdown,
  formTrafficLight,
  recentActivity,
  demoBanner,
  emptyGetStarted,
}

/// Kontext-Eingabe für den HomeCardResolver.
class HomeCardContext {
  final bool isBrandNewUser;
  final bool isDemo;
  final bool hasTodayPlan;
  final bool isRestDay;
  final double todayActualLoad;
  final double todayPlannedLoad;
  final int unreadChatMessages;
  final int pendingThresholdProposals;
  final int unmatchedActivitiesCount;
  final bool hasRecentActivity;
  final bool hasFormOrReadiness;
  final RaceGoal? raceGoal;

  const HomeCardContext({
    this.isBrandNewUser = false,
    this.isDemo = false,
    this.hasTodayPlan = false,
    this.isRestDay = false,
    this.todayActualLoad = 0.0,
    this.todayPlannedLoad = 0.0,
    this.unreadChatMessages = 0,
    this.pendingThresholdProposals = 0,
    this.unmatchedActivitiesCount = 0,
    this.hasRecentActivity = false,
    this.hasFormOrReadiness = false,
    this.raceGoal,
  });

  bool get hasActionItems =>
      unreadChatMessages > 0 ||
      pendingThresholdProposals > 0 ||
      unmatchedActivitiesCount > 0;
}

/// Domänenlogik zur Priorisierung und Anordnung der Home-Dashboard-Karten („Heute").
///
/// Regeln:
/// 1. Neuer Nutzer ohne Daten -> `emptyGetStarted`.
/// 2. To-Do / Action-Banner erscheint ganz oben, wenn Handlungsbedarf besteht.
/// 3. Hero Navy Card (Daily Ring + Heutiges Training / Ruhetag) ist das visuelle Zentrum.
/// 4. Wettkampf-Countdown folgt direkt, falls ein aktives Ziel hinterlegt ist.
/// 5. Form-Ampel / Erholungsstatus liefert physiologischen Kontext.
/// 6. Letzte absolvierte Aktivität mit 1-Klick-Link ins Cockpit.
/// 7. Maximal 4 Karten oberhalb der Falz für ruhiges, klares Nutzererlebnis.
class HomeCardResolver {
  const HomeCardResolver();

  List<HomeCardType> resolveVisibleCards(HomeCardContext context) {
    if (context.isBrandNewUser) {
      return const [HomeCardType.emptyGetStarted];
    }

    final cards = <HomeCardType>[];

    // 1. Dringende To-Dos / Aktionen ganz oben
    if (context.hasActionItems) {
      cards.add(HomeCardType.actionBanner);
    }

    // 2. Hero-Karte mit Daily Ring (immer an zentraler Stelle)
    cards.add(HomeCardType.heroDailyRing);

    // 3. Wettkampf-Countdown (wenn vorhanden und in der Zukunft)
    if (context.raceGoal != null && context.raceGoal!.daysRemaining >= 0) {
      cards.add(HomeCardType.raceCountdown);
    }

    // 4. Form-Ampel / Erholungsstatus
    if (context.hasFormOrReadiness) {
      cards.add(HomeCardType.formTrafficLight);
    }

    // 5. Letzte Aktivität
    if (context.hasRecentActivity) {
      cards.add(HomeCardType.recentActivity);
    }

    // 6. Demo-Hinweis (am Ende)
    if (context.isDemo) {
      cards.add(HomeCardType.demoBanner);
    }

    return cards;
  }
}
