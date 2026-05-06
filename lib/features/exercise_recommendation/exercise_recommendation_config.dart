import 'exercise_recommendation_catalog.dart';

const Map<String, List<String>> exerciseDetailOptions =
    ExerciseRecommendationCatalog.detailOptions;

const List<String> exerciseSeverityOptions =
    ExerciseRecommendationCatalog.severityOptions;

Map<String, dynamic> buildExerciseRecommendation({
  required String primary,
  required String detail,
  required String severity,
}) {
  final template = ExerciseRecommendationCatalog.templateFor(primary);
  final caution = ExerciseRecommendationCatalog.cautionForSeverity(severity);
  final reason = '$primary 증상과 "$detail" 선택 결과를 반영했어요.';

  return {
    'primary': primary,
    'detail': detail,
    'severity': severity,
    'title': template.title,
    'summary': template.summary,
    'reason': '$reason $caution',
    'videoKey': template.videoKey,
    'videoLink': template.videoLink,
    'exerciseId': template.id,
    'countingType': template.countingType,
    'targetCount': template.defaultTargetCount,
    'targetSets': template.defaultTargetSets,
    'movementHint': template.movementHint,
    'tags': template.tags,
    'updatedAtClient': DateTime.now().toIso8601String(),
  };
}
