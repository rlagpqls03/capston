import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' as kakao;
import 'services/auth_service.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'screens/registration_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  // 카카오 SDK 초기화
  kakao.KakaoSdk.init(nativeAppKey: '9afedfa75e5eda578ba61766640dbee9');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<Widget> _buildHomeForSignedInUser(auth.User user) async {
    final authService = AuthService();
    final socialId = await authService.resolveSocialIdForCurrentUser(user);

    if (socialId == null) return LoginScreen();

    final isIncomplete = await authService.isProfileIncomplete(socialId);
    if (isIncomplete) {
      return RegistrationScreen(socialId: socialId);
    }
    return MainScreen(socialId: socialId);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '느티나무',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: StreamBuilder<auth.User?>(
        stream: AuthService().userStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            );
          }

          final user = snapshot.data;
          if (user == null) return LoginScreen();

          return FutureBuilder<Widget>(
            future: _buildHomeForSignedInUser(user),
            builder: (context, homeSnapshot) {
              if (homeSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                );
              }

              if (homeSnapshot.hasData) return homeSnapshot.data!;
              return LoginScreen();
            },
          );
        },
      ),
    );
  }
}


