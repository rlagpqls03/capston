class ExerciseTemplate {
  final String id;
  final String title;
  final String summary;
  final String videoKey;
  final String videoLink;
  final String countingType;
  final int defaultTargetCount;
  final int defaultTargetSets;
  final String movementHint;
  final List<String> tags;

  const ExerciseTemplate({
    required this.id,
    required this.title,
    required this.summary,
    required this.videoKey,
    this.videoLink = '',
    required this.countingType,
    required this.defaultTargetCount,
    required this.defaultTargetSets,
    required this.movementHint,
    required this.tags,
  });
}
