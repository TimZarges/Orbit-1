import 'package:flutter_test/flutter_test.dart';
import 'package:orbit/features/home/domain/home_card_resolver.dart';
import 'package:orbit/features/home/models/race_goal.dart';

void main() {
  group('HomeCardResolver Tests', () {
    const resolver = HomeCardResolver();

    test('Brand new user without data resolves only to emptyGetStarted', () {
      const context = HomeCardContext(
        isBrandNewUser: true,
      );

      final cards = resolver.resolveVisibleCards(context);
      expect(cards, equals([HomeCardType.emptyGetStarted]));
    });

    test('Regular user with today plan and form traffic light', () {
      const context = HomeCardContext(
        isBrandNewUser: false,
        hasTodayPlan: true,
        todayActualLoad: 45.0,
        todayPlannedLoad: 75.0,
        hasFormOrReadiness: true,
        hasRecentActivity: true,
      );

      final cards = resolver.resolveVisibleCards(context);
      expect(cards, contains(HomeCardType.heroDailyRing));
      expect(cards, contains(HomeCardType.formTrafficLight));
      expect(cards, contains(HomeCardType.recentActivity));
      expect(cards, isNot(contains(HomeCardType.actionBanner)));
      expect(cards, isNot(contains(HomeCardType.raceCountdown)));
    });

    test('User with action items prioritizes actionBanner at top', () {
      const context = HomeCardContext(
        isBrandNewUser: false,
        unreadChatMessages: 2,
        pendingThresholdProposals: 1,
        hasTodayPlan: true,
      );

      final cards = resolver.resolveVisibleCards(context);
      expect(cards.first, equals(HomeCardType.actionBanner));
      expect(cards[1], equals(HomeCardType.heroDailyRing));
    });

    test('User with upcoming race goal displays raceCountdown card after hero', () {
      final now = DateTime.now();
      final futureDate = '${now.year + 1}-08-20';
      final goal = RaceGoal(
        title: 'Ironman Frankfurt',
        date: futureDate,
        distance: 'Langdistanz',
      );

      final context = HomeCardContext(
        isBrandNewUser: false,
        raceGoal: goal,
        hasTodayPlan: false,
        isRestDay: true,
      );

      final cards = resolver.resolveVisibleCards(context);
      expect(cards, contains(HomeCardType.raceCountdown));
      final heroIndex = cards.indexOf(HomeCardType.heroDailyRing);
      final raceIndex = cards.indexOf(HomeCardType.raceCountdown);
      expect(raceIndex, equals(heroIndex + 1));
    });

    test('Past race goal is omitted from cards', () {
      final goal = RaceGoal(
        title: 'Marathon 2020',
        date: '2020-04-12',
      );

      final context = HomeCardContext(
        isBrandNewUser: false,
        raceGoal: goal,
      );

      final cards = resolver.resolveVisibleCards(context);
      expect(cards, isNot(contains(HomeCardType.raceCountdown)));
    });

    test('Demo user displays demoBanner at end of dashboard', () {
      const context = HomeCardContext(
        isBrandNewUser: false,
        isDemo: true,
        hasTodayPlan: true,
      );

      final cards = resolver.resolveVisibleCards(context);
      expect(cards.last, equals(HomeCardType.demoBanner));
    });
  });
}
