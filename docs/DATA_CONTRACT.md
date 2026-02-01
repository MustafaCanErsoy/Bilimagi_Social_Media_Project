# Bilimagi Data Contract

**Version:** v6.0
**Last Updated:** 2026-02-01

Bu dosya Firestore veritabanı şemasını ve veri akışlarını detaylı şekilde açıklar.

---

## Koleksiyon Yapısı Özeti

```
firestore/
├── users/{uid}/
│   ├── following/{targetUid}/
│   ├── followers/{followerUid}/
│   ├── notifications/{notificationId}/
│   ├── savedArticles/{articleId}/
│   └── activities/{activityId}/              [v6.0]
├── communities/{communityId}/
│   ├── members/{uid}/
│   ├── bans/{bannedUid}/                     [v6.0]
│   └── moderationLogs/{logId}/               [v6.0]
└── weeks/{weekId}/
    ├── articles/{articleId}/
    │   ├── votes/{uid}/
    │   └── comments/{commentId}/
    │       └── votes/{uid}/
    └── suggestions/{suggestionId}/           [v5.0]
        └── interests/{uid}/                  [v5.0]
```

---

## 1. Users Koleksiyonu

### users/{uid}
Kullanıcı profil bilgileri.

| Alan | Tip | Açıklama |
|------|-----|----------|
| `displayName` | string | Görünen isim |
| `email` | string | E-posta adresi |
| `photoURL` | string? | Profil fotoğrafı URL'i |
| `bio` | string? | Kullanıcı biyografisi |
| `role` | string | "admin" \| "member" |
| `avatarColorIndex` | number? | Avatar renk indeksi (0-9) |
| `createdAt` | timestamp | Hesap oluşturma tarihi |
| `stats` | map | İstatistikler (aşağıda) |

**stats alt alanları:**
| Alan | Tip | Açıklama |
|------|-----|----------|
| `totalVotes` | number | Toplam verilen oy |
| `totalComments` | number | Toplam yorum sayısı |
| `followersCount` | number | Takipçi sayısı |
| `followingCount` | number | Takip edilen sayısı |
| `joinedAt` | timestamp | Katılım tarihi |

---

### users/{uid}/following/{targetUid}
Kullanıcının takip ettiği kişiler.

| Alan | Tip | Açıklama |
|------|-----|----------|
| `followedAt` | timestamp | Takip başlangıç tarihi |

---

### users/{uid}/followers/{followerUid}
Kullanıcıyı takip edenler.

| Alan | Tip | Açıklama |
|------|-----|----------|
| `followedAt` | timestamp | Takip başlangıç tarihi |

---

### users/{uid}/notifications/{notificationId}
Kullanıcı bildirimleri.

| Alan | Tip | Açıklama |
|------|-----|----------|
| `type` | string | Bildirim türü (aşağıda) |
| `fromUid` | string | Bildirimi tetikleyen kullanıcı |
| `fromDisplayName` | string | Kullanıcı görünen ismi |
| `read` | boolean | Okundu mu? |
| `createdAt` | timestamp | Oluşturulma tarihi |
| `targetId` | string? | Hedef yorum ID'si |
| `weekId` | string? | İlgili hafta ID'si |
| `articleId` | string? | İlgili makale ID'si |
| `preview` | string? | Önizleme metni |
| `communityId` | string? | İlgili topluluk ID'si |
| `communityName` | string? | Topluluk adı |
| `newRole` | string? | Yeni rol (roleChanged için) [v6.0] |

**Bildirim Türleri (type):**
| Değer | Açıklama | Versiyon |
|-------|----------|----------|
| `follow` | Birisi seni takip etti | v1.0 |
| `mention` | Birisi senden bahsetti | v3.0 |
| `reply` | Birisi yorumuna yanıt verdi | v3.0 |
| `upvote` | Birisi yorumunu beğendi | v3.0 |
| `membershipRequest` | Birisi topluluğuna katılmak istiyor | v5.0 |
| `membershipApproved` | Üyelik başvurun onaylandı | v5.0 |
| `membershipRejected` | Üyelik başvurun reddedildi | v5.0 |
| `suggestionApproved` | Makale önerin onaylandı | v5.0 |
| `suggestionRejected` | Makale önerin reddedildi | v5.0 |
| `roleChanged` | Topluluktaki rolün değişti | v6.0 |
| `memberRemoved` | Topluluktan çıkarıldın | v6.0 |

---

### users/{uid}/savedArticles/{articleId}
Kaydedilen makaleler (denormalize).

