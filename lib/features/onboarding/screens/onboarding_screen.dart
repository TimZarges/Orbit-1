import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  String? _selectedRole;
  List<String> _selectedSports = [];
  String? _experienceLevel;

  final _goalNameController = TextEditingController();
  final _goalTypeController = TextEditingController();
  DateTime? _goalDate;

  void _nextPage() {
    if (_currentIndex < 4) {
      _pageController.nextPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      _finishOnboarding();
    }
  }

  void _finishOnboarding() async {
    // TODO: Call cloud function setInitialRole
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Schritt ${_currentIndex + 1} von 5'),
        leading: _currentIndex > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut);
                },
              )
            : null,
      ),
      body: PageView(
        controller: _pageController,
        physics:
            const NeverScrollableScrollPhysics(), // Blockiert Wischen, Nutzer muss Buttons tippen
        onPageChanged: (index) => setState(() => _currentIndex = index),
        children: [
          _buildRoleSelection(),
          _buildSportsSelection(),
          _buildExperienceLevelSelection(),
          _buildGoalSelection(),
          _buildFinishScreen(),
        ],
      ),
    );
  }

  Widget _buildRoleSelection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Wähle deine Rolle',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              setState(() => _selectedRole = 'ATHLETE');
              _nextPage();
            },
            child: const Text('Ich bin Athlet'),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() => _selectedRole = 'TRAINER');
              _nextPage();
            },
            child: const Text('Ich bin Trainer'),
          ),
        ],
      ),
    );
  }

  Widget _buildSportsSelection() {
    final sports = ['TRIATHLON', 'BIKE', 'RUN', 'SWIM', 'STRENGTH'];
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Deine Sportarten',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 24),
          ...sports.map((sport) => CheckboxListTile(
                title: Text(sport),
                value: _selectedSports.contains(sport),
                onChanged: (val) {
                  setState(() {
                    if (val == true) {
                      _selectedSports.add(sport);
                    } else {
                      _selectedSports.remove(sport);
                    }
                  });
                },
              )),
          const Spacer(),
          ElevatedButton(
            onPressed: _selectedSports.isNotEmpty ? _nextPage : null,
            child: const Text('Weiter'),
          ),
        ],
      ),
    );
  }

  Widget _buildExperienceLevelSelection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Erfahrungsstufe',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 24),
          ListTile(
            title: const Text('Einfach'),
            subtitle: const Text('Basis-Metriken, leicht verständlich'),
            onTap: () {
              setState(() => _experienceLevel = 'SIMPLE');
              _nextPage();
            },
          ),
          ListTile(
            title: const Text('Fortgeschritten'),
            subtitle: const Text('TSS, Zonen und grundlegende Analyse'),
            onTap: () {
              setState(() => _experienceLevel = 'ADVANCED');
              _nextPage();
            },
          ),
          ListTile(
            title: const Text('Experte'),
            subtitle: const Text('Alle Metriken, volle Datenkontrolle'),
            onTap: () {
              setState(() => _experienceLevel = 'EXPERT');
              _nextPage();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGoalSelection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Wettkampfziel (optional)',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 24),
          TextField(
            controller: _goalNameController,
            decoration:
                const InputDecoration(labelText: 'Name (z.B. Ironman 70.3)'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _goalTypeController,
            decoration:
                const InputDecoration(labelText: 'Typ (z.B. Triathlon)'),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
              );
              if (date != null) {
                setState(() => _goalDate = date);
              }
            },
            child: Text(_goalDate != null
                ? _goalDate.toString().split(' ')[0]
                : 'Datum wählen'),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: _nextPage,
            child: const Text('Weiter'),
          ),
          TextButton(
            onPressed: _nextPage,
            child: const Text('Überspringen'),
          ),
        ],
      ),
    );
  }

  Widget _buildFinishScreen() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Fast geschafft!',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {},
            child: const Text('Garmin verbinden (folgt)'),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {},
            child: const Text('FIT importieren (folgt)'),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _finishOnboarding,
            child: const Text('Setup abschließen'),
          ),
        ],
      ),
    );
  }
}
