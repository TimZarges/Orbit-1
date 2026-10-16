import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/design/app_typography.dart';
import '../models/daily_metrics.dart';

/// 15-Sekunden-Kurz-Journal für den morgendlichen Check-in.
///
/// Ermöglicht Athleten das schnelle Erfassen von Lifestyle- und Kontextfaktoren
/// (Koffein, Alkohol, Stress, Hydration, etc.), um Korrelationen mit HRV und
/// Erholungsscore automatisiert auszuwerten.
class DailyJournalCard extends StatefulWidget {
  final String athleteId;
  final String dateStr;
  final JournalData? initialJournal;
  final void Function(JournalData updatedJournal)? onSaved;

  const DailyJournalCard({
    super.key,
    required this.athleteId,
    required this.dateStr,
    this.initialJournal,
    this.onSaved,
  });

  @override
  State<DailyJournalCard> createState() => _DailyJournalCardState();
}

class _DailyJournalCardState extends State<DailyJournalCard> {
  final Set<String> _selectedTags = {};
  final TextEditingController _notesController = TextEditingController();
  bool _isSaving = false;
  bool _hasSaved = false;

  static const List<Map<String, dynamic>> _availableTags = [
    {
      'id': 'lateCaffeine',
      'label': 'Spätes Koffein',
      'icon': Icons.coffee,
    },
    {
      'id': 'alcohol',
      'label': 'Alkohol',
      'icon': Icons.local_bar,
    },
    {
      'id': 'soreness',
      'label': 'Muskelkater',
      'icon': Icons.fitness_center,
    },
    {
      'id': 'highStress',
      'label': 'Hoher Alltagsstress',
      'icon': Icons.sentiment_dissatisfied,
    },
    {
      'id': 'goodHydration',
      'label': 'Hydration gut',
      'icon': Icons.water_drop,
    },
    {
      'id': 'lateMeal',
      'label': 'Späte Mahlzeit',
      'icon': Icons.restaurant,
    },
    {
      'id': 'travelAltitude',
      'label': 'Reise / Höhe',
      'icon': Icons.flight,
    },
    {
      'id': 'meditationBreathwork',
      'label': 'Atemübung / Entspannung',
      'icon': Icons.spa,
    },
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialJournal != null) {
      if (widget.initialJournal!.tags != null) {
        _selectedTags.addAll(widget.initialJournal!.tags!);
      }
      if (widget.initialJournal!.lateCaffeine == true) {
        _selectedTags.add('lateCaffeine');
      }
      if (widget.initialJournal!.alcohol == true) {
        _selectedTags.add('alcohol');
      }
      if (widget.initialJournal!.soreness == true) {
        _selectedTags.add('soreness');
      }
      if (widget.initialJournal!.highStress == true) {
        _selectedTags.add('highStress');
      }
      if (widget.initialJournal!.goodHydration == true) {
        _selectedTags.add('goodHydration');
      }
      if (widget.initialJournal!.lateMeal == true) {
        _selectedTags.add('lateMeal');
      }
      if (widget.initialJournal!.travelAltitude == true) {
        _selectedTags.add('travelAltitude');
      }
      if (widget.initialJournal!.meditationBreathwork == true) {
        _selectedTags.add('meditationBreathwork');
      }
      if (widget.initialJournal!.notes != null) {
        _notesController.text = widget.initialJournal!.notes!;
      }
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveJournal() async {
    setState(() {
      _isSaving = true;
      _hasSaved = false;
    });

    final journalMap = <String, dynamic>{
      'tags': _selectedTags.toList(),
      'notes': _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      'lateCaffeine': _selectedTags.contains('lateCaffeine'),
      'alcohol': _selectedTags.contains('alcohol'),
      'soreness': _selectedTags.contains('soreness'),
      'highStress': _selectedTags.contains('highStress'),
      'goodHydration': _selectedTags.contains('goodHydration'),
      'lateMeal': _selectedTags.contains('lateMeal'),
      'travelAltitude': _selectedTags.contains('travelAltitude'),
      'meditationBreathwork': _selectedTags.contains('meditationBreathwork'),
      'loggedAt': FieldValue.serverTimestamp(),
    };

    try {
      if (widget.athleteId.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.athleteId)
            .collection('dailyMetrics')
            .doc(widget.dateStr)
            .set({'journal': journalMap}, SetOptions(merge: true));
      }

      final updatedJournal = JournalData.fromMap(journalMap);
      widget.onSaved?.call(updatedJournal);

      if (mounted) {
        setState(() {
          _isSaving = false;
          _hasSaved = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tages-Journal erfolgreich gespeichert.'),
            duration: Duration(seconds: 2),
            backgroundColor: AppColors.navy,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Speichern: $e'),
            backgroundColor: AppColors.coral,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A), // Dark Navy Surface
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.volt.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.edit_note_rounded,
                  color: AppColors.volt,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Morgen-Check-in (15 Sek.)',
                      style: AppTypography.title.copyWith(
                        color: AppColors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tippe an, was heute zutrifft für deine HRV-Korrelation.',
                      style: AppTypography.label.copyWith(
                        color: AppColors.techGrey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (_hasSaved)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.emerald.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.emerald),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check, size: 14, color: AppColors.emerald),
                      SizedBox(width: 4),
                      Text(
                        'Gespeichert',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.emerald,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableTags.map((tag) {
              final id = tag['id'] as String;
              final label = tag['label'] as String;
              final icon = tag['icon'] as IconData;
              final isSelected = _selectedTags.contains(id);

              return FilterChip(
                showCheckmark: false,
                avatar: Icon(
                  icon,
                  size: 16,
                  color: isSelected ? AppColors.navy : AppColors.techGrey,
                ),
                label: Text(label),
                selected: isSelected,
                labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? AppColors.navy : AppColors.white,
                ),
                backgroundColor: const Color(0xFF1E293B),
                selectedColor: AppColors.volt,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color:
                        isSelected ? AppColors.volt : const Color(0xFF334155),
                  ),
                ),
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedTags.add(id);
                    } else {
                      _selectedTags.remove(id);
                    }
                    _hasSaved = false;
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 14),

          // Optionale Kurznotiz
          TextField(
            controller: _notesController,
            maxLength: 140,
            style: const TextStyle(color: AppColors.white, fontSize: 13),
            decoration: InputDecoration(
              counterText: '',
              hintText:
                  'Optionale Kurznotiz (z. B. leichte Erkältung, schweres Essen)...',
              hintStyle:
                  const TextStyle(color: Color(0xFF64748B), fontSize: 12),
              filled: true,
              fillColor: const Color(0xFF1E293B),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (_) {
              if (_hasSaved) {
                setState(() => _hasSaved = false);
              }
            },
          ),
          const SizedBox(height: 12),

          // Save Button
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveJournal,
              icon: _isSaving
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.navy,
                      ),
                    )
                  : const Icon(Icons.check, size: 16),
              label: Text(_isSaving ? 'Speichern...' : 'Eintrag speichern'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.volt,
                foregroundColor: AppColors.navy,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
