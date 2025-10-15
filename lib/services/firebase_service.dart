import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../models/habit_model.dart';
import '../models/user_model.dart';
import '../models/badge_model.dart';

/// Firebase service for authentication and data management
/// Handles user authentication, CRUD operations for habits, and user data
class FirebaseService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  User? _firebaseUser;
  User? _currentUser;
  List<Habit> _habits = [];
  List<Badge> _badges = [];
  bool _isLoading = false;

  // Getters
  User? get firebaseUser => _firebaseUser;
  User? get currentUser => _currentUser;
  List<Habit> get habits => _habits;
  List<Badge> get badges => _badges;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _firebaseUser != null;

  /// Initialize the service and listen to auth state changes
  FirebaseService() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  /// Handle authentication state changes
  Future<void> _onAuthStateChanged(User? user) async {
    _firebaseUser = user;
    if (user != null) {
      await _loadUserData();
    } else {
      _currentUser = null;
      _habits.clear();
      _badges.clear();
    }
    notifyListeners();
  }

  /// Load user data from Firestore
  Future<void> _loadUserData() async {
    if (_firebaseUser == null) return;

    try {
      _isLoading = true;
      notifyListeners();

      // Load user profile
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(_firebaseUser!.uid)
          .get();

      if (userDoc.exists) {
        _currentUser = User.fromFirestore(userDoc);
      } else {
        // Create new user if doesn't exist
        await _createNewUser();
      }

      // Load user habits
      await _loadHabits();

      // Load user badges
      await _loadBadges();

    } catch (e) {
      _showError('Failed to load user data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create a new user in Firestore
  Future<void> _createNewUser() async {
    if (_firebaseUser == null) return;

    final newUser = User(
      id: _firebaseUser!.uid,
      name: _firebaseUser!.displayName ?? 'Eco Warrior',
      email: _firebaseUser!.email ?? '',
      avatar: '🌱',
      totalPoints: 0,
      currentStreak: 0,
      longestStreak: 0,
      joinDate: DateTime.now(),
      ecoGoal: 'Make the world greener!',
      badges: {},
      isDarkMode: false,
    );

    await _firestore
        .collection('users')
        .doc(_firebaseUser!.uid)
        .set(newUser.toFirestore());

    _currentUser = newUser;
  }

  /// Load user habits from Firestore
  Future<void> _loadHabits() async {
    if (_firebaseUser == null) return;

    try {
      QuerySnapshot habitsSnapshot = await _firestore
          .collection('habits')
          .where('userId', isEqualTo: _firebaseUser!.uid)
          .orderBy('date', descending: true)
          .get();

      _habits = habitsSnapshot.docs
          .map((doc) => Habit.fromFirestore(doc))
          .toList();
    } catch (e) {
      _showError('Failed to load habits: $e');
    }
  }

  /// Load user badges from Firestore
  Future<void> _loadBadges() async {
    if (_firebaseUser == null) return;

    try {
      // Initialize with default badges
      _badges = BadgeDefinitions.allBadges.map((badge) {
        bool isUnlocked = _currentUser?.badges[badge.id] ?? false;
        return badge.copyWith(isUnlocked: isUnlocked);
      }).toList();

      // Check for new badges based on current points
      if (_currentUser != null) {
        List<Badge> newBadges = BadgeDefinitions.checkForNewBadges(
          _currentUser!.totalPoints,
          _badges,
        );

        if (newBadges.isNotEmpty) {
          await _unlockBadges(newBadges);
        }
      }
    } catch (e) {
      _showError('Failed to load badges: $e');
    }
  }

  /// Sign up with email and password
  Future<bool> signUp(String email, String password, String name) async {
    try {
      _isLoading = true;
      notifyListeners();

      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        // Update display name
        await result.user!.updateDisplayName(name);
        
        // Create user profile
        await _createNewUser();
        
        _showSuccess('Account created successfully!');
        return true;
      }
      return false;
    } on FirebaseAuthException catch (e) {
      _showError(_getAuthErrorMessage(e.code));
      return false;
    } catch (e) {
      _showError('Sign up failed: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sign in with email and password
  Future<bool> signIn(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      _showSuccess('Welcome back!');
      return true;
    } on FirebaseAuthException catch (e) {
      _showError(_getAuthErrorMessage(e.code));
      return false;
    } catch (e) {
      _showError('Sign in failed: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _showSuccess('Signed out successfully');
    } catch (e) {
      _showError('Sign out failed: $e');
    }
  }

  /// Add a new habit
  Future<bool> addHabit(Habit habit) async {
    if (_firebaseUser == null) return false;

    try {
      await _firestore
          .collection('habits')
          .add(habit.toFirestore());

      await _loadHabits();
      _showSuccess('Habit added successfully!');
      return true;
    } catch (e) {
      _showError('Failed to add habit: $e');
      return false;
    }
  }

  /// Update a habit
  Future<bool> updateHabit(Habit habit) async {
    try {
      await _firestore
          .collection('habits')
          .doc(habit.id)
          .update(habit.toFirestore());

      await _loadHabits();
      return true;
    } catch (e) {
      _showError('Failed to update habit: $e');
      return false;
    }
  }

  /// Delete a habit
  Future<bool> deleteHabit(String habitId) async {
    try {
      await _firestore
          .collection('habits')
          .doc(habitId)
          .delete();

      await _loadHabits();
      _showSuccess('Habit deleted successfully!');
      return true;
    } catch (e) {
      _showError('Failed to delete habit: $e');
      return false;
    }
  }

  /// Mark habit as completed and update points
  Future<bool> completeHabit(String habitId) async {
    if (_currentUser == null) return false;

    try {
      // Find the habit
      Habit? habit = _habits.firstWhere(
        (h) => h.id == habitId,
        orElse: () => throw Exception('Habit not found'),
      );

      if (habit.isCompleted) return true; // Already completed

      // Update habit as completed
      Habit updatedHabit = habit.copyWith(isCompleted: true);
      await updateHabit(updatedHabit);

      // Update user points
      int newPoints = _currentUser!.totalPoints + habit.points;
      await _updateUserPoints(newPoints);

      _showSuccess('Great job! +${habit.points} eco points!');
      return true;
    } catch (e) {
      _showError('Failed to complete habit: $e');
      return false;
    }
  }

  /// Update user points and check for new badges
  Future<void> _updateUserPoints(int newPoints) async {
    if (_firebaseUser == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(_firebaseUser!.uid)
          .update({'totalPoints': newPoints});

      // Update local user data
      _currentUser = _currentUser!.copyWith(totalPoints: newPoints);

      // Check for new badges
      List<Badge> newBadges = BadgeDefinitions.checkForNewBadges(
        newPoints,
        _badges,
      );

      if (newBadges.isNotEmpty) {
        await _unlockBadges(newBadges);
      }
    } catch (e) {
      _showError('Failed to update points: $e');
    }
  }

  /// Unlock new badges
  Future<void> _unlockBadges(List<Badge> newBadges) async {
    if (_firebaseUser == null) return;

    try {
      Map<String, bool> updatedBadges = Map.from(_currentUser!.badges);
      
      for (Badge badge in newBadges) {
        updatedBadges[badge.id] = true;
        
        // Update local badges list
        int index = _badges.indexWhere((b) => b.id == badge.id);
        if (index != -1) {
          _badges[index] = badge;
        }
      }

      // Update user badges in Firestore
      await _firestore
          .collection('users')
          .doc(_firebaseUser!.uid)
          .update({'badges': updatedBadges});

      // Update local user data
      _currentUser = _currentUser!.copyWith(badges: updatedBadges);

      // Show celebration for new badges
      for (Badge badge in newBadges) {
        _showSuccess('🎉 New badge unlocked: ${badge.name}!');
      }
    } catch (e) {
      _showError('Failed to unlock badges: $e');
    }
  }

  /// Get habits for a specific date
  List<Habit> getHabitsForDate(DateTime date) {
    return _habits.where((habit) {
      return habit.date.year == date.year &&
             habit.date.month == date.month &&
             habit.date.day == date.day;
    }).toList();
  }

  /// Get today's habits
  List<Habit> getTodaysHabits() {
    return getHabitsForDate(DateTime.now());
  }

  /// Get completed habits count for today
  int getTodaysCompletedHabits() {
    return getTodaysHabits().where((habit) => habit.isCompleted).length;
  }

  /// Get total points for today
  int getTodaysPoints() {
    return getTodaysHabits()
        .where((habit) => habit.isCompleted)
        .fold(0, (sum, habit) => sum + habit.points);
  }

  /// Get weekly habits for chart
  List<Map<String, dynamic>> getWeeklyHabits() {
    List<Map<String, dynamic>> weeklyData = [];
    DateTime now = DateTime.now();
    
    for (int i = 6; i >= 0; i--) {
      DateTime date = now.subtract(Duration(days: i));
      List<Habit> dayHabits = getHabitsForDate(date);
      int completedCount = dayHabits.where((h) => h.isCompleted).length;
      
      weeklyData.add({
        'date': date,
        'completed': completedCount,
        'total': dayHabits.length,
      });
    }
    
    return weeklyData;
  }

  /// Get authentication error message
  String _getAuthErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'invalid-email':
        return 'The email address is not valid.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }

  /// Show success message
  void _showSuccess(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.green,
      textColor: Colors.white,
    );
  }

  /// Show error message
  void _showError(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.red,
      textColor: Colors.white,
    );
  }
}
