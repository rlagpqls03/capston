enum HomeSearchType {
  recommendation,
  exercise,
  hospital,
  job,
  health,
  point,
  activityTab,
  profileTab,
}

class HomeSearchItem {
  final String title;
  final String subtitle;
  final List<String> keywords;
  final HomeSearchType type;

  const HomeSearchItem({
    required this.title,
    required this.subtitle,
    required this.keywords,
    required this.type,
  });

  bool matches(String rawQuery) {
    final query = rawQuery.trim().toLowerCase();
    if (query.isEmpty) return true;
    return title.toLowerCase().contains(query) ||
        subtitle.toLowerCase().contains(query) ||
        keywords.any((keyword) => keyword.toLowerCase().contains(query));
  }
}
