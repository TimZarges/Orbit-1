import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../core/config/app_config.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/design/app_typography.dart';
import '../../beta_feedback/widgets/beta_bug_reporter_sheet.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _birthYearController;
  late TextEditingController _weightController;
  late TextEditingController _heightController;
  late TextEditingController _restingHrController;
  late TextEditingController _maxHrController;

  List<String> _selectedSports = ['BIKE', 'RUN'];
  String? _photoBase64;
  bool _isSaving = false;
  bool _hasInitialized = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _birthYearController = TextEditingController();
    _weightController = TextEditingController();
    _heightController = TextEditingController();
    _restingHrController = TextEditingController();
    _maxHrController = TextEditingController();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final doc =
            await FirebaseFirestore.instance.collection('users').doc(uid).get();
        if (doc.exists && mounted) {
          _initFromUserDoc(doc.data() ?? {});
          setState(() {});
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameController.dispose();
    _birthYearController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _restingHrController.dispose();
    _maxHrController.dispose();
    super.dispose();
  }

  void _initFromUserDoc(Map<String, dynamic> userDoc) {
    if (_hasInitialized) return;
    _hasInitialized = true;

    final profile = userDoc['profile'] as Map<String, dynamic>? ?? {};
    final thresholds = userDoc['thresholds'] as Map<String, dynamic>? ?? {};

    _nameController.text =
        (profile['displayName'] ?? profile['firstName'] ?? '').toString();
    _birthYearController.text = (profile['birthYear'] ?? '').toString();
    _weightController.text = (profile['weightKg'] ?? '').toString();
    _heightController.text = (profile['heightCm'] ?? '').toString();
    _restingHrController.text =
        (thresholds['restingHrBpm'] ?? profile['restingHrBpm'] ?? '')
            .toString();
    _maxHrController.text =
        (thresholds['maxHrBpm'] ?? profile['maxHrBpm'] ?? '').toString();

    final sports = profile['sports'] ?? profile['sportTypes'];
    if (sports is List && sports.isNotEmpty) {
      _selectedSports = sports.map((e) => e.toString()).toList();
    }

    _photoBase64 = profile['photoUrl'] as String?;
  }

  Future<void> _pickImage() async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.image,
      );

      if (file != null) {
        final bytes = await file.readAsBytes();
        final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        setState(() {
          _photoBase64 = base64Image;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bildauswahl fehlgeschlagen: $e')),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    String? uid;
    try {
      uid = FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {}
    if (uid == null) return;

    setState(() => _isSaving = true);
    try {
      final name = _nameController.text.trim();
      final nameParts = name.split(RegExp(r'\s+'));
      final firstName = nameParts.first;
      final lastName =
          nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

      final birthYear = int.tryParse(_birthYearController.text.trim());
      final weightKg = double.tryParse(_weightController.text.trim());
      final heightCm = int.tryParse(_heightController.text.trim());
      final restingHr = int.tryParse(_restingHrController.text.trim());
      final maxHr = int.tryParse(_maxHrController.text.trim());

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'profile': {
          'displayName': name,
          'firstName': firstName,
          'lastName': lastName,
          if (birthYear != null) 'birthYear': birthYear,
          if (weightKg != null) 'weightKg': weightKg,
          if (heightCm != null) 'heightCm': heightCm,
          if (restingHr != null) 'restingHrBpm': restingHr,
          if (maxHr != null) 'maxHrBpm': maxHr,
          if (_photoBase64 != null) 'photoUrl': _photoBase64,
          'sports': _selectedSports,
          'sportTypes': _selectedSports,
        },
        'thresholds': {
          if (restingHr != null) 'restingHrBpm': restingHr,
          if (maxHr != null) 'maxHrBpm': maxHr,
        },
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil erfolgreich gespeichert!'),
            backgroundColor: AppColors.navy,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Speichern: $e'),
            backgroundColor: AppColors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    String email = '';
    try {
      email = FirebaseAuth.instance.currentUser?.email ?? '';
    } catch (_) {}

    return Scaffold(
      backgroundColor: AppColors.navy,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title:
            const Text('Mein Profil', style: TextStyle(color: AppColors.white)),
        actions: const [
          BetaBugReportIconButton(),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 54,
                        backgroundColor: const Color(0xFF002A5C),
                        backgroundImage: _photoBase64 != null &&
                                _photoBase64!.startsWith('data:image')
                            ? MemoryImage(
                                base64Decode(_photoBase64!.split(',').last))
                            : null,
                        child: _photoBase64 == null
                            ? const Icon(Icons.person,
                                size: 56, color: AppColors.volt)
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.volt,
                          child: IconButton(
                            icon: const Icon(Icons.camera_alt,
                                size: 18, color: AppColors.navy),
                            onPressed: _pickImage,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (email.isNotEmpty)
                  Text(
                    email,
                    textAlign: TextAlign.center,
                    style:
                        AppTypography.bodySmall.copyWith(color: Colors.white70),
                  ),
                const SizedBox(height: 24),
                _buildCard(
                  title: 'Persönliche Angaben',
                  children: [
                    TextFormField(
                      controller: _nameController,
                      style: const TextStyle(color: AppColors.white),
                      decoration: const InputDecoration(
                        labelText: 'Name (Vor- und Nachname)',
                        labelStyle: TextStyle(color: Colors.white70),
                        prefixIcon:
                            Icon(Icons.person_outline, color: AppColors.volt),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _birthYearController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: AppColors.white),
                      decoration: const InputDecoration(
                        labelText: 'Geburtsjahr (z. B. 1992)',
                        labelStyle: TextStyle(color: Colors.white70),
                        prefixIcon: Icon(Icons.calendar_today_outlined,
                            color: AppColors.volt),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _weightController,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            style: const TextStyle(color: AppColors.white),
                            decoration: const InputDecoration(
                              labelText: 'Gewicht (kg)',
                              labelStyle: TextStyle(color: Colors.white70),
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: TextFormField(
                            controller: _heightController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: AppColors.white),
                            decoration: const InputDecoration(
                              labelText: 'Größe (cm)',
                              labelStyle: TextStyle(color: Colors.white70),
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildCard(
                  title: 'Herzdaten (Basis für Erholung & Zonen)',
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _restingHrController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: AppColors.white),
                            decoration: const InputDecoration(
                              labelText: 'Ruhepuls (bpm)',
                              labelStyle: TextStyle(color: Colors.white70),
                              hintText: '50',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: TextFormField(
                            controller: _maxHrController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: AppColors.white),
                            decoration: const InputDecoration(
                              labelText: 'Max-Puls (bpm)',
                              labelStyle: TextStyle(color: Colors.white70),
                              hintText: '190',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildCard(
                  title: 'Sportarten',
                  children: [
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: [
                        _sportChip('BIKE', 'Radfahren', Icons.directions_bike),
                        _sportChip('RUN', 'Laufen', Icons.directions_run),
                        _sportChip('SWIM', 'Schwimmen', Icons.pool),
                        _sportChip('TRIATHLON', 'Triathlon',
                            Icons.emoji_events_outlined),
                        _sportChip('STRENGTH', 'Kraft & Athletik',
                            Icons.fitness_center),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isSaving ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.volt,
                    foregroundColor: AppColors.navy,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.navy),
                        )
                      : const Text(
                          'Profil speichern',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
                const SizedBox(height: 32),
                Center(
                  child: Column(
                    children: [
                      Text(
                        'ORBIT ${AppInfo.fullVersionString}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white60,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Server-Region: ${AppInfo.region}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white38,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard({required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF002A5C),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF003D82)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.title
                .copyWith(color: AppColors.white, fontSize: 16),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _sportChip(String code, String label, IconData icon) {
    final isSelected = _selectedSports.contains(code);
    return FilterChip(
      avatar: Icon(icon,
          size: 18, color: isSelected ? AppColors.navy : AppColors.volt),
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.volt,
      backgroundColor: const Color(0xFF001F47),
      checkmarkColor: AppColors.navy,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.navy : AppColors.white,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.volt : const Color(0xFF003D82),
      ),
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _selectedSports.add(code);
          } else if (_selectedSports.length > 1) {
            _selectedSports.remove(code);
          }
        });
      },
    );
  }
}
