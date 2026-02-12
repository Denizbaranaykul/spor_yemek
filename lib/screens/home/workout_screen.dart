import 'package:flutter/material.dart';
import '../../models/workout.dart';
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
  final _formKey = GlobalKey<FormState>();

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Spor'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Antrenman Kaydı',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Hareket',
                          border: OutlineInputBorder(),
                        ),
                        items: _commonExercises.map((exercise) {
                          return DropdownMenuItem(
                            value: exercise,
                            child: Text(exercise),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            _exerciseController.text = value;
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
                          backgroundColor: AppTheme.primaryColor,
                          minimumSize: const Size(double.infinity, 48),
                        ),
                        child: const Text('Kaydet'),
                      ),
                    ],
                  ),
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

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Son Kayıtlar',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...workouts.take(5).map((workout) => Card(
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
                        )),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

