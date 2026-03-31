// lib/models/exercise.dart
class Exercise {
  final String id;
  final String title;
  final String description;
  final String thumbnailUrl;
  final int rewardPoints;
  final String difficulty; // 쉬움, 보통, 어려움

  Exercise({
    required this.id,
    required this.title,
    required this.description,
    required this.thumbnailUrl,
    required this.rewardPoints,
    required this.difficulty,
  });
}