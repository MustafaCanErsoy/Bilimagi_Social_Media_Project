import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/report.dart';

/// Service for handling content reports
class ReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _currentUid => _auth.currentUser?.uid;

  /// Report a comment
  Future<void> reportComment({
    required String communityId,
    required String periodId,
    required String articleId,
    required String commentId,
    required String commentUid,
    String? commentDisplayName,
    required String reason,
    String? details,
  }) async {
    final uid = _currentUid;
    if (uid == null) throw Exception('User not logged in');

    // Get reporter display name
    final userDoc = await _firestore.collection('users').doc(uid).get();
    final reporterDisplayName = userDoc.data()?['displayName'] ?? 'Anonim';

    // Check if already reported by this user
    final existing = await _firestore
        .collection('communities')
        .doc(communityId)
        .collection('reports')
        .where('reporterUid', isEqualTo: uid)
        .where('targetId', isEqualTo: commentId)
        .where('type', isEqualTo: 'comment')
        .get();

    if (existing.docs.isNotEmpty) {
      throw Exception('Bu içeriği zaten raporladınız');
    }

    await _firestore
        .collection('communities')
        .doc(communityId)
        .collection('reports')
        .add({
      'reporterUid': uid,
      'reporterDisplayName': reporterDisplayName,
      'type': 'comment',
      'targetId': commentId,
      'targetUid': commentUid,
      'targetDisplayName': commentDisplayName,
      'periodId': periodId,
      'articleId': articleId,
      'reason': reason,
      'details': details,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Report a user
  Future<void> reportUser({
    required String communityId,
    required String targetUid,
    required String targetDisplayName,
    required String reason,
    String? details,
  }) async {
    final uid = _currentUid;
    if (uid == null) throw Exception('User not logged in');

    if (uid == targetUid) {
      throw Exception('Kendinizi raporlayamazsınız');
    }

    // Get reporter display name
    final userDoc = await _firestore.collection('users').doc(uid).get();
    final reporterDisplayName = userDoc.data()?['displayName'] ?? 'Anonim';

    // Check if already reported by this user
    final existing = await _firestore
        .collection('communities')
        .doc(communityId)
        .collection('reports')
        .where('reporterUid', isEqualTo: uid)
        .where('targetUid', isEqualTo: targetUid)
        .where('type', isEqualTo: 'user')
        .get();

    if (existing.docs.isNotEmpty) {
      throw Exception('Bu kullanıcıyı zaten raporladınız');
    }

    await _firestore
        .collection('communities')
        .doc(communityId)
        .collection('reports')
        .add({
      'reporterUid': uid,
      'reporterDisplayName': reporterDisplayName,
      'type': 'user',
      'targetId': targetUid,
      'targetUid': targetUid,
      'targetDisplayName': targetDisplayName,
      'reason': reason,
      'details': details,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Get pending reports for a community (for moderators)
  Stream<List<Report>> getPendingReports(String communityId) {
    return _firestore
        .collection('communities')
        .doc(communityId)
        .collection('reports')
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Report.fromFirestore(doc)).toList());
  }

  /// Get pending report count for a community
  Stream<int> getPendingReportCount(String communityId) {
    return _firestore
        .collection('communities')
        .doc(communityId)
        .collection('reports')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Review a report (mark as reviewed or dismissed)
  Future<void> reviewReport({
    required String communityId,
    required String reportId,
    required bool isDismissed,
    String? note,
  }) async {
    final uid = _currentUid;
    if (uid == null) throw Exception('User not logged in');

    await _firestore
        .collection('communities')
        .doc(communityId)
        .collection('reports')
        .doc(reportId)
        .update({
      'status': isDismissed ? 'dismissed' : 'reviewed',
      'reviewedByUid': uid,
      'reviewedAt': FieldValue.serverTimestamp(),
      'reviewNote': note,
    });
  }
}
