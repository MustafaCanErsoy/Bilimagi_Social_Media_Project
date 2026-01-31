import 'package:cloud_firestore/cloud_firestore.dart';

class Article {
  final String id;
  final String title;
  final String summary;
  final String link;
  int voteCount;

  Article({
    required this.id,
    required this.title,
    required this.summary,
    required this.link,
    this.voteCount = 0,
  });

  factory Article.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Article(
      id: doc.id,
      title: data['title'] ?? '',
      summary: data['summary'] ?? '',
      link: data['link'] ?? '',
    );
  }

  Article copyWith({int? voteCount}) {
    return Article(
      id: id,
      title: title,
      summary: summary,
      link: link,
      voteCount: voteCount ?? this.voteCount,
    );
  }
}
