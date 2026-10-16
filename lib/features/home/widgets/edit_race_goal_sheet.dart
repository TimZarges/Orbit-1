import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/design/app_typography.dart';
import '../../races/repositories/race_repository.dart';
import '../models/race_goal.dart';

/// Modal-Sheet zur Eingabe und Bearbeitung des Saisonziels (A-, B-, C-Rennen).
class EditRaceGoalSheet extends StatefulWidget {
  final RaceGoal? initialGoal;
  final VoidCallback onSaved;

  const EditRaceGoalSheet({
    super.key,
    this.initialGoal,
    required this.onSaved,
  });

  static Future<void> show(
    BuildContext context, {
    RaceGoal? initialGoal,
    required VoidCallback onSaved,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) =>
          EditRaceGoalSheet(initialGoal: initialGoal, onSaved: onSaved),
    );
  }

  @override
  State<EditRaceGoalSheet> createState() => _EditRaceGoalSheetState();
}

class _EditRaceGoalSheetState extends State<EditRaceGoalSheet> {
  late TextEditingController _titleController;
  late TextEditingController _targetTimeController;
  late TextEditingController _targetPowerController;
  late TextEditingController _notesController;
  late String _selectedDate;
  String? _selectedDistance;
  String _selectedPriority = 'A';
  String _selectedSport = 'TRIATHLON';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController =
        TextEditingController(text: widget.initialGoal?.title ?? '');
    _targetTimeController =
        TextEditingController(text: widget.initialGoal?.targetTime ?? '');
    _targetPowerController = TextEditingController(
        text: widget.initialGoal?.targetPowerWatts != null
            ? widget.initialGoal!.targetPowerWatts.toString()
            : '');
    _notesController =
        TextEditingController(text: widget.initialGoal?.notes ?? '');
    _selectedDate = widget.initialGoal?.date ??
        DateTime.now().add(const Duration(days: 90)).toString().split(' ')[0];
    _selectedDistance = widget.initialGoal?.distance ?? 'Mitteldistanz';
    _selectedPriority = widget.initialGoal?.priority ?? 'A';
    _selectedSport = widget.initialGoal?.sport ?? 'TRIATHLON';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _targetTimeController.dispose();
    _targetPowerController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    setState(() => _isSaving = true);

    final targetPower = int.tryParse(_targetPowerController.text.trim());
    final targetTime = _targetTimeController.text.trim();

    final goal = RaceGoal(
      id: widget.initialGoal?.id,
      title: title,
      date: _selectedDate,
      distance: _selectedDistance,
      targetTime: targetTime.isNotEmpty ? targetTime : null,
      priority: _selectedPriority,
      sport: _selectedSport,
      targetPowerWatts: targetPower,
      notes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
    );

