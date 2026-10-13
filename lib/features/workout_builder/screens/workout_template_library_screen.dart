import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/design/app_colors.dart';
import '../../calendar/models/planned_workout.dart';
import '../../calendar/repositories/planned_workout_repository.dart';
import '../models/workout_template.dart';
import '../repositories/workout_template_repository.dart';
import '../widgets/workout_profile_chart.dart';
import 'workout_builder_screen.dart';

/// Screen für die Vorlagenbibliothek: Durchsuchen, Filtern, Favorisieren und Einplanen.
class WorkoutTemplateLibraryScreen extends ConsumerStatefulWidget {
  final String? athleteId;
  final String? coachId;
  final String? targetLocalDate;

  const WorkoutTemplateLibraryScreen({
    super.key,
    this.athleteId,
    this.coachId,
    this.targetLocalDate,
  });

  @override
  ConsumerState<WorkoutTemplateLibraryScreen> createState() =>
      _WorkoutTemplateLibraryScreenState();
}

class _WorkoutTemplateLibraryScreenState
    extends ConsumerState<WorkoutTemplateLibraryScreen> {
  late final WorkoutTemplateRepository _repository;
  String _selectedSport = 'ALL';
  bool _onlyFavorites = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _repository = WorkoutTemplateRepository();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveUserId = widget.athleteId ?? 'me';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vorlagenbibliothek'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_outlined),
            tooltip: '20 Startvorlagen laden',
            onPressed: () => _seedInitialTemplates(effectiveUserId),
          ),
        ],
      ),
      body: Column(
        children: [
          // Suchleiste
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Vorlagen durchsuchen (Titel, Tag, Beschreibung)...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.cockpit.withValues(alpha: 0.03),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.cardBorder),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),

          // Filter-Chips (Sportart & Favoriten)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                _buildSportFilterChip('ALL', 'Alle'),
                _buildSportFilterChip('BIKE', 'Rad'),
                _buildSportFilterChip('RUN', 'Lauf'),
                _buildSportFilterChip('SWIM', 'Schwimmen'),
                _buildSportFilterChip('STRENGTH', 'Kraft'),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.favorite, size: 14, color: Colors.red),
                      SizedBox(width: 4),
                      Text('Favoriten'),
                    ],
                  ),
                  selected: _onlyFavorites,
                  onSelected: (val) => setState(() => _onlyFavorites = val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Vorlagen-Liste
          Expanded(
            child: FutureBuilder<List<WorkoutTemplate>>(
              future: _repository.getTemplates(
                userId: effectiveUserId,
                coachId: widget.coachId,
                sport: _selectedSport,
                searchQuery: _searchQuery,
                onlyFavorites: _onlyFavorites,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final templates = snapshot.data ?? [];

                if (templates.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.fitness_center_outlined, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          const Text(
                            'Keine Vorlagen gefunden',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Lade die 20 triathlon-spezifischen Startvorlagen oder erstelle dein erstes eigenes Workout.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.navy,
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.download),
                            label: const Text('20 Startvorlagen laden'),
                            onPressed: () => _seedInitialTemplates(effectiveUserId),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  itemCount: templates.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final template = templates[index];
                    return _buildTemplateCard(template, effectiveUserId);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Neues Workout'),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => WorkoutBuilderScreen(
                athleteId: widget.athleteId,
                targetLocalDate: widget.targetLocalDate,
              ),
            ),
          ).then((_) => setState(() {}));
        },
      ),
    );
  }

  Widget _buildSportFilterChip(String sportCode, String label) {
    final isSelected = _selectedSport == sportCode;
    return Padding(
      padding: const EdgeInsets.only(right: 6.0),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (val) {
          if (val) {
            setState(() => _selectedSport = sportCode);
          }
        },
      ),
    );
  }

  Widget _buildTemplateCard(WorkoutTemplate template, String currentUserId) {
    final sportColor = _getSportColor(template.sport);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.cardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Zeile 1: Sportart-Badge, Titel & Favorit
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: sportColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: sportColor),
                  ),
                  child: Text(
                    template.sport,
                    style: TextStyle(
                      color: sportColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    template.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    template.isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: template.isFavorite ? Colors.red : Colors.grey,
                    size: 20,
                  ),
                  onPressed: () async {
                    await _repository.toggleFavorite(template.id, template.isFavorite);
                    setState(() {});
                  },
                ),
              ],
            ),

            if (template.description != null && template.description!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                template.description!,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            const SizedBox(height: 8),

            // Mini Profilgrafik
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: WorkoutProfileChart(
                structure: template.structure,
                height: 55,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            ),

            const SizedBox(height: 8),

            // Tags
            if (template.tags.isNotEmpty)
              Wrap(
                spacing: 6,
                children: template.tags.map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      tag,
                      style: const TextStyle(fontSize: 10, color: Colors.black54),
                    ),
                  );
                }).toList(),
              ),

            const SizedBox(height: 10),

            // Aktionsleiste
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Bearbeiten', style: TextStyle(fontSize: 12)),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => WorkoutBuilderScreen(
                          sport: template.sport,
                          initialStructure: template.structure,
                          athleteId: widget.athleteId,
                          targetLocalDate: widget.targetLocalDate,
                        ),
                      ),
                    ).then((_) => setState(() {}));
                  },
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.calendar_today_outlined, size: 16),
                  label: const Text('Planen', style: TextStyle(fontSize: 12)),
                  onPressed: () => _scheduleTemplateInCalendar(template),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getSportColor(String sport) {
    switch (sport.toUpperCase()) {
      case 'BIKE':
        return AppColors.sportBike;
      case 'RUN':
        return AppColors.sportRun;
      case 'SWIM':
        return AppColors.sportSwim;
      default:
        return AppColors.sportStrength;
    }
  }

  Future<void> _seedInitialTemplates(String userId) async {
    final count = await _repository.seedInitialTemplatesIfEmpty(userId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            count > 0
                ? '$count Startvorlagen erfolgreich geladen!'
                : 'Vorlagen sind bereits vorhanden.',
          ),
        ),
      );
      setState(() {});
    }
  }

  Future<void> _scheduleTemplateInCalendar(WorkoutTemplate template) async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: widget.targetLocalDate != null ? DateTime.parse(widget.targetLocalDate!) : now,
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: now.add(const Duration(days: 365)),
    );

    if (pickedDate == null || !mounted) return;

    final localDateStr =
        "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";

    final athleteId = widget.athleteId ?? 'me';
    final repo = PlannedWorkoutRepository();

    // Struktur wird kopiert, nicht referenziert (gemäß Spec Task 9)
    final planned = PlannedWorkout(
      id: '',
      athleteId: athleteId,
      createdBy: athleteId,
      localDate: localDateStr,
      sport: template.sport,
      title: template.title,
      description: template.description,
      plannedDurationSec: 3600, // Platzhalter oder aus Struktur
      status: 'PLANNED',
      structure: template.structure.toJson(),
      templateId: template.id,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await repo.create(planned);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${template.title}" für $localDateStr eingeplant!')),
      );
      Navigator.of(context).pop();
    }
  }
}
