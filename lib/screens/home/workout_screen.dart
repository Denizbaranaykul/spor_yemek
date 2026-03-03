import 'package:flutter/material.dart';
import '../../models/workout.dart';
import '../../models/cardio_log.dart';
import '../../models/step_log.dart';
import '../../models/calisthenics_log.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  final _firestoreService = FirestoreService();
  final _exerciseController = TextEditingController();
  final _weightController = TextEditingController();
  final _cardioController = TextEditingController();
  final _stepsController = TextEditingController();
  final _calisthenicsExerciseController = TextEditingController();
  final _calisthenicsRepsController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _selectedExercise;

  final List<String> _commonExercises = [
    'Lateral Raise',
    'Sirt icin bar',
    'Chest Press',
    'Fly',
    'Tricep Extension',
    'Seated Cable Row',
    'Lat pull down',
    'plakali sirt',
    'Bicep Curl',
    'Hammer Curl',
    'sholder press',
    'Leg Press',
    'Leg Extension',
    'Leg Curl',
    'yana bacak acma',
  ];

  @override
  void dispose() {
    _exerciseController.dispose();
    _weightController.dispose();
    _cardioController.dispose();
    _stepsController.dispose();
    _calisthenicsExerciseController.dispose();
    _calisthenicsRepsController.dispose();
    super.dispose();
  }

  Future<void> _saveWorkout() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final workout = Workout(
        exerciseName: _exerciseController.text.trim(),
        weight: double.parse(_weightController.text),
        timestamp: DateTime.now(),
      );

      await _firestoreService.addWorkout(workout);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Antrenman kaydedildi!'),
            backgroundColor: Colors.green,
          ),
        );
        _exerciseController.clear();
        _weightController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kayıt hatası: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveCardio() async {
    if (_cardioController.text.trim().isEmpty) return;

    try {
      final minutes = int.parse(_cardioController.text);
      if (minutes <= 0) return;

      final cardioLog = CardioLog(
        minutes: minutes,
        timestamp: DateTime.now(),
      );

      await _firestoreService.addCardioLog(cardioLog);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kardiyo kaydedildi!'), backgroundColor: Colors.green));
        _cardioController.clear();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _saveSteps() async {
    if (_stepsController.text.trim().isEmpty) return;

    try {
      final steps = int.parse(_stepsController.text);
      if (steps <= 0) return;

      final stepLog = StepLog(
        steps: steps,
        timestamp: DateTime.now(),
      );

      await _firestoreService.addStepLog(stepLog);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Adım sayısı kaydedildi!'), backgroundColor: Colors.green));
        _stepsController.clear();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _saveCalisthenics() async {
    if (_calisthenicsExerciseController.text.trim().isEmpty || _calisthenicsRepsController.text.trim().isEmpty) return;
    
    try {
      final reps = int.parse(_calisthenicsRepsController.text);
      if (reps <= 0) return;

      final log = CalisthenicsLog(
        exerciseName: _calisthenicsExerciseController.text.trim(),
        reps: reps,
        timestamp: DateTime.now(),
      );

      await _firestoreService.addCalisthenicsLog(log);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Calisthenics kaydedildi!'), backgroundColor: Colors.green));
        _calisthenicsExerciseController.clear();
        _calisthenicsRepsController.clear();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 36.0, left: 16.0, right: 16.0, bottom: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: const Color(0xFF1A237E).withOpacity(0.3), // Lacivert/Navy Tonu
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.fitness_center, color: Color(0xFF7986CB)), // Açık lacivert/mavi
                          const SizedBox(width: 8),
                          const Text(
                            'Antrenman Kaydı',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedExercise,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          labelText: 'Hareket Seç',
                        ),
                        items: _commonExercises.map((exercise) {
                          return DropdownMenuItem(
                            value: exercise,
                            child: Text(exercise),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedExercise = value;
                              _exerciseController.text = value;
                            });
                          }
                        },
                        validator: (value) {
                          if (_exerciseController.text.isEmpty) {
                            return 'Hareket seçin veya girin';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _exerciseController,
                        decoration: const InputDecoration(
                          labelText: 'Hareket Adı (Özel)',
                          hintText: 'Veya özel hareket adı yazın',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _weightController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Ağırlık (kg)',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Ağırlık gerekli';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Geçerli bir sayı girin';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _saveWorkout,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF283593), // Buton için tok bir lacivert
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 48),
                        ),
                        child: const Text('Kaydet', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              color: const Color(0xFF4A0E17).withOpacity(0.6), // Koyu Bordo Tonu
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.directions_run, color: Color(0xFFEF9A9A)), // Açık Kırmızı/Pembe vurucu ton
                        const SizedBox(width: 8),
                        const Text('Kardiyo ve Adım', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _cardioController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Kardiyo (Dk)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _saveCardio,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8E1D2C), // Buton için kırmızı/bordo
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Ekle', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _stepsController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Adım Sayısı',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _saveSteps,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8E1D2C),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Ekle', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              color: const Color(0xFF2E7D32).withOpacity(0.6), // Green tone
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.accessibility_new, color: Color(0xFFA5D6A7)), // Light green
                        const SizedBox(width: 8),
                        const Text('Calisthenics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _calisthenicsExerciseController,
                      decoration: const InputDecoration(
                        labelText: 'Hareket Adı',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _calisthenicsRepsController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Tekrar Sayısı',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _saveCalisthenics,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1B5E20), // Dark green
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Ekle', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            StreamBuilder<List<Workout>>(
              stream: _firestoreService.getWorkouts(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Hata: ${snapshot.error}'),
                  );
                }

                final workouts = snapshot.data ?? [];

                if (workouts.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(
                        child: Text('Henüz antrenman kaydı yok'),
                      ),
                    ),
                  );
                }

                return StreamBuilder<List<CardioLog>>(
                  stream: _firestoreService.getCardioLogs(),
                  builder: (context, cardioSnapshot) {
                    final cardios = cardioSnapshot.data ?? [];
                    final today = DateTime.now();
                    final todayStart = DateTime(today.year, today.month, today.day);
                    
                    final todayCardios = cardios.where((c) => c.timestamp.compareTo(todayStart) >= 0).toList();
                    final todayTotalCardio = todayCardios.fold<int>(0, (s, c) => s + c.minutes);

                    return StreamBuilder<List<CalisthenicsLog>>(
                      stream: _firestoreService.getCalisthenicsLogs(),
                      builder: (context, calisthenicsSnapshot) {
                        final calisthenics = calisthenicsSnapshot.data ?? [];

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (todayTotalCardio > 0) ...[
                              Card(
                                color: const Color(0xFF4A0E17).withOpacity(0.6),
                                child: ListTile(
                                  leading: const Icon(Icons.directions_run, color: Color(0xFFEF9A9A)),
                                  title: const Text('Bugün Toplam Kardiyo', style: TextStyle(color: Colors.white)),
                                  trailing: Text(
                                    '$todayTotalCardio dk',
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFEF9A9A)),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                            const Text(
                              'Son Kayıtlar',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...workouts.take(5).map((workout) => Dismissible(
                                  key: Key(workout.id ?? workout.timestamp.toString()),
                                  direction: DismissDirection.endToStart,
                                  background: Container(
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.only(right: 20.0),
                                    color: Colors.red,
                                    child: const Icon(Icons.delete, color: Colors.white),
                                  ),
                                  onDismissed: (direction) {
                                    if (workout.id != null) {
                                      _firestoreService.deleteWorkout(workout.id);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Antrenman silindi')),
                                      );
                                    }
                                  },
                                  child: Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: ListTile(
                                      leading: const Icon(Icons.fitness_center),
                                      title: Text(workout.exerciseName),
                                      subtitle: Text(
                                        '${workout.timestamp.day}/${workout.timestamp.month}/${workout.timestamp.year}',
                                      ),
                                      trailing: Text(
                                        '${workout.weight} kg',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.primaryColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                )),
                            ...calisthenics.take(5).map((calisthenic) => Dismissible(
                                  key: Key(calisthenic.id ?? calisthenic.timestamp.toString()),
                                  direction: DismissDirection.endToStart,
                                  background: Container(
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.only(right: 20.0),
                                    color: Colors.red,
                                    child: const Icon(Icons.delete, color: Colors.white),
                                  ),
                                  onDismissed: (direction) {
                                    if (calisthenic.id != null) {
                                      _firestoreService.deleteCalisthenicsLog(calisthenic.id);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Calisthenics kaydı silindi')),
                                      );
                                    }
                                  },
                                  child: Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: ListTile(
                                      leading: const Icon(Icons.accessibility_new, color: Colors.green),
                                      title: Text(calisthenic.exerciseName),
                                      subtitle: Text(
                                        '${calisthenic.timestamp.day}/${calisthenic.timestamp.month}/${calisthenic.timestamp.year}',
                                      ),
                                      trailing: Text(
                                        '${calisthenic.reps} tekrar',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ),
                                  ),
                                )),
                          ],
                        );
                      }
                    );
                  }
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

