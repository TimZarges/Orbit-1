import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/design/app_typography.dart';
import '../../workout_builder/models/workout_template.dart';
import '../../workout_builder/providers/workout_templates_provider.dart';
import '../services/batch_assign_service.dart';

/// Modal-Dialog zur Massenzuweisung von Workouts an ausgewählte Athleten.
class BatchAssignDialog extends ConsumerStatefulWidget {
  final String coachId;
  final List<String> athleteIds;
  final VoidCallback onCompleted;

  const BatchAssignDialog({
    super.key,
    required this.coachId,
    required this.athleteIds,
    required this.onCompleted,
  });

  static Future<void> show(
    BuildContext context, {
    required String coachId,
    required List<String> athleteIds,
    required VoidCallback onCompleted,
  }) {
    return showDialog(
      context: context,
      builder: (_) => BatchAssignDialog(
        coachId: coachId,
        athleteIds: athleteIds,
        onCompleted: onCompleted,
      ),
    );
  }

  @override
  ConsumerState<BatchAssignDialog> createState() => _BatchAssignDialogState();
}

class _BatchAssignDialogState extends ConsumerState<BatchAssignDialog> {
  late String _targetDate;
  WorkoutTemplate? _selectedTemplate;
  bool _isExecuting = false;

  @override
  void initState() {
    super.initState();
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    _targetDate =
        '${tomorrow.year}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}';
  }

  Future<void> _handleExecute() async {
    if (_selectedTemplate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Bitte wähle zuerst eine Workout-Vorlage aus.')),
      );
      return;
    }

    setState(() => _isExecuting = true);

    final service = BatchAssignService();
    final result = await service.assignTemplateToAthletes(
      coachId: widget.coachId,
      athleteIds: widget.athleteIds,
      template: _selectedTemplate!,
      targetLocalDate: _targetDate,
    );

    if (mounted) {
      setState(() => _isExecuting = false);
      Navigator.of(context).pop();
      widget.onCompleted();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erfolgreich zugewiesen: ${result.successCount} Einheiten eingeplant.'
            '${result.failureCount > 0 ? " (${result.failureCount} fehlgeschlagen)" : ""}',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final templatesAsync = ref.watch(workoutTemplatesProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: AppColors.white,
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 540),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.techGrey,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.group_add_outlined,
                          size: 20, color: AppColors.navy),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Massenzuweisung',
                      style: AppTypography.title
                          .copyWith(fontSize: 18, color: AppColors.navy),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Ausgewählte Athleten: ${widget.athleteIds.length}',
              style: AppTypography.label.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),

            // Vorlagen-Auswahl
            Text('Vorlage auswählen:',
                style:
                    AppTypography.body.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            templatesAsync.when(
              data: (templates) {
                if (templates.isEmpty) {
                  return const Text(
                      'Keine Vorlagen in der Bibliothek vorhanden.');
                }
                return DropdownButtonFormField<WorkoutTemplate>(
                  value: _selectedTemplate,
                  decoration:
                      const InputDecoration(border: OutlineInputBorder()),
                  hint: const Text('Vorlage wählen...'),
                  items: templates.map((tmpl) {
                    return DropdownMenuItem(
                      value: tmpl,
                      child: Text('${tmpl.title} (${tmpl.sport})'),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedTemplate = val),
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (err, _) => Text('Fehler: $err'),
            ),
            const SizedBox(height: 16),

            // Datumsauswahl
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.tryParse(_targetDate) ?? DateTime.now(),
                  firstDate: DateTime.now().subtract(const Duration(days: 7)),
                  lastDate: DateTime.now().add(const Duration(days: 90)),
                );
                if (picked != null) {
                  setState(() {
                    _targetDate =
                        '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                  });
                }
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.lightBackground,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Datum: $_targetDate',
                        style:
                            AppTypography.body.copyWith(color: AppColors.navy)),
                    const Icon(Icons.calendar_month,
                        size: 20, color: AppColors.navy),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Vorschau-Box
            if (_selectedTemplate != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.volt.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.volt),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.preview_outlined,
                        size: 20, color: AppColors.navy),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Vorschau: ${widget.athleteIds.length} Athleten erhalten „${_selectedTemplate!.title}" am $_targetDate.',
                        style: AppTypography.body.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.navy),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Aktionen
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Abbrechen'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isExecuting || _selectedTemplate == null
                      ? null
                      : _handleExecute,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.volt,
                    foregroundColor: AppColors.navy,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isExecuting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Jetzt zuweisen',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
