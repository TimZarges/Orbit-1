import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/design/app_typography.dart';

/// Dialog für Trainer zur Erstellung eines fundierten Schwellenwert-Vorschlags für einen Athleten.
class CreateThresholdProposalDialog extends StatefulWidget {
  final String coachId;
  final String athleteId;
  final String athleteName;

  const CreateThresholdProposalDialog({
    super.key,
    required this.coachId,
    required this.athleteId,
    required this.athleteName,
  });

  static Future<void> show(
    BuildContext context, {
    required String coachId,
    required String athleteId,
    required String athleteName,
  }) {
    return showDialog(
      context: context,
      builder: (_) => CreateThresholdProposalDialog(
        coachId: coachId,
        athleteId: athleteId,
        athleteName: athleteName,
      ),
    );
  }

  @override
  State<CreateThresholdProposalDialog> createState() =>
      _CreateThresholdProposalDialogState();
}

class _CreateThresholdProposalDialogState
    extends State<CreateThresholdProposalDialog> {
  String _selectedSport = 'BIKE';
  String _selectedType = 'FTP';
  final _valueController = TextEditingController();
  final _basisController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _valueController.dispose();
    _basisController.dispose();
    super.dispose();
  }

  void _onSportChanged(String? sport) {
    if (sport == null) return;
    setState(() {
      _selectedSport = sport;
      if (sport == 'BIKE') {
        _selectedType = 'FTP';
      } else if (sport == 'RUN') {
        _selectedType = 'LTHR';
      } else {
        _selectedType = 'CSS';
      }
    });
  }

  Future<void> _handleSubmit() async {
    final value = double.tryParse(_valueController.text.replaceAll(',', '.'));
    if (value == null || value <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Bitte einen gültigen Zahlenwert eingeben.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.athleteId)
          .collection('thresholdProposals')
          .doc();

      final now = DateTime.now();

      await docRef.set({
        'sport': _selectedSport,
        'type': _selectedType,
        'proposedValue': value,
        'confidence': 'HIGH',
        'status': 'PENDING',
        'proposedBy': widget.coachId,
        'basis': _basisController.text.trim().isNotEmpty
            ? _basisController.text.trim()
            : 'Vom Trainer ${widget.coachId} vorgeschlagener Schwellenwert',
        'createdAt': Timestamp.fromDate(now),
      });

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Vorschlag für ${widget.athleteName} erfolgreich eingereicht.')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Einreichen: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: AppColors.white,
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Schwellenwert vorschlagen',
                  style: AppTypography.title
                      .copyWith(fontSize: 18, color: AppColors.navy),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            Text(
              'Für Athlet: ${widget.athleteName}',
              style: AppTypography.label.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),

            // Sportart Dropdown
            DropdownButtonFormField<String>(
              value: _selectedSport,
              decoration: const InputDecoration(
                  labelText: 'Sportart', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'BIKE', child: Text('Rad (Bike)')),
                DropdownMenuItem(value: 'RUN', child: Text('Lauf (Run)')),
                DropdownMenuItem(
                    value: 'SWIM', child: Text('Schwimmen (Swim)')),
              ],
              onChanged: _onSportChanged,
            ),
            const SizedBox(height: 14),

            // Schwellentyp
            Text('Schwellenparameter: $_selectedType',
                style:
                    AppTypography.body.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),

            // Neuer Wert
            TextField(
              controller: _valueController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: _selectedType == 'FTP'
                    ? 'Neue FTP in Watt'
                    : _selectedType == 'LTHR'
                        ? 'Neue LTHR in bpm'
                        : 'CSS (m/s oder Sek/100m)',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),

            // Begründung / Notiz
            TextField(
              controller: _basisController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Begründung / Trainingsbeobachtung (optional)',
                hintText:
                    'z.B. Konstante Leistungssteigerung in 4x4min Intervallen',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Abbrechen'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.volt,
                    foregroundColor: AppColors.navy,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Vorschlag senden',
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
