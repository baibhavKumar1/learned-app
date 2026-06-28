import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/dashboard_models.dart';

class TeacherDashboardService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<ActionItem>> getActionItems(String teacherId) {
    return _db
        .collection('teachers')
        .doc(teacherId)
        .collection('alerts')
        .where('isResolved', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ActionItem.fromMap(doc.data(), doc.id))
            .toList());
  }

  Stream<List<ActivityItem>> getRecentActivity(String teacherId) {
    return _db
        .collection('teachers')
        .doc(teacherId)
        .collection('activities')
        .orderBy('timestamp', descending: true)
        .limit(10)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ActivityItem.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> markActionItemResolved(String teacherId, String actionItemId) async {
    await _db
        .collection('teachers')
        .doc(teacherId)
        .collection('alerts')
        .doc(actionItemId)
        .update({'isResolved': true});
  }
}