| Alan | Tip | Açıklama |
|------|-----|----------|
| `title` | string | Makale başlığı |
| `summary` | string | Makale özeti |
| `weekId` | string | Hafta ID'si |
| `savedAt` | timestamp | Kaydetme tarihi |

---

### users/{uid}/activities/{activityId} [v6.0]
Kullanıcı aktiviteleri (takip akışı için).

| Alan | Tip | Açıklama |
|------|-----|----------|
| `uid` | string | Kullanıcı ID'si |
| `displayName` | string | Görünen isim |
| `avatarColorIndex` | number | Avatar renk indeksi |
| `type` | string | Aktivite türü (aşağıda) |
| `targetType` | string | Hedef türü (aşağıda) |
| `targetId` | string | Hedef ID'si |
| `targetName` | string? | Hedef adı |
| `weekId` | string? | İlgili hafta ID'si |
| `communityId` | string? | İlgili topluluk ID'si |
| `communityName` | string? | Topluluk adı |
| `preview` | string? | Önizleme metni |
| `createdAt` | timestamp | Aktivite zamanı |

**Aktivite Türleri (type):**
| Değer | Açıklama |
|-------|----------|
| `comment` | Yorum yaptı |
| `vote` | Oy verdi |
| `join` | Topluluğa katıldı |
| `suggestion` | Makale önerdi |

**Hedef Türleri (targetType):**
| Değer | Açıklama |
|-------|----------|
| `article` | Makale |
| `community` | Topluluk |
| `user` | Kullanıcı |

---

## 2. Communities Koleksiyonu

### communities/{communityId}
Topluluk bilgileri.

| Alan | Tip | Açıklama |
|------|-----|----------|
| `name` | string | Topluluk adı |
| `description` | string | Açıklama |
| `ownerUid` | string | Sahip kullanıcı ID'si |
| `currentWeekId` | string? | Aktif hafta ID'si |
| `category` | string | Kategori kodu |
| `customCategory` | string? | Özel kategori adı |
| `iconEmoji` | string? | Simge emoji |
| `colorIndex` | number | Renk indeksi 0-7 |
| `createdAt` | timestamp | Oluşturulma tarihi |
| `isPublic` | boolean | Herkese açık mı? |
| `isDeleted` | boolean | Silindi mi? (soft delete) [v6.0] |
| `stats` | map | İstatistikler |

**category değerleri:**
| Kod | Türkçe |
|-----|--------|
| `physics` | Fizik |
| `biology` | Biyoloji |
| `chemistry` | Kimya |
| `mathematics` | Matematik |
| `medicine` | Tıp |
| `engineering` | Mühendislik |
| `psychology` | Psikoloji |
| `other` | Diğer (customCategory kullanılır) |

