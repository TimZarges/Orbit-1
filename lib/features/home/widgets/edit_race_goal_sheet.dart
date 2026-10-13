import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/design/app_typography.dart';
import '../models/race_goal.dart';

/// Modal-Sheet zur Eingabe und Bearbeitung des Saisonziels.
class EditRaceGoalSheet extends StatefulWidget {
  final RaceGoal? initialGoal;
  final VoidCallback onSaved;

  const EditRaceGoalSheet({
    super.key,
    this.initialGoal,
    required this.onSaved,
  });

  static Future<void> show(BuildContext context, {RaceGoal? initialGoal, required VoidCallback onSaved}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => EditRaceGoalSheet(initialGoal: initialGoal, onSaved: onSaved),
    );
  }

  @override
  State<EditRaceGoalSheet> createState() => _EditRaceGoalSheetState();
}

class _EditRaceGoalSheetState extends State<EditRaceGoalSheet> {
  late TextEditingController _titleController;
  late String _selectedDate;
  String? _selectedDistance;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialGoal?.title ?? '');
    _selectedDate = widget.initialGoal?.date ?? DateTime.now().add(const Duration(days: 90)).toString().split(' ')[0];
    _selectedDistance = widget.initialGoal?.distance ?? 'Mitteldistanz';
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    setState(() => _isSaving = true);

    final goal = RaceGoal(
      title: title,
      date: _selectedDate,
      distance: _selectedDistance,
    );

    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'profile': {
          'raceGoal': goal.toMap(),
        },
      }, SetOptions(merge: true));

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
              'Saisonziel festlegen',
              style: AppTypography.title.copyWith(fontSize: 18, color: AppColors.navy),
            ),
            const SizedBox(height: 16),

            // Titel
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Name des Wettkampfs',
                hintText: 'z. B. Ironman 70.3 Kraichgau',
                filled: true,
                fillColor: AppColors.lightBackground,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 14),

            // Datum
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.tryParse(_selectedDate) ?? DateTime.now().add(const Duration(days: 90)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 730)),
                );
                if (picked != null) {
                  setState(() {
                    _selectedDate = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                  });
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.lightBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Datum: $_selectedDate', style: AppTypography.body.copyWith(color: AppColors.navy)),
                    const Icon(Icons.calendar_month, size: 20, color: AppColors.navy),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Distanz
            DropdownButtonFormField<String>(
              value: _selectedDistance,
              decoration: InputDecoration(
                labelText: 'Distanz / Kategorie',
                filled: true,
                fillColor: AppColors.lightBackground,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              items: const [
                DropdownMenuItem(value: 'Sprint', child: Text('Sprintdistanz')),
                DropdownMenuItem(value: 'Olympisch', child: Text('Olympische Distanz')),
                DropdownMenuItem(value: 'Mitteldistanz', child: Text('Mitteldistanz (70.3)')),
                DropdownMenuItem(value: 'Langdistanz', child: Text('Langdistanz (Ironman)')),
                DropdownMenuItem(value: 'Marathon', child: Text('Marathon')),
                DropdownMenuItem(value: 'Halbmarathon', child: Text('Halbmarathon')),
                DropdownMenuItem(value: 'Sonstige', child: Text('Sonstige')),
              ],
              onChanged: (val) => setState(() => _selectedDistance = val),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _isSaving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(
                        'Ziel speichern',
                        style: AppTypography.body.copyWith(fontWeight: FontWeight.bold, color: AppColors.navy),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
