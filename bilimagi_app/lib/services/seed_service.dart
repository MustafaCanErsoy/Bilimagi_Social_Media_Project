import 'package:cloud_firestore/cloud_firestore.dart';

/// Seed service for Bilimagi MVP demo data
class SeedService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> seedDatabase() async {
    print('🌱 Starting Firestore seed...\n');

    try {
      // Step 1: Create demo users in Firestore
      print('📝 Creating user profiles...');
      await _seedUsers();

      // Step 2: Create communities
      print('🏘️  Creating communities...');
      final communityIds = await _seedCommunities();

      // Step 3: Create weeks for each community
      print('📅 Creating weeks...');
      final weekIds = await _seedWeeks(communityIds);

      // Step 4: Create articles for each week
      print('📄 Creating articles...');
      await _seedArticles(weekIds);

      print('\n✅ Seed completed successfully!');
      print('Communities: ${communityIds.length}');
      print('Weeks: ${weekIds.length}');
    } catch (e) {
      print('❌ Error during seed: $e');
      rethrow;
    }
  }

  Future<void> _seedUsers() async {
    final users = [
      {
        'uid': '20ShZTwj7eWHvkH07yJfS3Dmbim2',
        'role': 'admin',
        'displayName': 'Admin User',
        'communityIds': [],
      },
      {
        'uid': 'b1fKshU0sDhqqBELKTgxCtyILcl2',
        'role': 'member',
        'displayName': 'Ahmet Yılmaz',
        'communityIds': ['physics-community', 'biology-community'],
      },
      {
        'uid': 'cKzFatBm8WOHcoYUonP8khEw3tq2',
        'role': 'member',
        'displayName': 'Ayşe Demir',
        'communityIds': ['physics-community', 'biology-community'],
      },
    ];

    for (final user in users) {
      await _firestore.collection('users').doc(user['uid'] as String).set(user);
      print('  ✓ User: ${user['displayName']}');
    }
  }

  Future<List<String>> _seedCommunities() async {
    final communities = [
      {
        'id': 'physics-community',
        'name': 'Fizik Topluluğu',
        'description': 'Kuantum mekaniği, astrofizik ve modern fizik üzerine haftalık tartışmalar',
        'ownerUid': '20ShZTwj7eWHvkH07yJfS3Dmbim2',
        'currentWeekId': null,
      },
      {
        'id': 'biology-community',
        'name': 'Biyoloji Topluluğu',
        'description': 'Genetik, evrim ve moleküler biyoloji alanında bilimsel makaleler',
        'ownerUid': '20ShZTwj7eWHvkH07yJfS3Dmbim2',
        'currentWeekId': null,
      },
    ];

    final ids = <String>[];
    for (final community in communities) {
      final id = community['id'] as String;
      await _firestore.collection('communities').doc(id).set({
        'name': community['name'],
        'description': community['description'],
        'ownerUid': community['ownerUid'],
        'currentWeekId': community['currentWeekId'],
      });
      ids.add(id);
      print('  ✓ Community: ${community['name']}');
    }

    return ids;
  }

  Future<List<Map<String, String>>> _seedWeeks(List<String> communityIds) async {
    final weekIds = <Map<String, String>>[];

    for (final communityId in communityIds) {
      final weekId = '$communityId-week-001';
      await _firestore.collection('weeks').doc(weekId).set({
        'communityId': communityId,
        'phase': 'voting',
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _firestore.collection('communities').doc(communityId).update({
        'currentWeekId': weekId,
      });

      weekIds.add({'communityId': communityId, 'weekId': weekId});
      print('  ✓ Week: $weekId (phase: voting)');
    }

    return weekIds;
  }

  Future<void> _seedArticles(List<Map<String, String>> weekIds) async {
    // Physics articles
    final physicsWeek = weekIds.firstWhere((w) => w['communityId'] == 'physics-community');
    final physicsArticles = [
      {
        'title': 'Kuantum Dolanıklık ve Einstein-Podolsky-Rosen Paradoksu',
        'summary': 'Kuantum mekaniğinin en şaşırtıcı özelliklerinden biri olan dolanıklık olayının deneysel kanıtları ve teorik temelleri üzerine kapsamlı bir inceleme.',
        'link': 'https://arxiv.org/abs/quant-ph/0101012',
      },
      {
        'title': 'Karadeliklerden Hawking Radyasyonu',
        'summary': 'Stephen Hawking\'in karadeliklerin termal radyasyon yaydığı teorisi ve bu teorinin modern astrofiziğe etkileri üzerine güncel araştırmalar.',
        'link': 'https://arxiv.org/abs/hep-th/9204017',
      },
      {
        'title': 'Higgs Bozonunun Keşfi ve Standart Model',
        'summary': 'CERN\'deki LHC deneylerinde Higgs bozonunun keşfi ve bu keşfin parçacık fiziğinin Standart Modeli için önemi.',
        'link': 'https://arxiv.org/abs/1207.7214',
      },
      {
        'title': 'Karanlık Madde ve Galaksi Rotasyon Eğrileri',
        'summary': 'Galaksilerin gözlemlenen rotasyon hızlarının karanlık madde hipotezi ile açıklanması ve alternatif teoriler.',
        'link': 'https://arxiv.org/abs/astro-ph/0206508',
      },
    ];

    for (int i = 0; i < physicsArticles.length; i++) {
      final articleId = 'physics-article-00${i + 1}';
      await _firestore
          .collection('weeks')
          .doc(physicsWeek['weekId'])
          .collection('articles')
          .doc(articleId)
          .set(physicsArticles[i]);
      final title = physicsArticles[i]['title'] ?? '';
      final displayTitle = title.length > 40 ? '${title.substring(0, 40)}...' : title;
      print('  ✓ Article: $displayTitle');
    }

    // Biology articles
    final biologyWeek = weekIds.firstWhere((w) => w['communityId'] == 'biology-community');
    final biologyArticles = [
      {
        'title': 'CRISPR-Cas9 Gen Düzenleme Teknolojisi',
        'summary': 'CRISPR-Cas9 sisteminin gen düzenleme alanındaki devrimci uygulamaları ve potansiyel tıbbi kullanımları.',
        'link': 'https://www.nature.com/articles/nature14299',
      },
      {
        'title': 'Epigenetik: DNA Dizisi Değişmeden Gen İfadesinin Düzenlenmesi',
        'summary': 'DNA metilasyonu ve histon modifikasyonları yoluyla gen ifadesinin nasıl kontrol edildiği ve bu süreçlerin hastalıklardaki rolü.',
        'link': 'https://www.nature.com/articles/nrg3230',
      },
      {
        'title': 'İnsan Mikrobiyomu ve Sağlık Üzerindeki Etkileri',
        'summary': 'İnsan vücudundaki mikroorganizma topluluklarının metabolizma, bağışıklık sistemi ve ruh sağlığı üzerindeki etkileri.',
        'link': 'https://www.nature.com/articles/nature11234',
      },
      {
        'title': 'Evrimsel Gelişim Biyolojisi (Evo-Devo)',
        'summary': 'Organizmaların gelişim süreçlerinin evrimi ve bu süreçlerin morfolojik çeşitlilik üzerindeki etkisi.',
        'link': 'https://www.nature.com/articles/nrg1556',
      },
      {
        'title': 'mRNA Aşıları: COVID-19\'dan Öğrendiklerimiz',
        'summary': 'mRNA bazlı aşı teknolojisinin gelişimi, COVID-19 pandemisindeki başarısı ve gelecekteki uygulamaları.',
        'link': 'https://www.nature.com/articles/nrd.2017.243',
      },
    ];

    for (int i = 0; i < biologyArticles.length; i++) {
      final articleId = 'biology-article-00${i + 1}';
      await _firestore
          .collection('weeks')
          .doc(biologyWeek['weekId'])
          .collection('articles')
          .doc(articleId)
          .set(biologyArticles[i]);
      final title = biologyArticles[i]['title'] ?? '';
      final displayTitle = title.length > 40 ? '${title.substring(0, 40)}...' : title;
      print('  ✓ Article: $displayTitle');
    }
  }
}
