import 'package:cloud_firestore/cloud_firestore.dart';

class Community {
  final String id;
  final String name;
  final String description;
  final String ownerUid;
  final String? currentWeekId;

  Community({
    required this.id,
    required this.name,
    required this.description,
    required this.ownerUid,
    this.currentWeekId,
  });

  factory Community.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Community(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      ownerUid: data['ownerUid'] ?? '',
      currentWeekId: data['currentWeekId'],
    );
  }
}
