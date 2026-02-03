import 'package:cloud_firestore/cloud_firestore.dart';

/// Report types
enum ReportType {
  comment,
  user,
}

/// Report status
enum ReportStatus {
  pending,
  reviewed,
  dismissed,
}

/// Report reasons (predefined)
class ReportReason {
  static const spam = 'spam';
  static const harassment = 'harassment';
  static const inappropriate = 'inappropriate';
  static const misinformation = 'misinformation';
  static const other = 'other';

  static const all = [spam, harassment, inappropriate, misinformation, other];

  static String getLabel(String reason) {
    switch (reason) {
      case spam:
        return 'Spam';
      case harassment:
        return 'Taciz / Zorbalık';
      case inappropriate:
        return 'Uygunsuz İçerik';
      case misinformation:
        return 'Yanlış Bilgi';
      case other:
        return 'Diğer';
      default:
        return reason;
    }
  }
}

/// Report model for flagged content
class Report {
  final String id;
  final String reporterUid;
  final String reporterDisplayName;
  final ReportType type;
  final String targetId;
  final String targetUid;
  final String? targetDisplayName;
  final String? periodId;
  final String? articleId;
  final String reason;
  final String? details;
  final ReportStatus status;
  final DateTime createdAt;
  final String? reviewedByUid;
  final DateTime? reviewedAt;
  final String? reviewNote;

  Report({
    required this.id,
    required this.reporterUid,
    required this.reporterDisplayName,
    required this.type,
    required this.targetId,
    required this.targetUid,
    this.targetDisplayName,
    this.periodId,
    this.articleId,
    required this.reason,
    this.details,
    required this.status,
    required this.createdAt,
    this.reviewedByUid,
    this.reviewedAt,
    this.reviewNote,
  });

  factory Report.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Report(
      id: doc.id,
      reporterUid: data['reporterUid'] ?? '',
      reporterDisplayName: data['reporterDisplayName'] ?? '',
      type: _parseType(data['type']),
      targetId: data['targetId'] ?? '',
      targetUid: data['targetUid'] ?? '',
      targetDisplayName: data['targetDisplayName'],
      periodId: data['periodId'],
      articleId: data['articleId'],
      reason: data['reason'] ?? '',
      details: data['details'],
      status: _parseStatus(data['status']),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reviewedByUid: data['reviewedByUid'],
      reviewedAt: (data['reviewedAt'] as Timestamp?)?.toDate(),
      reviewNote: data['reviewNote'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'reporterUid': reporterUid,
      'reporterDisplayName': reporterDisplayName,
      'type': type.name,
      'targetId': targetId,
      'targetUid': targetUid,
      'targetDisplayName': targetDisplayName,
      'periodId': periodId,
      'articleId': articleId,
      'reason': reason,
      'details': details,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'reviewedByUid': reviewedByUid,
      'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
      'reviewNote': reviewNote,
    };
  }

  static ReportType _parseType(String? type) {
    switch (type) {
      case 'user':
        return ReportType.user;
      case 'comment':
      default:
        return ReportType.comment;
    }
  }

  static ReportStatus _parseStatus(String? status) {
    switch (status) {
      case 'reviewed':
        return ReportStatus.reviewed;
      case 'dismissed':
        return ReportStatus.dismissed;
      case 'pending':
      default:
        return ReportStatus.pending;
    }
  }
}
