import 'package:cloud_firestore/cloud_firestore.dart';

/// Model class for user data
/// Stores user profile information, points, and achievements
class User {
  final String id;
  final String name;
  final String email;
  final String avatar;
  final int totalPoints;
  final int currentStreak;
  final int longestStreak;
  final DateTime joinDate;
  final String ecoGoal;
  final Map<String, bool> badges;
  final bool isDarkMode;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.avatar,
    required this.totalPoints,
    required this.currentStreak,
    required this.longestStreak,
    required this.joinDate,
    required this.ecoGoal,
    required this.badges,
    required this.isDarkMode,
  });

  /// Create a User from Firestore document
  factory User.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return User(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      avatar: data['avatar'] ?? '🌱',
      totalPoints: data['totalPoints'] ?? 0,
      currentStreak: data['currentStreak'] ?? 0,
      longestStreak: data['longestStreak'] ?? 0,
      joinDate: (data['joinDate'] as Timestamp).toDate(),
      ecoGoal: data['ecoGoal'] ?? 'Make the world greener!',
      badges: Map<String, bool>.from(data['badges'] ?? {}),
      isDarkMode: data['isDarkMode'] ?? false,
    );
  }

  /// Convert User to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'avatar': avatar,
      'totalPoints': totalPoints,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'joinDate': Timestamp.fromDate(joinDate),
      'ecoGoal': ecoGoal,
      'badges': badges,
      'isDarkMode': isDarkMode,
    };
  }

  /// Create a copy of the user with updated fields
  User copyWith({
    String? id,
    String? name,
    String? email,
    String? avatar,
    int? totalPoints,
    int? currentStreak,
    int? longestStreak,
    DateTime? joinDate,
    String? ecoGoal,
    Map<String, bool>? badges,
    bool? isDarkMode,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatar: avatar ?? this.avatar,
      totalPoints: totalPoints ?? this.totalPoints,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      joinDate: joinDate ?? this.joinDate,
      ecoGoal: ecoGoal ?? this.ecoGoal,
      badges: badges ?? this.badges,
      isDarkMode: isDarkMode ?? this.isDarkMode,
    );
  }

  @override
  String toString() {
    return 'User(id: $id, name: $name, email: $email, totalPoints: $totalPoints)';
  }
}

/// Available avatar options for users
class UserAvatars {
  static const List<String> avatars = [
    '🌱', '🌿', '🌳', '🌲', '🌴', '🌵', '🍃', '🌾',
    '🌺', '🌸', '🌼', '🌻', '🌷', '🌹', '🌻', '🌺'
  ];
}

/// Eco goals that users can choose from
class EcoGoals {
  static const List<String> goals = [
    'Make the world greener!',
    'Reduce my carbon footprint',
    'Save water every day',
    'Use less plastic',
    'Walk more, drive less',
    'Eat more plant-based foods',
    'Recycle everything possible',
    'Conserve energy at home',
  ];
}
