import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('알림'),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.notifications_none_rounded,
                size: 54,
                color: AppColors.textSub,
              ),
              SizedBox(height: 14),
              Text(
                '아직 알림이 없어요.',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textMain,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
