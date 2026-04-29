import 'package:flutter/material.dart';

import '../models/home_search_item.dart';
import '../theme/app_theme.dart';

class HomeMenuSearchDelegate extends SearchDelegate<HomeSearchItem?> {
  final List<HomeSearchItem> items;

  HomeMenuSearchDelegate({required this.items});

  List<HomeSearchItem> get _filteredItems {
    final matches = items.where((item) => item.matches(query)).toList();
    if (matches.isEmpty && query.trim().isNotEmpty) {
      return items;
    }
    return matches;
  }

  @override
  String get searchFieldLabel => '메뉴 검색';

  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    return theme.copyWith(
      appBarTheme: theme.appBarTheme.copyWith(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
        hintStyle: TextStyle(
          color: AppColors.textSub,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back_rounded),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildListView(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildListView(context);
  }

  Widget _buildListView(BuildContext context) {
    final filtered = _filteredItems;
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemBuilder: (context, index) {
        final item = filtered[index];
        return ListTile(
          tileColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: AppColors.border),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          title: Text(
            item.title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.textMain,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              item.subtitle,
              style: const TextStyle(
                color: AppColors.textSub,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          trailing: const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.primary,
          ),
          onTap: () => close(context, item),
        );
      },
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemCount: filtered.length,
    );
  }
}
