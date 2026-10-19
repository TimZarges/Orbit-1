import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/design/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../../onboarding/widgets/triathlon_combined_icon.dart';
import '../../races/models/race.dart';
import '../../races/providers/races_provider.dart';
import '../../workout_builder/screens/workout_builder_screen.dart';
import '../../workout_builder/screens/workout_template_library_screen.dart';
import '../models/planned_workout.dart';
import '../providers/calendar_provider.dart';
import '../../beta_feedback/widgets/beta_bug_reporter_sheet.dart';
import '../../home/providers/home_dashboard_provider.dart';

/// Öffnet das Formular zur Schnelleingabe einer neuen geplanten Trainingseinheit oder eines Wettkampfs (Phase 37.4).
Future<void> showCreateWorkoutDialog(
  BuildContext context, {
  required String athleteId,
  DateTime? initialDate,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF001F47), // Deep Navy
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child:
          CreateWorkoutDialog(athleteId: athleteId, initialDate: initialDate),
    ),
  );
}

/// Dialog zur Schnelleingabe von Einheiten, Koppeleinheiten (Triathlon) und A/B/C Wettkämpfen.
class CreateWorkoutDialog extends ConsumerStatefulWidget {
  /// ID des Athleten, für den die Einheit geplant wird.
  final String athleteId;

  /// Optionales voreingestelltes Datum.
  final DateTime? initialDate;

  const CreateWorkoutDialog({
    super.key,
    required this.athleteId,
    this.initialDate,
  });

  @override
  ConsumerState<CreateWorkoutDialog> createState() =>
      _CreateWorkoutDialogState();
}

class _CreateWorkoutDialogState extends ConsumerState<CreateWorkoutDialog> {
  final _formKey = GlobalKey<FormState>();

  // Modus: false = Training planen, true = Wettkampf / Rennen planen
  bool _isRaceMode = false;

  // Gemeinsame Felder
  late DateTime _selectedDate;
  String _sport = 'RUN';
  bool _isSaving = false;

  // Trainings-Felder
  final _titleController = TextEditingController();
  final _durationMinutesController = TextEditingController(text: '60');
  final _distanceKmController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _intensity = 'MODERATE';

