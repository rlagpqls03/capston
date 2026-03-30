import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' as kakao;
import 'services/auth_service.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  // 카카오 SDK 초기화
  kakao.KakaoSdk.init(nativeAppKey: '9afedfa75e5eda578ba61766640dbee9');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '느티나무',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primaryColor: Colors.green, useMaterial3: true),
      home: StreamBuilder<auth.User?>(
        stream: AuthService().userStream,
        builder: (context, snapshot) {
          // 구글 로그인 기록이 있으면 즉시 메인으로 이동
          if (snapshot.hasData) return const MainScreen();
          return LoginScreen();
        },
      ),
    );
  }
}