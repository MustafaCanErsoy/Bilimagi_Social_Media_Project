import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile.dart';

class ProfileService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  /// Get user profile by UID
  Stream<UserProfile?> getUserProfile(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserProfile.fromFirestore(doc);
    });
  }

  /// Get current user profile
  Stream<UserProfile?> getCurrentUserProfile() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(null);
    return getUserProfile(uid);
  }

  /// Update user profile
  Future<void> updateProfile({
    String? displayName,
    String? bio,
    String? photoURL,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('No user logged in');

    final updates = <String, dynamic>{};
    if (displayName != null) updates['displayName'] = displayName;
    if (bio != null) updates['bio'] = bio;
    if (photoURL != null) updates['photoURL'] = photoURL;

    if (updates.isNotEmpty) {
      await _firestore.collection('users').doc(uid).update(updates);
    }
  }

  /// Increment user stats (called after actions)
  Future<void> incrementStats({
    int? votes,
    int? comments,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final updates = <String, dynamic>{};
    if (votes != null && votes > 0) {
      updates['stats.totalVotes'] = FieldValue.increment(votes);
    }
    if (comments != null && comments > 0) {
      updates['stats.totalComments'] = FieldValue.increment(comments);
    }

    if (updates.isNotEmpty) {
      await _firestore.collection('users').doc(uid).update(updates);
    }
  }

  /// Initialize user stats if not exists
  Future<void> initializeUserStats(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists && doc.data()?['stats'] == null) {
      await _firestore.collection('users').doc(uid).update({
        'stats': {
          'totalVotes': 0,
          'totalComments': 0,
          'joinedAt': FieldValue.serverTimestamp(),
        },
      });
    }
  }

  /// v4.0: Create new user profile
  Future<void> createUserProfile({
    required String uid,
    required String email,
    required String displayName,
  }) async {
    await _firestore.collection('users').doc(uid).set({
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'role': 'member',
      'bio': null,
      'photoURL': null,
      'avatarColorIndex': uid.hashCode.abs() % 8,
      'interests': [],
      'stats': {
        'totalVotes': 0,
        'totalComments': 0,
        'followersCount': 0,
        'followingCount': 0,
        'joinedAt': FieldValue.serverTimestamp(),
      },
    });
  }

  /// v7.2: Update profile photo URL
  Future<void> updateProfilePhoto(String photoURL) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Kullanici oturumu acik degil');

    await _firestore.collection('users').doc(uid).update({
      'photoURL': photoURL,
    });
  }

  /// v7.2: Remove profile photo
  Future<void> removeProfilePhoto() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Kullanici oturumu acik degil');

    await _firestore.collection('users').doc(uid).update({
      'photoURL': FieldValue.delete(),
    });
  }

  /// v7.2: Update user interests
  Future<void> updateInterests(List<String> interests) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Kullanici oturumu acik degil');

    await _firestore.collection('users').doc(uid).update({
      'interests': interests,
    });
  }

  /// v7.2: Get user profile once (not stream)
  Future<UserProfile?> getUserProfileOnce(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserProfile.fromFirestore(doc);
  }
}
