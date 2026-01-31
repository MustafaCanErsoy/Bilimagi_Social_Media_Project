import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum NotificationType {
  follow,    // Someone followed you
  mention,   // Someone mentioned you in a comment
  reply,     // Someone replied to your comment
  upvote,    // Someone upvoted your comment
}

class AppNotification {
  final String id;
  final NotificationType type;
  final String fromUid;
  final String fromDisplayName;
  final String? targetId;      // commentId for reply/mention/upvote
  final String? weekId;
  final String? articleId;
  final String? preview;       // Comment preview text
  final DateTime createdAt;
  final bool read;

  AppNotification({
    required this.id,
    required this.type,
    required this.fromUid,
    required this.fromDisplayName,
    this.targetId,
    this.weekId,
    this.articleId,
    this.preview,
    required this.createdAt,
    this.read = false,
  });

  factory AppNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppNotification(
      id: doc.id,
      type: NotificationType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => NotificationType.follow,
      ),
      fromUid: data['fromUid'] ?? '',
      fromDisplayName: data['fromDisplayName'] ?? '',
      targetId: data['targetId'],
      weekId: data['weekId'],
      articleId: data['articleId'],
      preview: data['preview'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      read: data['read'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'type': type.name,
      'fromUid': fromUid,
      'fromDisplayName': fromDisplayName,
      if (targetId != null) 'targetId': targetId,
      if (weekId != null) 'weekId': weekId,
      if (articleId != null) 'articleId': articleId,
      if (preview != null) 'preview': preview,
      'createdAt': FieldValue.serverTimestamp(),
      'read': read,
    };
  }

  String get message {
    switch (type) {
      case NotificationType.follow:
        return '$fromDisplayName seni takip etmeye başladı';
      case NotificationType.mention:
        return '$fromDisplayName senden bahsetti';
      case NotificationType.reply:
        return '$fromDisplayName yorumuna yanıt verdi';
      case NotificationType.upvote:
        return '$fromDisplayName yorumunu beğendi';
    }
  }

  String get icon {
    switch (type) {
      case NotificationType.follow:
        return 'person_add';
      case NotificationType.mention:
        return 'alternate_email';
      case NotificationType.reply:
        return 'reply';
      case NotificationType.upvote:
        return 'thumb_up';
    }
  }
}

class NotificationService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String? get _currentUid => _auth.currentUser?.uid;

  /// Get notifications for current user
  Stream<List<AppNotification>> getNotifications() {
    final uid = _currentUid;
    if (uid == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AppNotification.fromFirestore(doc))
            .toList());
  }

  /// Get unread count for current user
  Stream<int> getUnreadCount() {
    final uid = _currentUid;
    if (uid == null) return Stream.value(0);

    return _firestore
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    final uid = _currentUid;
    if (uid == null) return;

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .doc(notificationId)
        .update({'read': true});
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    final uid = _currentUid;
    if (uid == null) return;

    final batch = _firestore.batch();
    final notifications = await _firestore
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .where('read', isEqualTo: false)
        .get();

    for (final doc in notifications.docs) {
      batch.update(doc.reference, {'read': true});
    }

    await batch.commit();
  }

  /// Create a follow notification
  Future<void> createFollowNotification({
    required String targetUid,
    required String fromDisplayName,
    String? fromUid,
  }) async {
    final uid = fromUid ?? _currentUid;
    if (uid == null || uid == targetUid) {
      print('🔔 Follow notification skipped: uid=$uid, targetUid=$targetUid');
      return;
    }

    try {
      await _firestore
          .collection('users')
          .doc(targetUid)
          .collection('notifications')
          .add(AppNotification(
            id: '',
            type: NotificationType.follow,
            fromUid: uid,
            fromDisplayName: fromDisplayName,
            createdAt: DateTime.now(),
          ).toFirestore());
      print('🔔 Follow notification created for $targetUid from $fromDisplayName');
    } catch (e) {
      print('🔔 Follow notification error: $e');
    }
  }

  /// Create a mention notification
  Future<void> createMentionNotification({
    required String targetUid,
    required String fromDisplayName,
    required String weekId,
    required String articleId,
    required String commentId,
    String? preview,
  }) async {
    final uid = _currentUid;
    if (uid == null || uid == targetUid) return;

    await _firestore
        .collection('users')
        .doc(targetUid)
        .collection('notifications')
        .add(AppNotification(
          id: '',
          type: NotificationType.mention,
          fromUid: uid,
          fromDisplayName: fromDisplayName,
          targetId: commentId,
          weekId: weekId,
          articleId: articleId,
          preview: preview,
          createdAt: DateTime.now(),
        ).toFirestore());
  }

  /// Create a reply notification
  Future<void> createReplyNotification({
    required String targetUid,
    required String fromDisplayName,
    required String weekId,
    required String articleId,
    required String commentId,
    String? preview,
  }) async {
    final uid = _currentUid;
    if (uid == null || uid == targetUid) return;

    await _firestore
        .collection('users')
        .doc(targetUid)
        .collection('notifications')
        .add(AppNotification(
          id: '',
          type: NotificationType.reply,
          fromUid: uid,
          fromDisplayName: fromDisplayName,
          targetId: commentId,
          weekId: weekId,
          articleId: articleId,
          preview: preview,
          createdAt: DateTime.now(),
        ).toFirestore());
  }

  /// Create an upvote notification
  Future<void> createUpvoteNotification({
    required String targetUid,
    required String fromDisplayName,
    required String weekId,
    required String articleId,
    required String commentId,
  }) async {
    final uid = _currentUid;
    if (uid == null || uid == targetUid) return;

    // Check if we already sent an upvote notification for this comment
    // to avoid spam
    final existing = await _firestore
        .collection('users')
        .doc(targetUid)
        .collection('notifications')
        .where('type', isEqualTo: 'upvote')
        .where('fromUid', isEqualTo: uid)
        .where('targetId', isEqualTo: commentId)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) return;

    await _firestore
        .collection('users')
        .doc(targetUid)
        .collection('notifications')
        .add(AppNotification(
          id: '',
          type: NotificationType.upvote,
          fromUid: uid,
          fromDisplayName: fromDisplayName,
          targetId: commentId,
          weekId: weekId,
          articleId: articleId,
          createdAt: DateTime.now(),
        ).toFirestore());
  }
}