    try {
      final raceRepo = RaceRepository();
      final race = goal.toRace(userId: uid);
      await raceRepo.saveRace(race);

      if (mounted) {
        widget.onSaved();
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Wettkampfziel festlegen',
                style: AppTypography.title
                    .copyWith(fontSize: 18, color: AppColors.navy),
              ),
              const SizedBox(height: 16),

              // Prioritäts-Auswahl (A / B / C)
              Text('Priorität des Wettkampfs',
                  style: AppTypography.label.copyWith(
                      fontWeight: FontWeight.bold, color: AppColors.navy)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _PrioritySegment(
                    code: 'A',
                    label: 'A-Hauptziel',
                    color: AppColors.volt,
                    textColor: AppColors.navy,
                    isSelected: _selectedPriority == 'A',
                    onTap: () => setState(() => _selectedPriority = 'A'),
                  ),
                  const SizedBox(width: 8),
                  _PrioritySegment(
                    code: 'B',
                    label: 'B-Vorbereitung',
                    color: const Color(0xFF00D2FF),
                    textColor: AppColors.navy,
                    isSelected: _selectedPriority == 'B',
                    onTap: () => setState(() => _selectedPriority = 'B'),
                  ),
                  const SizedBox(width: 8),
                  _PrioritySegment(
                    code: 'C',
                    label: 'C-Trainingsrennen',
                    color: const Color(0xFFE2E8F0),
                    textColor: const Color(0xFF475569),
                    isSelected: _selectedPriority == 'C',
                    onTap: () => setState(() => _selectedPriority = 'C'),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Titel
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Name des Wettkampfs',
                  hintText: 'z. B. Ironman 70.3 Kraichgau',
                  filled: true,
                  fillColor: AppColors.lightBackground,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 14),

              // Datum
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.tryParse(_selectedDate) ??
                        DateTime.now().add(const Duration(days: 90)),
                    firstDate:
                        DateTime.now().subtract(const Duration(days: 30)),
                    lastDate: DateTime.now().add(const Duration(days: 730)),
                  );
                  if (picked != null) {
                    setState(() {
                      _selectedDate =
                          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                    });
                  }
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.lightBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Datum: $_selectedDate',
                          style: AppTypography.body
                              .copyWith(color: AppColors.navy)),
                      const Icon(Icons.calendar_month,
                          size: 20, color: AppColors.navy),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Sportart & Distanz in einer Reihe
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedSport,
                      decoration: InputDecoration(
                        labelText: 'Sportart',
                        filled: true,
                        fillColor: AppColors.lightBackground,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'TRIATHLON', child: Text('Triathlon')),
                        DropdownMenuItem(
                            value: 'BIKE', child: Text('Radsport')),
                        DropdownMenuItem(value: 'RUN', child: Text('Laufen')),
                        DropdownMenuItem(
                            value: 'SWIM', child: Text('Schwimmen')),
                        DropdownMenuItem(
                            value: 'OTHER', child: Text('Sonstige')),
                      ],
                      onChanged: (val) =>
                          setState(() => _selectedSport = val ?? 'TRIATHLON'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedDistance,
                      decoration: InputDecoration(
                        labelText: 'Distanz',
                        filled: true,
                        fillColor: AppColors.lightBackground,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'Sprint', child: Text('Sprint')),
                        DropdownMenuItem(
                            value: 'Olympisch', child: Text('Olympisch')),
                        DropdownMenuItem(
                            value: 'Mitteldistanz',
                            child: Text('Mitteldistanz')),
                        DropdownMenuItem(
                            value: 'Langdistanz', child: Text('Langdistanz')),
                        DropdownMenuItem(
                            value: 'Marathon', child: Text('Marathon')),
                        DropdownMenuItem(
                            value: 'Halbmarathon', child: Text('Halbmarathon')),
                        DropdownMenuItem(value: '10 km', child: Text('10 km')),
                        DropdownMenuItem(
                            value: 'Sonstige', child: Text('Sonstige')),
                      ],
                      onChanged: (val) =>
                          setState(() => _selectedDistance = val),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Zielzeit & Ziel-Watt
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _targetTimeController,
                      decoration: InputDecoration(
                        labelText: 'Zielzeit (opt.)',
                        hintText: 'z. B. 4:30:00',
                        filled: true,
                        fillColor: AppColors.lightBackground,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _targetPowerController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Ziel-Watt (opt.)',
                        hintText: 'z. B. 260 W',
                        filled: true,
                        fillColor: AppColors.lightBackground,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Speichern-Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.volt,
                    foregroundColor: AppColors.navy,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(
                          'Wettkampf speichern',
                          style: AppTypography.body.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.navy),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrioritySegment extends StatelessWidget {
  final String code;
  final String label;
  final Color color;
  final Color textColor;
  final bool isSelected;
  final VoidCallback onTap;

  const _PrioritySegment({
    required this.code,
    required this.label,
    required this.color,
    required this.textColor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color : AppColors.lightBackground,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                code,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isSelected ? textColor : Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: isSelected ? textColor : Colors.grey.shade600,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
