import 'exercise_recommendation_models.dart';

class ExerciseRecommendationCatalog {
  static const Map<String, List<String>> detailOptions = {
    '어깨': ['앞쪽이 아파요', '뒤쪽이 아파요', '팔을 들 때 아파요', '목/팔꿈치도 같이 아파요'],
    '무릎': ['계단에서 아파요', '걷다가 아파요', '앉았다 일어날 때 아파요', '붓고 뻐근해요'],
    '허리': ['오래 앉으면 아파요', '일어날 때 뻐근해요', '숙일 때 아파요', '엉덩이/다리까지 저려요'],
    '목': ['뒤가 뻐근해요', '옆으로 돌리기 힘들어요', '두통이 같이 와요', '어깨까지 뭉쳐요'],
    '손목/팔꿈치': ['손목이 시큰해요', '팔꿈치 바깥쪽이 아파요', '물건 들 때 아파요', '저림이 있어요'],
    '발목': ['걷기 시작할 때 아파요', '계단에서 불안해요', '자주 접질려요', '붓고 뻣뻣해요'],
    '전신 피로': ['몸이 무겁고 무기력해요', '숨이 쉽게 차요', '관절이 전체적으로 뻐근해요', '잠을 자도 피곤해요'],
  };

  static const List<String> severityOptions = [
    '가벼운 편이에요',
    '중간 정도예요',
    '심한 편이에요',
  ];

  static const Map<String, ExerciseTemplate> templatesByPrimary = {
    '어깨': ExerciseTemplate(
      id: 'shoulder_mobility',
      title: '벽 짚고 어깨 가동 스트레칭',
      summary: '굳은 어깨 관절을 부드럽게 풀고 움직임 범위를 늘려줍니다.',
      videoKey: 'shoulder_mobility',
      countingType: 'repetition',
      defaultTargetCount: 10,
      defaultTargetSets: 2,
      movementHint: '팔을 어깨 높이까지 천천히 들어 올렸다 내리며 1회로 계산합니다.',
      tags: ['어깨', '가동성', '오십견'],
    ),
    '무릎': ExerciseTemplate(
      id: 'knee_strength',
      title: '의자 앉았다 일어나기',
      summary: '무릎 주변 근육을 강화해 계단과 보행 시 통증 완화에 도움을 줍니다.',
      videoKey: 'knee_strength',
      countingType: 'repetition',
      defaultTargetCount: 10,
      defaultTargetSets: 2,
      movementHint: '의자에서 일어섰다가 다시 앉으면 1회로 계산합니다.',
      tags: ['무릎', '하체', '근력'],
    ),
    '허리': ExerciseTemplate(
      id: 'low_back_relief',
      title: '누워서 무릎 당기기 스트레칭',
      summary: '허리 주변 긴장을 줄여 뻐근함 완화에 도움을 줍니다.',
      videoKey: 'low_back_relief',
      countingType: 'duration',
      defaultTargetCount: 30,
      defaultTargetSets: 2,
      movementHint: '양손으로 무릎을 당겨 30초 유지하면 1세트로 계산합니다.',
      tags: ['허리', '유연성', '통증완화'],
    ),
    '목': ExerciseTemplate(
      id: 'neck_posture',
      title: '턱 당기기 + 목 옆면 스트레칭',
      summary: '목-어깨 정렬을 바로잡아 뻐근함과 긴장 완화에 도움이 됩니다.',
      videoKey: 'neck_posture',
      countingType: 'repetition',
      defaultTargetCount: 8,
      defaultTargetSets: 2,
      movementHint: '턱을 당긴 뒤 좌우로 천천히 기울이는 왕복 동작을 1회로 계산합니다.',
      tags: ['목', '자세', '거북목'],
    ),
    '손목/팔꿈치': ExerciseTemplate(
      id: 'wrist_elbow_care',
      title: '손목 굽힘/폄 스트레칭',
      summary: '손목과 팔꿈치에 반복되는 부담을 줄이는 데 도움이 됩니다.',
      videoKey: 'wrist_elbow_care',
      countingType: 'repetition',
      defaultTargetCount: 10,
      defaultTargetSets: 2,
      movementHint: '손목을 굽혔다 펴는 동작을 천천히 1회로 계산합니다.',
      tags: ['손목', '팔꿈치', '스트레칭'],
    ),
    '발목': ExerciseTemplate(
      id: 'ankle_stability',
      title: '앉아서 발목 펌핑 운동',
      summary: '발목 안정성을 높이고 보행 불안감을 줄이는 데 도움이 됩니다.',
      videoKey: 'ankle_stability',
      countingType: 'repetition',
      defaultTargetCount: 15,
      defaultTargetSets: 2,
      movementHint: '발끝을 몸쪽으로 당겼다가 밀어내는 동작을 1회로 계산합니다.',
      tags: ['발목', '보행', '균형'],
    ),
    '전신 피로': ExerciseTemplate(
      id: 'full_body_light',
      title: '저강도 전신 순환 스트레칭',
      summary: '몸 전체 순환을 도와 피로감과 무기력 완화에 도움이 됩니다.',
      videoKey: 'full_body_light',
      countingType: 'duration',
      defaultTargetCount: 300,
      defaultTargetSets: 1,
      movementHint: '5분 동안 무리 없는 범위에서 천천히 지속합니다.',
      tags: ['전신', '순환', '회복'],
    ),
  };

  static const ExerciseTemplate defaultTemplate = ExerciseTemplate(
    id: 'default_strength',
    title: '의자 앉았다 일어나기',
    summary: '하체 근력을 안정적으로 키워 무릎 부담을 덜어줍니다.',
    videoKey: 'default_strength',
    countingType: 'repetition',
    defaultTargetCount: 10,
    defaultTargetSets: 2,
    movementHint: '의자에서 안전하게 일어섰다가 앉는 동작을 1회로 계산합니다.',
    tags: ['하체', '기초근력'],
  );

  static ExerciseTemplate templateFor(String primary) {
    return templatesByPrimary[primary] ?? defaultTemplate;
  }

  static String cautionForSeverity(String severity) {
    if (severity.contains('심한')) {
      return '심한 통증 단계이므로 아주 가볍게 시작하고, 무리하지 마세요.';
    }
    if (severity.contains('가벼운')) {
      return '가벼운 강도로 하루 10분부터 시작해 보세요.';
    }
    return '통증이 심해지면 즉시 중단하고 전문가 상담을 권장해요.';
  }
}
