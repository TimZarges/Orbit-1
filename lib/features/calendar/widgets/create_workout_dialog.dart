import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/design/app_colors.dart';
import '../../workout_builder/screens/workout_builder_screen.dart';
import '../../workout_builder/screens/workout_template_library_screen.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/planned_workout.dart';
import '../providers/calendar_provider.dart';

/// Öffnet das Formular zur Schnelleingabe einer neuen geplanten Trainingseinheit.
Future<void> showCreateWorkoutDialog(BuildContext context,
    {required String athleteId, DateTime? initialDate}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
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

class CreateWorkoutDialog extends ConsumerStatefulWidget {
  final String athleteId;
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
  String _sport = 'RUN';
  late DateTime _selectedDate;
  final _titleController = TextEditingController();
  final _durationMinutesController = TextEditingController(text: '60');
  final _distanceKmController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _intensity = 'MODERATE';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
    _titleController.text = 'Lauf Dauerlauf GA1';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _durationMinutesController.dispose();
    _distanceKmController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _onSportChanged(String sport) {
    setState(() {
      _sport = sport;
      if (sport == 'RUN') _titleController.text = 'Lauf Dauerlauf GA1';
      if (sport == 'BIKE') _titleController.text = 'Rad Grundlagenausdauer GA1';
      if (sport == 'SWIM')
        _titleController.text = 'Schwimmen Technik & Ausdauer';
      if (sport == 'STRENGTH') _titleController.text = 'Stabi & Krafttraining';
      if (sport == 'OTHER') _titleController.text = 'Regeneration & Yoga';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Training planen',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Sportart-Auswahl
              Text('Sportart',
                  style: theme.textTheme.labelMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  _sportChip('RUN', 'Laufen', Icons.directions_run,
                      AppColors.sportRun),
                  _sportChip('BIKE', 'Rad', Icons.directions_bike,
                      AppColors.sportBike),
                  _sportChip(
                      'SWIM', 'Schwimmen', Icons.pool, AppColors.sportSwim),
                  _sportChip('STRENGTH', 'Kraft', Icons.fitness_center,
                      AppColors.sportStrength),
                  _sportChip(
                      'OTHER', 'Sonstiges', Icons.sports, AppColors.navyLight),
                ],
              ),
              const SizedBox(height: 16),

              // Datumswahl
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today),
                title: const Text('Datum'),
                subtitle: Text(DateFormat('EEEE, dd. MMMM yyyy', 'de')
                    .format(_selectedDate)),
                trailing: TextButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2025),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      setState(() => _selectedDate = picked);
                    }
                  },
                  child: const Text('Ändern'),
                ),
              ),

              // Titel
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Titel der Einheit',
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
                      decoration: const InputDecoration(
                        labelText: 'Dauer (Minuten)',
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) {
                        final parsed = int.tryParse(val ?? '');
                        if (parsed == null || parsed <= 0)
                          return 'Gültige Dauer angeben';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _distanceKmController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Distanz (km, opt.)',
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
                decoration: const InputDecoration(
                  labelText: 'Intensität',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                      value: 'EASY', child: Text('Locker / Erholung (Z1-Z2)')),
                  DropdownMenuItem(
                      value: 'MODERATE', child: Text('Moderat / GA1 (Z2-Z3)')),
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
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Notizen / Beschreibung (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),

              // Aus Vorlage wählen oder im Builder bauen
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.library_books_outlined, size: 16),
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
                      icon: const Icon(Icons.construction_outlined, size: 16),
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
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Einheit speichern',
                        style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sportChip(String sport, String label, IconData icon, Color color) {
    final isSelected = _sport == sport;
    return ChoiceChip(
      avatar: Icon(icon, size: 16, color: isSelected ? Colors.white : color),
      label: Text(label),
      selected: isSelected,
      selectedColor: color,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : null,
        fontWeight: isSelected ? FontWeight.bold : null,
      ),
      onSelected: (_) => _onSportChanged(sport),
    );
  }

  Future<void> _saveWorkout() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final currentUid =
          ref.read(authStateChangesProvider).valueOrNull?.uid ?? '';
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
      );

      final repo = ref.read(plannedWorkoutRepositoryProvider);
      await repo.create(workout);

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
