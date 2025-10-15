import 'package:cloud_firestore/cloud_firestore.dart';

/// Model class for eco-friendly habits
/// This represents a single habit that users can track daily
class Habit {
  final String id;
  final String title;
  final String description;
  final String category;
  final int points;
  final DateTime date;
  final bool isCompleted;
  final String userId;

  Habit({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.points,
    required this.date,
    required this.isCompleted,
    required this.userId,
  });

  /// Create a Habit from Firestore document
  factory Habit.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Habit(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? 'General',
      points: data['points'] ?? 10,
      date: (data['date'] as Timestamp).toDate(),
      isCompleted: data['isCompleted'] ?? false,
      userId: data['userId'] ?? '',
    );
  }

  /// Convert Habit to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'points': points,
      'date': Timestamp.fromDate(date),
      'isCompleted': isCompleted,
      'userId': userId,
    };
  }

  /// Create a copy of the habit with updated fields
  Habit copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    int? points,
    DateTime? date,
    bool? isCompleted,
    String? userId,
  }) {
    return Habit(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      points: points ?? this.points,
      date: date ?? this.date,
      isCompleted: isCompleted ?? this.isCompleted,
      userId: userId ?? this.userId,
    );
  }

  @override
  String toString() {
    return 'Habit(id: $id, title: $title, category: $category, points: $points, isCompleted: $isCompleted)';
  }
}

/// Categories for different types of eco-friendly habits
class HabitCategory {
  static const String water = 'Water Conservation';
  static const String energy = 'Energy Saving';
  static const String waste = 'Waste Reduction';
  static const String transport = 'Green Transport';
  static const String food = 'Sustainable Food';
  static const String general = 'General';

  static const List<String> all = [
    water,
    energy,
    waste,
    transport,
    food,
    general,
  ];

  static const Map<String, String> icons = {
    water: '💧',
    energy: '⚡',
    waste: '♻️',
    transport: '🚶',
    food: '🥗',
    general: '🌱',
  };
}