  // Wettkampf-Felder
  final _raceTitleController = TextEditingController();
  final _raceDistanceController = TextEditingController();
  final _raceTargetTimeController = TextEditingController();
  final _raceTargetPowerController = TextEditingController();
  final _raceNotesController = TextEditingController();
  RacePriority _racePriority = RacePriority.a;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
    _titleController.text = 'Lauf Dauerlauf GA1';
    _raceTitleController.text = 'Saison-Wettkampf';
    _raceDistanceController.text = 'Mitteldistanz';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _durationMinutesController.dispose();
    _distanceKmController.dispose();
    _descriptionController.dispose();
    _raceTitleController.dispose();
    _raceDistanceController.dispose();
    _raceTargetTimeController.dispose();
    _raceTargetPowerController.dispose();
    _raceNotesController.dispose();
    super.dispose();
  }

  void _onSportChanged(String sport) {
    setState(() {
      _sport = sport;
      if (sport == 'RUN') _titleController.text = 'Lauf Dauerlauf GA1';
      if (sport == 'BIKE') _titleController.text = 'Rad Grundlagenausdauer GA1';
      if (sport == 'SWIM') {
        _titleController.text = 'Schwimmen Technik & Ausdauer';
      }
      if (sport == 'TRIATHLON') {
        _titleController.text = 'Triathlon Koppeltraining (Rad + Lauf)';
      }
      if (sport == 'STRENGTH') _titleController.text = 'Stabi & Krafttraining';
      if (sport == 'OTHER') _titleController.text = 'Regeneration & Yoga';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.90,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Drag Handle
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF475569),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _isRaceMode
                          ? 'Wettkampf / Rennen planen'
                          : 'Training planen',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const BetaBugReportIconButton(),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white70),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Modus-Umschaltung: Training vs. Wettkampf
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment<bool>(
                      value: false,
                      icon: Icon(Icons.fitness_center, size: 16),
                      label: Text(
                        'Training planen',
                        key: Key('planner_mode_training'),
                      ),
                    ),
                    ButtonSegment<bool>(
                      value: true,
                      icon: Icon(Icons.emoji_events_outlined, size: 16),
                      label: Text(
                        'Wettkampf / Rennen',
                        key: Key('planner_mode_race'),
                      ),
                    ),
                  ],
                  selected: {_isRaceMode},
                  onSelectionChanged: (set) {
                    if (set.isNotEmpty) {
                      setState(() => _isRaceMode = set.first);
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Datumsauswahl
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today,
                      color: AppColors.volt, size: 20),
                  title: const Text('Datum',
                      style: TextStyle(color: Colors.white70, fontSize: 13)),
                  subtitle: Text(
                    DateFormat('dd.MM.yyyy').format(_selectedDate),
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15),
                  ),
                  trailing: TextButton(
                    key: const Key('plan_date_picker_button'),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2025),
                        lastDate: DateTime(2030),
                        builder: (ctx, child) {
                          return Theme(
                            data: Theme.of(ctx).copyWith(
                              colorScheme: const ColorScheme.dark(
                                primary: AppColors.volt,
                                onPrimary: AppColors.navy,
                                surface: Color(0xFF002A5C),
                                onSurface: Colors.white,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setState(() => _selectedDate = picked);
                      }
                    },
                    child: const Text('Ändern',
                        style: TextStyle(color: AppColors.volt)),
                  ),
                ),
                const SizedBox(height: 10),

                // Sportart-Auswahl (inkl. Triathlon / Koppel)
                Text(
                  'Sportart',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _sportChip('TRIATHLON', 'Triathlon / Koppel', null,
                        AppColors.volt),
                    _sportChip('BIKE', 'Rad', Icons.directions_bike,
                        AppColors.sportBike),
                    _sportChip('RUN', 'Laufen', Icons.directions_run,
                        AppColors.sportRun),
                    _sportChip(
                        'SWIM', 'Schwimmen', Icons.pool, AppColors.sportSwim),
                    _sportChip('STRENGTH', 'Kraft', Icons.fitness_center,
                        AppColors.sportStrength),
                    _sportChip('OTHER', 'Sonstiges', Icons.sports,
                        AppColors.navyLight),
                  ],
                ),
                const SizedBox(height: 16),

                // MODUS 1: WETTKAMPF-PLANUNG
                if (_isRaceMode) ...[
                  // Wettkampf-Priorität (A / B / C)
                  Text(
                    'Priorität des Rennens',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<RacePriority>(
                    segments: const [
                      ButtonSegment<RacePriority>(
                        value: RacePriority.a,
                        label: Text(
                          'A-Hauptziel',
                          key: Key('race_priority_A'),
                        ),
                        icon: Icon(Icons.star, color: AppColors.volt, size: 16),
                      ),
                      ButtonSegment<RacePriority>(
                        value: RacePriority.b,
                        label: Text(
                          'B-Vorbereitung',
                          key: Key('race_priority_B'),
                        ),
                      ),
                      ButtonSegment<RacePriority>(
                        value: RacePriority.c,
                        label: Text(
                          'C-Testrennen',
                          key: Key('race_priority_C'),
                        ),
                      ),
                    ],
                    selected: {_racePriority},
                    onSelectionChanged: (set) {
                      if (set.isNotEmpty) {
                        setState(() => _racePriority = set.first);
                      }
                    },
                  ),
                  const SizedBox(height: 14),

                  // Name des Rennens
                  TextFormField(
                    key: const Key('race_title_field'),
                    controller: _raceTitleController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Name des Wettkampfs',
                      hintText: 'z. B. Challenge Roth, Berlin Marathon',
                      labelStyle: TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) => val == null || val.trim().isEmpty
                        ? 'Bitte Wettkampf-Namen eingeben'
                        : null,
                  ),
                  const SizedBox(height: 14),

                  // Distanz / Kategorie & Zielzeit
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          key: const Key('race_distance_field'),
                          controller: _raceDistanceController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Distanz / Format',
                            hintText: 'Mitteldistanz, Marathon',
                            labelStyle: TextStyle(color: Colors.white70),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          key: const Key('race_target_time_field'),
                          controller: _raceTargetTimeController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Zielzeit (opt.)',
                            hintText: '04:30:00',
                            labelStyle: TextStyle(color: Colors.white70),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Renn-Notizen
                  TextFormField(
                    controller: _raceNotesController,
                    style: const TextStyle(color: Colors.white),
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Renntaktik & Notizen (optional)',
                      hintText:
                          'Pacing-Strategie, Verpflegungsplan, Ausrüstung',
                      labelStyle: TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Wettkampf speichern
                  ElevatedButton.icon(
                    key: const Key('race_save_button'),
                    onPressed: _isSaving ? null : _saveRace,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.volt,
                      foregroundColor: AppColors.navy,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.emoji_events),
                    label: Text(
                      _isSaving
                          ? 'Speichere...'
                          : '${_racePriority.name.toUpperCase()}-Wettkampf planen',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ] else ...[
                  // MODUS 2: NORMALES TRAINING / KOPPEL-EINHEIT
                  // Titel
                  TextFormField(
                    controller: _titleController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Titel der Einheit',
                      labelStyle: TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) => val == null || val.trim().isEmpty
                        ? 'Bitte Titel eingeben'
                        : null,
                  ),
                  const SizedBox(height: 14),

                  // Dauer und Distanz
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _durationMinutesController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Dauer (Minuten)',
                            labelStyle: TextStyle(color: Colors.white70),
                            border: OutlineInputBorder(),
                          ),
                          validator: (val) {
                            final parsed = int.tryParse(val ?? '');
                            if (parsed == null || parsed <= 0) {
                              return 'Gültige Dauer angeben';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _distanceKmController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Distanz (km, opt.)',
                            labelStyle: TextStyle(color: Colors.white70),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Intensität
                  DropdownButtonFormField<String>(
                    initialValue: _intensity,
                    dropdownColor: const Color(0xFF002A5C),
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Intensität',
                      labelStyle: TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: 'EASY',
                          child: Text('Locker / Erholung (Z1-Z2)')),
                      DropdownMenuItem(
                          value: 'MODERATE',
                          child: Text('Moderat / GA1 (Z2-Z3)')),
                      DropdownMenuItem(
                          value: 'HARD',
                          child: Text('Hart / Tempo / Schwelle (Z4)')),
                      DropdownMenuItem(
                          value: 'INTERVALS',
                          child: Text('Intervalle / HIIT (Z5+)')),
                    ],
                    onChanged: (val) =>
                        setState(() => _intensity = val ?? 'MODERATE'),
                  ),
                  const SizedBox(height: 14),

                  // Beschreibung
                  TextFormField(
                    controller: _descriptionController,
                    style: const TextStyle(color: Colors.white),
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Notizen / Beschreibung (optional)',
                      labelStyle: TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Aus Vorlage wählen oder im Builder bauen
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.library_books_outlined,
                              size: 16),
                          label: const Text('Aus Vorlage',
                              style: TextStyle(fontSize: 12)),
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => WorkoutTemplateLibraryScreen(
                                  athleteId: widget.athleteId,
                                  targetLocalDate: DateFormat('yyyy-MM-dd')
                                      .format(_selectedDate),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon:
                              const Icon(Icons.construction_outlined, size: 16),
                          label: const Text('Im Builder bauen',
                              style: TextStyle(fontSize: 12)),
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => WorkoutBuilderScreen(
                                  sport: _sport,
                                  athleteId: widget.athleteId,
                                  targetLocalDate: DateFormat('yyyy-MM-dd')
                                      .format(_selectedDate),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Speichern
                  ElevatedButton(
                    onPressed: _isSaving ? null : _saveWorkout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.volt,
                      foregroundColor: AppColors.navy,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(
                            'Einheit speichern',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sportChip(String sport, String label, IconData? icon, Color color) {
    final isSelected = _sport == sport;

    Widget avatarWidget;
    if (sport == 'TRIATHLON') {
      avatarWidget = const SizedBox(
        width: 18,
        height: 18,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: TriathlonCombinedIcon(size: 16),
        ),
      );
    } else {
      avatarWidget = Icon(
        icon ?? Icons.sports,
        size: 16,
        color: isSelected ? AppColors.navy : color,
      );
    }

    return ChoiceChip(
      avatar: avatarWidget,
      showCheckmark: false,
      label: Text(label),
      selected: isSelected,
      selectedColor: color,
      backgroundColor: const Color(0xFF002A5C),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.navy : Colors.white,
        fontWeight: isSelected ? FontWeight.bold : null,
      ),
      onSelected: (_) => _onSportChanged(sport),
    );
  }

  /// Speichert einen Wettkampf sowohl in `users/{uid}/races` als auch als Kalendereintrag.
  Future<void> _saveRace() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final currentUid = ref.read(authStateChangesProvider).valueOrNull?.uid ??
          widget.athleteId;
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

      int? targetTimeSec;
      if (_raceTargetTimeController.text.trim().isNotEmpty) {
        final parts = _raceTargetTimeController.text.trim().split(':');
        if (parts.length == 3) {
          final h = int.tryParse(parts[0]) ?? 0;
          final m = int.tryParse(parts[1]) ?? 0;
          final s = int.tryParse(parts[2]) ?? 0;
          targetTimeSec = h * 3600 + m * 60 + s;
        } else if (parts.length == 2) {
          final m = int.tryParse(parts[0]) ?? 0;
          final s = int.tryParse(parts[1]) ?? 0;
          targetTimeSec = m * 60 + s;
        }
      }

      final race = Race(
        id: '',
        userId: widget.athleteId,
        title: _raceTitleController.text.trim(),
        date: dateStr,
        sport: _sport,
        distanceLabel: _raceDistanceController.text.trim().isNotEmpty
            ? _raceDistanceController.text.trim()
            : null,
        priority: _racePriority,
        targetTimeSec: targetTimeSec,
        notes: _raceNotesController.text.trim().isNotEmpty
            ? _raceNotesController.text.trim()
            : null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // In Race-Repository speichern
      final raceRepo = ref.read(raceRepositoryProvider);
      await raceRepo.saveRace(race);

      // Auch als geplantes Workout im Kalender anlegen
      final planned = PlannedWorkout(
        id: '',
        athleteId: widget.athleteId,
        createdBy: currentUid,
        localDate: dateStr,
        sport: _sport,
        title: '${race.priorityCode}-WETTKAMPF: ${race.title}',
        description: race.distanceLabel != null
            ? '${race.distanceLabel} · ${race.notes ?? ""}'
            : race.notes,
        plannedDurationSec: targetTimeSec ?? 7200,
        status: 'PLANNED',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final workoutRepo = ref.read(plannedWorkoutRepositoryProvider);
      await workoutRepo.create(planned);

      ref.invalidate(homeDashboardProvider(widget.athleteId));
      ref.invalidate(athleteCurrentWeekWorkoutsProvider(widget.athleteId));
      ref.invalidate(athleteCurrentMonthWorkoutsProvider(widget.athleteId));
      ref.invalidate(weekSummaryProvider(widget.athleteId));

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${race.priorityCode}-Wettkampf "${race.title}" für $dateStr erfolgreich eingeplant!',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Speichern des Wettkampfs: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _saveWorkout() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final currentUid = ref.read(authStateChangesProvider).valueOrNull?.uid ??
          widget.athleteId;
      final durationMin = int.parse(_durationMinutesController.text.trim());
      final distanceKm = double.tryParse(
          _distanceKmController.text.trim().replaceAll(',', '.'));
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

      // Grobe TSS-Schätzung für die Planung (z. B. 50 TSS/h bei Moderat)
      double loadEst = durationMin * (60.0 / 60.0);
      if (_intensity == 'EASY') loadEst = durationMin * 0.6;
      if (_intensity == 'HARD') loadEst = durationMin * 1.2;
      if (_intensity == 'INTERVALS') loadEst = durationMin * 1.4;

      final workout = PlannedWorkout(
        id: '',
        athleteId: widget.athleteId,
        createdBy: currentUid,
        localDate: dateStr,
        sport: _sport,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        plannedDurationSec: durationMin * 60,
        plannedDistanceM: distanceKm != null ? distanceKm * 1000 : null,
        plannedLoad: loadEst,
        intensity: _intensity,
        status: 'PLANNED',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final repo = ref.read(plannedWorkoutRepositoryProvider);
      await repo.create(workout);

      ref.invalidate(homeDashboardProvider(widget.athleteId));
      ref.invalidate(athleteCurrentWeekWorkoutsProvider(widget.athleteId));
      ref.invalidate(athleteCurrentMonthWorkoutsProvider(widget.athleteId));
      ref.invalidate(weekSummaryProvider(widget.athleteId));

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Trainingseinheit erfolgreich geplant!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Speichern: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
