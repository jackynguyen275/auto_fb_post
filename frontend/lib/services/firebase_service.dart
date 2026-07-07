import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/project_model.dart';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  // Lưu dự án mới
  Future<String?> createProject(ProjectModel project) async {
    try {
      final docRef = await _db.collection('projects').add(project.toMap());
      return docRef.id;
    } catch (e) {
      print("Lỗi tạo dự án: $e");
      return null;
    }
  }

  // Lấy danh sách dự án của người dùng
  Stream<List<ProjectModel>> getUserProjects() {
    return _db
        .collection('projects')
        .where('userId', isEqualTo: currentUserId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProjectModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Lưu lịch đăng bài
  Future<void> addSchedule(String projectId, DateTime scheduleTime) async {
    await _db.collection('scheduled_posts').add({
      'projectId': projectId,
      'scheduledAt': scheduleTime.toIso8601String(),
      'isPosted': false,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  // Lấy lịch đăng bài của dự án
  Stream<QuerySnapshot> getProjectSchedules(String projectId) {
    return _db
        .collection('scheduled_posts')
        .where('projectId', isEqualTo: projectId)
        .orderBy('scheduledAt', descending: true)
        .snapshots();
  }
}