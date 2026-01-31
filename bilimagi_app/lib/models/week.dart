import 'package:cloud_firestore/cloud_firestore.dart';

enum WeekPhase { voting, discussion, closed }

class Week {
  final String id;
  final String communityId;
  final WeekPhase phase;
  final DateTime createdAt;

  Week({
    required this.id,
    required this.communityId,
    required this.phase,
    required this.createdAt,
  });

  factory Week.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Week(
      id: doc.id,
      communityId: data['communityId'] ?? '',
      phase: _parsePhase(data['phase']),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  static WeekPhase _parsePhase(String? phase) {
    switch (phase) {
      case 'voting':
        return WeekPhase.voting;
      case 'discussion':
        return WeekPhase.discussion;
      case 'closed':
        return WeekPhase.closed;
      default:
        return WeekPhase.voting;
    }
  }

  static String phaseToString(WeekPhase phase) {
    switch (phase) {
      case WeekPhase.voting:
        return 'voting';
      case WeekPhase.discussion:
        return 'discussion';
      case WeekPhase.closed:
        return 'closed';
    }
  }

  String get phaseDisplayName {
    switch (phase) {
      case WeekPhase.voting:
        return 'Oylama';
      case WeekPhase.discussion:
        return 'Tartışma';
      case WeekPhase.closed:
        return 'Kapalı';
    }
  }
}