**colorIndex değerleri:**
| İndeks | Renk |
|--------|------|
| 0 | Mavi (#2196F3) |
| 1 | Yeşil (#4CAF50) |
| 2 | Turuncu (#FF9800) |
| 3 | Mor (#9C27B0) |
| 4 | Kırmızı (#F44336) |
| 5 | Turkuaz (#00BCD4) |
| 6 | Pembe (#E91E63) |
| 7 | Kahverengi (#795548) |

**stats alt alanları:**
| Alan | Tip | Açıklama |
|------|-----|----------|
| `memberCount` | number | Üye sayısı |
| `weekCount` | number | Toplam hafta sayısı |
| `totalArticles` | number | Toplam makale sayısı |

---

### communities/{communityId}/members/{uid}
Topluluk üyeleri.

| Alan | Tip | Açıklama |
|------|-----|----------|
| `uid` | string | Kullanıcı ID'si |
| `displayName` | string | Görünen isim |
| `role` | string | "owner" \| "moderator" \| "member" |
| `status` | string | "pending" \| "approved" \| "rejected" |
| `requestedAt` | timestamp | Başvuru tarihi |
| `approvedAt` | timestamp? | Onay tarihi |
| `approvedByUid` | string? | Onaylayan kullanıcı |

**Rol Yetkileri:**
| Rol | Yetkiler |
|-----|----------|
| `owner` | Tüm yetkiler, topluluğu silme, moderatör atama |
| `moderator` | Öneri onaylama, üye kabul/red, üye çıkarma, yorum gizleme, kullanıcı banlama |
| `member` | Oylama, yorum yapma, makale önerme |

---

### communities/{communityId}/bans/{bannedUid} [v6.0]
Yasaklı kullanıcılar.

| Alan | Tip | Açıklama |
|------|-----|----------|
| `bannedUid` | string | Yasaklanan kullanıcı ID'si |
| `bannedDisplayName` | string | Yasaklanan kullanıcı adı |
| `bannedByUid` | string | Yasaklayan moderatör ID'si |
| `bannedByDisplayName` | string | Yasaklayan moderatör adı |
| `bannedAt` | timestamp | Yasaklanma tarihi |
| `expiresAt` | timestamp? | Yasak bitiş tarihi (null = kalıcı) |
| `reason` | string | Yasaklanma sebebi |

---

### communities/{communityId}/moderationLogs/{logId} [v6.0]
Moderasyon işlem geçmişi (audit log).

| Alan | Tip | Açıklama |
|------|-----|----------|
| `type` | string | İşlem türü (aşağıda) |
| `moderatorUid` | string | İşlemi yapan moderatör ID'si |
| `moderatorDisplayName` | string | Moderatör adı |
| `targetUid` | string? | Hedef kullanıcı ID'si |
| `targetDisplayName` | string? | Hedef kullanıcı adı |
| `targetId` | string? | Hedef içerik ID'si (yorum vb.) |
| `reason` | string? | İşlem sebebi |
| `details` | string? | Ek detaylar |
| `createdAt` | timestamp | İşlem zamanı |

**Moderasyon İşlem Türleri (type):**
| Değer | Açıklama |
|-------|----------|
| `hideComment` | Yorum gizlendi |
| `unhideComment` | Yorum görünür yapıldı |
| `banUser` | Kullanıcı yasaklandı |
| `unbanUser` | Kullanıcı yasağı kaldırıldı |
| `changeRole` | Kullanıcı rolü değiştirildi |
| `removeMember` | Kullanıcı topluluktan çıkarıldı |
| `approveMember` | Üyelik onaylandı |
| `rejectMember` | Üyelik reddedildi |
| `approveSuggestion` | Öneri onaylandı |
| `rejectSuggestion` | Öneri reddedildi |

---

## 3. Weeks Koleksiyonu

### weeks/{weekId}
Haftalık oylama/tartışma döngüsü.

| Alan | Tip | Açıklama |
|------|-----|----------|
| `communityId` | string | Ait olduğu topluluk |
| `phase` | string | "voting" \| "discussion" \| "closed" |
| `createdAt` | timestamp | Oluşturulma tarihi |
| `lastVoteAt` | timestamp? | Son oy zamanı (stream trigger) |

**Faz Akışı:**
```
voting → discussion → closed
   ↑_________|  (yeni hafta ile)
```

---

### weeks/{weekId}/articles/{articleId}
Haftalık makaleler.

| Alan | Tip | Açıklama |
|------|-----|----------|
| `title` | string | Makale başlığı |
| `summary` | string | Özet |
| `link` | string | Makale URL'i |
| `suggestedByUid` | string? | Öneren kullanıcı |
| `suggestedByDisplayName` | string? | Öneren ismi |
| `suggestionId` | string? | Kaynak öneri ID'si |
| `createdAt` | timestamp? | Oluşturulma tarihi |

---

### weeks/{weekId}/articles/{articleId}/votes/{uid}
Makale oyları.

| Alan | Tip | Açıklama |
|------|-----|----------|
| `choice` | string | Seçilen makale ID'si |
| `weekId` | string | Hafta ID'si |
| `updatedAt` | timestamp | Oy zamanı |

---

### weeks/{weekId}/articles/{articleId}/comments/{commentId}
Makale yorumları.

| Alan | Tip | Açıklama |
|------|-----|----------|
| `uid` | string | Yorum sahibi |
| `displayName` | string | Görünen isim |
| `text` | string | Yorum metni |
| `createdAt` | timestamp | Oluşturulma tarihi |
| `parentId` | string? | Üst yorum ID'si (yanıt için) |
| `depth` | number | Yuvalama derinliği (0, 1, 2...) |
| `replyCount` | number | Yanıt sayısı |
| `upvoteCount` | number | Beğeni sayısı |
| `downvoteCount` | number | Beğenmeme sayısı |
| `score` | number | upvoteCount - downvoteCount |
| `isEdited` | boolean? | Düzenlendi mi? |
| `editedAt` | timestamp? | Düzenleme zamanı |
| `isDeleted` | boolean? | Silindi mi? (soft delete) |
| `isHidden` | boolean? | Moderatör tarafından gizlendi mi? [v6.0] |
| `hiddenByUid` | string? | Gizleyen moderatör ID'si [v6.0] |
| `hiddenAt` | timestamp? | Gizlenme zamanı [v6.0] |
| `hiddenReason` | string? | Gizleme sebebi [v6.0] |

**@mention formatı:**
```
@[Kullanıcı Adı](userId)
```

---

### weeks/{weekId}/articles/{articleId}/comments/{commentId}/votes/{uid}
Yorum oyları.

| Alan | Tip | Açıklama |
|------|-----|----------|
| `value` | number | 1 (upvote) veya -1 (downvote) |
| `createdAt` | timestamp | Oy zamanı |

---

### weeks/{weekId}/suggestions/{suggestionId}
Makale önerileri.

| Alan | Tip | Açıklama |
|------|-----|----------|
| `title` | string | Makale başlığı |
| `summary` | string | Özet |
| `link` | string | Makale URL'i |
| `submitterUid` | string | Öneren kullanıcı |
| `submitterDisplayName` | string | Öneren ismi |
| `createdAt` | timestamp | Gönderilme tarihi |
| `status` | string | "pending" \| "approved" \| "rejected" |
| `interestScore` | number | İlgi oyu sayısı |
| `reviewerUid` | string? | İnceleyen moderatör |
| `reviewedAt` | timestamp? | İnceleme zamanı |
| `rejectionReason` | string? | Red sebebi |

---

### weeks/{weekId}/suggestions/{suggestionId}/interests/{uid}
Öneri ilgi oyları.

| Alan | Tip | Açıklama |
|------|-----|----------|
| `createdAt` | timestamp | Oy zamanı |

---

## Sorgu Kalıpları

### Kullanıcının Üye Olduğu Topluluklar
```dart
collectionGroup('members')
  .where('uid', isEqualTo: userId)
  .where('status', isEqualTo: 'approved')
```

### Bekleyen Üyelik İstekleri
```dart
collection('communities/{id}/members')
  .where('status', isEqualTo: 'pending')
```

### Aktif Tartışmalar (Home Feed)
```dart
collection('weeks')
  .where('phase', isEqualTo: 'discussion')
  .limit(20)
// + client-side: community.isDeleted == false filtresi
```

### Oylama Fazındaki Haftalar
```dart
collection('weeks')
  .where('phase', isEqualTo: 'voting')
// + client-side: community.isDeleted == false filtresi
```

### Bekleyen Öneriler
```dart
collection('weeks/{weekId}/suggestions')
  .where('status', isEqualTo: 'pending')
```

### Public Topluluklar (Silinmemiş) [v6.0]
```dart
collection('communities')
  .where('isPublic', isEqualTo: true)
// + client-side: isDeleted == false filtresi
```

### Topluluk Arama (Client-side) [v6.0]
```dart
// Tüm public topluluklar alınır, sonra filtrelenir:
communities.where((c) =>
  c.name.toLowerCase().contains(query) ||
  c.description.toLowerCase().contains(query) ||
  c.category.contains(query)
)
```

### Yasaklı Kullanıcılar [v6.0]
```dart
collection('communities/{id}/bans')
  .orderBy('bannedAt', descending: true)
```

### Moderasyon Logları [v6.0]
```dart
collection('communities/{id}/moderationLogs')
  .orderBy('createdAt', descending: true)
  .limit(50)
```

### Takip Edilen Aktiviteler [v6.0]
```dart
// Her takip edilen için:
collection('users/{followedUid}/activities')
  .orderBy('createdAt', descending: true)
  .limit(10)
// Sonra client-side merge ve sıralama
```

---

## Firestore Güvenlik Kuralları (Özet)

```javascript
// Kullanıcılar
match /users/{userId} {
  allow read: if request.auth != null;
  allow write: if request.auth.uid == userId;
}

// Aktiviteler
match /users/{userId}/activities/{activityId} {
  allow read: if request.auth != null;
  allow write: if request.auth.uid == userId;
}

// Topluluklar
match /communities/{communityId} {
  allow read: if resource.data.isPublic == true;
  allow create: if request.auth != null;
  allow update: if isOwnerOrMod(communityId);
  allow delete: if isOwner(communityId);
}

// Üyelikler
match /communities/{communityId}/members/{uid} {
  allow read: if request.auth != null;
  allow create: if request.auth.uid == uid; // Kendi başvurusu
  allow update: if isOwnerOrMod(communityId);
  allow delete: if isOwnerOrMod(communityId);
}

// Banlar [v6.0]
match /communities/{communityId}/bans/{bannedUid} {
  allow read: if request.auth != null;
  allow write: if isOwnerOrMod(communityId);
}

// Moderasyon Logları [v6.0]
match /communities/{communityId}/moderationLogs/{logId} {
  allow read: if isOwnerOrMod(communityId);
  allow create: if isOwnerOrMod(communityId);
}

// Öneriler
match /weeks/{weekId}/suggestions/{suggestionId} {
  allow read: if request.auth != null;
  allow create: if isMember(weekId);
  allow update: if isOwnerOrMod(weekId);
}

// Yorumlar (gizleme için) [v6.0]
match /weeks/{weekId}/articles/{articleId}/comments/{commentId} {
  allow read: if request.auth != null;
  allow create: if request.auth != null;
  allow update: if request.auth.uid == resource.data.uid || isOwnerOrMod(weekId);
}
```

---

## Veri Akış Diyagramları

### Üyelik Başvuru Akışı
```
Kullanıcı                    Sistem                     Owner/Mod
    |                          |                           |
    |-- Katıl isteği --------> |                           |
    |                          |-- Kaydet (pending) -----> |
    |                          |-- Bildirim gönder ------> |
    |                          |                           |
    |                          | <-- Onayla/Reddet --------|
    |                          |-- Durum güncelle          |
    | <-- Bildirim ----------- |                           |
```

### Makale Önerisi Akışı
```
Üye                          Sistem                     Moderatör
 |                              |                           |
 |-- Öneri gönder ------------> |                           |
 |                              |-- Kaydet (pending)        |
 |                              |                           |
 |-- İlgi oyu ver ------------> |-- interestScore++        |
 |                              |                           |
 |                              | <-- Onayla ---------------|
 |                              |-- Article oluştur         |
 |                              |-- stats.totalArticles++   |
 | <-- Bildirim --------------- |                           |
```

### Yorum Gizleme Akışı [v6.0]
```
Moderatör                    Sistem                     Kullanıcı
    |                          |                           |
    |-- Yorumu gizle --------> |                           |
    |                          |-- isHidden = true         |
    |                          |-- hiddenByUid = mod       |
    |                          |-- Audit log kaydet        |
    |                          |                           |
    |                          |-- [Yorum gizli görünür] ->|
```

### Kullanıcı Banlama Akışı [v6.0]
```
Moderatör                    Sistem                     Kullanıcı
    |                          |                           |
    |-- Kullanıcıyı banla ---> |                           |
    |                          |-- Ban kaydı oluştur       |
    |                          |-- Üyelikten çıkar         |
    |                          |-- Audit log kaydet        |
    |                          |-- Bildirim gönder ------->|
```

---

## Index Gereksinimleri

Firestore composite index gerektiren sorgular:

| Koleksiyon | Alanlar | Sıralama |
|------------|---------|----------|
| `members` (collectionGroup) | `uid`, `status` | - |
| `suggestions` | `status`, `interestScore` | DESC |
| `activities` | `uid`, `createdAt` | DESC |
| `moderationLogs` | `communityId`, `createdAt` | DESC |
| `bans` | `communityId`, `bannedAt` | DESC |

---

## Enum Değerleri Özeti

### NotificationType
```dart
enum NotificationType {
  follow,            // v1.0
  mention,           // v3.0
  reply,             // v3.0
  upvote,            // v3.0
  membershipRequest, // v5.0
  membershipApproved,// v5.0
  membershipRejected,// v5.0
  suggestionApproved,// v5.0
  suggestionRejected,// v5.0
  roleChanged,       // v6.0
  memberRemoved,     // v6.0
}
```

### MemberRole
```dart
enum MemberRole {
  owner,
  moderator,
  member,
}
```

### MemberStatus
```dart
enum MemberStatus {
  pending,
  approved,
  rejected,
}
```

### WeekPhase
```dart
enum WeekPhase {
  voting,
  discussion,
  closed,
}
```

### SuggestionStatus
```dart
enum SuggestionStatus {
  pending,
  approved,
  rejected,
}
```

### ActivityType [v6.0]
```dart
enum ActivityType {
  comment,
  vote,
  join,
  suggestion,
}
```

### ModerationActionType [v6.0]
```dart
enum ModerationActionType {
  hideComment,
  unhideComment,
  banUser,
  unbanUser,
  changeRole,
  removeMember,
  approveMember,
  rejectMember,
  approveSuggestion,
  rejectSuggestion,
}
```

### CommunityCategory
```dart
class CommunityCategory {
  static const physics = 'physics';
  static const biology = 'biology';
  static const chemistry = 'chemistry';
  static const mathematics = 'mathematics';
  static const medicine = 'medicine';
  static const engineering = 'engineering';
  static const psychology = 'psychology';
  static const other = 'other';
}
```

---

**Son Güncelleme:** 2026-02-01 (v6.0)
