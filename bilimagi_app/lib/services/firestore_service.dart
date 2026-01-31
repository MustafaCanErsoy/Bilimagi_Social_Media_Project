import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/community.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<Community>> getCommunities() {
    return _db.collection('communities').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Community.fromFirestore(doc)).toList();
    });
  }

  Future<Community?> getCommunity(String communityId) async {
    final doc = await _db.collection('communities').doc(communityId).get();
    if (doc.exists) {
      return Community.fromFirestore(doc);
    }
    return null;
  }
}
