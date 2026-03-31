// lib/models/user_model.dart
class UserModel {
  final String uid;
  final String name;
  final int age;
  final String gender;
  final String role; // 'senior' 또는 'guardian'
  final String? connectionCode; // 보호자일 경우 어르신과 연결할 코드

  UserModel({
    required this.uid,
    required this.name,
    required this.age,
    required this.gender,
    required this.role,
    this.connectionCode,
  });

  // Firestore 저장을 위한 Map 변환
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'age': age,
      'gender': gender,
      'role': role,
      'connectionCode': connectionCode,
      'createdAt': DateTime.now(),
    };
  }
}