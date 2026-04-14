import 'package:cloud_firestore/cloud_firestore.dart';

class JobBoardService {
  JobBoardService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _jobs =>
      _firestore.collection('job_posts');
  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');
  CollectionReference<Map<String, dynamic>> get _jobApplications =>
      _firestore.collection('job_applications');

  Stream<QuerySnapshot<Map<String, dynamic>>> streamJobPosts() {
    return _jobs.orderBy('createdAt', descending: true).snapshots();
  }

  Future<Map<String, String>> getUserProfile(String socialId) async {
    final userDoc = await _users.doc(socialId).get();
    final data = userDoc.data();
    final name = (data?['name'] ?? data?['displayName'] ?? '사용자').toString();
    final role = (data?['role'] ?? '').toString();
    final phone = (data?['phone'] ?? '').toString();
    return {
      'name': name,
      'role': role,
      'phone': phone,
    };
  }

  Future<void> createJobPost({
    required String socialId,
    required String title,
    required String company,
    required String location,
    required String locationBase,
    required String locationDetail,
    double? locationLat,
    double? locationLng,
    required String pay,
    required String workTime,
    required String category,
    required String description,
  }) async {
    final profile = await getUserProfile(socialId);
    if (profile['role'] != '구인자') {
      throw Exception('구인자만 구인글을 등록할 수 있습니다.');
    }
    if ((profile['phone'] ?? '').trim().isEmpty) {
      throw Exception('휴대폰 번호를 등록한 뒤 구인글을 작성할 수 있습니다.');
    }

    await _jobs.add({
      'title': title,
      'company': company,
      'location': location,
      'locationBase': locationBase,
      'locationDetail': locationDetail,
      'locationLat': locationLat,
      'locationLng': locationLng,
      'pay': pay,
      'time': workTime,
      'category': category,
      'description': description,
      'authorId': socialId,
      'authorName': profile['name'],
      'authorRole': profile['role'],
      'recruiterPhone': profile['phone'],
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateJobPost({
    required String docId,
    required String title,
    required String company,
    required String location,
    required String locationBase,
    required String locationDetail,
    double? locationLat,
    double? locationLng,
    required String pay,
    required String workTime,
    required String category,
    required String description,
  }) async {
    await _jobs.doc(docId).update({
      'title': title,
      'company': company,
      'location': location,
      'locationBase': locationBase,
      'locationDetail': locationDetail,
      'locationLat': locationLat,
      'locationLng': locationLng,
      'pay': pay,
      'time': workTime,
      'category': category,
      'description': description,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteJobPost(String docId) async {
    await _jobs.doc(docId).delete();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamApplications(String jobId) {
    return _jobApplications
        .where('jobId', isEqualTo: jobId)
        .snapshots();
  }

  Future<void> applyToJob({
    required String jobId,
    required String applicantId,
    required String message,
  }) async {
    final profile = await getUserProfile(applicantId);
    if (profile['role'] != '어르신') {
      throw Exception('어르신만 지원할 수 있습니다.');
    }

    final duplicate = await _jobApplications
        .where('jobId', isEqualTo: jobId)
        .where('applicantId', isEqualTo: applicantId)
        .limit(1)
        .get();
    if (duplicate.docs.isNotEmpty) {
      throw Exception('이미 지원한 공고입니다.');
    }

    await _jobApplications.add({
      'jobId': jobId,
      'applicantId': applicantId,
      'applicantName': profile['name'],
      'applicantPhone': profile['phone'],
      'message': message,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
