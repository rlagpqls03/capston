import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class HomeSearchActionButton extends StatelessWidget {
  final VoidCallback onPressed;

  const HomeSearchActionButton({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      margin: const EdgeInsets.symmetric(vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5ECE6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: const Icon(
          Icons.search_rounded,
          color: Color(0xFF48515A),
          size: 22,
        ),
        onPressed: onPressed,
      ),
    );
  }
}

class HomeBellActionButton extends StatelessWidget {
  final VoidCallback onPressed;

  const HomeBellActionButton({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      margin: const EdgeInsets.symmetric(vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5ECE6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(
                Icons.notifications_none_rounded,
                color: Color(0xFF48515A),
                size: 22,
              ),
              onPressed: onPressed,
            ),
          ),
          const Positioned(
            top: 9,
            right: 9,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Color(0xFFFF6B4A),
                shape: BoxShape.circle,
              ),
              child: SizedBox(width: 8, height: 8),
            ),
          ),
        ],
      ),
    );
  }
}

class HomeTreeAvatarButton extends StatelessWidget {
  const HomeTreeAvatarButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      margin: const EdgeInsets.symmetric(vertical: 7),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFF2FBEE),
            Color(0xFFDBF0D3),
          ],
        ),
        border: Border.all(color: const Color(0xFFD7EBCF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: const Icon(
        Icons.park_rounded,
        color: AppColors.primaryDark,
        size: 24,
      ),
    );
  }
}
