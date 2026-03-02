import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/daily_goals.dart';
import '../models/meal.dart';
import '../models/workout.dart';
import '../models/water_log.dart';
import '../models/cardio_log.dart';
import '../models/step_log.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  // Meal operations
  Future<void> addMeal(Meal meal) async {
    if (_userId == null) throw Exception('User not authenticated');

    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('meals')
        .add(meal.toMap());
  }

  Stream<List<Meal>> getMeals() {
    if (_userId == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('meals')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Meal.fromMap(doc.id, doc.data()))
            .toList());
  }

  Future<List<Meal>> getMealsByDateRange(DateTime start, DateTime end) async {
    if (_userId == null) return [];

    final snapshot = await _firestore
        .collection('users')
        .doc(_userId)
        .collection('meals')
        .where('timestamp', isGreaterThanOrEqualTo: start.toIso8601String())
        .where('timestamp', isLessThanOrEqualTo: end.toIso8601String())
        .get();

    final meals = snapshot.docs
        .map((doc) => Meal.fromMap(doc.id, doc.data()))
        .toList();
    
    // Filter and sort in memory
    meals.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return meals;
  }

  // Workout operations
  Future<void> addWorkout(Workout workout) async {
    if (_userId == null) throw Exception('User not authenticated');

    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('workouts')
        .add(workout.toMap());
  }

  Stream<List<Workout>> getWorkouts() {
    if (_userId == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('workouts')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Workout.fromMap(doc.id, doc.data()))
            .toList());
  }

  Future<List<Workout>> getWorkoutsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    if (_userId == null) return [];

    final snapshot = await _firestore
        .collection('users')
        .doc(_userId)
        .collection('workouts')
        .where('timestamp', isGreaterThanOrEqualTo: start.toIso8601String())
        .where('timestamp', isLessThanOrEqualTo: end.toIso8601String())
        .get();

    final workouts = snapshot.docs
        .map((doc) => Workout.fromMap(doc.id, doc.data()))
        .toList();
    
    // Filter and sort in memory
    workouts.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return workouts;
  }

  // Water operations
  Future<void> addWaterLog(WaterLog log) async {
    if (_userId == null) throw Exception('User not authenticated');

    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('water_logs')
        .add(log.toMap());
  }

  Stream<List<WaterLog>> getWaterLogs() {
    if (_userId == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('water_logs')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => WaterLog.fromMap(doc.id, doc.data()))
            .toList());
  }

  // Cardio operations
  Future<void> addCardioLog(CardioLog log) async {
    if (_userId == null) throw Exception('User not authenticated');

    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('cardio_logs')
        .add(log.toMap());
  }

  Stream<List<CardioLog>> getCardioLogs() {
    if (_userId == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('cardio_logs')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CardioLog.fromMap(doc.id, doc.data()))
            .toList());
  }

  // Step operations
  Future<void> addStepLog(StepLog log) async {
    if (_userId == null) throw Exception('User not authenticated');

    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('step_logs')
        .add(log.toMap());
  }

  Stream<List<StepLog>> getStepLogs() {
    if (_userId == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('step_logs')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => StepLog.fromMap(doc.id, doc.data()))
            .toList());
  }

  // Daily goals
  Future<DailyGoals> getDailyGoals() async {
    if (_userId == null) return DailyGoals();

    try {
      final doc = await _firestore.collection('users').doc(_userId!).get();
      if (doc.exists && doc.data() != null) {
        return DailyGoals.fromMap(doc.data());
      }
    } catch (_) {}
    return DailyGoals();
  }

  Future<void> saveDailyGoals(DailyGoals goals) async {
    if (_userId == null) throw Exception('User not authenticated');

    await _firestore.collection('users').doc(_userId!).set(
      goals.toMap(),
      SetOptions(merge: true),
    );
  }
}

